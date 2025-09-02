import Foundation

final class StartEscrowHoldUseCase {
    private let escrowService: EscrowService
    
    init(escrowService: EscrowService) {
        self.escrowService = escrowService
    }
    
    struct Request {
        let goalId: String
        let stakeholders: [EscrowStakeholder]
        let currency: String
        let idempotencyKey: String
    }
    
    func execute(_ request: Request) async throws -> Escrow {
        return try await escrowService.hold(goalId: request.goalId, stakeholders: request.stakeholders, currency: request.currency, idempotencyKey: request.idempotencyKey)
    }
}
