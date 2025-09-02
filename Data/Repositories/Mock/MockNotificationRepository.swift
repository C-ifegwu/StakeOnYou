import Foundation
import Combine

// MARK: - Mock Notification Repository Implementation
class MockNotificationRepository: NotificationRepository {
    // MARK: - Properties
    private var notifications: [String: NotificationItem] = [:]
    private let logger: Logger
    
    // MARK: - Initialization
    init(logger: Logger = ConsoleLogger()) {
        self.logger = logger
        setupMockData()
    }
    
    // MARK: - CRUD Operations
    func createNotification(_ notification: NotificationItem) async throws -> NotificationItem {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        var newNotification = notification
        if newNotification.id.isEmpty {
            newNotification = NotificationItem(
                id: UUID().uuidString,
                title: notification.title,
                body: notification.body,
                notificationType: notification.notificationType,
                userId: notification.userId,
                isRead: notification.isRead,
                createdAt: Date(),
                scheduledAt: notification.scheduledAt
            )
        }
        
        notifications[newNotification.id] = newNotification
        logger.info("Mock: Created notification with ID: \(newNotification.id)")
        return newNotification
    }
    
    func getNotification(id: String) async throws -> NotificationItem? {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 200_000_000)
        
        let notification = notifications[id]
        logger.info("Mock: Retrieved notification with ID: \(id), found: \(notification != nil)")
        return notification
    }
    
    func updateNotification(_ notification: NotificationItem) async throws -> NotificationItem {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        guard notifications[notification.id] != nil else {
            throw NotificationRepositoryError.notificationNotFound
        }
        
        notifications[notification.id] = notification
        logger.info("Mock: Updated notification with ID: \(notification.id)")
        return notification
    }
    
    func deleteNotification(id: String) async throws -> Bool {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        guard notifications[id] != nil else {
            throw NotificationRepositoryError.notificationNotFound
        }
        
        notifications.removeValue(forKey: id)
        logger.info("Mock: Deleted notification with ID: \(id)")
        return true
    }
    
    // MARK: - Query Operations
    func getNotifications(forUserId: String) async throws -> [NotificationItem] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let userNotifications = notifications.values.filter { $0.userId == forUserId }
        logger.info("Mock: Retrieved \(userNotifications.count) notifications for user: \(forUserId)")
        return userNotifications
    }
    
    func getNotifications(byType: NotificationType) async throws -> [NotificationItem] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 200_000_000)
        
        let typeNotifications = notifications.values.filter { $0.notificationType == byType }
        logger.info("Mock: Retrieved \(typeNotifications.count) notifications with type: \(byType)")
        return typeNotifications
    }
    
    func getNotifications(byDateRange: DateInterval) async throws -> [NotificationItem] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let dateRangeNotifications = notifications.values.filter { notification in
            return notification.createdAt >= byDateRange.start && notification.createdAt <= byDateRange.end
        }
        
        logger.info("Mock: Retrieved \(dateRangeNotifications.count) notifications in date range")
        return dateRangeNotifications
    }
    
    func getUnreadNotifications(forUserId: String) async throws -> [NotificationItem] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 200_000_000)
        
        let unreadNotifications = notifications.values.filter { $0.userId == forUserId && !$0.isRead }
        logger.info("Mock: Retrieved \(unreadNotifications.count) unread notifications for user: \(forUserId)")
        return unreadNotifications
    }
    
    func getScheduledNotifications(forUserId: String) async throws -> [NotificationItem] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 200_000_000)
        
        let scheduledNotifications = notifications.values.filter { $0.userId == forUserId && $0.scheduledAt != nil }
        logger.info("Mock: Retrieved \(scheduledNotifications.count) scheduled notifications for user: \(forUserId)")
        return scheduledNotifications
    }
    
    // MARK: - Status Operations
    func markNotificationAsRead(id: String) async throws -> NotificationItem {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 200_000_000)
        
        guard var notification = notifications[id] else {
            throw NotificationRepositoryError.notificationNotFound
        }
        
        notification.isRead = true
        notifications[id] = notification
        
        logger.info("Mock: Marked notification as read: \(id)")
        return notification
    }
    
    func markNotificationAsUnread(id: String) async throws -> NotificationItem {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 200_000_000)
        
        guard var notification = notifications[id] else {
            throw NotificationRepositoryError.notificationNotFound
        }
        
        notification.isRead = false
        notifications[id] = notification
        
        logger.info("Mock: Marked notification as unread: \(id)")
        return notification
    }
    
    func markAllNotificationsAsRead(forUserId: String) async throws -> [NotificationItem] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        let userNotifications = notifications.values.filter { $0.userId == forUserId }
        var updatedNotifications: [NotificationItem] = []
        
        for var notification in userNotifications {
            notification.isRead = true
            notifications[notification.id] = notification
            updatedNotifications.append(notification)
        }
        
        logger.info("Mock: Marked all notifications as read for user: \(forUserId)")
        return updatedNotifications
    }
    
    func markNotificationsAsRead(ids: [String]) async throws -> [NotificationItem] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        var updatedNotifications: [NotificationItem] = []
        
        for id in ids {
            if var notification = notifications[id] {
                notification.isRead = true
                notifications[id] = notification
                updatedNotifications.append(notification)
            }
        }
        
        logger.info("Mock: Marked \(updatedNotifications.count) notifications as read")
        return updatedNotifications
    }
    
    // MARK: - Scheduling Operations
    func scheduleNotification(_ notification: NotificationItem, forDate: Date) async throws -> NotificationItem {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        guard var existingNotification = notifications[notification.id] else {
            throw NotificationRepositoryError.notificationNotFound
        }
        
        existingNotification.scheduledAt = forDate
        notifications[notification.id] = existingNotification
        
        logger.info("Mock: Scheduled notification for date: \(forDate)")
        return existingNotification
    }
    
    func cancelScheduledNotification(id: String) async throws -> Bool {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        guard var notification = notifications[id] else {
            throw NotificationRepositoryError.notificationNotFound
        }
        
        notification.scheduledAt = nil
        notifications[id] = notification
        
        logger.info("Mock: Cancelled scheduled notification: \(id)")
        return true
    }
    
    func updateNotificationSchedule(id: String, newDate: Date) async throws -> NotificationItem {
        return try await scheduleNotification(NotificationItem(id: id, title: "", body: "", notificationType: .general, userId: "", isRead: false, createdAt: Date(), scheduledAt: newDate), forDate: newDate)
    }
    
    func getNotificationsByScheduleDate(date: Date) async throws -> [NotificationItem] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let scheduledNotifications = notifications.values.filter { notification in
            guard let scheduledAt = notification.scheduledAt else { return false }
            return scheduledAt >= startOfDay && scheduledAt < endOfDay
        }
        
        logger.info("Mock: Retrieved \(scheduledNotifications.count) notifications for schedule date: \(date)")
        return scheduledNotifications
    }
    
    // MARK: - Bulk Operations
    func bulkUpdateNotifications(_ notifications: [NotificationItem]) async throws -> [NotificationItem] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        var updatedNotifications: [NotificationItem] = []
        
        for notification in notifications {
            if self.notifications[notification.id] != nil {
                self.notifications[notification.id] = notification
                updatedNotifications.append(notification)
            }
        }
        
        logger.info("Mock: Bulk updated \(updatedNotifications.count) notifications")
        return updatedNotifications
    }
    
    func deleteOldNotifications(olderThan date: Date) async throws -> Int {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 600_000_000)
        
        let oldNotifications = notifications.values.filter { $0.createdAt < date }
        let count = oldNotifications.count
        
        for notification in oldNotifications {
            notifications.removeValue(forKey: notification.id)
        }
        
        logger.info("Mock: Deleted \(count) old notifications")
        return count
    }
    
    func deleteNotifications(ids: [String]) async throws -> Int {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        var deletedCount = 0
        
        for id in ids {
            if notifications[id] != nil {
                notifications.removeValue(forKey: id)
                deletedCount += 1
            }
        }
        
        logger.info("Mock: Deleted \(deletedCount) notifications")
        return deletedCount
    }
    
    // MARK: - Analytics Operations
    func getNotificationStatistics(forUserId: String) async throws -> NotificationStatistics {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        let userNotifications = notifications.values.filter { $0.userId == forUserId }
        let totalNotifications = userNotifications.count
        let unreadNotifications = userNotifications.filter { !$0.isRead }.count
        let readNotifications = userNotifications.filter { $0.isRead }.count
        let scheduledNotifications = userNotifications.filter { $0.scheduledAt != nil }.count
        
        // Group by type
        let typeGroups = Dictionary(grouping: userNotifications) { $0.notificationType }
        let notificationsByType = typeGroups.map { type, notifications in
            NotificationTypeStats(
                type: type,
                count: notifications.count,
                readCount: notifications.filter { $0.isRead }.count,
                unreadCount: notifications.filter { !$0.isRead }.count,
                averageReadTime: 0.0 // Would need read time tracking
            )
        }
        
        let statistics = NotificationStatistics(
            totalNotifications: totalNotifications,
            unreadNotifications: unreadNotifications,
            readNotifications: readNotifications,
            scheduledNotifications: scheduledNotifications,
            notificationsByType: notificationsByType,
            averageReadTime: 0.0 // Would need read time tracking
        )
        
        logger.info("Mock: Generated notification statistics for user: \(forUserId)")
        return statistics
    }
    
    func getNotificationPerformance(forUserId: String, timeRange: TimeRange) async throws -> NotificationPerformance {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let performance = NotificationPerformance(
            deliveryRate: 0.98,
            readRate: 0.75,
            clickThroughRate: 0.45,
            averageResponseTime: 180, // 3 minutes
            userEngagementScore: 0.8
        )
        
        logger.info("Mock: Generated notification performance for user: \(forUserId)")
        return performance
    }
    
    func getNotificationDeliveryStats(forUserId: String) async throws -> NotificationDeliveryStats {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let stats = NotificationDeliveryStats(
            totalSent: 0,
            delivered: 0,
            failed: 0,
            deliveryRate: 0.98,
            averageDeliveryTime: 0.5, // 0.5 seconds
            failureReasons: [:]
        )
        
        logger.info("Mock: Generated notification delivery stats for user: \(forUserId)")
        return stats
    }
    
    // MARK: - Private Helper Methods
    private func setupMockData() {
        // Create some mock notifications for testing
        let mockNotifications = [
            NotificationItem(
                id: "notification-1",
                title: "Goal Reminder",
                body: "Don't forget to check in on your 'Learn SwiftUI' goal today!",
                notificationType: .goalReminder,
                userId: "user-1",
                isRead: false,
                createdAt: Date().addingTimeInterval(-2 * 60 * 60), // 2 hours ago
                scheduledAt: nil
            ),
            NotificationItem(
                id: "notification-2",
                title: "Milestone Achieved!",
                body: "Congratulations! You've completed the 'Complete Basics' milestone for your SwiftUI goal.",
                notificationType: .milestoneCompleted,
                userId: "user-1",
                isRead: true,
                createdAt: Date().addingTimeInterval(-1 * 24 * 60 * 60), // 1 day ago
                scheduledAt: nil
            ),
            NotificationItem(
                id: "notification-3",
                title: "Weekly Progress Report",
                body: "Here's your weekly progress summary. You're making great progress on your goals!",
                notificationType: .weeklyReport,
                userId: "user-1",
                isRead: false,
                createdAt: Date().addingTimeInterval(-6 * 24 * 60 * 60), // 6 days ago
                scheduledAt: nil
            ),
            NotificationItem(
                id: "notification-4",
                title: "Stake Accrual Update",
                body: "Your stake for 'Run 5K' has accrued $0.50 in interest this week.",
                notificationType: .stakeUpdate,
                userId: "user-1",
                isRead: true,
                createdAt: Date().addingTimeInterval(-3 * 24 * 60 * 60), // 3 days ago
                scheduledAt: nil
            ),
            NotificationItem(
                id: "notification-5",
                title: "Scheduled Reminder",
                body: "Time to work on your fitness goals! Your scheduled workout reminder.",
                notificationType: .scheduledReminder,
                userId: "user-1",
                isRead: false,
                createdAt: Date().addingTimeInterval(-1 * 60 * 60), // 1 hour ago
                scheduledAt: Date().addingTimeInterval(30 * 60) // 30 minutes from now
            ),
            NotificationItem(
                id: "notification-6",
                title: "Welcome to StakeOnYou!",
                body: "We're excited to have you on board. Start by creating your first goal and setting a stake.",
                notificationType: .welcome,
                userId: "user-2",
                isRead: false,
                createdAt: Date().addingTimeInterval(-1 * 24 * 60 * 60), // 1 day ago
                scheduledAt: nil
            ),
            NotificationItem(
                id: "notification-7",
                title: "Goal Deadline Warning",
                body: "Your goal 'Read 12 Books' is due in 2 days. Make sure to complete your final milestone!",
                notificationType: .deadlineWarning,
                userId: "user-2",
                isRead: false,
                createdAt: Date().addingTimeInterval(-12 * 60 * 60), // 12 hours ago
                scheduledAt: nil
            )
        ]
        
        for notification in mockNotifications {
            notifications[notification.id] = notification
        }
        
        logger.info("Mock: Setup \(mockNotifications.count) mock notifications")
    }
}
