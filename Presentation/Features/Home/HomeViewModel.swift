import SwiftUI
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Home Data
    @Published var upcomingDeadlines: [Goal] = []
    @Published var activeStakes: [Stake] = []
    @Published var recentActivity: [AuditEvent] = []
    @Published var quickStats: QuickStats = QuickStats()
    
    // MARK: - Dependencies
    private let goalRepository: GoalRepository
    private let stakeRepository: StakeRepository
    private let userRepository: UserRepository
    private let analyticsService: AnalyticsService
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(
        goalRepository: GoalRepository = DIContainer.shared.resolve(GoalRepository.self),
        stakeRepository: StakeRepository = DIContainer.shared.resolve(StakeRepository.self),
        userRepository: UserRepository = DIContainer.shared.resolve(UserRepository.self),
        analyticsService: AnalyticsService = DIContainer.shared.resolve(AnalyticsService.self)
    ) {
        self.goalRepository = goalRepository
        self.stakeRepository = stakeRepository
        self.userRepository = userRepository
        self.analyticsService = analyticsService
        
        setupObservers()
    }
    
    // MARK: - Public Methods
    func loadData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load data concurrently
            async let goalsTask = loadGoals()
            async let stakesTask = loadStakes()
            async let activityTask = loadRecentActivity()
            
            let (goals, stakes, activity) = try await (goalsTask, stakesTask, activityTask)
            
            // Process data
            upcomingDeadlines = goals.filter { $0.isActive && $0.daysRemaining <= 7 }
            activeStakes = stakes.filter { $0.status == .active }
            recentActivity = activity.prefix(10).map { $0 }
            
            // Calculate quick stats
            quickStats = calculateQuickStats(goals: goals, stakes: stakes)
            
            analyticsService.trackEvent(AnalyticsEvent(
                name: "home_data_loaded",
                properties: [
                    "upcoming_deadlines": upcomingDeadlines.count,
                    "active_stakes": activeStakes.count,
                    "recent_activity": recentActivity.count
                ]
            ))
        } catch {
            errorMessage = "Failed to load home data: \(error.localizedDescription)"
            logError("Failed to load home data: \(error)", category: "HomeViewModel")
            
            analyticsService.trackError(error, context: "HomeViewModel.loadData")
        }
        
        isLoading = false
    }
    
    func refreshData() async {
        await loadData()
    }
    
    func markGoalAsCompleted(_ goal: Goal) async {
        do {
            var updatedGoal = goal
            updatedGoal.status = .completed
            updatedGoal.updatedAt = Date()
            
            let savedGoal = try await goalRepository.updateGoal(updatedGoal)
            
            // Update local data
            if let index = upcomingDeadlines.firstIndex(where: { $0.id == goal.id }) {
                upcomingDeadlines.remove(at: index)
            }
            
            analyticsService.trackEvent(AnalyticsEvent(
                name: "goal_completed_from_home",
                properties: [
                    "goal_id": goal.id,
                    "category": goal.category.rawValue
                ]
            ))
            
            // Refresh data to update stats
            await loadData()
        } catch {
            errorMessage = "Failed to complete goal: \(error.localizedDescription)"
            logError("Failed to complete goal: \(error)", category: "HomeViewModel")
            
            analyticsService.trackError(error, context: "HomeViewModel.markGoalAsCompleted")
        }
    }
    
    func extendGoalDeadline(_ goal: Goal, newDeadline: Date) async {
        do {
            var updatedGoal = goal
            updatedGoal.endDate = newDeadline
            updatedGoal.updatedAt = Date()
            
            let savedGoal = try await goalRepository.updateGoal(updatedGoal)
            
            // Update local data
            if let index = upcomingDeadlines.firstIndex(where: { $0.id == goal.id }) {
                upcomingDeadlines[index] = savedGoal
            }
            
            analyticsService.trackEvent(AnalyticsEvent(
                name: "goal_deadline_extended",
                properties: [
                    "goal_id": goal.id,
                    "new_deadline": newDeadline.timeIntervalSince1970
                ]
            ))
        } catch {
            errorMessage = "Failed to extend deadline: \(error.localizedDescription)"
            logError("Failed to extend deadline: \(error)", category: "HomeViewModel")
            
            analyticsService.trackError(error, context: "HomeViewModel.extendGoalDeadline")
        }
    }
    
    func pauseStake(_ stake: Stake) async {
        do {
            var updatedStake = stake
            updatedStake.status = .paused
            updatedStake.updatedAt = Date()
            
            let savedStake = try await stakeRepository.updateStake(updatedStake)
            
            // Update local data
            if let index = activeStakes.firstIndex(where: { $0.id == stake.id }) {
                activeStakes[index] = savedStake
            }
            
            analyticsService.trackEvent(AnalyticsEvent(
                name: "stake_paused",
                properties: ["stake_id": stake.id]
            ))
            
            // Refresh data to update stats
            await loadData()
        } catch {
            errorMessage = "Failed to pause stake: \(error.localizedDescription)"
            logError("Failed to pause stake: \(error)", category: "HomeViewModel")
            
            analyticsService.trackError(error, context: "HomeViewModel.pauseStake")
        }
    }
    
    // MARK: - Private Methods
    private func loadGoals() async throws -> [Goal] {
        return try await goalRepository.fetchGoals()
    }
    
    private func loadStakes() async throws -> [Stake] {
        return try await stakeRepository.fetchStakes()
    }
    
    private func loadRecentActivity() async throws -> [AuditEvent] {
        // TODO: Implement actual audit event loading
        // For now, return empty array
        return []
    }
    
    private func calculateQuickStats(goals: [Goal], stakes: [Stake]) -> QuickStats {
        let activeGoals = goals.filter { $0.status == .active }
        let completedGoals = goals.filter { $0.status == .completed }
        let activeStakes = stakes.filter { $0.status == .active }
        let totalStakeValue = stakes.reduce(Decimal.zero) { $0 + $1.principal }
        
        return QuickStats(
            activeGoalsCount: activeGoals.count,
            completedGoalsCount: completedGoals.count,
            activeStakesCount: activeStakes.count,
            totalStakeValue: totalStakeValue,
            completionRate: goals.isEmpty ? 0 : Double(completedGoals.count) / Double(goals.count) * 100
        )
    }
    
    private func setupObservers() {
        // Observe data changes for analytics
        $upcomingDeadlines
            .sink { [weak self] deadlines in
                self?.analyticsService.trackEvent(AnalyticsEvent(
                    name: "upcoming_deadlines_updated",
                    properties: ["count": deadlines.count]
                ))
            }
            .store(in: &cancellables)
        
        $activeStakes
            .sink { [weak self] stakes in
                self?.analyticsService.trackEvent(AnalyticsEvent(
                    name: "active_stakes_updated",
                    properties: ["count": stakes.count]
                ))
            }
            .store(in: &cancellables)
    }
    
    private func logError(_ message: String, category: String) {
        logError(message, category: category)
    }
}

