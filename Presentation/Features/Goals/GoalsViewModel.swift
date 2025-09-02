import SwiftUI
import Combine

@MainActor
class GoalsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var goals: [Goal] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Sheet and Alert Presentation
    @Published var presentedSheet: GoalsSheetDestination?
    @Published var presentedAlert: GoalsAlertDestination?
    
    // Filtering and Sorting
    @Published var selectedCategory: GoalCategory?
    @Published var selectedStatus: GoalStatus?
    @Published var searchText = ""
    @Published var sortOrder: GoalSortOrder = .deadlineAscending
    
    // MARK: - Computed Properties
    var filteredGoals: [Goal] {
        var filtered = goals
        
        // Apply category filter
        if let selectedCategory = selectedCategory {
            filtered = filtered.filter { $0.category == selectedCategory }
        }
        
        // Apply status filter
        if let selectedStatus = selectedStatus {
            filtered = filtered.filter { $0.status == selectedStatus }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { goal in
                goal.title.localizedCaseInsensitiveContains(searchText) ||
                goal.description.localizedCaseInsensitiveContains(searchText) ||
                goal.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Apply sorting
        filtered.sort { first, second in
            switch sortOrder {
            case .deadlineAscending:
                return first.endDate < second.endDate
            case .deadlineDescending:
                return first.endDate > second.endDate
            case .createdAscending:
                return first.createdAt < second.createdAt
            case .createdDescending:
                return first.createdAt > second.createdAt
            case .stakeAmountAscending:
                return first.stakeAmount < second.stakeAmount
            case .stakeAmountDescending:
                return first.stakeAmount > second.stakeAmount
            case .titleAscending:
                return first.title < second.title
            case .titleDescending:
                return first.title > second.title
            }
        }
        
        return filtered
    }
    
    var activeGoals: [Goal] {
        filteredGoals.filter { $0.status == .active }
    }
    
    var completedGoals: [Goal] {
        filteredGoals.filter { $0.status == .completed }
    }
    
    var overdueGoals: [Goal] {
        filteredGoals.filter { $0.isOverdue }
    }
    
    var activeGoalsCount: Int {
        activeGoals.count
    }
    
    var totalStakesFormatted: String {
        let total = goals.reduce(Decimal.zero) { $0 + $1.stakeAmount }
        return String(format: "%.2f", NSDecimalNumber(decimal: total).doubleValue)
    }
    
    var categories: [GoalCategory] {
        Array(Set(goals.map { $0.category })).sorted { $0.displayName < $1.displayName }
    }
    
    var statuses: [GoalStatus] {
        Array(Set(goals.map { $0.status })).sorted { $0.displayName < $1.displayName }
    }
    
    // MARK: - Dependencies
    private let goalRepository: GoalRepository
    private let userRepository: UserRepository
    private let analyticsService: AnalyticsService
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(
        goalRepository: GoalRepository = DIContainer.shared.resolve(GoalRepository.self),
        userRepository: UserRepository = DIContainer.shared.resolve(UserRepository.self),
        analyticsService: AnalyticsService = DIContainer.shared.resolve(AnalyticsService.self)
    ) {
        self.goalRepository = goalRepository
        self.userRepository = userRepository
        self.analyticsService = analyticsService
        
        setupObservers()
    }
    
    // MARK: - Public Methods
    func loadGoals() async {
        isLoading = true
        errorMessage = nil
        
        do {
            goals = try await goalRepository.fetchGoals()
            analyticsService.trackEvent(AnalyticsEvent(
                name: "goals_loaded",
                properties: ["count": goals.count]
            ))
        } catch {
            errorMessage = "Failed to load goals: \(error.localizedDescription)"
            logError("Failed to load goals: \(error)", category: "GoalsViewModel")
            
            analyticsService.trackError(error, context: "GoalsViewModel.loadGoals")
        }
        
        isLoading = false
    }
    
    func refreshGoals() async {
        await loadGoals()
    }
    
    func createGoal(_ goal: Goal) async {
        do {
            let createdGoal = try await goalRepository.createGoal(goal)
            goals.append(createdGoal)
            
            analyticsService.trackEvent(AnalyticsEvent(
                name: "goal_created",
                properties: [
                    "goal_id": createdGoal.id,
                    "category": createdGoal.category.rawValue,
                    "stake_amount": createdGoal.stakeAmount
                ]
            ))
            
            presentedAlert = .success("Goal Created", "Your goal has been created successfully!")
        } catch {
            errorMessage = "Failed to create goal: \(error.localizedDescription)"
            logError("Failed to create goal: \(error)", category: "GoalsViewModel")
            
            analyticsService.trackError(error, context: "GoalsViewModel.createGoal")
        }
    }
    
    func updateGoal(_ goal: Goal) async {
        do {
            let updatedGoal = try await goalRepository.updateGoal(goal)
            if let index = goals.firstIndex(where: { $0.id == updatedGoal.id }) {
                goals[index] = updatedGoal
            }
            
            analyticsService.trackEvent(AnalyticsEvent(
                name: "goal_updated",
                properties: [
                    "goal_id": updatedGoal.id,
                    "status": updatedGoal.status.rawValue
                ]
            ))
            
            presentedAlert = .success("Goal Updated", "Your goal has been updated successfully!")
        } catch {
            errorMessage = "Failed to update goal: \(error.localizedDescription)"
            logError("Failed to update goal: \(error)", category: "GoalsViewModel")
            
            analyticsService.trackError(error, context: "GoalsViewModel.updateGoal")
        }
    }
    
    func deleteGoal(_ goal: Goal) async {
        do {
            try await goalRepository.deleteGoal(goal.id)
            goals.removeAll { $0.id == goal.id }
            
            analyticsService.trackEvent(AnalyticsEvent(
                name: "goal_deleted",
                properties: ["goal_id": goal.id]
            ))
            
            presentedAlert = .success("Goal Deleted", "Your goal has been deleted successfully!")
        } catch {
            errorMessage = "Failed to delete goal: \(error.localizedDescription)"
            logError("Failed to delete goal: \(error)", category: "GoalsViewModel")
            
            analyticsService.trackError(error, context: "GoalsViewModel.deleteGoal")
        }
    }
    
    func completeGoal(_ goal: Goal) async {
        var updatedGoal = goal
        updatedGoal.status = .completed
        updatedGoal.updatedAt = Date()
        
        await updateGoal(updatedGoal)
        
        // Show completion alert
        presentedAlert = .goalCompletion(
            "Goal Completed! 🎉",
            "Congratulations on completing your goal: \(goal.title)"
        )
    }
    
    func startStake(for goal: Goal) {
        presentedSheet = .startStake(goal.id)
    }
    
    func editGoal(_ goal: Goal) {
        presentedSheet = .editGoal(goal.id)
    }
    
    func verifyGoal(_ goal: Goal) {
        presentedSheet = .goalVerification(goal.id)
    }
    
    func showCreateGoal() {
        presentedSheet = .createGoal
    }
    
    // MARK: - Filtering and Sorting
    func applyCategoryFilter(_ category: GoalCategory?) {
        selectedCategory = category
        analyticsService.trackEvent(AnalyticsEvent(
            name: "goals_filtered",
            properties: ["filter_type": "category", "value": category?.rawValue ?? "none"]
        ))
    }
    
    func applyStatusFilter(_ status: GoalStatus?) {
        selectedStatus = status
        analyticsService.trackEvent(AnalyticsEvent(
            name: "goals_filtered",
            properties: ["filter_type": "status", "value": status?.rawValue ?? "none"]
        ))
    }
    
    func applySearchFilter(_ searchText: String) {
        self.searchText = searchText
        analyticsService.trackEvent(AnalyticsEvent(
            name: "goals_searched",
            properties: ["search_text": searchText]
        ))
    }
    
    func applySortOrder(_ sortOrder: GoalSortOrder) {
        self.sortOrder = sortOrder
        analyticsService.trackEvent(AnalyticsEvent(
            name: "goals_sorted",
            properties: ["sort_order": sortOrder.rawValue]
        ))
    }
    
    func clearFilters() {
        selectedCategory = nil
        selectedStatus = nil
        searchText = ""
        sortOrder = .deadlineAscending
        
        analyticsService.trackEvent(AnalyticsEvent(
            name: "goals_filters_cleared"
        ))
    }
    
    // MARK: - Private Methods
    private func setupObservers() {
        // Observe search text changes for debounced search
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] searchText in
                self?.applySearchFilter(searchText)
            }
            .store(in: &cancellables)
        
        // Observe filter changes
        $selectedCategory
            .sink { [weak self] category in
                if let category = category {
                    self?.applyCategoryFilter(category)
                }
            }
            .store(in: &cancellables)
        
        $selectedStatus
            .sink { [weak self] status in
                if let status = status {
                    self?.applyStatusFilter(status)
                }
            }
            .store(in: &cancellables)
    }
    
    private func logError(_ message: String, category: String) {
        logError(message, category: category)
    }
}

