import Foundation
import Combine
import SwiftUI

// MARK: - Goals View Model
@MainActor
class GoalsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var goals: [Goal] = []
    @Published var filteredGoals: [Goal] = []
    @Published var selectedGoal: Goal?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var showCreateGoal = false
    @Published var showEditGoal = false
    @Published var showGoalDetail = false
    
    // MARK: - Filter and Sort Properties
    @Published var selectedStatus: GoalStatus? = nil
    @Published var selectedCategory: GoalCategory? = nil
    @Published var selectedDifficulty: GoalDifficulty? = nil
    @Published var sortOption: GoalSortOption = .deadline
    @Published var searchText = ""
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let goalRepository: GoalRepository
    private let stakeRepository: StakeRepository
    private let userRepository: UserRepository
    
    // MARK: - Computed Properties
    var activeGoals: [Goal] {
        goals.filter { $0.status == .active }
    }
    
    var completedGoals: [Goal] {
        goals.filter { $0.status == .completed }
    }
    
    var overdueGoals: [Goal] {
        let now = Date()
        return goals.filter { goal in
            guard let deadline = goal.deadline else { return false }
            return goal.status == .active && deadline < now
        }
    }
    
    var upcomingDeadlines: [Goal] {
        let now = Date()
        let thirtyDaysFromNow = Calendar.current.date(byAdding: .day, value: 30, to: now) ?? now
        
        return goals.filter { goal in
            guard let deadline = goal.deadline else { return false }
            return goal.status == .active && deadline > now && deadline <= thirtyDaysFromNow
        }
    }
    
    // MARK: - Initialization
    init(
        goalRepository: GoalRepository,
        stakeRepository: StakeRepository,
        userRepository: UserRepository
    ) {
        self.goalRepository = goalRepository
        self.stakeRepository = stakeRepository
        self.userRepository = userRepository
        
        setupBindings()
    }
    
    // MARK: - Public Methods
    func loadGoals() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let userId = "current-user-id" // Get from auth service
            let allGoals = try await goalRepository.getGoals(forUserId: userId)
            
            await MainActor.run {
                self.goals = allGoals
                self.applyFiltersAndSort()
                self.isLoading = false
            }
        } catch {
            await handleError(error)
        }
    }
    
    func refreshGoals() async {
        await loadGoals()
    }
    
    func createGoal(_ goal: Goal) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let createdGoal = try await goalRepository.createGoal(goal)
            
            await MainActor.run {
                self.goals.append(createdGoal)
                self.applyFiltersAndSort()
                self.isLoading = false
                self.showCreateGoal = false
            }
        } catch {
            await handleError(error)
        }
    }
    
    func updateGoal(_ goal: Goal) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let updatedGoal = try await goalRepository.updateGoal(goal)
            
            await MainActor.run {
                if let index = self.goals.firstIndex(where: { $0.id == updatedGoal.id }) {
                    self.goals[index] = updatedGoal
                }
                self.applyFiltersAndSort()
                self.isLoading = false
                self.showEditGoal = false
            }
        } catch {
            await handleError(error)
        }
    }
    
    func deleteGoal(_ goal: Goal) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let success = try await goalRepository.deleteGoal(id: goal.id)
            
            if success {
                await MainActor.run {
                    self.goals.removeAll { $0.id == goal.id }
                    self.applyFiltersAndSort()
                    self.isLoading = false
                }
            }
        } catch {
            await handleError(error)
        }
    }
    
    func markGoalAsCompleted(_ goal: Goal) async {
        var updatedGoal = goal
        updatedGoal.status = .completed
        updatedGoal.completedAt = Date()
        
        await updateGoal(updatedGoal)
    }
    
    func markGoalAsActive(_ goal: Goal) async {
        var updatedGoal = goal
        updatedGoal.status = .active
        updatedGoal.completedAt = nil
        
        await updateGoal(updatedGoal)
    }
    
    func selectGoal(_ goal: Goal) {
        selectedGoal = goal
        showGoalDetail = true
    }
    
    func clearFilters() {
        selectedStatus = nil
        selectedCategory = nil
        selectedDifficulty = nil
        searchText = ""
        applyFiltersAndSort()
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
        // Combine publishers for reactive filtering
        Publishers.CombineLatest4($selectedStatus, $selectedCategory, $selectedDifficulty, $searchText)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _, _, _, _ in
                self?.applyFiltersAndSort()
            }
            .store(in: &cancellables)
        
        $sortOption
            .sink { [weak self] _ in
                self?.applyFiltersAndSort()
            }
            .store(in: &cancellables)
    }
    
    private func applyFiltersAndSort() {
        var filtered = goals
        
        // Apply status filter
        if let status = selectedStatus {
            filtered = filtered.filter { $0.status == status }
        }
        
        // Apply category filter
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        // Apply difficulty filter
        if let difficulty = selectedDifficulty {
            filtered = filtered.filter { $0.difficulty == difficulty }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { goal in
                goal.title.localizedCaseInsensitiveContains(searchText) ||
                goal.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply sorting
        filtered.sort { goal1, goal2 in
            switch sortOption {
            case .deadline:
                let deadline1 = goal1.deadline ?? Date.distantFuture
                let deadline2 = goal2.deadline ?? Date.distantFuture
                return deadline1 < deadline2
            case .createdAt:
                return goal1.createdAt > goal2.createdAt
            case .updatedAt:
                return goal1.updatedAt > goal2.updatedAt
            case .title:
                return goal1.title.localizedCaseInsensitiveCompare(goal2.title) == .orderedAscending
            case .category:
                return goal1.category.rawValue < goal2.category.rawValue
            case .difficulty:
                return goal1.difficulty.rawValue < goal2.difficulty.rawValue
            case .progress:
                let progress1 = calculateProgress(for: goal1)
                let progress2 = calculateProgress(for: goal2)
                return progress1 > progress2
            }
        }
        
        filteredGoals = filtered
    }
    
    private func calculateProgress(for goal: Goal) -> Double {
        guard !goal.milestones.isEmpty else { return 0.0 }
        
        let completedMilestones = goal.milestones.filter { $0.isCompleted }.count
        return Double(completedMilestones) / Double(goal.milestones.count)
    }
    
    private func handleError(_ error: Error) async {
        await MainActor.run {
            self.errorMessage = error.localizedDescription
            self.showError = true
            self.isLoading = false
        }
    }
}

// MARK: - Goal Sort Options
enum GoalSortOption: String, CaseIterable {
    case deadline = "Deadline"
    case createdAt = "Created Date"
    case updatedAt = "Updated Date"
    case title = "Title"
    case category = "Category"
    case difficulty = "Difficulty"
    case progress = "Progress"
    
    var icon: String {
        switch self {
        case .deadline: return "calendar"
        case .createdAt: return "clock"
        case .updatedAt: return "clock.arrow.circlepath"
        case .title: return "textformat"
        case .category: return "folder"
        case .difficulty: return "star"
        case .progress: return "chart.line.uptrend.xyaxis"
        }
    }
}

// MARK: - Goal Filter Options
extension GoalStatus {
    var displayName: String {
        switch self {
        case .active: return "Active"
        case .completed: return "Completed"
        case .paused: return "Paused"
        case .cancelled: return "Cancelled"
        }
    }
    
    var color: Color {
        switch self {
        case .active: return .green
        case .completed: return .blue
        case .paused: return .orange
        case .cancelled: return .red
        }
    }
}

extension GoalCategory {
    var displayName: String {
        switch self {
        case .health: return "Health & Fitness"
        case .education: return "Education"
        case .career: return "Career"
        case .finance: return "Finance"
        case .personal: return "Personal"
        case .fitness: return "Fitness"
        case .wellness: return "Wellness"
        case .hobby: return "Hobby"
        case .travel: return "Travel"
        case .social: return "Social"
        case .other: return "Other"
        }
    }
    
    var icon: String {
        switch self {
        case .health: return "heart.fill"
        case .education: return "book.fill"
        case .career: return "briefcase.fill"
        case .finance: return "dollarsign.circle.fill"
        case .personal: return "person.fill"
        case .fitness: return "figure.run"
        case .wellness: return "leaf.fill"
        case .hobby: return "gamecontroller.fill"
        case .travel: return "airplane"
        case .social: return "person.3.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

extension GoalDifficulty {
    var displayName: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        case .expert: return "Expert"
        }
    }
    
    var color: Color {
        switch self {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        case .expert: return .purple
        }
    }
}
