import Foundation
import CoreData
import Combine

// MARK: - Core Data AI Nudge Repository Implementation
class CoreDataAINudgeRepository: AINudgeRepository {
    // MARK: - Properties
    private let coreDataStack: CoreDataStack
    private let logger: Logger
    
    // MARK: - Initialization
    init(coreDataStack: CoreDataStack, logger: Logger) {
        self.coreDataStack = coreDataStack
        self.logger = logger
    }
    
    // MARK: - CRUD Operations
    func createNudge(_ nudge: Nudge) async throws -> Nudge {
        return try await coreDataStack.performBackgroundTask { context in
            let entity = NudgeEntity(context: context)
            
            // Map domain model to Core Data entity
            entity.id = nudge.id
            entity.title = nudge.title
            entity.content = nudge.content
            entity.type = nudge.type.rawValue
            entity.category = nudge.category.rawValue
            entity.priority = nudge.priority.rawValue
            entity.actionType = nudge.actionType.rawValue
            entity.userId = nudge.userId
            entity.isRead = nudge.isRead
            entity.isApplied = nudge.isApplied
            entity.createdAt = nudge.createdAt
            
            try context.save()
            
            self.logger.info("Created AI nudge with ID: \(nudge.id)")
            return nudge
        }
    }
    
    func getNudge(id: String) async throws -> Nudge? {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(NudgeEntity.self, predicate: CoreDataUtilities.createPredicate(format: "id == %@", arguments: [id]))
            request.fetchLimit = 1
            
            let results = try context.fetch(request)
            guard let entity = results.first else { return nil }
            
            return self.mapEntityToNudge(entity)
        }
    }
    
    func updateNudge(_ nudge: Nudge) async throws -> Nudge {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(NudgeEntity.self, predicate: CoreDataUtilities.createPredicate(format: "id == %@", arguments: [nudge.id]))
            request.fetchLimit = 1
            
            let results = try context.fetch(request)
            guard let entity = results.first else {
                throw AINudgeRepositoryError.nudgeNotFound
            }
            
            // Update entity with new values
            entity.title = nudge.title
            entity.content = nudge.content
            entity.type = nudge.type.rawValue
            entity.category = nudge.category.rawValue
            entity.priority = nudge.priority.rawValue
            entity.actionType = nudge.actionType.rawValue
            entity.userId = nudge.userId
            entity.isRead = nudge.isRead
            entity.isApplied = nudge.isApplied
            
            try context.save()
            
            self.logger.info("Updated AI nudge with ID: \(nudge.id)")
            return nudge
        }
    }
    
    func deleteNudge(id: String) async throws -> Bool {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(NudgeEntity.self, predicate: CoreDataUtilities.createPredicate(format: "id == %@", arguments: [id]))
            request.fetchLimit = 1
            
            let results = try context.fetch(request)
            guard let entity = results.first else {
                throw AINudgeRepositoryError.nudgeNotFound
            }
            
            context.delete(entity)
            try context.save()
            
            self.logger.info("Deleted AI nudge with ID: \(id)")
            return true
        }
    }
    
    // MARK: - Query Operations
    func getNudges(forUserId: String) async throws -> [Nudge] {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(NudgeEntity.self, predicate: CoreDataUtilities.createPredicate(format: "userId == %@", arguments: [userId]), sortDescriptors: [CoreDataUtilities.createSortDescriptor(key: "createdAt", ascending: false)])
            let results = try context.fetch(request)
            
            return results.map { self.mapEntityToNudge($0) }
        }
    }
    
    func getNudges(byType: NudgeType) async throws -> [Nudge] {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(NudgeEntity.self, predicate: CoreDataUtilities.createPredicate(format: "type == %@", arguments: [type.rawValue]), sortDescriptors: [CoreDataUtilities.createSortDescriptor(key: "createdAt", ascending: false)])
            let results = try context.fetch(request)
            
            return results.map { self.mapEntityToNudge($0) }
        }
    }
    
    func getNudges(byCategory: NudgeCategory) async throws -> [Nudge] {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(NudgeEntity.self, predicate: CoreDataUtilities.createPredicate(format: "category == %@", arguments: [category.rawValue]), sortDescriptors: [CoreDataUtilities.createSortDescriptor(key: "createdAt", ascending: false)])
            let results = try context.fetch(request)
            
            return results.map { self.mapEntityToNudge($0) }
        }
    }
    
    func getNudges(byPriority: NudgePriority) async throws -> [Nudge] {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(NudgeEntity.self, predicate: CoreDataUtilities.createPredicate(format: "priority == %@", arguments: [priority.rawValue]), sortDescriptors: [CoreDataUtilities.createSortDescriptor(key: "createdAt", ascending: false)])
            let results = try context.fetch(request)
            
            return results.map { self.mapEntityToNudge($0) }
        }
    }
    
    func getNudges(byDateRange: DateInterval) async throws -> [Nudge] {
        return try await coreDataStack.performBackgroundTask { context in
            let predicate = CoreDataUtilities.createPredicate(format: "createdAt >= %@ AND createdAt <= %@", arguments: [dateRange.start, dateRange.end])
            let request = CoreDataUtilities.createFetchRequest(NudgeEntity.self, predicate: predicate, sortDescriptors: [CoreDataUtilities.createSortDescriptor(key: "createdAt", ascending: false)])
            let results = try context.fetch(request)
            
            return results.map { self.mapEntityToNudge($0) }
        }
    }
    
    // MARK: - Status Operations
    func markNudgeAsRead(id: String) async throws -> Nudge {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(NudgeEntity.self, predicate: CoreDataUtilities.createPredicate(format: "id == %@", arguments: [id]))
            request.fetchLimit = 1
            
            let results = try context.fetch(request)
            guard let entity = results.first else {
                throw AINudgeRepositoryError.nudgeNotFound
            }
            
            entity.isRead = true
            try context.save()
            
            self.logger.info("Marked AI nudge as read: \(id)")
            return self.mapEntityToNudge(entity)
        }
    }
    
    func markNudgeAsApplied(id: String) async throws -> Nudge {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(NudgeEntity.self, predicate: CoreDataUtilities.createPredicate(format: "id == %@", arguments: [id]))
            request.fetchLimit = 1
            
            let results = try context.fetch(request)
            guard let entity = results.first else {
                throw AINudgeRepositoryError.nudgeNotFound
            }
            
            entity.isApplied = true
            try context.save()
            
            self.logger.info("Marked AI nudge as applied: \(id)")
            return self.mapEntityToNudge(entity)
        }
    }
    
    func markNudgeAsDismissed(id: String) async throws -> Nudge {
        // For now, just mark as read since we don't have a dismissed field
        return try await markNudgeAsRead(id: id)
    }
    
    func getUnreadNudges(forUserId: String) async throws -> [Nudge] {
        return try await coreDataStack.performBackgroundTask { context in
            let predicate = CoreDataUtilities.createPredicate(format: "userId == %@ AND isRead == NO", arguments: [userId])
            let request = CoreDataUtilities.createFetchRequest(NudgeEntity.self, predicate: predicate, sortDescriptors: [CoreDataUtilities.createSortDescriptor(key: "createdAt", ascending: false)])
            let results = try context.fetch(request)
            
            return results.map { self.mapEntityToNudge($0) }
        }
    }
    
    func getAppliedNudges(forUserId: String) async throws -> [Nudge] {
        return try await coreDataStack.performBackgroundTask { context in
            let predicate = CoreDataUtilities.createPredicate(format: "userId == %@ AND isApplied == YES", arguments: [userId])
            let request = CoreDataUtilities.createFetchRequest(NudgeEntity.self, predicate: predicate, sortDescriptors: [CoreDataUtilities.createSortDescriptor(key: "createdAt", ascending: false)])
            let results = try context.fetch(request)
            
            return results.map { self.mapEntityToNudge($0) }
        }
    }
    
    func getDismissedNudges(forUserId: String) async throws -> [Nudge] {
        // For now, return empty array since we don't have a dismissed field
        return []
    }
    
    // MARK: - AI Generation Operations
    func generatePersonalizedNudges(forUserId: String, context: UserContext) async throws -> [Nudge] {
        // This would need to be implemented with actual AI generation logic
        // For now, return empty array
        return []
    }
    
    func getNudgeSuggestions(forUserId: String, limit: Int) async throws -> [Nudge] {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(NudgeEntity.self, predicate: CoreDataUtilities.createPredicate(format: "userId == %@", arguments: [userId]), sortDescriptors: [CoreDataUtilities.createSortDescriptor(key: "createdAt", ascending: false)])
            request.fetchLimit = limit
            let results = try context.fetch(request)
            
            return results.map { self.mapEntityToNudge($0) }
        }
    }
    
    func updateNudgeEffectiveness(nudgeId: String, wasEffective: Bool, feedback: String?) async throws -> Nudge {
        // This would need to be implemented with actual effectiveness tracking
        // For now, just return the nudge
        return try await getNudge(id: nudgeId) ?? Nudge(
            id: nudgeId,
            title: "",
            content: "",
            type: .motivational,
            category: .general,
            priority: .medium,
            actionType: .none,
            userId: "",
            isRead: false,
            isApplied: false,
            createdAt: Date()
        )
    }
    
    // MARK: - Analytics Operations
    func getNudgeStatistics(forUserId: String) async throws -> NudgeStatistics {
        return try await coreDataStack.performBackgroundTask { context in
            let predicate = CoreDataUtilities.createPredicate(format: "userId == %@", arguments: [userId])
            let request = CoreDataUtilities.createFetchRequest(NudgeEntity.self, predicate: predicate)
            let results = try context.fetch(request)
            
            let totalNudges = results.count
            let unreadNudges = results.filter { !$0.isRead }.count
            let appliedNudges = results.filter { $0.isApplied }.count
            let dismissedNudges = 0 // Would need dismissed field
            
            // Group by type
            let typeGroups = Dictionary(grouping: results) { $0.type ?? "unknown" }
            let nudgesByType = typeGroups.map { type, nudges in
                NudgeTypeStats(
                    type: NudgeType(rawValue: type) ?? .motivational,
                    count: nudges.count,
                    appliedCount: nudges.filter { $0.isApplied }.count,
                    dismissedCount: 0, // Would need dismissed field
                    effectiveness: 0.0 // Would need effectiveness tracking
                )
            }
            
            // Group by category
            let categoryGroups = Dictionary(grouping: results) { $0.category ?? "unknown" }
            let nudgesByCategory = categoryGroups.map { category, nudges in
                NudgeCategoryStats(
                    category: NudgeCategory(rawValue: category) ?? .general,
                    count: nudges.count,
                    appliedCount: nudges.filter { $0.isApplied }.count,
                    dismissedCount: 0, // Would need dismissed field
                    effectiveness: 0.0 // Would need effectiveness tracking
                )
            }
            
            return NudgeStatistics(
                totalNudges: totalNudges,
                unreadNudges: unreadNudges,
                appliedNudges: appliedNudges,
                dismissedNudges: dismissedNudges,
                nudgesByType: nudgesByType,
                nudgesByCategory: nudgesByCategory,
                averageEffectiveness: 0.0 // Would need effectiveness tracking
            )
        }
    }
    
    func getNudgePerformance(forUserId: String, timeRange: TimeRange) async throws -> NudgePerformance {
        // This would need to be implemented with actual performance data
        return NudgePerformance(
            readRate: 0.8,
            applyRate: 0.6,
            dismissRate: 0.2,
            averageResponseTime: 300, // 5 minutes
            userEngagementScore: 0.7,
            goalImpactScore: 0.6
        )
    }
    
    func getNudgeEffectivenessMetrics(forUserId: String) async throws -> NudgeEffectivenessMetrics {
        // This would need to be implemented with actual effectiveness data
        return NudgeEffectivenessMetrics(
            overallEffectiveness: 0.7,
            effectivenessByType: [:],
            effectivenessByCategory: [:],
            effectivenessByPriority: [:],
            userFeedback: [],
            improvementSuggestions: []
        )
    }
    
    // MARK: - Bulk Operations
    func bulkUpdateNudges(_ nudges: [Nudge]) async throws -> [Nudge] {
        return try await coreDataStack.performBackgroundTask { context in
            var updatedNudges: [Nudge] = []
            
            for nudge in nudges {
                let request = CoreDataUtilities.createFetchRequest(NudgeEntity.self, predicate: CoreDataUtilities.createPredicate(format: "id == %@", arguments: [nudge.id]))
                request.fetchLimit = 1
                
                let results = try context.fetch(request)
                if let entity = results.first {
                    // Update existing entity
                    entity.title = nudge.title
                    entity.content = nudge.content
                    entity.type = nudge.type.rawValue
                    entity.category = nudge.category.rawValue
                    entity.priority = nudge.priority.rawValue
                    entity.actionType = nudge.actionType.rawValue
                    entity.userId = nudge.userId
                    entity.isRead = nudge.isRead
                    entity.isApplied = nudge.isApplied
                    
                    updatedNudges.append(nudge)
                }
            }
            
            try context.save()
            self.logger.info("Bulk updated \(updatedNudges.count) AI nudges")
            return updatedNudges
        }
    }
    
    func deleteOldNudges(olderThan date: Date) async throws -> Int {
        return try await coreDataStack.performBackgroundTask { context in
            let predicate = CoreDataUtilities.createPredicate(format: "createdAt < %@", arguments: [date])
            let request = CoreDataUtilities.createFetchRequest(NudgeEntity.self, predicate: predicate)
            let results = try context.fetch(request)
            
            let count = results.count
            for entity in results {
                context.delete(entity)
            }
            
            try context.save()
            self.logger.info("Deleted \(count) old AI nudges")
            return count
        }
    }
    
    func deleteDismissedNudges(olderThan date: Date) async throws -> Int {
        // This would need to be implemented with actual dismissed field
        // For now, return 0
        return 0
    }
    
    // MARK: - Private Helper Methods
    private func mapEntityToNudge(_ entity: NudgeEntity) -> Nudge {
        return Nudge(
            id: entity.id ?? "",
            title: entity.title ?? "",
            content: entity.content ?? "",
            type: NudgeType(rawValue: entity.type ?? "motivational") ?? .motivational,
            category: NudgeCategory(rawValue: entity.category ?? "general") ?? .general,
            priority: NudgePriority(rawValue: entity.priority ?? "medium") ?? .medium,
            actionType: NudgeActionType(rawValue: entity.actionType ?? "none") ?? .none,
            userId: entity.userId ?? "",
            isRead: entity.isRead,
            isApplied: entity.isApplied,
            createdAt: entity.createdAt ?? Date()
        )
    }
}
