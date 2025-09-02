import Foundation
import CoreData
import Combine

// MARK: - Core Data Audit Event Repository Implementation
class CoreDataAuditEventRepository: AuditEventRepository {
    // MARK: - Properties
    private let coreDataStack: CoreDataStack
    private let logger: Logger
    
    // MARK: - Initialization
    init(coreDataStack: CoreDataStack, logger: Logger) {
        self.coreDataStack = coreDataStack
        self.logger = logger
    }
    
    // MARK: - CRUD Operations
    func createAuditEvent(_ event: AuditEvent) async throws -> AuditEvent {
        return try await coreDataStack.performBackgroundTask { context in
            let entity = AuditEventEntity(context: context)
            
            // Map domain model to Core Data entity
            entity.id = event.id
            entity.action = event.action
            entity.category = event.category
            entity.entityId = event.entityId
            entity.entityType = event.entityType
            entity.userId = event.userId
            entity.details = event.details
            entity.severity = event.severity.rawValue
            entity.ipAddress = event.ipAddress
            entity.createdAt = event.createdAt
            
            try context.save()
            
            self.logger.info("Created audit event with ID: \(event.id)")
            return event
        }
    }
    
    func getAuditEvent(id: String) async throws -> AuditEvent? {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(AuditEventEntity.self, predicate: CoreDataUtilities.createPredicate(format: "id == %@", arguments: [id]))
            request.fetchLimit = 1
            
            let results = try context.fetch(request)
            guard let entity = results.first else { return nil }
            
            return self.mapEntityToAuditEvent(entity)
        }
    }
    
    func updateAuditEvent(_ event: AuditEvent) async throws -> AuditEvent {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(AuditEventEntity.self, predicate: CoreDataUtilities.createPredicate(format: "id == %@", arguments: [event.id]))
            request.fetchLimit = 1
            
            let results = try context.fetch(request)
            guard let entity = results.first else {
                throw AuditEventRepositoryError.auditEventNotFound
            }
            
            // Update entity with new values
            entity.action = event.action
            entity.category = event.category
            entity.entityId = event.entityId
            entity.entityType = event.entityType
            entity.userId = event.userId
            entity.details = event.details
            entity.severity = event.severity.rawValue
            entity.ipAddress = event.ipAddress
            
            try context.save()
            
            self.logger.info("Updated audit event with ID: \(event.id)")
            return event
        }
    }
    
    func deleteAuditEvent(id: String) async throws -> Bool {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(AuditEventEntity.self, predicate: CoreDataUtilities.createPredicate(format: "id == %@", arguments: [id]))
            request.fetchLimit = 1
            
            let results = try context.fetch(request)
            guard let entity = results.first else {
                throw AuditEventRepositoryError.auditEventNotFound
            }
            
            context.delete(entity)
            try context.save()
            
            self.logger.info("Deleted audit event with ID: \(id)")
            return true
        }
    }
    
    // MARK: - Query Operations
    func getAuditEvents(forUserId: String) async throws -> [AuditEvent] {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(AuditEventEntity.self, predicate: CoreDataUtilities.createPredicate(format: "userId == %@", arguments: [userId]), sortDescriptors: [CoreDataUtilities.createSortDescriptor(key: "createdAt", ascending: false)])
            let results = try context.fetch(request)
            
            return results.map { self.mapEntityToAuditEvent($0) }
        }
    }
    
    func getAuditEvents(byAction: String) async throws -> [AuditEvent] {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(AuditEventEntity.self, predicate: CoreDataUtilities.createPredicate(format: "action == %@", arguments: [action]), sortDescriptors: [CoreDataUtilities.createSortDescriptor(key: "createdAt", ascending: false)])
            let results = try context.fetch(request)
            
            return results.map { self.mapEntityToAuditEvent($0) }
        }
    }
    
    func getAuditEvents(byCategory: String) async throws -> [AuditEvent] {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(AuditEventEntity.self, predicate: CoreDataUtilities.createPredicate(format: "category == %@", arguments: [category]), sortDescriptors: [CoreDataUtilities.createSortDescriptor(key: "createdAt", ascending: false)])
            let results = try context.fetch(request)
            
            return results.map { self.mapEntityToAuditEvent($0) }
        }
    }
    
    func getAuditEvents(byEntityType: String) async throws -> [AuditEvent] {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(AuditEventEntity.self, predicate: CoreDataUtilities.createPredicate(format: "entityType == %@", arguments: [entityType]), sortDescriptors: [CoreDataUtilities.createSortDescriptor(key: "createdAt", ascending: false)])
            let results = try context.fetch(request)
            
            return results.map { self.mapEntityToAuditEvent($0) }
        }
    }
    
    func getAuditEvents(bySeverity: AuditEventSeverity) async throws -> [AuditEvent] {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(AuditEventEntity.self, predicate: CoreDataUtilities.createPredicate(format: "severity == %@", arguments: [severity.rawValue]), sortDescriptors: [CoreDataUtilities.createSortDescriptor(key: "createdAt", ascending: false)])
            let results = try context.fetch(request)
            
            return results.map { self.mapEntityToAuditEvent($0) }
        }
    }
    
    func getAuditEvents(byDateRange: DateInterval) async throws -> [AuditEvent] {
        return try await coreDataStack.performBackgroundTask { context in
            let predicate = CoreDataUtilities.createPredicate(format: "createdAt >= %@ AND createdAt <= %@", arguments: [dateRange.start, dateRange.end])
            let request = CoreDataUtilities.createFetchRequest(AuditEventEntity.self, predicate: predicate, sortDescriptors: [CoreDataUtilities.createSortDescriptor(key: "createdAt", ascending: false)])
            let results = try context.fetch(request)
            
            return results.map { self.mapEntityToAuditEvent($0) }
        }
    }
    
    func getAuditEvents(byEntityId: String) async throws -> [AuditEvent] {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(AuditEventEntity.self, predicate: CoreDataUtilities.createPredicate(format: "entityId == %@", arguments: [entityId]), sortDescriptors: [CoreDataUtilities.createSortDescriptor(key: "createdAt", ascending: false)])
            let results = try context.fetch(request)
            
            return results.map { self.mapEntityToAuditEvent($0) }
        }
    }
    
    func searchAuditEvents(query: String) async throws -> [AuditEvent] {
        return try await coreDataStack.performBackgroundTask { context in
            let predicate = CoreDataUtilities.createPredicate(format: "action CONTAINS[cd] %@ OR category CONTAINS[cd] %@ OR details CONTAINS[cd] %@ OR entityType CONTAINS[cd] %@", arguments: [query, query, query, query])
            let request = CoreDataUtilities.createFetchRequest(AuditEventEntity.self, predicate: predicate, sortDescriptors: [CoreDataUtilities.createSortDescriptor(key: "createdAt", ascending: false)])
            let results = try context.fetch(request)
            
            return results.map { self.mapEntityToAuditEvent($0) }
        }
    }
    
    // MARK: - Analytics Operations
    func getAuditEventStatistics(forUserId: String?) async throws -> AuditEventStatistics {
        return try await coreDataStack.performBackgroundTask { context in
            let predicate: NSPredicate
            if let userId = userId {
                predicate = CoreDataUtilities.createPredicate(format: "userId == %@", arguments: [userId])
            } else {
                predicate = NSPredicate(value: true)
            }
            
            let request = CoreDataUtilities.createFetchRequest(AuditEventEntity.self, predicate: predicate)
            let results = try context.fetch(request)
            
            let totalEvents = results.count
            
            // Group by action
            let actionGroups = Dictionary(grouping: results) { $0.action ?? "unknown" }
            let eventsByAction = actionGroups.map { action, events in
                AuditEventActionStats(
                    action: action,
                    count: events.count,
                    lastOccurrence: events.map { $0.createdAt ?? Date.distantPast }.max() ?? Date.distantPast
                )
            }
            
            // Group by category
            let categoryGroups = Dictionary(grouping: results) { $0.category ?? "unknown" }
            let eventsByCategory = categoryGroups.map { category, events in
                AuditEventCategoryStats(
                    category: category,
                    count: events.count,
                    lastOccurrence: events.map { $0.createdAt ?? Date.distantPast }.max() ?? Date.distantPast
                )
            }
            
            // Group by severity
            let severityGroups = Dictionary(grouping: results) { $0.severity ?? "unknown" }
            let eventsBySeverity = severityGroups.map { severity, events in
                AuditEventSeverityStats(
                    severity: AuditEventSeverity(rawValue: severity) ?? .info,
                    count: events.count,
                    lastOccurrence: events.map { $0.createdAt ?? Date.distantPast }.max() ?? Date.distantPast
                )
            }
            
            // Group by entity type
            let entityTypeGroups = Dictionary(grouping: results) { $0.entityType ?? "unknown" }
            let eventsByEntityType = entityTypeGroups.map { entityType, events in
                AuditEventEntityTypeStats(
                    entityType: entityType,
                    count: events.count,
                    lastOccurrence: events.map { $0.createdAt ?? Date.distantPast }.max() ?? Date.distantPast
                )
            }
            
            return AuditEventStatistics(
                totalEvents: totalEvents,
                eventsByAction: eventsByAction,
                eventsByCategory: eventsByCategory,
                eventsBySeverity: eventsBySeverity,
                eventsByEntityType: eventsByEntityType,
                lastEventDate: results.map { $0.createdAt ?? Date.distantPast }.max() ?? Date.distantPast
            )
        }
    }
    
    func getAuditEventPerformance(forUserId: String?, timeRange: TimeRange) async throws -> AuditEventPerformance {
        // This would need to be implemented with actual performance data
        return AuditEventPerformance(
            eventFrequency: 0.0,
            averageSeverity: .info,
            criticalEventRate: 0.0,
            userActivityScore: 0.8,
            systemHealthScore: 0.9
        )
    }
    
    func getAuditEventTrends(forUserId: String?, timeRange: TimeRange) async throws -> AuditEventTrends {
        // This would need to be implemented with actual trend analysis
        return AuditEventTrends(
            totalEvents: 0,
            eventsByDay: [:],
            eventsByWeek: [:],
            eventsByMonth: [:],
            peakEventTimes: [],
            commonActions: [],
            severityDistribution: [:]
        )
    }
    
    // MARK: - Security Operations
    func getSecurityAuditEvents(forUserId: String, timeRange: TimeRange) async throws -> [AuditEvent] {
        return try await coreDataStack.performBackgroundTask { context in
            let predicate = CoreDataUtilities.createPredicate(format: "userId == %@ AND (severity == %@ OR severity == %@ OR severity == %@) AND createdAt >= %@ AND createdAt <= %@", arguments: [userId, AuditEventSeverity.high.rawValue, AuditEventSeverity.critical.rawValue, AuditEventSeverity.security.rawValue, timeRange.start, timeRange.end])
            let request = CoreDataUtilities.createFetchRequest(AuditEventEntity.self, predicate: predicate, sortDescriptors: [CoreDataUtilities.createSortDescriptor(key: "createdAt", ascending: false)])
            let results = try context.fetch(request)
            
            return results.map { self.mapEntityToAuditEvent($0) }
        }
    }
    
    func getFailedAuthenticationEvents(forUserId: String, timeRange: TimeRange) async throws -> [AuditEvent] {
        return try await coreDataStack.performBackgroundTask { context in
            let predicate = CoreDataUtilities.createPredicate(format: "userId == %@ AND action == %@ AND createdAt >= %@ AND createdAt <= %@", arguments: [userId, "authentication_failed", timeRange.start, timeRange.end])
            let request = CoreDataUtilities.createFetchRequest(AuditEventEntity.self, predicate: predicate, sortDescriptors: [CoreDataUtilities.createSortDescriptor(key: "createdAt", ascending: false)])
            let results = try context.fetch(request)
            
            return results.map { self.mapEntityToAuditEvent($0) }
        }
    }
    
    func getSuspiciousActivityEvents(forUserId: String, timeRange: TimeRange) async throws -> [AuditEvent] {
        return try await coreDataStack.performBackgroundTask { context in
            let predicate = CoreDataUtilities.createPredicate(format: "userId == %@ AND (severity == %@ OR severity == %@) AND createdAt >= %@ AND createdAt <= %@", arguments: [userId, AuditEventSeverity.warning.rawValue, AuditEventSeverity.security.rawValue, timeRange.start, timeRange.end])
            let request = CoreDataUtilities.createFetchRequest(AuditEventEntity.self, predicate: predicate, sortDescriptors: [CoreDataUtilities.createSortDescriptor(key: "createdAt", ascending: false)])
            let results = try context.fetch(request)
            
            return results.map { self.mapEntityToAuditEvent($0) }
        }
    }
    
    // MARK: - Compliance Operations
    func getComplianceAuditTrail(forUserId: String, timeRange: TimeRange) async throws -> [AuditEvent] {
        return try await coreDataStack.performBackgroundTask { context in
            let predicate = CoreDataUtilities.createPredicate(format: "userId == %@ AND createdAt >= %@ AND createdAt <= %@", arguments: [userId, timeRange.start, timeRange.end])
            let request = CoreDataUtilities.createFetchRequest(AuditEventEntity.self, predicate: predicate, sortDescriptors: [CoreDataUtilities.createSortDescriptor(key: "createdAt", ascending: true)])
            let results = try context.fetch(request)
            
            return results.map { self.mapEntityToAuditEvent($0) }
        }
    }
    
    func exportAuditLog(forUserId: String?, timeRange: TimeRange, format: ExportFormat) async throws -> Data {
        // This would need to be implemented with actual export logic
        // For now, return empty data
        return Data()
    }
    
    // MARK: - Bulk Operations
    func bulkCreateAuditEvents(_ events: [AuditEvent]) async throws -> [AuditEvent] {
        return try await coreDataStack.performBackgroundTask { context in
            var createdEvents: [AuditEvent] = []
            
            for event in events {
                let entity = AuditEventEntity(context: context)
                
                // Map domain model to Core Data entity
                entity.id = event.id
                entity.action = event.action
                entity.category = event.category
                entity.entityId = event.entityId
                entity.entityType = event.entityType
                entity.userId = event.userId
                entity.details = event.details
                entity.severity = event.severity.rawValue
                entity.ipAddress = event.ipAddress
                entity.createdAt = event.createdAt
                
                createdEvents.append(event)
            }
            
            try context.save()
            self.logger.info("Bulk created \(createdEvents.count) audit events")
            return createdEvents
        }
    }
    
    func deleteOldAuditEvents(olderThan date: Date) async throws -> Int {
        return try await coreDataStack.performBackgroundTask { context in
            let predicate = CoreDataUtilities.createPredicate(format: "createdAt < %@", arguments: [date])
            let request = CoreDataUtilities.createFetchRequest(AuditEventEntity.self, predicate: predicate)
            let results = try context.fetch(request)
            
            let count = results.count
            for entity in results {
                context.delete(entity)
            }
            
            try context.save()
            self.logger.info("Deleted \(count) old audit events")
            return count
        }
    }
    
    func deleteAuditEvents(byUserId: String) async throws -> Int {
        return try await coreDataStack.performBackgroundTask { context in
            let predicate = CoreDataUtilities.createPredicate(format: "userId == %@", arguments: [userId])
            let request = CoreDataUtilities.createFetchRequest(AuditEventEntity.self, predicate: predicate)
            let results = try context.fetch(request)
            
            let count = results.count
            for entity in results {
                context.delete(entity)
            }
            
            try context.save()
            self.logger.info("Deleted \(count) audit events for user: \(userId)")
            return count
        }
    }
    
    // MARK: - Private Helper Methods
    private func mapEntityToAuditEvent(_ entity: AuditEventEntity) -> AuditEvent {
        return AuditEvent(
            id: entity.id ?? "",
            action: entity.action ?? "",
            category: entity.category ?? "",
            entityId: entity.entityId,
            entityType: entity.entityType,
            userId: entity.userId ?? "",
            details: entity.details,
            severity: AuditEventSeverity(rawValue: entity.severity ?? "info") ?? .info,
            ipAddress: entity.ipAddress,
            createdAt: entity.createdAt ?? Date()
        )
    }
}
