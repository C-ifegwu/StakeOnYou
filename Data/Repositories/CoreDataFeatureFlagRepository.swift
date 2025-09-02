import Foundation
import CoreData
import Combine

// MARK: - Core Data Feature Flag Repository Implementation
class CoreDataFeatureFlagRepository: FeatureFlagRepository {
    // MARK: - Properties
    private let coreDataStack: CoreDataStack
    private let logger: Logger
    
    // MARK: - Initialization
    init(coreDataStack: CoreDataStack, logger: Logger) {
        self.coreDataStack = coreDataStack
        self.logger = logger
    }
    
    // MARK: - CRUD Operations
    func createFeatureFlag(_ featureFlag: FeatureFlag) async throws -> FeatureFlag {
        return try await coreDataStack.performBackgroundTask { context in
            let entity = FeatureFlagEntity(context: context)
            
            // Map domain model to Core Data entity
            entity.id = featureFlag.id
            entity.key = featureFlag.key
            entity.name = featureFlag.name
            entity.description = featureFlag.description
            entity.category = featureFlag.category
            entity.defaultValue = featureFlag.defaultValue
            entity.value = featureFlag.value
            entity.createdAt = featureFlag.createdAt
            entity.updatedAt = featureFlag.updatedAt
            
            try context.save()
            
            self.logger.info("Created feature flag with key: \(featureFlag.key)")
            return featureFlag
        }
    }
    
