import Foundation
import CoreData
import Combine

// MARK: - Core Data Group Repository Implementation
class CoreDataGroupRepository: GroupRepository {
    // MARK: - Properties
    private let coreDataStack: CoreDataStack
    private let logger: Logger
    
    // MARK: - Initialization
    init(coreDataStack: CoreDataStack, logger: Logger) {
        self.coreDataStack = coreDataStack
        self.logger = logger
    }
    
    // MARK: - CRUD Operations
    func createGroup(_ group: Group) async throws -> Group {
        return try await coreDataStack.performBackgroundTask { context in
            let entity = GroupEntity(context: context)
            
            // Map domain model to Core Data entity
            entity.id = group.id
            entity.name = group.name
            entity.description = group.description
            entity.ownerId = group.ownerId
            entity.isPrivate = group.isPrivate
            entity.maxMembers = Int32(group.maxMembers)
            entity.memberIds = group.memberIds
            entity.tags = group.tags
            entity.rules = group.rules
            entity.createdAt = group.createdAt
            
            try context.save()
            
            self.logger.info("Created group with ID: \(group.id)")
            return group
        }
    }
    
    func getGroup(id: String) async throws -> Group? {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(GroupEntity.self, predicate: CoreDataUtilities.createPredicate(format: "id == %@", arguments: [id]))
            request.fetchLimit = 1
            
            let results = try context.fetch(request)
            guard let entity = results.first else { return nil }
            
            return self.mapEntityToGroup(entity)
        }
    }
    
    func updateGroup(_ group: Group) async throws -> Group {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(GroupEntity.self, predicate: CoreDataUtilities.createPredicate(format: "id == %@", arguments: [group.id]))
            request.fetchLimit = 1
            
            let results = try context.fetch(request)
            guard let entity = results.first else {
                throw GroupRepositoryError.groupNotFound
            }
            
            // Update entity with new values
            entity.name = group.name
            entity.description = group.description
            entity.ownerId = group.ownerId
            entity.isPrivate = group.isPrivate
            entity.maxMembers = Int32(group.maxMembers)
            entity.memberIds = group.memberIds
            entity.tags = group.tags
            entity.rules = group.rules
            
            try context.save()
            
            self.logger.info("Updated group with ID: \(group.id)")
            return group
        }
    }
    
    func deleteGroup(id: String) async throws -> Bool {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(GroupEntity.self, predicate: CoreDataUtilities.createPredicate(format: "id == %@", arguments: [id]))
            request.fetchLimit = 1
            
            let results = try context.fetch(request)
            guard let entity = results.first else {
                throw GroupRepositoryError.groupNotFound
            }
            
            context.delete(entity)
            try context.save()
            
            self.logger.info("Deleted group with ID: \(id)")
            return true
        }
    }
    
    // MARK: - Query Operations
    func getGroupsForUser(userId: String) async throws -> [Group] {
        return try await coreDataStack.performBackgroundTask { context in
            let predicate = CoreDataUtilities.createPredicate(format: "ownerId == %@ OR %@ IN memberIds", arguments: [userId, userId])
            let request = CoreDataUtilities.createFetchRequest(GroupEntity.self, predicate: predicate)
            let results = try context.fetch(request)
            
            return results.map { self.mapEntityToGroup($0) }
        }
    }
    
    func getGroups(byCategory: String) async throws -> [Group] {
        // This would need to be implemented with actual category data
        // For now, return all groups
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(GroupEntity.self)
            let results = try context.fetch(request)
            
            return results.map { self.mapEntityToGroup($0) }
        }
    }
    
    func getGroups(byDateRange: DateInterval) async throws -> [Group] {
        return try await coreDataStack.performBackgroundTask { context in
            let predicate = CoreDataUtilities.createPredicate(format: "createdAt >= %@ AND createdAt <= %@", arguments: [dateRange.start, dateRange.end])
            let request = CoreDataUtilities.createFetchRequest(GroupEntity.self, predicate: predicate)
            let results = try context.fetch(request)
            
            return results.map { self.mapEntityToGroup($0) }
        }
    }
    
    func getPublicGroups() async throws -> [Group] {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(GroupEntity.self, predicate: CoreDataUtilities.createPredicate(format: "isPrivate == NO"))
            let results = try context.fetch(request)
            
            return results.map { self.mapEntityToGroup($0) }
        }
    }
    
    func getPrivateGroups(forUserId: String) async throws -> [Group] {
        return try await coreDataStack.performBackgroundTask { context in
            let predicate = CoreDataUtilities.createPredicate(format: "isPrivate == YES AND (ownerId == %@ OR %@ IN memberIds)", arguments: [userId, userId])
            let request = CoreDataUtilities.createFetchRequest(GroupEntity.self, predicate: predicate)
            let results = try context.fetch(request)
            
            return results.map { self.mapEntityToGroup($0) }
        }
    }
    
    // MARK: - Member Operations
    func addMemberToGroup(groupId: String, userId: String) async throws -> Group {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(GroupEntity.self, predicate: CoreDataUtilities.createPredicate(format: "id == %@", arguments: [groupId]))
            request.fetchLimit = 1
            
            let results = try context.fetch(request)
            guard let entity = results.first else {
                throw GroupRepositoryError.groupNotFound
            }
            
            var memberIds = entity.memberIds ?? []
            if !memberIds.contains(userId) {
                memberIds.append(userId)
                entity.memberIds = memberIds
                
                try context.save()
                self.logger.info("Added user \(userId) to group \(groupId)")
            }
            
            return self.mapEntityToGroup(entity)
        }
    }
    
    func removeMemberFromGroup(groupId: String, userId: String) async throws -> Group {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(GroupEntity.self, predicate: CoreDataUtilities.createPredicate(format: "id == %@", arguments: [groupId]))
            request.fetchLimit = 1
            
            let results = try context.fetch(request)
            guard let entity = results.first else {
                throw GroupRepositoryError.groupNotFound
            }
            
            var memberIds = entity.memberIds ?? []
            memberIds.removeAll { $0 == userId }
            entity.memberIds = memberIds
            
            try context.save()
            self.logger.info("Removed user \(userId) from group \(groupId)")
            
            return self.mapEntityToGroup(entity)
        }
    }
    
    func getGroupMembers(groupId: String) async throws -> [User] {
        // This would need to be implemented with actual user data
        // For now, return empty array
        return []
    }
    
    func isUserMemberOfGroup(userId: String, groupId: String) async throws -> Bool {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(GroupEntity.self, predicate: CoreDataUtilities.createPredicate(format: "id == %@", arguments: [groupId]))
            request.fetchLimit = 1
            
            let results = try context.fetch(request)
            guard let entity = results.first else { return false }
            
            let memberIds = entity.memberIds ?? []
            return memberIds.contains(userId)
        }
    }
    
    func isUserOwnerOfGroup(userId: String, groupId: String) async throws -> Bool {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(GroupEntity.self, predicate: CoreDataUtilities.createPredicate(format: "id == %@", arguments: [groupId]))
            request.fetchLimit = 1
            
            let results = try context.fetch(request)
            guard let entity = results.first else { return false }
            
            return entity.ownerId == userId
        }
    }
    
    // MARK: - Group Management
    func updateGroupRules(groupId: String, rules: GroupRules) async throws -> Group {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(GroupEntity.self, predicate: CoreDataUtilities.createPredicate(format: "id == %@", arguments: [groupId]))
            request.fetchLimit = 1
            
            let results = try context.fetch(request)
            guard let entity = results.first else {
                throw GroupRepositoryError.groupNotFound
            }
            
            entity.rules = rules
            try context.save()
            
            self.logger.info("Updated rules for group: \(groupId)")
            return self.mapEntityToGroup(entity)
        }
    }
    
    func updateGroupSettings(groupId: String, settings: GroupSettings) async throws -> Group {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(GroupEntity.self, predicate: CoreDataUtilities.createPredicate(format: "id == %@", arguments: [groupId]))
            request.fetchLimit = 1
            
            let results = try context.fetch(request)
            guard let entity = results.first else {
                throw GroupRepositoryError.groupNotFound
            }
            
            // Update settings-related properties
            entity.isPrivate = settings.isPrivate
            entity.maxMembers = Int32(settings.maxMembers)
            
            try context.save()
            
            self.logger.info("Updated settings for group: \(groupId)")
            return self.mapEntityToGroup(entity)
        }
    }
    
    func transferGroupOwnership(groupId: String, newOwnerId: String) async throws -> Group {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(GroupEntity.self, predicate: CoreDataUtilities.createPredicate(format: "id == %@", arguments: [groupId]))
            request.fetchLimit = 1
            
            let results = try context.fetch(request)
            guard let entity = results.first else {
                throw GroupRepositoryError.groupNotFound
            }
            
            entity.ownerId = newOwnerId
            try context.save()
            
            self.logger.info("Transferred ownership of group \(groupId) to user \(newOwnerId)")
            return self.mapEntityToGroup(entity)
        }
    }
    
    // MARK: - Analytics Operations
    func getGroupStatistics(groupId: String) async throws -> GroupStatistics {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(GroupEntity.self, predicate: CoreDataUtilities.createPredicate(format: "id == %@", arguments: [groupId]))
            request.fetchLimit = 1
            
            let results = try context.fetch(request)
            guard let entity = results.first else {
                throw GroupRepositoryError.groupNotFound
            }
            
            let memberIds = entity.memberIds ?? []
            let totalMembers = memberIds.count + 1 // +1 for owner
            
            return GroupStatistics(
                totalMembers: totalMembers,
                activeMembers: totalMembers, // Would need activity tracking
                totalGoals: 0, // Would need goal data
                completedGoals: 0,
                totalStakeAmount: Decimal(0),
                averageGoalCompletionRate: 0.0,
                memberActivityScore: 0.0
            )
        }
    }
    
    func getGroupPerformance(groupId: String, timeRange: TimeRange) async throws -> GroupPerformance {
        // This would need to be implemented with actual performance data
        return GroupPerformance(
            totalReturn: Decimal(0),
            returnRate: Decimal(0),
            memberRetentionRate: 0.0,
            goalSuccessRate: 0.0,
            averageGoalDuration: 0
        )
    }
    
    func getTopGroups(limit: Int) async throws -> [GroupWithStats] {
        // This would need to be implemented with actual statistics
        return []
    }
    
    // MARK: - Bulk Operations
    func bulkUpdateGroups(_ groups: [Group]) async throws -> [Group] {
        return try await coreDataStack.performBackgroundTask { context in
            var updatedGroups: [Group] = []
            
            for group in groups {
                let request = CoreDataUtilities.createFetchRequest(GroupEntity.self, predicate: CoreDataUtilities.createPredicate(format: "id == %@", arguments: [group.id]))
                request.fetchLimit = 1
                
                let results = try context.fetch(request)
                if let entity = results.first {
                    // Update existing entity
                    entity.name = group.name
                    entity.description = group.description
                    entity.ownerId = group.ownerId
                    entity.isPrivate = group.isPrivate
                    entity.maxMembers = Int32(group.maxMembers)
                    entity.memberIds = group.memberIds
                    entity.tags = group.tags
                    entity.rules = group.rules
                    
                    updatedGroups.append(group)
                }
            }
            
            try context.save()
            self.logger.info("Bulk updated \(updatedGroups.count) groups")
            return updatedGroups
        }
    }
    
    func deleteEmptyGroups() async throws -> Int {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(GroupEntity.self)
            let results = try context.fetch(request)
            
            let emptyGroups = results.filter { 
                let memberIds = $0.memberIds ?? []
                return memberIds.isEmpty
            }
            
            let count = emptyGroups.count
            for entity in emptyGroups {
                context.delete(entity)
            }
            
            try context.save()
            self.logger.info("Deleted \(count) empty groups")
            return count
        }
    }
    
    // MARK: - Private Helper Methods
    private func mapEntityToGroup(_ entity: GroupEntity) -> Group {
        return Group(
            id: entity.id ?? "",
            name: entity.name ?? "",
            description: entity.description,
            ownerId: entity.ownerId ?? "",
            isPrivate: entity.isPrivate,
            maxMembers: Int(entity.maxMembers),
            memberIds: entity.memberIds ?? [],
            tags: entity.tags,
            rules: entity.rules,
            createdAt: entity.createdAt ?? Date()
        )
    }
}
