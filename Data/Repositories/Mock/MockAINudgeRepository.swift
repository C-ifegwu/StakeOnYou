import Foundation
import Combine

// MARK: - Mock AI Nudge Repository Implementation
class MockAINudgeRepository: AINudgeRepository {
    // MARK: - Properties
    private var nudges: [String: Nudge] = [:]
    private let logger: Logger
    
    // MARK: - Initialization
    init(logger: Logger = ConsoleLogger()) {
        self.logger = logger
        setupMockData()
    }
    
    // MARK: - CRUD Operations
    func createNudge(_ nudge: Nudge) async throws -> Nudge {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        var newNudge = nudge
        if newNudge.id.isEmpty {
            newNudge = Nudge(
                id: UUID().uuidString,
                title: nudge.title,
                content: nudge.content,
                type: nudge.type,
                category: nudge.category,
                priority: nudge.priority,
                actionType: nudge.actionType,
                userId: nudge.userId,
                isRead: nudge.isRead,
                isApplied: nudge.isApplied,
                createdAt: Date()
            )
        }
        
        nudges[newNudge.id] = newNudge
        logger.info("Mock: Created AI nudge with ID: \(newNudge.id)")
        return newNudge
    }
    
    func getNudge(id: String) async throws -> Nudge? {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 200_000_000)
        
