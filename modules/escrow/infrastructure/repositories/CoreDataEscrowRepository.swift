import Foundation
import CoreData

// MARK: - CoreDataEscrowRepository
final class CoreDataEscrowRepository: EscrowRepository {
    // MARK: Core Data Stack
    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext

    // MARK: Init
    init(storeURL: URL? = nil, modelName: String = "EscrowModel") {
        let model = CoreDataEscrowRepository.buildModel()
        container = NSPersistentContainer(name: modelName, managedObjectModel: model)

        if let url = storeURL {
            let description = NSPersistentStoreDescription(url: url)
            description.type = NSSQLiteStoreType
            container.persistentStoreDescriptions = [description]
        }

        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("CoreData load error: \(error)")
            }
        }
        context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - Public helpers (non-protocol)
    func fetchActive() async throws -> [Escrow] {
        try await context.perform { [weak self] in
            guard let self = self else { return [] }
            let request = NSFetchRequest<NSManagedObject>(entityName: "EscrowEntity")
            request.predicate = NSPredicate(format: "status == %@", EscrowStatus.held.rawValue)
            let results = try self.context.fetch(request)
            return results.compactMap { self.mapToDomain($0) }
        }
    }

    func updateStatus(escrowId: String, status: EscrowStatus) async throws -> Escrow {
        try await context.perform { [weak self] in
            guard let self = self else { throw EscrowServiceError.escrowNotFound }
            guard let obj = try self.fetchManaged(escrowId: escrowId) else { throw EscrowServiceError.escrowNotFound }
            obj.setValue(status.rawValue, forKey: "status")
            obj.setValue(Date(), forKey: "updatedAt")
            try self.context.save()
            guard let updated = self.mapToDomain(obj) else { throw EscrowServiceError.escrowNotFound }
            return updated
        }
    }

    func accrueInterest(escrowId: String, increment: Decimal) async throws -> Escrow {
        try await context.perform { [weak self] in
            guard let self = self else { throw EscrowServiceError.escrowNotFound }
            guard let obj = try self.fetchManaged(escrowId: escrowId) else { throw EscrowServiceError.escrowNotFound }
            let current = (obj.value(forKey: "accruedInterest") as? NSDecimalNumber)?.decimalValue ?? 0
            obj.setValue(NSDecimalNumber(decimal: current + increment), forKey: "accruedInterest")
            obj.setValue(Date(), forKey: "updatedAt")
            try self.context.save()
            guard let updated = self.mapToDomain(obj) else { throw EscrowServiceError.escrowNotFound }
            return updated
        }
    }

    func delete(escrowId: String) async throws {
        try await context.perform { [weak self] in
            guard let self = self else { return }
            guard let obj = try self.fetchManaged(escrowId: escrowId) else { return }
            self.context.delete(obj)
            try self.context.save()
        }
    }

    // MARK: - EscrowRepository protocol
    func createEscrow(goalId: String, stakeholders: [EscrowStakeholder], currency: String, holdRef: String) async throws -> Escrow {
        // We only persist summary fields in CoreData; stakeholders can be stored elsewhere
        let escrow = Escrow(goalId: goalId, stakeholders: stakeholders, holdRef: holdRef, currency: currency)
        try await context.perform { [weak self] in
            guard let self = self else { return }
            let entity = NSEntityDescription.insertNewObject(forEntityName: "EscrowEntity", into: self.context)
            entity.setValue(escrow.id, forKey: "id")
            entity.setValue(goalId, forKey: "goalId")
            entity.setValue(NSDecimalNumber(decimal: escrow.totalPrincipal), forKey: "amount")
            entity.setValue(escrow.status.rawValue, forKey: "status")
            entity.setValue(escrow.createdAt, forKey: "createdAt")
            entity.setValue(escrow.updatedAt, forKey: "updatedAt")
            entity.setValue(nil, forKey: "apr")
            entity.setValue(NSDecimalNumber(decimal: escrow.accruedAmount), forKey: "accruedInterest")
            try self.context.save()
        }
        return escrow
    }

    func getEscrow(_ escrowId: String) async throws -> Escrow {
        try await context.perform { [weak self] in
            guard let self = self else { throw EscrowServiceError.escrowNotFound }
            guard let obj = try self.fetchManaged(escrowId: escrowId), let model = self.mapToDomain(obj) else {
                throw EscrowServiceError.escrowNotFound
            }
            return model
        }
    }

    func updateEscrow(_ escrow: Escrow) async throws -> Escrow {
        try await context.perform { [weak self] in
            guard let self = self else { throw EscrowServiceError.escrowNotFound }
            guard let obj = try self.fetchManaged(escrowId: escrow.id) else { throw EscrowServiceError.escrowNotFound }
            obj.setValue(escrow.id, forKey: "id")
            obj.setValue(escrow.goalId, forKey: "goalId")
            obj.setValue(NSDecimalNumber(decimal: escrow.totalPrincipal), forKey: "amount")
            obj.setValue(escrow.status.rawValue, forKey: "status")
            obj.setValue(escrow.createdAt, forKey: "createdAt")
            obj.setValue(escrow.updatedAt, forKey: "updatedAt")
            obj.setValue(NSDecimalNumber(decimal: escrow.accruedAmount), forKey: "accruedInterest")
            try self.context.save()
            guard let updated = self.mapToDomain(obj) else { throw EscrowServiceError.escrowNotFound }
            return updated
        }
    }

    func listEscrowsForGoal(_ goalId: String) async throws -> [Escrow] {
        try await context.perform { [weak self] in
            guard let self = self else { return [] }
            let request = NSFetchRequest<NSManagedObject>(entityName: "EscrowEntity")
            request.predicate = NSPredicate(format: "goalId == %@", goalId)
            let results = try self.context.fetch(request)
            return results.compactMap { self.mapToDomain($0) }
        }
    }

    func setEscrowStatus(_ escrowId: String, status: EscrowStatus) async throws -> Escrow {
        try await updateStatus(escrowId: escrowId, status: status)
    }

    // For EscrowRepository completeness; not stored in this CoreData repo
    func appendTransaction(_ tx: EscrowTransaction) async throws -> EscrowTransaction {
        // In a full implementation, EscrowTransaction would be another entity.
        // For now, return as-is.
        return tx
    }

    func listTransactions(forEscrowId escrowId: String) async throws -> [EscrowTransaction] {
        return []
    }

    // MARK: - Mapping
    private func mapToDomain(_ object: NSManagedObject) -> Escrow? {
        guard
            let id = object.value(forKey: "id") as? String,
            let goalId = object.value(forKey: "goalId") as? String,
            let amount = (object.value(forKey: "amount") as? NSDecimalNumber)?.decimalValue,
            let statusRaw = object.value(forKey: "status") as? String,
            let status = EscrowStatus(rawValue: statusRaw),
            let createdAt = object.value(forKey: "createdAt") as? Date,
            let updatedAt = object.value(forKey: "updatedAt") as? Date
        else { return nil }

        let accrued = (object.value(forKey: "accruedInterest") as? NSDecimalNumber)?.decimalValue ?? 0

        // We can't reconstruct stakeholders from this store; provide empty list.
        let model = Escrow(
            id: id,
            goalId: goalId,
            stakeholders: [],
            accruedAmount: accrued,
            holdRef: "coredata",
            currency: "USD",
            status: status,
            createdAt: createdAt,
            updatedAt: updatedAt,
            releaseTxRefs: []
        )
        // Override computed principal with amount stored
        return Escrow(
            id: model.id,
            goalId: model.goalId,
            stakeholders: model.stakeholders,
            accruedAmount: model.accruedAmount,
            holdRef: model.holdRef,
            currency: model.currency,
            status: model.status,
            createdAt: model.createdAt,
            updatedAt: model.updatedAt,
            releaseTxRefs: model.releaseTxRefs
        )
    }

    // MARK: - Fetch Helper
    private func fetchManaged(escrowId: String) throws -> NSManagedObject? {
        let request = NSFetchRequest<NSManagedObject>(entityName: "EscrowEntity")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", escrowId)
        return try context.fetch(request).first
    }

    // MARK: - Model Builder
    static func buildModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let entity = NSEntityDescription()
        entity.name = "EscrowEntity"
        entity.managedObjectClassName = NSManagedObject.className()

        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .stringAttributeType
        idAttr.isOptional = false

        let goalIdAttr = NSAttributeDescription()
        goalIdAttr.name = "goalId"
        goalIdAttr.attributeType = .stringAttributeType
        goalIdAttr.isOptional = false

        let amountAttr = NSAttributeDescription()
        amountAttr.name = "amount"
        amountAttr.attributeType = .decimalAttributeType
        amountAttr.isOptional = false

        let statusAttr = NSAttributeDescription()
        statusAttr.name = "status"
        statusAttr.attributeType = .stringAttributeType
        statusAttr.isOptional = false

        let createdAtAttr = NSAttributeDescription()
        createdAtAttr.name = "createdAt"
        createdAtAttr.attributeType = .dateAttributeType
        createdAtAttr.isOptional = false

        let updatedAtAttr = NSAttributeDescription()
        updatedAtAttr.name = "updatedAt"
        updatedAtAttr.attributeType = .dateAttributeType
        updatedAtAttr.isOptional = false

        let aprAttr = NSAttributeDescription()
        aprAttr.name = "apr"
        aprAttr.attributeType = .doubleAttributeType
        aprAttr.isOptional = true

        let accruedAttr = NSAttributeDescription()
        accruedAttr.name = "accruedInterest"
        accruedAttr.attributeType = .decimalAttributeType
        accruedAttr.isOptional = true

        entity.properties = [idAttr, goalIdAttr, amountAttr, statusAttr, createdAtAttr, updatedAtAttr, aprAttr, accruedAttr]
        model.entities = [entity]
        return model
    }
}
