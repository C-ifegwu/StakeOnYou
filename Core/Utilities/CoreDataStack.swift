import Foundation
import CoreData
import Combine

// MARK: - Core Data Stack Protocol
protocol CoreDataStack {
    var mainContext: NSManagedObjectContext { get }
    var backgroundContext: NSManagedObjectContext { get }
    
    func performBackgroundTask<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T
    func performMainTask<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T
    
    func save() async throws
    func saveBackgroundContext() async throws
    
    func deleteAllData() async throws
    func resetStore() async throws
}

// MARK: - Core Data Stack Implementation
class CoreDataStackImpl: CoreDataStack {
    // MARK: - Properties
    private let container: NSPersistentContainer
    private let logger: Logger
    
    var mainContext: NSManagedObjectContext {
        container.viewContext
    }
    
    var backgroundContext: NSManagedObjectContext {
        container.newBackgroundContext()
    }
    
    // MARK: - Initialization
    init(modelName: String = "StakeOnYou", logger: Logger) {
        self.logger = logger
        
        // Create the persistent container
        container = NSPersistentContainer(name: modelName)
        
        // Configure the container
        configureContainer()
        
        // Load the persistent stores
        loadPersistentStores()
    }
    
    // MARK: - Configuration
    private func configureContainer() {
        // Enable automatic lightweight migrations
        let description = NSPersistentStoreDescription()
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        
        // Set the store description
        container.persistentStoreDescriptions = [description]
        
        // Configure the main context
        mainContext.automaticallyMergesChangesFromParent = true
        mainContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    private func loadPersistentStores() {
        container.loadPersistentStores { [weak self] _, error in
            if let error = error {
                self?.logger.error("Failed to load Core Data stores: \(error.localizedDescription)")
                fatalError("Core Data store failed to load: \(error)")
            } else {
                self?.logger.info("Core Data stores loaded successfully")
            }
        }
    }
    
    // MARK: - Context Operations
    func performBackgroundTask<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            container.performBackgroundTask { context in
                do {
                    let result = try block(context)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func performMainTask<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            mainContext.perform {
                do {
                    let result = try block(self.mainContext)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Save Operations
    func save() async throws {
        try await performMainTask { context in
            if context.hasChanges {
                try context.save()
                self.logger.info("Main context saved successfully")
            }
        }
    }
    
    func saveBackgroundContext() async throws {
        try await performBackgroundTask { context in
            if context.hasChanges {
                try context.save()
                self.logger.info("Background context saved successfully")
            }
        }
    }
    
    // MARK: - Data Management
    func deleteAllData() async throws {
        try await performBackgroundTask { context in
            let entities = self.container.managedObjectModel.entities
            
            for entity in entities {
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity.name!)
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                
                try context.execute(deleteRequest)
            }
            
            try context.save()
            self.logger.info("All data deleted successfully")
        }
    }
    
    func resetStore() async throws {
        try await performBackgroundTask { context in
            // Delete all persistent stores
            for store in self.container.persistentStoreCoordinator.persistentStores {
                try self.container.persistentStoreCoordinator.remove(store)
            }
            
            // Recreate the stores
            self.loadPersistentStores()
            
            self.logger.info("Core Data store reset successfully")
        }
    }
}

// MARK: - Core Data Error
enum CoreDataError: LocalizedError {
    case saveFailed(Error)
    case fetchFailed(Error)
    case deleteFailed(Error)
    case invalidEntity
    case contextError(Error)
    case storeError(Error)
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let error):
            return "Failed to save Core Data context: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch from Core Data: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete from Core Data: \(error.localizedDescription)"
        case .invalidEntity:
            return "Invalid Core Data entity"
        case .contextError(let error):
            return "Core Data context error: \(error.localizedDescription)"
        case .storeError(let error):
            return "Core Data store error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Core Data Extensions
extension NSManagedObjectContext {
    func saveIfNeeded() throws {
        if hasChanges {
            try save()
        }
    }
    
    func deleteAll<T: NSManagedObject>(_ entityType: T.Type) throws {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: entityType))
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        try execute(deleteRequest)
    }
}

// MARK: - Core Data Utilities
struct CoreDataUtilities {
    static func createFetchRequest<T: NSManagedObject>(_ entityType: T.Type, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil) -> NSFetchRequest<T> {
        let request = NSFetchRequest<T>(entityName: String(describing: entityType))
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        return request
    }
    
    static func createPredicate(format: String, arguments: [Any]) -> NSPredicate {
        return NSPredicate(format: format, argumentArray: arguments)
    }
    
    static func createSortDescriptor(key: String, ascending: Bool = true) -> NSSortDescriptor {
        return NSSortDescriptor(key: key, ascending: ascending)
    }
}