// MARK: - Supporting Types
struct QuickStats {
    let activeGoalsCount: Int
    let completedGoalsCount: Int
    let activeStakesCount: Int
    let totalStakeValue: Decimal
    let completionRate: Double
    
    var totalStakeValueFormatted: String {
        String(format: "%.2f", NSDecimalNumber(decimal: totalStakeValue).doubleValue)
    }
    
    var completionRateFormatted: String {
        String(format: "%.1f%%", completionRate)
    }
}

// MARK: - Extensions
extension Goal {
    var isActive: Bool {
        status == .active
    }
    
    var daysRemaining: Int {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day], from: now, to: endDate)
        return components.day ?? 0
    }
    
    var isOverdue: Bool {
        daysRemaining < 0
    }
    
    var deadlineStatus: DeadlineStatus {
        if isOverdue {
            return .overdue
        } else if daysRemaining <= 1 {
            return .urgent
        } else if daysRemaining <= 3 {
            return .soon
        } else if daysRemaining <= 7 {
            return .upcoming
        } else {
            return .normal
        }
    }
}

enum DeadlineStatus {
    case overdue
    case urgent
    case soon
    case upcoming
    case normal
    
    var color: Color {
        switch self {
        case .overdue: return .appError
        case .urgent: return .appWarning
        case .soon: return .appWarning
        case .upcoming: return .appInfo
        case .normal: return .appSuccess
        }
    }
    
    var displayText: String {
        switch self {
        case .overdue: return "Overdue"
        case .urgent: return "Due Today"
        case .soon: return "Due Soon"
        case .upcoming: return "Upcoming"
        case .normal: return "On Track"
        }
    }
}
