import Foundation
import Combine

// MARK: - Mock Goal Repository Implementation
class MockGoalRepository: GoalRepository {
    // MARK: - Properties
    private var goals: [String: Goal] = [:]
    private let logger: Logger
    
    // MARK: - Initialization
    init(logger: Logger = ConsoleLogger()) {
        self.logger = logger
        setupMockData()
    }
    
    // MARK: - CRUD Operations
    func createGoal(_ goal: Goal) async throws -> Goal {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        var newGoal = goal
        if newGoal.id.isEmpty {
            newGoal = Goal(
                id: UUID().uuidString,
                title: goal.title,
                description: goal.description,
                category: goal.category,
                startDate: goal.startDate,
                endDate: goal.endDate,
                verificationMethod: goal.verificationMethod,
                stakeAmount: goal.stakeAmount,
                ownerId: goal.ownerId,
                isPublic: goal.isPublic,
                priority: goal.priority,
                tags: goal.tags,
                milestones: goal.milestones,
                status: goal.status,
                createdAt: Date(),
                updatedAt: Date()
            )
        }
        
        goals[newGoal.id] = newGoal
        logger.info("Mock: Created goal with ID: \(newGoal.id)")
        return newGoal
    }
    
    func getGoal(id: String) async throws -> Goal? {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 200_000_000)
        