// MARK: - Supporting Types
enum GoalSortOrder: String, CaseIterable {
    case deadlineAscending = "deadline_asc"
    case deadlineDescending = "deadline_desc"
    case createdAscending = "created_asc"
    case createdDescending = "created_desc"
    case stakeAmountAscending = "stake_asc"
    case stakeAmountDescending = "stake_desc"
    case titleAscending = "title_asc"
    case titleDescending = "title_desc"
    
    var displayName: String {
        switch self {
        case .deadlineAscending: return "Deadline (Earliest)"
        case .deadlineDescending: return "Deadline (Latest)"
        case .createdAscending: return "Created (Oldest)"
        case .createdDescending: return "Created (Newest)"
        case .stakeAmountAscending: return "Stake (Lowest)"
        case .stakeAmountDescending: return "Stake (Highest)"
        case .titleAscending: return "Title (A-Z)"
        case .titleDescending: return "Title (Z-A)"
        }
    }
}

enum GoalsSheetDestination: Identifiable {
    case createGoal
    case editGoal(String)
    case startStake(String)
    case goalVerification(String)
    
    var id: String {
        switch self {
        case .createGoal: return "createGoal"
        case .editGoal(let id): return "editGoal_\(id)"
        case .startStake(let goalId): return "startStake_\(goalId)"
        case .goalVerification(let id): return "goalVerification_\(id)"
        }
    }
}

