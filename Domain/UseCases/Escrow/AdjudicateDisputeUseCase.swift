import Foundation

enum DisputeDecision: Equatable {
    case upholdSuccess // release to stakeholders
    case upholdFailure // forfeit per plan
    case refund // refund original principal
}

final class AdjudicateDisputeUseCase {
    private let disputeRepository: DisputeRepository
    private let escrowRepository: EscrowRepository
    private let escrowService: EscrowService
    private let audit: RecordAuditEventUseCase?
    private let notify: ScheduleLocalNotificationUseCase?
    
    init(disputeRepository: DisputeRepository, escrowRepository: EscrowRepository, escrowService: EscrowService, audit: RecordAuditEventUseCase? = nil, notify: ScheduleLocalNotificationUseCase? = nil) {
        self.disputeRepository = disputeRepository
        self.escrowRepository = escrowRepository
        self.escrowService = escrowService
        self.audit = audit
        self.notify = notify
    }
    
    struct Request {
        let disputeId: String
        let decision: DisputeDecision
        let notes: String?
        let actorId: String
        let distributionPlan: DistributionPlan
        let idempotencyKey: String
    }
    
    func execute(_ request: Request) async throws -> [String] {
        let dispute = try await disputeRepository.getDispute(request.disputeId)
        guard let escrow = try await escrowRepository.listEscrowsForGoal(dispute.goalId).first else {
            throw EscrowServiceError.escrowNotFound
        }
        
        _ = try await disputeRepository.setDecision(disputeId: dispute.id, status: .resolved, notes: request.notes, actorId: request.actorId)
        
        let txRefs: [String]
        switch request.decision {
        case .upholdSuccess:
            txRefs = try await escrowService.release(escrowId: escrow.id, distributionPlan: request.distributionPlan, idempotencyKey: request.idempotencyKey)
        case .upholdFailure:
            txRefs = try await escrowService.forfeit(escrowId: escrow.id, distributionPlan: request.distributionPlan, idempotencyKey: request.idempotencyKey)
        case .refund:
            txRefs = try await escrowService.refund(escrowId: escrow.id, idempotencyKey: request.idempotencyKey)
        }
        // Audit
        try? await audit?.execute(
            actorId: request.actorId,
            entity: "Dispute",
            entityId: dispute.id,
            action: "adjudicated",
            oldState: "open",
            newState: "resolved",
            correlationId: dispute.id,
            externalTxRef: txRefs.first
        )
        // Notify
        try? await notify?.execute(title: "Dispute Resolved", body: "Your dispute has been adjudicated.", at: Date().addingTimeInterval(1))
        return txRefs
    }
}
