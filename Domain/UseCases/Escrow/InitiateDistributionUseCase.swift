import Foundation

enum GoalOutcome: Equatable {
    case success
    case failure
    case pendingDispute
}

final class InitiateDistributionUseCase {
    private let escrowService: EscrowService
    
    init(escrowService: EscrowService) {
        self.escrowService = escrowService
    }
    
    struct Request {
        let escrowId: String
        let distributionPlan: DistributionPlan
        let outcome: GoalOutcome
        let idempotencyKey: String
    }
    
    func execute(_ request: Request) async throws -> [String] {
        switch request.outcome {
        case .success:
            return try await escrowService.release(escrowId: request.escrowId, distributionPlan: request.distributionPlan, idempotencyKey: request.idempotencyKey)
        case .failure:
            return try await escrowService.forfeit(escrowId: request.escrowId, distributionPlan: request.distributionPlan, idempotencyKey: request.idempotencyKey)
        case .pendingDispute:
            throw EscrowServiceError.distributionPausedDueToDispute
        }
    }
}