        let goal = goals[id]
        logger.info("Mock: Retrieved goal with ID: \(id), found: \(goal != nil)")
        return goal
    }
    
    func updateGoal(_ goal: Goal) async throws -> Goal {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        guard goals[goal.id] != nil else {
            throw GoalRepositoryError.goalNotFound
        }
        
        var updatedGoal = goal
        updatedGoal.updatedAt = Date()
        goals[goal.id] = updatedGoal
        
        logger.info("Mock: Updated goal with ID: \(goal.id)")
        return updatedGoal
    }
    
    func deleteGoal(id: String) async throws -> Bool {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        guard goals[id] != nil else {
            throw GoalRepositoryError.goalNotFound
        }
        
        goals.removeValue(forKey: id)
        logger.info("Mock: Deleted goal with ID: \(id)")
        return true
    }
    
    // MARK: - Query Operations
    func getGoals(forUserId: String) async throws -> [Goal] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let userGoals = goals.values.filter { $0.ownerId == userId }
        logger.info("Mock: Retrieved \(userGoals.count) goals for user: \(userId)")
        return userGoals
    }
    
    func getGoals(byGroupId: String) async throws -> [Goal] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        // Mock implementation - return goals that might be group-related
        let groupGoals = goals.values.filter { $0.isPublic }
        logger.info("Mock: Retrieved \(groupGoals.count) group goals for group: \(groupId)")
        return groupGoals
    }
    
    func getGoals(byCorporateId: String) async throws -> [Goal] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        // Mock implementation - return goals that might be corporate-related
        let corporateGoals = goals.values.filter { $0.category == .work || $0.category == .professional }
        logger.info("Mock: Retrieved \(corporateGoals.count) corporate goals for corporate: \(corporateId)")
        return corporateGoals
    }
    
    func getGoals(byStatus: GoalStatus) async throws -> [Goal] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 200_000_000)
        
        let statusGoals = goals.values.filter { $0.status == status }
        logger.info("Mock: Retrieved \(statusGoals.count) goals with status: \(status)")
        return statusGoals
    }
    
    func getGoals(byCategory: GoalCategory) async throws -> [Goal] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 200_000_000)
        
        let categoryGoals = goals.values.filter { $0.category == category }
        logger.info("Mock: Retrieved \(categoryGoals.count) goals with category: \(category)")
        return categoryGoals
    }
    
    func getGoals(byDateRange: DateInterval) async throws -> [Goal] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let dateRangeGoals = goals.values.filter { goal in
            guard let startDate = goal.startDate, let endDate = goal.endDate else { return false }
            return startDate >= dateRange.start && endDate <= dateRange.end
        }
        
        logger.info("Mock: Retrieved \(dateRangeGoals.count) goals in date range")
        return dateRangeGoals
    }
    
    func searchGoals(query: String) async throws -> [Goal] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        let searchResults = goals.values.filter { goal in
            goal.title.localizedCaseInsensitiveContains(query) ||
            goal.description.localizedCaseInsensitiveContains(query) ||
            goal.tags.contains { $0.localizedCaseInsensitiveContains(query) }
        }
        
        logger.info("Mock: Search for '\(query)' returned \(searchResults.count) results")
        return searchResults
    }
    
    func getGoalsWithStakes() async throws -> [GoalWithStake] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        let goalsWithStakes = goals.values.compactMap { goal -> GoalWithStake? in
            guard goal.stakeAmount > 0 else { return nil }
            
            // Create a mock stake for the goal
            let stake = Stake(
                id: UUID().uuidString,
                principal: goal.stakeAmount,
                apr: 0.05, // 5% APR
                accrualMethod: .daily,
                startDate: goal.startDate ?? Date(),
                endDate: goal.endDate ?? Date(),
                status: .active,
                userId: goal.ownerId,
                goalId: goal.id,
                currentAccruedAmount: goal.stakeAmount * 0.02, // Mock accrued amount
                lastAccrualDate: Date(),
                bonusPercentage: 0.0,
                charityId: nil,
                notes: [],
                createdAt: Date(),
                updatedAt: Date()
            )
            
            return GoalWithStake(goal: goal, stake: stake)
        }
        
        logger.info("Mock: Retrieved \(goalsWithStakes.count) goals with stakes")
        return goalsWithStakes
    }
    
    // MARK: - Analytics Operations
    func getGoalStatistics(forUserId: String) async throws -> GoalStatistics {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        let userGoals = goals.values.filter { $0.ownerId == userId }
        let totalGoals = userGoals.count
        let completedGoals = userGoals.filter { $0.status == .completed }.count
        let activeGoals = userGoals.filter { $0.status == .active }.count
        let overdueGoals = userGoals.filter { $0.status == .overdue }.count
        
        let totalStakeAmount = userGoals.reduce(Decimal.zero) { $0 + $1.stakeAmount }
        let averageGoalDuration = userGoals.compactMap { goal -> TimeInterval? in
            guard let start = goal.startDate, let end = goal.endDate else { return nil }
            return end.timeIntervalSince(start)
        }.reduce(0, +) / Double(max(userGoals.count, 1))
        
        let statistics = GoalStatistics(
            totalGoals: totalGoals,
            completedGoals: completedGoals,
            activeGoals: activeGoals,
            overdueGoals: overdueGoals,
            totalStakeAmount: totalStakeAmount,
            averageGoalDuration: averageGoalDuration,
            completionRate: totalGoals > 0 ? Double(completedGoals) / Double(totalGoals) : 0.0
        )
        
        logger.info("Mock: Generated goal statistics for user: \(userId)")
        return statistics
    }
    
    func getGoalCompletionRate(forUserId: String, timeRange: TimeRange) async throws -> Double {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 200_000_000)
        
        let userGoals = goals.values.filter { $0.ownerId == userId }
        let goalsInTimeRange = userGoals.filter { goal in
            guard let startDate = goal.startDate else { return false }
            return startDate >= timeRange.start && startDate <= timeRange.end
        }
        
        let completedGoals = goalsInTimeRange.filter { $0.status == .completed }.count
        let completionRate = goalsInTimeRange.count > 0 ? Double(completedGoals) / Double(goalsInTimeRange.count) : 0.0
        
        logger.info("Mock: Calculated completion rate: \(completionRate) for user: \(userId)")
        return completionRate
    }
    
    // MARK: - Bulk Operations
    func bulkUpdateGoals(_ goals: [Goal]) async throws -> [Goal] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        var updatedGoals: [Goal] = []
        
        for goal in goals {
            if let existingGoal = self.goals[goal.id] {
                var updatedGoal = goal
                updatedGoal.updatedAt = Date()
                self.goals[goal.id] = updatedGoal
                updatedGoals.append(updatedGoal)
            }
        }
        
        logger.info("Mock: Bulk updated \(updatedGoals.count) goals")
        return updatedGoals
    }
    
    func deleteExpiredGoals() async throws -> Int {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 600_000_000)
        
        let expiredGoals = goals.values.filter { goal in
            guard let endDate = goal.endDate else { return false }
            return endDate < Date() && goal.status != .completed
        }
        
        let count = expiredGoals.count
        for goal in expiredGoals {
            goals.removeValue(forKey: goal.id)
        }
        
        logger.info("Mock: Deleted \(count) expired goals")
        return count
    }
    
    // MARK: - Private Helper Methods
    private func setupMockData() {
        // Create some mock goals for testing
        let mockGoals = [
            Goal(
                id: "goal-1",
                title: "Learn SwiftUI",
                description: "Master SwiftUI framework for iOS development",
                category: .learning,
                startDate: Date().addingTimeInterval(-7 * 24 * 60 * 60), // 7 days ago
                endDate: Date().addingTimeInterval(30 * 24 * 60 * 60), // 30 days from now
                verificationMethod: .manual,
                stakeAmount: 100.0,
                ownerId: "user-1",
                isPublic: true,
                priority: .high,
                tags: ["programming", "iOS", "SwiftUI"],
                milestones: [
                    Milestone(
                        id: "milestone-1",
                        title: "Complete Basics",
                        description: "Finish SwiftUI fundamentals",
                        deadline: Date().addingTimeInterval(7 * 24 * 60 * 60),
                        order: 1,
                        isCompleted: false,
                        createdAt: Date(),
                        updatedAt: Date()
                    )
                ],
                status: .active,
                createdAt: Date().addingTimeInterval(-7 * 24 * 60 * 60),
                updatedAt: Date().addingTimeInterval(-7 * 24 * 60 * 60)
            ),
            Goal(
                id: "goal-2",
                title: "Run 5K",
                description: "Complete a 5K run in under 25 minutes",
                category: .fitness,
                startDate: Date().addingTimeInterval(-14 * 24 * 60 * 60), // 14 days ago
                endDate: Date().addingTimeInterval(21 * 24 * 60 * 60), // 21 days from now
                verificationMethod: .healthKit,
                stakeAmount: 50.0,
                ownerId: "user-1",
                isPublic: false,
                priority: .medium,
                tags: ["running", "fitness", "5K"],
                milestones: [],
                status: .active,
                createdAt: Date().addingTimeInterval(-14 * 24 * 60 * 60),
                updatedAt: Date().addingTimeInterval(-14 * 24 * 60 * 60)
            ),
            Goal(
                id: "goal-3",
                title: "Read 12 Books",
                description: "Read one book per month this year",
                category: .learning,
                startDate: Date(timeIntervalSince1970: 1640995200), // January 1, 2022
                endDate: Date(timeIntervalSince1970: 1672531200), // December 31, 2022
                verificationMethod: .manual,
                stakeAmount: 200.0,
                ownerId: "user-1",
                isPublic: true,
                priority: .low,
                tags: ["reading", "books", "yearly"],
                milestones: [],
                status: .completed,
                createdAt: Date(timeIntervalSince1970: 1640995200),
                updatedAt: Date(timeIntervalSince1970: 1672531200)
            )
        ]
        
        for goal in mockGoals {
            goals[goal.id] = goal
        }
        
        logger.info("Mock: Setup \(mockGoals.count) mock goals")
    }
}
