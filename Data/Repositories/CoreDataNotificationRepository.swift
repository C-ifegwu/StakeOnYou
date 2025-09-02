import Foundation
import CoreData
import Combine

// MARK: - Core Data Notification Repository Implementation
class CoreDataNotificationRepository: NotificationRepository {
    // MARK: - Properties
    private let coreDataStack: CoreDataStack
    private let logger: Logger
    
    // MARK: - Initialization
    init(coreDataStack: CoreDataStack, logger: Logger) {
        self.coreDataStack = coreDataStack
        self.logger = logger
    }
    
    // MARK: - CRUD Operations
    func createNotification(_ notification: NotificationItem) async throws -> NotificationItem {
        return try await coreDataStack.performBackgroundTask { context in
            let entity = NotificationItemEntity(context: context)
            
            // Map domain model to Core Data entity
            entity.id = notification.id
            entity.title = notification.title
            entity.body = notification.body
            entity.notificationType = notification.notificationType.rawValue
            entity.userId = notification.userId
            entity.isRead = notification.isRead
            entity.createdAt = notification.createdAt
            entity.scheduledAt = notification.scheduledAt
            
            try context.save()
            
            self.logger.info("Created notification with ID: \(notification.id)")
            return notification
        }
    }
    
    func getNotification(id: String) async throws -> NotificationItem? {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(NotificationItemEntity.self, predicate: CoreDataUtilities.createPredicate(format: "id == %@", arguments: [id]))
            request.fetchLimit = 1
            
            let results = try context.fetch(request)
            guard let entity = results.first else { return nil }
            
            return self.mapEntityToNotification(entity)
        }
    }
    
    func updateNotification(_ notification: NotificationItem) async throws -> NotificationItem {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(NotificationItemEntity.self, predicate: CoreDataUtilities.createPredicate(format: "id == %@", arguments: [notification.id]))
            request.fetchLimit = 1
            
            let results = try context.fetch(request)
            guard let entity = results.first else {
                throw NotificationRepositoryError.notificationNotFound
            }
            
            // Update entity with new values
            entity.title = notification.title
            entity.body = notification.body
            entity.notificationType = notification.notificationType.rawValue
            entity.userId = notification.userId
            entity.isRead = notification.isRead
            entity.scheduledAt = notification.scheduledAt
            
            try context.save()
            
            self.logger.info("Updated notification with ID: \(notification.id)")
            return notification
        }
    }
    
    func deleteNotification(id: String) async throws -> Bool {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(NotificationItemEntity.self, predicate: CoreDataUtilities.createPredicate(format: "id == %@", arguments: [id]))
            request.fetchLimit = 1
            
            let results = try context.fetch(request)
            guard let entity = results.first else {
                throw NotificationRepositoryError.notificationNotFound
            }
            
            context.delete(entity)
            try context.save()
            
            self.logger.info("Deleted notification with ID: \(id)")
            return true
        }
    }
    
    // MARK: - Query Operations
    func getNotifications(forUserId: String) async throws -> [NotificationItem] {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(NotificationItemEntity.self, predicate: CoreDataUtilities.createPredicate(format: "userId == %@", arguments: [forUserId]), sortDescriptors: [CoreDataUtilities.createSortDescriptor(key: "createdAt", ascending: false)])
            let results = try context.fetch(request)
            
            return results.map { self.mapEntityToNotification($0) }
        }
    }
    
    func getNotifications(byType: NotificationType) async throws -> [NotificationItem] {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(NotificationItemEntity.self, predicate: CoreDataUtilities.createPredicate(format: "notificationType == %@", arguments: [byType.rawValue]), sortDescriptors: [CoreDataUtilities.createSortDescriptor(key: "createdAt", ascending: false)])
            let results = try context.fetch(request)
            
            return results.map { self.mapEntityToNotification($0) }
        }
    }
    
    func getNotifications(byDateRange: DateInterval) async throws -> [NotificationItem] {
        return try await coreDataStack.performBackgroundTask { context in
            let predicate = CoreDataUtilities.createPredicate(format: "createdAt >= %@ AND createdAt <= %@", arguments: [byDateRange.start, byDateRange.end])
            let request = CoreDataUtilities.createFetchRequest(NotificationItemEntity.self, predicate: predicate, sortDescriptors: [CoreDataUtilities.createSortDescriptor(key: "createdAt", ascending: false)])
            let results = try context.fetch(request)
            
            return results.map { self.mapEntityToNotification($0) }
        }
    }
    
    func getUnreadNotifications(forUserId: String) async throws -> [NotificationItem] {
        return try await coreDataStack.performBackgroundTask { context in
            let predicate = CoreDataUtilities.createPredicate(format: "userId == %@ AND isRead == NO", arguments: [forUserId])
            let request = CoreDataUtilities.createFetchRequest(NotificationItemEntity.self, predicate: predicate, sortDescriptors: [CoreDataUtilities.createSortDescriptor(key: "createdAt", ascending: false)])
            let results = try context.fetch(request)
            
            return results.map { self.mapEntityToNotification($0) }
        }
    }
    
    func getScheduledNotifications(forUserId: String) async throws -> [NotificationItem] {
        return try await coreDataStack.performBackgroundTask { context in
            let predicate = CoreDataUtilities.createPredicate(format: "userId == %@ AND scheduledAt != nil", arguments: [forUserId])
            let request = CoreDataUtilities.createFetchRequest(NotificationItemEntity.self, predicate: predicate, sortDescriptors: [CoreDataUtilities.createSortDescriptor(key: "scheduledAt", ascending: true)])
            let results = try context.fetch(request)
            
            return results.map { self.mapEntityToNotification($0) }
        }
    }
    
    // MARK: - Status Operations
    func markNotificationAsRead(id: String) async throws -> NotificationItem {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(NotificationItemEntity.self, predicate: CoreDataUtilities.createPredicate(format: "id == %@", arguments: [id]))
            request.fetchLimit = 1
            
            let results = try context.fetch(request)
            guard let entity = results.first else {
                throw NotificationRepositoryError.notificationNotFound
            }
            
            entity.isRead = true
            try context.save()
            
            self.logger.info("Marked notification as read: \(id)")
            return self.mapEntityToNotification(entity)
        }
    }
    
    func markNotificationAsUnread(id: String) async throws -> NotificationItem {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(NotificationItemEntity.self, predicate: CoreDataUtilities.createPredicate(format: "id == %@", arguments: [id]))
            request.fetchLimit = 1
            
            let results = try context.fetch(request)
            guard let entity = results.first else {
                throw NotificationRepositoryError.notificationNotFound
            }
            
            entity.isRead = false
            try context.save()
            
            self.logger.info("Marked notification as unread: \(id)")
            return self.mapEntityToNotification(entity)
        }
    }
    
    func markAllNotificationsAsRead(forUserId: String) async throws -> [NotificationItem] {
        return try await coreDataStack.performBackgroundTask { context in
            let predicate = CoreDataUtilities.createPredicate(format: "userId == %@ AND isRead == NO", arguments: [forUserId])
            let request = CoreDataUtilities.createFetchRequest(NotificationItemEntity.self, predicate: predicate)
            let results = try context.fetch(request)
            
            for entity in results {
                entity.isRead = true
            }
            
            try context.save()
            
            self.logger.info("Marked all notifications as read for user: \(forUserId)")
            return results.map { self.mapEntityToNotification($0) }
        }
    }
    
    func markNotificationsAsRead(ids: [String]) async throws -> [NotificationItem] {
        return try await coreDataStack.performBackgroundTask { context in
            let predicate = CoreDataUtilities.createPredicate(format: "id IN %@", arguments: [ids])
            let request = CoreDataUtilities.createFetchRequest(NotificationItemEntity.self, predicate: predicate)
            let results = try context.fetch(request)
            
            for entity in results {
                entity.isRead = true
            }
            
            try context.save()
            
            self.logger.info("Marked \(results.count) notifications as read")
            return results.map { self.mapEntityToNotification($0) }
        }
    }
    
    // MARK: - Scheduling Operations
    func scheduleNotification(_ notification: NotificationItem, forDate: Date) async throws -> NotificationItem {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(NotificationItemEntity.self, predicate: CoreDataUtilities.createPredicate(format: "id == %@", arguments: [notification.id]))
            request.fetchLimit = 1
            
            let results = try context.fetch(request)
            guard let entity = results.first else {
                throw NotificationRepositoryError.notificationNotFound
            }
            
            entity.scheduledAt = forDate
            try context.save()
            
            self.logger.info("Scheduled notification for date: \(forDate)")
            return self.mapEntityToNotification(entity)
        }
    }
    
    func cancelScheduledNotification(id: String) async throws -> Bool {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(NotificationItemEntity.self, predicate: CoreDataUtilities.createPredicate(format: "id == %@", arguments: [id]))
            request.fetchLimit = 1
            
            let results = try context.fetch(request)
            guard let entity = results.first else {
                throw NotificationRepositoryError.notificationNotFound
            }
            
            entity.scheduledAt = nil
            try context.save()
            
            self.logger.info("Cancelled scheduled notification: \(id)")
            return true
        }
    }
    
    func updateNotificationSchedule(id: String, newDate: Date) async throws -> NotificationItem {
        return try await scheduleNotification(NotificationItem(id: id, title: "", body: "", notificationType: .general, userId: "", isRead: false, createdAt: Date(), scheduledAt: newDate), forDate: newDate)
    }
    
    func getNotificationsByScheduleDate(date: Date) async throws -> [NotificationItem] {
        return try await coreDataStack.performBackgroundTask { context in
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            
            let predicate = CoreDataUtilities.createPredicate(format: "scheduledAt >= %@ AND scheduledAt < %@", arguments: [startOfDay, endOfDay])
            let request = CoreDataUtilities.createFetchRequest(NotificationItemEntity.self, predicate: predicate, sortDescriptors: [CoreDataUtilities.createSortDescriptor(key: "scheduledAt", ascending: true)])
            let results = try context.fetch(request)
            
            return results.map { self.mapEntityToNotification($0) }
        }
    }
    
    // MARK: - Bulk Operations
    func bulkUpdateNotifications(_ notifications: [NotificationItem]) async throws -> [NotificationItem] {
        return try await coreDataStack.performBackgroundTask { context in
            var updatedNotifications: [NotificationItem] = []
            
            for notification in notifications {
                let request = CoreDataUtilities.createFetchRequest(NotificationItemEntity.self, predicate: CoreDataUtilities.createPredicate(format: "id == %@", arguments: [notification.id]))
                request.fetchLimit = 1
                
                let results = try context.fetch(request)
                if let entity = results.first {
                    // Update existing entity
                    entity.title = notification.title
                    entity.body = notification.body
                    entity.notificationType = notification.notificationType.rawValue
                    entity.userId = notification.userId
                    entity.isRead = notification.isRead
                    entity.scheduledAt = notification.scheduledAt
                    
                    updatedNotifications.append(notification)
                }
            }
            
            try context.save()
            self.logger.info("Bulk updated \(updatedNotifications.count) notifications")
            return updatedNotifications
        }
    }
    
    func deleteOldNotifications(olderThan date: Date) async throws -> Int {
        return try await coreDataStack.performBackgroundTask { context in
            let predicate = CoreDataUtilities.createPredicate(format: "createdAt < %@", arguments: [date])
            let request = CoreDataUtilities.createFetchRequest(NotificationItemEntity.self, predicate: predicate)
            let results = try context.fetch(request)
            
            let count = results.count
            for entity in results {
                context.delete(entity)
            }
            
            try context.save()
            self.logger.info("Deleted \(count) old notifications")
            return count
        }
    }
    
    func deleteNotifications(ids: [String]) async throws -> Int {
        return try await coreDataStack.performBackgroundTask { context in
            let predicate = CoreDataUtilities.createPredicate(format: "id IN %@", arguments: [ids])
            let request = CoreDataUtilities.createFetchRequest(NotificationItemEntity.self, predicate: predicate)
            let results = try context.fetch(request)
            
            let count = results.count
            for entity in results {
                context.delete(entity)
            }
            
            try context.save()
            self.logger.info("Deleted \(count) notifications")
            return count
        }
    }
    
    // MARK: - Analytics Operations
    func getNotificationStatistics(forUserId: String) async throws -> NotificationStatistics {
        return try await coreDataStack.performBackgroundTask { context in
            let predicate = CoreDataUtilities.createPredicate(format: "userId == %@", arguments: [forUserId])
            let request = CoreDataUtilities.createFetchRequest(NotificationItemEntity.self, predicate: predicate)
            let results = try context.fetch(request)
            
            let totalNotifications = results.count
            let unreadNotifications = results.filter { !$0.isRead }.count
            let readNotifications = results.filter { $0.isRead }.count
            let scheduledNotifications = results.filter { $0.scheduledAt != nil }.count
            
            // Group by type
            let typeGroups = Dictionary(grouping: results) { $0.notificationType ?? "unknown" }
            let notificationsByType = typeGroups.map { type, notifications in
                NotificationTypeStats(
                    type: NotificationType(rawValue: type) ?? .general,
                    count: notifications.count,
                    readCount: notifications.filter { $0.isRead }.count,
                    unreadCount: notifications.filter { !$0.isRead }.count,
                    averageReadTime: 0.0 // Would need read time tracking
                )
            }
            
            return NotificationStatistics(
                totalNotifications: totalNotifications,
                unreadNotifications: unreadNotifications,
                readNotifications: readNotifications,
                scheduledNotifications: scheduledNotifications,
                notificationsByType: notificationsByType,
                averageReadTime: 0.0 // Would need read time tracking
            )
        }
    }
    
    func getNotificationPerformance(forUserId: String, timeRange: TimeRange) async throws -> NotificationPerformance {
        // This would need to be implemented with actual performance data
        return NotificationPerformance(
            deliveryRate: 0.98,
            readRate: 0.75,
            clickThroughRate: 0.45,
            averageResponseTime: 180, // 3 minutes
            userEngagementScore: 0.8
        )
    }
    
    func getNotificationDeliveryStats(forUserId: String) async throws -> NotificationDeliveryStats {
        // This would need to be implemented with actual delivery data
        return NotificationDeliveryStats(
            totalSent: 0,
            delivered: 0,
            failed: 0,
            deliveryRate: 0.98,
            averageDeliveryTime: 0.5, // 0.5 seconds
            failureReasons: [:]
        )
    }
    
    // MARK: - Private Helper Methods
    private func mapEntityToNotification(_ entity: NotificationItemEntity) -> NotificationItem {
        return NotificationItem(
            id: entity.id ?? "",
            title: entity.title ?? "",
            body: entity.body ?? "",
            notificationType: NotificationType(rawValue: entity.notificationType ?? "general") ?? .general,
            userId: entity.userId ?? "",
            isRead: entity.isRead,
            createdAt: entity.createdAt ?? Date(),
            scheduledAt: entity.scheduledAt
        )
    }
}
