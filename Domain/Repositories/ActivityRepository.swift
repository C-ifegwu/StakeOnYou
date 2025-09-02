import Foundation
import Combine

// MARK: - Activity Repository Protocol
protocol ActivityRepository {
    // MARK: - CRUD Operations
    func createActivity(_ activity: ActivityItem) async throws -> ActivityItem
    func getActivity(id: String) async throws -> ActivityItem?
    func updateActivity(_ activity: ActivityItem) async throws -> ActivityItem
    func deleteActivity(id: String) async throws -> Bool
    
    // MARK: - Query Operations
    func getActivities(forUserId: String) async throws -> [ActivityItem]
    func getActivities(byType: ActivityType) async throws -> [ActivityItem]
    func getActivities(byDateRange: DateInterval) async throws -> [ActivityItem]
    func getRecentActivities(forUserId: String, limit: Int) async throws -> [ActivityItem]
    func getActivitiesByEntity(entityId: String, entityType: String) async throws -> [ActivityItem]
    
    // MARK: - Feed Operations
    func getUserFeed(userId: String, limit: Int, offset: Int) async throws -> [ActivityItem]
    func getGroupFeed(groupId: String, limit: Int, offset: Int) async throws -> [ActivityItem]
    func getCorporateFeed(corporateId: String, limit: Int, offset: Int) async throws -> [ActivityItem]
    func getGlobalFeed(limit: Int, offset: Int) async throws -> [ActivityItem]
    
    // MARK: - Analytics Operations
    func getActivityStatistics(forUserId: String) async throws -> ActivityStatistics
    func getActivityPerformance(forUserId: String, timeRange: TimeRange) async throws -> ActivityPerformance
    func getActivityTrends(forUserId: String, timeRange: TimeRange) async throws -> ActivityTrends
    
    // MARK: - Bulk Operations
    func bulkCreateActivities(_ activities: [ActivityItem]) async throws -> [ActivityItem]
    func bulkUpdateActivities(_ activities: [ActivityItem]) async throws -> [ActivityItem]
    func deleteOldActivities(olderThan date: Date) async throws -> Int
}

// MARK: - Supporting Models
struct ActivityStatistics {
    let totalActivities: Int
    let activitiesByType: [ActivityTypeStats]
    let activitiesByDate: [Date: Int]
    let averageActivitiesPerDay: Double
    let mostActiveDay: Date?
    let leastActiveDay: Date?
}

struct ActivityTypeStats {
    let type: ActivityType
    let count: Int
    let percentage: Double
    let averageEngagement: Double
}

struct ActivityPerformance {
    let engagementRate: Double
    let averageResponseTime: TimeInterval
    let userInteractionScore: Double
    let contentQualityScore: Double
    let socialImpactScore: Double
}

struct ActivityTrends {
    let trendingActivities: [ActivityType]
    let activityGrowth: Double
    let peakActivityTimes: [Date]
    let seasonalPatterns: [SeasonalPattern]
}

struct SeasonalPattern {
    let season: String
    let averageActivity: Double
    let peakDays: [String]
    let lowActivityDays: [String]
}

// MARK: - Activity Repository Extensions
extension ActivityRepository {
    // MARK: - Convenience Methods
    func getTodayActivities(forUserId: String) async throws -> [ActivityItem] {
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? today
        
        let dateInterval = DateInterval(start: startOfDay, end: endOfDay)
        return try await getActivities(byDateRange: dateInterval).filter { $0.userId == userId }
    }
    
    func getWeekActivities(forUserId: String) async throws -> [ActivityItem] {
        let calendar = Calendar.current
        let today = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let endOfWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.end ?? today
        
        let dateInterval = DateInterval(start: startOfWeek, end: endOfWeek)
        return try await getActivities(byDateRange: dateInterval).filter { $0.userId == userId }
    }
    
    func getMonthActivities(forUserId: String) async throws -> [ActivityItem] {
        let calendar = Calendar.current
        let today = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: today)?.start ?? today
        let endOfMonth = calendar.dateInterval(of: .month, for: today)?.end ?? today
        
