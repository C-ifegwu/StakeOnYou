import Foundation

public struct AuditEvent: Identifiable, Codable, Equatable {
    public let id: String
    public let actorId: String?
    public let entity: String
    public let entityId: String
    public let action: String
    public let oldState: String?
    public let newState: String?
    public let correlationId: String?
    public let externalTxRef: String?
    public let timestamp: Date
}

public protocol AuditRepository: AnyObject {
    func record(_ event: AuditEvent) async throws
}

public final class RecordAuditEventUseCase {
    private let repository: AuditRepository
    public init(repository: AuditRepository) { self.repository = repository }
    public func execute(
        actorId: String?,
        entity: String,
        entityId: String,
        action: String,
        oldState: String?,
        newState: String?,
        correlationId: String?,
        externalTxRef: String?
    ) async throws {
        let event = AuditEvent(
            id: UUID().uuidString,
            actorId: actorId,
            entity: entity,
            entityId: entityId,
            action: action,
            oldState: oldState,
            newState: newState,
            correlationId: correlationId,
            externalTxRef: externalTxRef,
            timestamp: Date()
        )
        try await repository.record(event)
    }
}


