import Foundation
import Combine
import SwiftUI

// MARK: - Home View Model
@MainActor
class HomeViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var homeSummary: HomeSummary?
    @Published var recentGoals: [Goal] = []
    @Published var activeStakes: [Stake] = []
    @Published var upcomingDeadlines: [Goal] = []
    @Published var aiNudges: [Nudge] = []
    @Published var quickActions: [QuickAction] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let goalRepository: GoalRepository
    private let stakeRepository: StakeRepository
    private let userRepository: UserRepository
    private let aiRepository: AINudgeRepository
    private let notificationRepository: NotificationRepository
    
    // MARK: - Initialization
    init(
        goalRepository: GoalRepository,
        stakeRepository: StakeRepository,
        userRepository: UserRepository,
        aiRepository: AINudgeRepository,
        notificationRepository: NotificationRepository
    ) {
        self.goalRepository = goalRepository
        self.stakeRepository = stakeRepository
        self.userRepository = userRepository
        self.aiRepository = aiRepository
        self.notificationRepository = notificationRepository
        
        setupQuickActions()
    }
    
    // MARK: - Public Methods
    func loadHomeData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            async let summaryTask = loadHomeSummary()
            async let goalsTask = loadRecentGoals()
            async let stakesTask = loadActiveStakes()
            async let deadlinesTask = loadUpcomingDeadlines()
            async let nudgesTask = loadAINudges()
            
            let (summary, goals, stakes, deadlines, nudges) = await (
                try summaryTask,
                try goalsTask,
                try stakesTask,
                try deadlinesTask,
                try nudgesTask
            )
            
            self.homeSummary = summary
            self.recentGoals = goals
            self.activeStakes = stakes
            self.upcomingDeadlines = deadlines
            self.aiNudges = nudges
            
            isLoading = false
        } catch {
            await handleError(error)
        }
    }
    
    func refreshData() async {
        await loadHomeData()
    }
    
    func quickActionTapped(_ action: QuickAction) async {
        switch action.type {
        case .createGoal:
            // Navigate to create goal
            break
        case .joinGroup:
            // Navigate to join group
            break
        case .viewLeaderboard:
            // Navigate to leaderboard
            break
        case .corporateDashboard:
            // Navigate to corporate dashboard
            break
        case .settings:
            // Navigate to settings
            break
        }
    }
    
    // MARK: - Private Methods
    private func loadHomeSummary() async throws -> HomeSummary {
        // In a real app, this would come from a dedicated use case
        // For now, we'll aggregate data from repositories
        let userId = "current-user-id" // Get from auth service
        
        let totalGoals = try await goalRepository.getGoals(forUserId: userId).count
        let activeGoals = try await goalRepository.getGoals(byStatus: .active).count
        let completedGoals = try await goalRepository.getGoals(byStatus: .completed).count
        
        let totalStakes = try await stakeRepository.getStakes(forUserId: userId).count
        let activeStakes = try await stakeRepository.getStakes(byStatus: .active).count
        
        let totalBalance = try await calculateTotalBalance(userId: userId)
        let totalAccrued = try await calculateTotalAccrued(userId: userId)
        
        return HomeSummary(
            totalGoals: totalGoals,
            activeGoals: activeGoals,
            completedGoals: completedGoals,
            totalStakes: totalStakes,
            activeStakes: activeStakes,
            totalBalance: totalBalance,
            totalAccrued: totalAccrued,
            weeklyProgress: 0.75,
            monthlyProgress: 0.60,
            lastUpdated: Date()
        )
    }
    
    private func loadRecentGoals() async throws -> [Goal] {
        let userId = "current-user-id"
        let allGoals = try await goalRepository.getGoals(forUserId: userId)
        return Array(allGoals.prefix(5)).sorted { $0.updatedAt > $1.updatedAt }
    }
    
    private func loadActiveStakes() async throws -> [Stake] {
        let userId = "current-user-id"
        let stakes = try await stakeRepository.getStakes(byStatus: .active)
        return Array(stakes.prefix(3)).sorted { $0.updatedAt > $1.updatedAt }
    }
    
    private func loadUpcomingDeadlines() async throws -> [Goal] {
        let userId = "current-user-id"
        let activeGoals = try await goalRepository.getGoals(byStatus: .active)
        let now = Date()
        let thirtyDaysFromNow = Calendar.current.date(byAdding: .day, value: 30, to: now) ?? now
        
        return activeGoals
            .filter { goal in
                guard let deadline = goal.deadline else { return false }
                return deadline > now && deadline <= thirtyDaysFromNow
            }
            .sorted { ($0.deadline ?? Date.distantFuture) < ($1.deadline ?? Date.distantFuture) }
            .prefix(3)
            .map { $0 }
    }
    
    private func loadAINudges() async throws -> [Nudge] {
        let userId = "current-user-id"
        return try await aiRepository.getNudges(forUserId: userId, limit: 3)
    }
    
    private func calculateTotalBalance(userId: String) async throws -> Double {
        // This would typically come from a transaction repository
        // For now, return a mock value
        return 1250.0
    }
    
    private func calculateTotalAccrued(userId: String) async throws -> Double {
        // This would calculate total accrued interest from all active stakes
        // For now, return a mock value
        return 75.50
    }
    
    private func setupQuickActions() {
        quickActions = [
            QuickAction(
                id: "create-goal",
                title: "Create Goal",
                subtitle: "Set a new challenge",
                icon: "plus.circle.fill",
                color: .blue,
                type: .createGoal
            ),
            QuickAction(
                id: "join-group",
                title: "Join Group",
                subtitle: "Find accountability partners",
                icon: "person.3.fill",
                color: .green,
                type: .joinGroup
            ),
            QuickAction(
                id: "leaderboard",
                title: "Leaderboard",
                subtitle: "See top performers",
                icon: "trophy.fill",
                color: .orange,
                type: .viewLeaderboard
            ),
            QuickAction(
                id: "corporate",
                title: "Corporate",
                subtitle: "Team dashboard",
                icon: "building.2.fill",
                color: .purple,
                type: .corporateDashboard
            ),
            QuickAction(
                id: "settings",
                title: "Settings",
                subtitle: "Preferences & account",
                icon: "gearshape.fill",
                color: .gray,
                type: .settings
            )
        ]
    }
    
    private func handleError(_ error: Error) async {
        await MainActor.run {
            self.errorMessage = error.localizedDescription
            self.showError = true
            self.isLoading = false
        }
    }
}

// MARK: - Quick Action Model
struct QuickAction: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let type: QuickActionType
}

enum QuickActionType {
    case createGoal
    case joinGroup
    case viewLeaderboard
    case corporateDashboard
    case settings
}