        let dateInterval = DateInterval(start: startOfMonth, end: endOfMonth)
        return try await getActivities(byDateRange: dateInterval).filter { $0.userId == userId }
    }
    
    func getActivitiesByType(forUserId: String, type: ActivityType) async throws -> [ActivityItem] {
        return try await getActivities(byType: type).filter { $0.userId == userId }
    }
    
    func getGoalActivities(forUserId: String, goalId: String) async throws -> [ActivityItem] {
        return try await getActivitiesByEntity(entityId: goalId, entityType: "Goal").filter { $0.userId == userId }
    }
    
    func getStakeActivities(forUserId: String, stakeId: String) async throws -> [ActivityItem] {
        return try await getActivitiesByEntity(entityId: stakeId, entityType: "Stake").filter { $0.userId == userId }
    }
    
    func getGroupActivities(forUserId: String, groupId: String) async throws -> [ActivityItem] {
        return try await getActivitiesByEntity(entityId: groupId, entityType: "Group").filter { $0.userId == userId }
    }
    
    func getCorporateActivities(forUserId: String, corporateId: String) async throws -> [ActivityItem] {
        return try await getActivitiesByEntity(entityId: corporateId, entityType: "Corporate").filter { $0.userId == userId }
    }
    
    func getActivityCount(forUserId: String) async throws -> Int {
        let activities = try await getActivities(forUserId: userId)
        return activities.count
    }
    
    func getActivityCountByType(forUserId: String, type: ActivityType) async throws -> Int {
        let activities = try await getActivitiesByType(forUserId: userId, type: type)
        return activities.count
    }
    
    func getActivityCountByDate(forUserId: String, date: Date) async throws -> Int {
        let activities = try await getTodayActivities(forUserId: userId)
        return activities.count
    }
    
    func getActivityCountByWeek(forUserId: String, weekOfYear: Int, year: Int) async throws -> Int {
        let activities = try await getWeekActivities(forUserId: userId)
        return activities.count
    }
    
    func getActivityCountByMonth(forUserId: String, month: Int, year: Int) async throws -> Int {
        let activities = try await getMonthActivities(forUserId: userId)
        return activities.count
    }
    
    func hasRecentActivity(forUserId: String, withinHours hours: Int) async throws -> Bool {
        let activities = try await getRecentActivities(forUserId: userId, limit: 100)
        let cutoffTime = Date().addingTimeInterval(TimeInterval(-hours * 60 * 60))
        
        return activities.contains { $0.timestamp > cutoffTime }
    }
    
    func getLastActivity(forUserId: String) async throws -> ActivityItem? {
        let activities = try await getRecentActivities(forUserId: userId, limit: 1)
        return activities.first
    }
    
    func getLastActivityByType(forUserId: String, type: ActivityType) async throws -> ActivityItem? {
        let activities = try await getActivitiesByType(forUserId: userId, type: type)
        return activities.sorted { $0.timestamp > $1.timestamp }.first
    }
    
    func getActivitiesByPriority(forUserId: String, priority: ActivityPriority) async throws -> [ActivityItem] {
        let activities = try await getActivities(forUserId: userId)
        return activities.filter { $0.priority == priority }
    }
    
    func getActivitiesByCategory(forUserId: String, category: String) async throws -> [ActivityItem] {
        let activities = try await getActivities(forUserId: userId)
        return activities.filter { $0.category == category }
    }
    
    func getActivitiesByDateRangeAndType(forUserId: String, dateRange: DateInterval, type: ActivityType) async throws -> [ActivityItem] {
        let activities = try await getActivities(byDateRange: dateRange)
        return activities.filter { $0.userId == userId && $0.type == type }
    }
    
    func getHighPriorityActivities(forUserId: String) async throws -> [ActivityItem] {
        let activities = try await getActivities(forUserId: userId)
        return activities.filter { $0.priority == .high }
    }
    
    func getPublicActivities(forUserId: String) async throws -> [ActivityItem] {
        let activities = try await getActivities(forUserId: userId)
        return activities.filter { $0.isPublic }
    }
    
    func getPrivateActivities(forUserId: String) async throws -> [ActivityItem] {
        let activities = try await getActivities(forUserId: userId)
        return activities.filter { !$0.isPublic }
    }
}

// MARK: - Activity Repository Error
enum ActivityRepositoryError: LocalizedError {
    case activityNotFound
    case invalidActivityData
    case activityAlreadyExists
    case invalidEntityReference
    case insufficientPermissions
    case databaseError(Error)
    case networkError(Error)
    case permissionDenied
    case quotaExceeded
    
    var errorDescription: String? {
        switch self {
        case .activityNotFound:
            return "Activity not found"
        case .invalidActivityData:
            return "Invalid activity data"
        case .activityAlreadyExists:
            return "Activity already exists"
        case .invalidEntityReference:
            return "Invalid entity reference"
        case .insufficientPermissions:
            return "Insufficient permissions for this operation"
        case .databaseError(let error):
            return "Database error: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .permissionDenied:
            return "Permission denied"
        case .quotaExceeded:
            return "Quota exceeded"
        }
    }
}
