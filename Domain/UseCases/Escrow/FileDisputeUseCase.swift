import Foundation

final class FileDisputeUseCase {
    private let disputeRepository: DisputeRepository
    private let escrowRepository: EscrowRepository
    private let audit: RecordAuditEventUseCase?
    private let notify: ScheduleLocalNotificationUseCase?
    
    init(disputeRepository: DisputeRepository, escrowRepository: EscrowRepository, audit: RecordAuditEventUseCase? = nil, notify: ScheduleLocalNotificationUseCase? = nil) {
        self.disputeRepository = disputeRepository
        self.escrowRepository = escrowRepository
        self.audit = audit
        self.notify = notify
    }
    
    struct Request {
        let goalId: String
        let userId: String
        let reason: String
        let evidenceRefs: [String]
    }
    
    func execute(_ request: Request) async throws -> Dispute {
        // Create dispute
        let dispute = try await disputeRepository.createDispute(goalId: request.goalId, filedBy: request.userId, reason: request.reason, evidenceRefs: request.evidenceRefs)
        
        // Mark escrow as pending distribution
        if let escrow = try await escrowRepository.listEscrowsForGoal(request.goalId).first {
            _ = try await escrowRepository.setEscrowStatus(escrow.id, status: .pendingDistribution)
        }
        
        // Audit
        try? await audit?.execute(
            actorId: request.userId,
            entity: "Dispute",
            entityId: dispute.id,
            action: "filed",
            oldState: nil,
            newState: "open",
            correlationId: dispute.id,
            externalTxRef: nil
        )
        
        // Notify (local)
        try? await notify?.execute(title: "Dispute Filed", body: "Your dispute was filed and is under review.", at: Date().addingTimeInterval(1))
        
        return dispute
    }
}