    func getFeatureFlag(id: String) async throws -> FeatureFlag? {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(FeatureFlagEntity.self, predicate: CoreDataUtilities.createPredicate(format: "id == %@", arguments: [id]))
            request.fetchLimit = 1
            
            let results = try context.fetch(request)
            guard let entity = results.first else { return nil }
            
            return self.mapEntityToFeatureFlag(entity)
        }
    }
    
    func getFeatureFlag(byKey: String) async throws -> FeatureFlag? {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(FeatureFlagEntity.self, predicate: CoreDataUtilities.createPredicate(format: "key == %@", arguments: [key]))
            request.fetchLimit = 1
            
            let results = try context.fetch(request)
            guard let entity = results.first else { return nil }
            
            return self.mapEntityToFeatureFlag(entity)
        }
    }
    
    func updateFeatureFlag(_ featureFlag: FeatureFlag) async throws -> FeatureFlag {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(FeatureFlagEntity.self, predicate: CoreDataUtilities.createPredicate(format: "id == %@", arguments: [featureFlag.id]))
            request.fetchLimit = 1
            
            let results = try context.fetch(request)
            guard let entity = results.first else {
                throw FeatureFlagRepositoryError.featureFlagNotFound
            }
            
            // Update entity with new values
            entity.key = featureFlag.key
            entity.name = featureFlag.name
            entity.description = featureFlag.description
            entity.category = featureFlag.category
            entity.defaultValue = featureFlag.defaultValue
            entity.value = featureFlag.value
            entity.updatedAt = Date()
            
            try context.save()
            
            self.logger.info("Updated feature flag with key: \(featureFlag.key)")
            return featureFlag
        }
    }
    
    func deleteFeatureFlag(id: String) async throws -> Bool {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(FeatureFlagEntity.self, predicate: CoreDataUtilities.createPredicate(format: "id == %@", arguments: [id]))
            request.fetchLimit = 1
            
            let results = try context.fetch(request)
            guard let entity = results.first else {
                throw FeatureFlagRepositoryError.featureFlagNotFound
            }
            
            context.delete(entity)
            try context.save()
            
            self.logger.info("Deleted feature flag with ID: \(id)")
            return true
        }
    }
    
    // MARK: - Query Operations
    func getAllFeatureFlags() async throws -> [FeatureFlag] {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(FeatureFlagEntity.self, sortDescriptors: [CoreDataUtilities.createSortDescriptor(key: "key", ascending: true)])
            let results = try context.fetch(request)
            
            return results.map { self.mapEntityToFeatureFlag($0) }
        }
    }
    
    func getFeatureFlags(byCategory: String) async throws -> [FeatureFlag] {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(FeatureFlagEntity.self, predicate: CoreDataUtilities.createPredicate(format: "category == %@", arguments: [category]), sortDescriptors: [CoreDataUtilities.createSortDescriptor(key: "key", ascending: true)])
            let results = try context.fetch(request)
            
            return results.map { self.mapEntityToFeatureFlag($0) }
        }
    }
    
    func getFeatureFlags(byDateRange: DateInterval) async throws -> [FeatureFlag] {
        return try await coreDataStack.performBackgroundTask { context in
            let predicate = CoreDataUtilities.createPredicate(format: "updatedAt >= %@ AND updatedAt <= %@", arguments: [dateRange.start, dateRange.end])
            let request = CoreDataUtilities.createFetchRequest(FeatureFlagEntity.self, predicate: predicate, sortDescriptors: [CoreDataUtilities.createSortDescriptor(key: "updatedAt", ascending: false)])
            let results = try context.fetch(request)
            
            return results.map { self.mapEntityToFeatureFlag($0) }
        }
    }
    
    func getEnabledFeatureFlags() async throws -> [FeatureFlag] {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(FeatureFlagEntity.self, predicate: CoreDataUtilities.createPredicate(format: "value == YES", arguments: []), sortDescriptors: [CoreDataUtilities.createSortDescriptor(key: "key", ascending: true)])
            let results = try context.fetch(request)
            
            return results.map { self.mapEntityToFeatureFlag($0) }
        }
    }
    
    func getDisabledFeatureFlags() async throws -> [FeatureFlag] {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(FeatureFlagEntity.self, predicate: CoreDataUtilities.createPredicate(format: "value == NO", arguments: []), sortDescriptors: [CoreDataUtilities.createSortDescriptor(key: "key", ascending: true)])
            let results = try context.fetch(request)
            
            return results.map { self.mapEntityToFeatureFlag($0) }
        }
    }
    
    func searchFeatureFlags(query: String) async throws -> [FeatureFlag] {
        return try await coreDataStack.performBackgroundTask { context in
            let predicate = CoreDataUtilities.createPredicate(format: "key CONTAINS[cd] %@ OR name CONTAINS[cd] %@ OR description CONTAINS[cd] %@ OR category CONTAINS[cd] %@", arguments: [query, query, query, query])
            let request = CoreDataUtilities.createFetchRequest(FeatureFlagEntity.self, predicate: predicate, sortDescriptors: [CoreDataUtilities.createSortDescriptor(key: "key", ascending: true)])
            let results = try context.fetch(request)
            
            return results.map { self.mapEntityToFeatureFlag($0) }
        }
    }
    
    // MARK: - Feature Flag Operations
    func isFeatureEnabled(key: String) async throws -> Bool {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(FeatureFlagEntity.self, predicate: CoreDataUtilities.createPredicate(format: "key == %@", arguments: [key]))
            request.fetchLimit = 1
            
            let results = try context.fetch(request)
            guard let entity = results.first else {
                // If feature flag doesn't exist, return default value
                return false
            }
            
            return entity.value
        }
    }
    
    func enableFeature(key: String) async throws -> FeatureFlag {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(FeatureFlagEntity.self, predicate: CoreDataUtilities.createPredicate(format: "key == %@", arguments: [key]))
            request.fetchLimit = 1
            
            let results = try context.fetch(request)
            guard let entity = results.first else {
                throw FeatureFlagRepositoryError.featureFlagNotFound
            }
            
            entity.value = true
            entity.updatedAt = Date()
            
            try context.save()
            
            self.logger.info("Enabled feature flag: \(key)")
            return self.mapEntityToFeatureFlag(entity)
        }
    }
    
    func disableFeature(key: String) async throws -> FeatureFlag {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(FeatureFlagEntity.self, predicate: CoreDataUtilities.createPredicate(format: "key == %@", arguments: [key]))
            request.fetchLimit = 1
            
            let results = try context.fetch(request)
            guard let entity = results.first else {
                throw FeatureFlagRepositoryError.featureFlagNotFound
            }
            
            entity.value = false
            entity.updatedAt = Date()
            
            try context.save()
            
            self.logger.info("Disabled feature flag: \(key)")
            return self.mapEntityToFeatureFlag(entity)
        }
    }
    
    func toggleFeature(key: String) async throws -> FeatureFlag {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(FeatureFlagEntity.self, predicate: CoreDataUtilities.createPredicate(format: "key == %@", arguments: [key]))
            request.fetchLimit = 1
            
            let results = try context.fetch(request)
            guard let entity = results.first else {
                throw FeatureFlagRepositoryError.featureFlagNotFound
            }
            
            entity.value.toggle()
            entity.updatedAt = Date()
            
            try context.save()
            
            self.logger.info("Toggled feature flag \(key) to: \(entity.value)")
            return self.mapEntityToFeatureFlag(entity)
        }
    }
    
    func resetFeatureToDefault(key: String) async throws -> FeatureFlag {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(FeatureFlagEntity.self, predicate: CoreDataUtilities.createPredicate(format: "key == %@", arguments: [key]))
            request.fetchLimit = 1
            
            let results = try context.fetch(request)
            guard let entity = results.first else {
                throw FeatureFlagRepositoryError.featureFlagNotFound
            }
            
            entity.value = entity.defaultValue
            entity.updatedAt = Date()
            
            try context.save()
            
            self.logger.info("Reset feature flag \(key) to default value: \(entity.value)")
            return self.mapEntityToFeatureFlag(entity)
        }
    }
    
    // MARK: - Bulk Operations
    func bulkUpdateFeatureFlags(_ featureFlags: [FeatureFlag]) async throws -> [FeatureFlag] {
        return try await coreDataStack.performBackgroundTask { context in
            var updatedFeatureFlags: [FeatureFlag] = []
            
            for featureFlag in featureFlags {
                let request = CoreDataUtilities.createFetchRequest(FeatureFlagEntity.self, predicate: CoreDataUtilities.createPredicate(format: "id == %@", arguments: [featureFlag.id]))
                request.fetchLimit = 1
                
                let results = try context.fetch(request)
                if let entity = results.first {
                    // Update existing entity
                    entity.key = featureFlag.key
                    entity.name = featureFlag.name
                    entity.description = featureFlag.description
                    entity.category = featureFlag.category
                    entity.defaultValue = featureFlag.defaultValue
                    entity.value = featureFlag.value
                    entity.updatedAt = Date()
                    
                    updatedFeatureFlags.append(featureFlag)
                }
            }
            
            try context.save()
            self.logger.info("Bulk updated \(updatedFeatureFlags.count) feature flags")
            return updatedFeatureFlags
        }
    }
    
    func bulkEnableFeatures(keys: [String]) async throws -> [FeatureFlag] {
        return try await coreDataStack.performBackgroundTask { context in
            let predicate = CoreDataUtilities.createPredicate(format: "key IN %@", arguments: [keys])
            let request = CoreDataUtilities.createFetchRequest(FeatureFlagEntity.self, predicate: predicate)
            let results = try context.fetch(request)
            
            for entity in results {
                entity.value = true
                entity.updatedAt = Date()
            }
            
            try context.save()
            self.logger.info("Bulk enabled \(results.count) feature flags")
            return results.map { self.mapEntityToFeatureFlag($0) }
        }
    }
    
    func bulkDisableFeatures(keys: [String]) async throws -> [FeatureFlag] {
        return try await coreDataStack.performBackgroundTask { context in
            let predicate = CoreDataUtilities.createPredicate(format: "key IN %@", arguments: [keys])
            let request = CoreDataUtilities.createFetchRequest(FeatureFlagEntity.self, predicate: predicate)
            let results = try context.fetch(request)
            
            for entity in results {
                entity.value = false
                entity.updatedAt = Date()
            }
            
            try context.save()
            self.logger.info("Bulk disabled \(results.count) feature flags")
            return results.map { self.mapEntityToFeatureFlag($0) }
        }
    }
    
    func deleteFeatureFlags(keys: [String]) async throws -> Int {
        return try await coreDataStack.performBackgroundTask { context in
            let predicate = CoreDataUtilities.createPredicate(format: "key IN %@", arguments: [keys])
            let request = CoreDataUtilities.createFetchRequest(FeatureFlagEntity.self, predicate: predicate)
            let results = try context.fetch(request)
            
            let count = results.count
            for entity in results {
                context.delete(entity)
            }
            
            try context.save()
            self.logger.info("Deleted \(count) feature flags")
            return count
        }
    }
    
    // MARK: - Analytics Operations
    func getFeatureFlagStatistics() async throws -> FeatureFlagStatistics {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(FeatureFlagEntity.self)
            let results = try context.fetch(request)
            
            let totalFlags = results.count
            let enabledFlags = results.filter { $0.value }.count
            let disabledFlags = results.filter { !$0.value }.count
            
            // Group by category
            let categoryGroups = Dictionary(grouping: results) { $0.category ?? "unknown" }
            let flagsByCategory = categoryGroups.map { category, flags in
                FeatureFlagCategoryStats(
                    category: category,
                    totalCount: flags.count,
                    enabledCount: flags.filter { $0.value }.count,
                    disabledCount: flags.filter { !$0.value }.count
                )
            }
            
            return FeatureFlagStatistics(
                totalFlags: totalFlags,
                enabledFlags: enabledFlags,
                disabledFlags: disabledFlags,
                flagsByCategory: flagsByCategory,
                lastUpdated: results.map { $0.updatedAt ?? Date.distantPast }.max() ?? Date.distantPast
            )
        }
    }
    
    func getFeatureFlagUsage(forUserId: String) async throws -> [FeatureFlagUsage] {
        // This would need to be implemented with actual usage tracking
        // For now, return empty array
        return []
    }
    
    // MARK: - Private Helper Methods
    private func mapEntityToFeatureFlag(_ entity: FeatureFlagEntity) -> FeatureFlag {
        return FeatureFlag(
            id: entity.id ?? "",
            key: entity.key ?? "",
            name: entity.name ?? "",
            description: entity.description,
            category: entity.category,
            defaultValue: entity.defaultValue,
            value: entity.value,
            createdAt: entity.createdAt ?? Date(),
            updatedAt: entity.updatedAt ?? Date()
        )
    }
}