        let nudge = nudges[id]
        logger.info("Mock: Retrieved AI nudge with ID: \(id), found: \(nudge != nil)")
        return nudge
    }
    
    func updateNudge(_ nudge: Nudge) async throws -> Nudge {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        guard nudges[nudge.id] != nil else {
            throw AINudgeRepositoryError.nudgeNotFound
        }
        
        nudges[nudge.id] = nudge
        logger.info("Mock: Updated AI nudge with ID: \(nudge.id)")
        return nudge
    }
    
    func deleteNudge(id: String) async throws -> Bool {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        guard nudges[id] != nil else {
            throw AINudgeRepositoryError.nudgeNotFound
        }
        
        nudges.removeValue(forKey: id)
        logger.info("Mock: Deleted AI nudge with ID: \(id)")
        return true
    }
    
    // MARK: - Query Operations
    func getNudges(forUserId: String) async throws -> [Nudge] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let userNudges = nudges.values.filter { $0.userId == userId }
        logger.info("Mock: Retrieved \(userNudges.count) AI nudges for user: \(userId)")
        return userNudges
    }
    
    func getNudges(byType: NudgeType) async throws -> [Nudge] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 200_000_000)
        
        let typeNudges = nudges.values.filter { $0.type == type }
        logger.info("Mock: Retrieved \(typeNudges.count) AI nudges with type: \(type)")
        return typeNudges
    }
    
    func getNudges(byCategory: NudgeCategory) async throws -> [Nudge] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 200_000_000)
        
        let categoryNudges = nudges.values.filter { $0.category == category }
        logger.info("Mock: Retrieved \(categoryNudges.count) AI nudges with category: \(category)")
        return categoryNudges
    }
    
    func getNudges(byPriority: NudgePriority) async throws -> [Nudge] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 200_000_000)
        
        let priorityNudges = nudges.values.filter { $0.priority == priority }
        logger.info("Mock: Retrieved \(priorityNudges.count) AI nudges with priority: \(priority)")
        return priorityNudges
    }
    
    func getNudges(byDateRange: DateInterval) async throws -> [Nudge] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let dateRangeNudges = nudges.values.filter { nudge in
            return nudge.createdAt >= dateRange.start && nudge.createdAt <= dateRange.end
        }
        
        logger.info("Mock: Retrieved \(dateRangeNudges.count) AI nudges in date range")
        return dateRangeNudges
    }
    
    // MARK: - Status Operations
    func markNudgeAsRead(id: String) async throws -> Nudge {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 200_000_000)
        
        guard var nudge = nudges[id] else {
            throw AINudgeRepositoryError.nudgeNotFound
        }
        
        nudge.isRead = true
        nudges[id] = nudge
        
        logger.info("Mock: Marked AI nudge as read: \(id)")
        return nudge
    }
    
    func markNudgeAsApplied(id: String) async throws -> Nudge {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 200_000_000)
        
        guard var nudge = nudges[id] else {
            throw AINudgeRepositoryError.nudgeNotFound
        }
        
        nudge.isApplied = true
        nudges[id] = nudge
        
        logger.info("Mock: Marked AI nudge as applied: \(id)")
        return nudge
    }
    
    func markNudgeAsDismissed(id: String) async throws -> Nudge {
        // For now, just mark as read since we don't have a dismissed field
        return try await markNudgeAsRead(id: id)
    }
    
    func getUnreadNudges(forUserId: String) async throws -> [Nudge] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 200_000_000)
        
        let unreadNudges = nudges.values.filter { $0.userId == userId && !$0.isRead }
        logger.info("Mock: Retrieved \(unreadNudges.count) unread AI nudges for user: \(userId)")
        return unreadNudges
    }
    
    func getAppliedNudges(forUserId: String) async throws -> [Nudge] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 200_000_000)
        
        let appliedNudges = nudges.values.filter { $0.userId == userId && $0.isApplied }
        logger.info("Mock: Retrieved \(appliedNudges.count) applied AI nudges for user: \(userId)")
        return appliedNudges
    }
    
    func getDismissedNudges(forUserId: String) async throws -> [Nudge] {
        // For now, return empty array since we don't have a dismissed field
        return []
    }
    
    // MARK: - AI Generation Operations
    func generatePersonalizedNudges(forUserId: String, context: UserContext) async throws -> [Nudge] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Generate mock personalized nudges based on context
        let personalizedNudges = [
            Nudge(
                id: UUID().uuidString,
                title: "Time to Check In!",
                content: "Based on your activity patterns, this is a great time to review your goals and make progress.",
                type: .motivational,
                category: .productivity,
                priority: .medium,
                actionType: .checkIn,
                userId: userId,
                isRead: false,
                isApplied: false,
                createdAt: Date()
            ),
            Nudge(
                id: UUID().uuidString,
                title: "Weekly Goal Review",
                content: "It's been a week since you set your goals. Take a moment to reflect on your progress.",
                type: .reminder,
                category: .goalManagement,
                priority: .high,
                actionType: .reviewGoals,
                userId: userId,
                isRead: false,
                isApplied: false,
                createdAt: Date()
            )
        ]
        
        // Add generated nudges to the repository
        for nudge in personalizedNudges {
            nudges[nudge.id] = nudge
        }
        
        logger.info("Mock: Generated \(personalizedNudges.count) personalized AI nudges for user: \(userId)")
        return personalizedNudges
    }
    
    func getNudgeSuggestions(forUserId: String, limit: Int) async throws -> [Nudge] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        let userNudges = nudges.values.filter { $0.userId == userId }
        let suggestions = Array(userNudges.prefix(limit))
        
        logger.info("Mock: Retrieved \(suggestions.count) AI nudge suggestions for user: \(userId)")
        return suggestions
    }
    
    func updateNudgeEffectiveness(nudgeId: String, wasEffective: Bool, feedback: String?) async throws -> Nudge {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        guard let nudge = nudges[nudgeId] else {
            throw AINudgeRepositoryError.nudgeNotFound
        }
        
        logger.info("Mock: Updated nudge effectiveness for ID: \(nudgeId), was effective: \(wasEffective)")
        return nudge
    }
    
    // MARK: - Analytics Operations
    func getNudgeStatistics(forUserId: String) async throws -> NudgeStatistics {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        let userNudges = nudges.values.filter { $0.userId == userId }
        let totalNudges = userNudges.count
        let unreadNudges = userNudges.filter { !$0.isRead }.count
        let appliedNudges = userNudges.filter { $0.isApplied }.count
        let dismissedNudges = 0 // Would need dismissed field
        
        // Group by type
        let typeGroups = Dictionary(grouping: userNudges) { $0.type }
        let nudgesByType = typeGroups.map { type, nudges in
            NudgeTypeStats(
                type: type,
                count: nudges.count,
                appliedCount: nudges.filter { $0.isApplied }.count,
                dismissedCount: 0, // Would need dismissed field
                effectiveness: 0.0 // Would need effectiveness tracking
            )
        }
        
        // Group by category
        let categoryGroups = Dictionary(grouping: userNudges) { $0.category }
        let nudgesByCategory = categoryGroups.map { category, nudges in
            NudgeCategoryStats(
                category: category,
                count: nudges.count,
                appliedCount: nudges.filter { $0.isApplied }.count,
                dismissedCount: 0, // Would need dismissed field
                effectiveness: 0.0 // Would need effectiveness tracking
            )
        }
        
        let statistics = NudgeStatistics(
            totalNudges: totalNudges,
            unreadNudges: unreadNudges,
            appliedNudges: appliedNudges,
            dismissedNudges: dismissedNudges,
            nudgesByType: nudgesByType,
            nudgesByCategory: nudgesByCategory,
            averageEffectiveness: 0.0 // Would need effectiveness tracking
        )
        
        logger.info("Mock: Generated AI nudge statistics for user: \(userId)")
        return statistics
    }
    
    func getNudgePerformance(forUserId: String, timeRange: TimeRange) async throws -> NudgePerformance {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let performance = NudgePerformance(
            readRate: 0.8,
            applyRate: 0.6,
            dismissRate: 0.2,
            averageResponseTime: 300, // 5 minutes
            userEngagementScore: 0.7,
            goalImpactScore: 0.6
        )
        
        logger.info("Mock: Generated AI nudge performance for user: \(userId)")
        return performance
    }
    
    func getNudgeEffectivenessMetrics(forUserId: String) async throws -> NudgeEffectivenessMetrics {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        let metrics = NudgeEffectivenessMetrics(
            overallEffectiveness: 0.7,
            effectivenessByType: [:],
            effectivenessByCategory: [:],
            effectivenessByPriority: [:],
            userFeedback: [],
            improvementSuggestions: []
        )
        
        logger.info("Mock: Generated AI nudge effectiveness metrics for user: \(userId)")
        return metrics
    }
    
    // MARK: - Bulk Operations
    func bulkUpdateNudges(_ nudges: [Nudge]) async throws -> [Nudge] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        var updatedNudges: [Nudge] = []
        
        for nudge in nudges {
            if self.nudges[nudge.id] != nil {
                self.nudges[nudge.id] = nudge
                updatedNudges.append(nudge)
            }
        }
        
        logger.info("Mock: Bulk updated \(updatedNudges.count) AI nudges")
        return updatedNudges
    }
    
    func deleteOldNudges(olderThan date: Date) async throws -> Int {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 600_000_000)
        
        let oldNudges = nudges.values.filter { $0.createdAt < date }
        let count = oldNudges.count
        
        for nudge in oldNudges {
            nudges.removeValue(forKey: nudge.id)
        }
        
        logger.info("Mock: Deleted \(count) old AI nudges")
        return count
    }
    
    func deleteDismissedNudges(olderThan date: Date) async throws -> Int {
        // This would need to be implemented with actual dismissed field
        // For now, return 0
        return 0
    }
    
    // MARK: - Private Helper Methods
    private func setupMockData() {
        // Create some mock AI nudges for testing
        let mockNudges = [
            Nudge(
                id: "nudge-1",
                title: "Welcome to StakeOnYou!",
                content: "Start your journey by creating your first goal. Remember, every great achievement begins with a single step.",
                type: .motivational,
                category: .onboarding,
                priority: .high,
                actionType: .createGoal,
                userId: "user-1",
                isRead: false,
                isApplied: false,
                createdAt: Date().addingTimeInterval(-2 * 24 * 60 * 60) // 2 days ago
            ),
            Nudge(
                id: "nudge-2",
                title: "Daily Progress Check",
                content: "Take a moment to review your goals and celebrate your progress. Small wins add up to big results!",
                type: .reminder,
                category: .productivity,
                priority: .medium,
                actionType: .checkIn,
                userId: "user-1",
                isRead: true,
                isApplied: false,
                createdAt: Date().addingTimeInterval(-1 * 24 * 60 * 60) // 1 day ago
            ),
            Nudge(
                id: "nudge-3",
                title: "Goal Deadline Approaching",
                content: "Your goal 'Learn SwiftUI' is due in 3 days. Consider breaking it down into smaller milestones if needed.",
                type: .alert,
                category: .goalManagement,
                priority: .high,
                actionType: .reviewGoal,
                userId: "user-1",
                isRead: false,
                isApplied: false,
                createdAt: Date()
            ),
            Nudge(
                id: "nudge-4",
                title: "Weekly Reflection",
                content: "It's time for your weekly goal review. Reflect on what went well and what you can improve.",
                type: .reminder,
                category: .reflection,
                priority: .medium,
                actionType: .weeklyReview,
                userId: "user-2",
                isRead: false,
                isApplied: false,
                createdAt: Date().addingTimeInterval(-6 * 24 * 60 * 60) // 6 days ago
            ),
            Nudge(
                id: "nudge-5",
                title: "Celebrate Your Success!",
                content: "Congratulations on completing your goal! Take a moment to reflect on what you've learned and set your next challenge.",
                type: .celebration,
                category: .achievement,
                priority: .high,
                actionType: .celebrate,
                userId: "user-2",
                isRead: true,
                isApplied: true,
                createdAt: Date().addingTimeInterval(-3 * 24 * 60 * 60) // 3 days ago
            )
        ]
        
        for nudge in mockNudges {
            nudges[nudge.id] = nudge
        }
        
        logger.info("Mock: Setup \(mockNudges.count) mock AI nudges")
    }
}