enum GoalsAlertDestination: Identifiable {
    case error(String, String?)
    case success(String, String?)
    case confirmation(String, String?, () -> Void)
    case goalCompletion(String, String?)
    
    var id: String {
        switch self {
        case .error(let title, let message): return "error_\(title)_\(message ?? "")"
        case .success(let title, let message): return "success_\(title)_\(message ?? "")"
        case .confirmation(let title, let message, _): return "confirmation_\(title)_\(message ?? "")"
        case .goalCompletion(let title, let message): return "goalCompletion_\(title)_\(message ?? "")"
        }
    }
}

// MARK: - Extensions
extension GoalCategory {
    var color: Color {
        switch self {
        case .health: return .appSuccess
        case .fitness: return .appPrimary
        case .education: return .appInfo
        case .career: return .appWarning
        case .finance: return .appSecondary
        case .personal: return .appTextSecondary
        case .social: return .appPrimary
        case .creative: return .appSecondary
        case .travel: return .appInfo
        case .other: return .appTextSecondary
        }
    }
    
    var icon: String {
        switch self {
        case .health: return "heart.fill"
        case .fitness: return "figure.run"
        case .education: return "book.fill"
        case .career: return "briefcase.fill"
        case .finance: return "dollarsign.circle"
        case .personal: return "person.fill"
        case .social: return "person.3.fill"
        case .creative: return "paintbrush.fill"
        case .travel: return "airplane"
        case .other: return "star.fill"
        }
    }
}

extension GoalStatus {
    var color: Color {
        switch self {
        case .active: return .appSuccess
        case .completed: return .appPrimary
        case .failed: return .appError
        case .paused: return .appWarning
        case .cancelled: return .appTextSecondary
        }
    }
    
    var displayName: String {
        switch self {
        case .active: return "Active"
        case .completed: return "Completed"
        case .failed: return "Failed"
        case .paused: return "Paused"
        case .cancelled: return "Cancelled"
        }
    }
}
