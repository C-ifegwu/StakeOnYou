import Foundation
import Combine

// MARK: - Notification Repository Protocol
protocol NotificationRepository {
    // MARK: - CRUD Operations
    func createNotification(_ notification: NotificationItem) async throws -> NotificationItem
    func getNotification(id: String) async throws -> NotificationItem?
    func updateNotification(_ notification: NotificationItem) async throws -> NotificationItem
    func deleteNotification(id: String) async throws -> Bool
    
    // MARK: - Query Operations
    func getNotifications(forUserId: String) async throws -> [NotificationItem]
    func getNotifications(byType: NotificationType) async throws -> [NotificationItem]
    func getNotifications(byDateRange: DateInterval) async throws -> [NotificationItem]
    func getUnreadNotifications(forUserId: String) async throws -> [NotificationItem]
    func getScheduledNotifications(forUserId: String) async throws -> [NotificationItem]
    
    // MARK: - Status Operations
    func markNotificationAsRead(id: String) async throws -> NotificationItem
    func markNotificationAsUnread(id: String) async throws -> NotificationItem
    func markAllNotificationsAsRead(forUserId: String) async throws -> [NotificationItem]
    func markNotificationsAsRead(ids: [String]) async throws -> [NotificationItem]
    
    // MARK: - Scheduling Operations
    func scheduleNotification(_ notification: NotificationItem, forDate: Date) async throws -> NotificationItem
    func cancelScheduledNotification(id: String) async throws -> Bool
    func updateNotificationSchedule(id: String, newDate: Date) async throws -> NotificationItem
    func getNotificationsByScheduleDate(date: Date) async throws -> [NotificationItem]
    
    // MARK: - Bulk Operations
    func bulkUpdateNotifications(_ notifications: [NotificationItem]) async throws -> [NotificationItem]
    func deleteOldNotifications(olderThan date: Date) async throws -> Int
    func deleteNotifications(ids: [String]) async throws -> Int
    
    // MARK: - Analytics Operations
    func getNotificationStatistics(forUserId: String) async throws -> NotificationStatistics
    func getNotificationPerformance(forUserId: String, timeRange: TimeRange) async throws -> NotificationPerformance
    func getNotificationDeliveryStats(forUserId: String) async throws -> NotificationDeliveryStats
}

// MARK: - Supporting Models
struct NotificationStatistics {
    let totalNotifications: Int
    let unreadNotifications: Int
    let readNotifications: Int
    let scheduledNotifications: Int
    let notificationsByType: [NotificationTypeStats]
    let averageReadTime: TimeInterval
}

struct NotificationTypeStats {
    let type: NotificationType
    let count: Int
    let readCount: Int
    let unreadCount: Int
    let averageReadTime: TimeInterval
}

struct NotificationPerformance {
    let deliveryRate: Double
    let readRate: Double
    let clickThroughRate: Double
    let averageResponseTime: TimeInterval
    let userEngagementScore: Double
}

struct NotificationDeliveryStats {
    let totalSent: Int
    let delivered: Int
    let failed: Int
    let deliveryRate: Double
    let averageDeliveryTime: TimeInterval
    let failureReasons: [String: Int]
}

// MARK: - Notification Repository Extensions
extension NotificationRepository {
    // MARK: - Convenience Methods
    func getRecentNotifications(forUserId: String, limit: Int = 10) async throws -> [NotificationItem] {
        let notifications = try await getNotifications(forUserId: userId)
        return Array(notifications.prefix(limit))
    }
    
    func getNotificationsByPriority(forUserId: String, priority: NotificationPriority) async throws -> [NotificationItem] {
        let notifications = try await getNotifications(forUserId: userId)
        return notifications.filter { $0.priority == priority }
    }
    
    func getNotificationsByCategory(forUserId: String, category: String) async throws -> [NotificationItem] {
        let notifications = try await getNotifications(forUserId: userId)
        return notifications.filter { $0.category == category }
    }
    
    func getNotificationsByStatus(forUserId: String, isRead: Bool) async throws -> [NotificationItem] {
        if isRead {
            return try await getNotifications(forUserId: userId).filter { $0.isRead }
        } else {
            return try await getUnreadNotifications(forUserId: userId)
        }
    }
    
    func getNotificationsByDate(forUserId: String, date: Date) async throws -> [NotificationItem] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
        
        let dateInterval = DateInterval(start: startOfDay, end: endOfDay)
        return try await getNotifications(byDateRange: dateInterval)
    }
    
    func getNotificationsByWeek(forUserId: String, weekOfYear: Int, year: Int) async throws -> [NotificationItem] {
        let calendar = Calendar.current
        let dateComponents = DateComponents(weekOfYear: weekOfYear, yearForWeekOfYear: year)
        guard let startOfWeek = calendar.date(from: dateComponents),
              let endOfWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: startOfWeek) else {
            return []
        }
        
        let dateInterval = DateInterval(start: startOfWeek, end: endOfWeek)
        return try await getNotifications(byDateRange: dateInterval)
    }
    
    func getNotificationsByMonth(forUserId: String, month: Int, year: Int) async throws -> [NotificationItem] {
        let calendar = Calendar.current
        let dateComponents = DateComponents(month: month, year: year)
        guard let startOfMonth = calendar.date(from: dateComponents),
              let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) else {
            return []
        }
        
        let dateInterval = DateInterval(start: startOfMonth, end: endOfMonth)
        return try await getNotifications(byDateRange: dateInterval)
    }
    
    func getNotificationCount(forUserId: String) async throws -> Int {
        let notifications = try await getNotifications(forUserId: userId)
        return notifications.count
    }
    
    func getUnreadNotificationCount(forUserId: String) async throws -> Int {
        let unreadNotifications = try await getUnreadNotifications(forUserId: userId)
        return unreadNotifications.count
    }
    
    func getScheduledNotificationCount(forUserId: String) async throws -> Int {
        let scheduledNotifications = try await getScheduledNotifications(forUserId: userId)
        return scheduledNotifications.count
    }
    
    func hasUnreadNotifications(forUserId: String) async throws -> Bool {
        let unreadCount = try await getUnreadNotificationCount(forUserId: userId)
        return unreadCount > 0
    }
    
    func getNotificationsByTypeAndStatus(forUserId: String, type: NotificationType, isRead: Bool) async throws -> [NotificationItem] {
        let notifications = try await getNotifications(forUserId: userId)
        return notifications.filter { $0.notificationType == type && $0.isRead == isRead }
    }
    
    func getNotificationsByDateRangeAndType(forUserId: String, dateRange: DateInterval, type: NotificationType) async throws -> [NotificationItem] {
        let notifications = try await getNotifications(byDateRange: dateRange)
        return notifications.filter { $0.userId == userId && $0.notificationType == type }
    }
}

// MARK: - Notification Repository Error
enum NotificationRepositoryError: LocalizedError {
    case notificationNotFound
    case invalidNotificationData
    case notificationAlreadyExists
    case invalidScheduleDate
    case notificationNotScheduled
    case insufficientPermissions
    case databaseError(Error)
    case networkError(Error)
    case permissionDenied
    case quotaExceeded
    
    var errorDescription: String? {
        switch self {
        case .notificationNotFound:
            return "Notification not found"
        case .invalidNotificationData:
            return "Invalid notification data"
        case .notificationAlreadyExists:
            return "Notification already exists"
        case .invalidScheduleDate:
            return "Invalid schedule date"
        case .notificationNotScheduled:
            return "Notification is not scheduled"
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
