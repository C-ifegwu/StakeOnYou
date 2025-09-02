import Foundation

// Placeholder types for goal creation; integrate with existing Goal domain
struct StakableGoalPayload: Codable, Equatable {
    let goalId: String
    let title: String
}

final class CreateStakableGoalUseCase {
    private let startEscrowHold: StartEscrowHoldUseCase
    
    init(startEscrowHold: StartEscrowHoldUseCase) {
        self.startEscrowHold = startEscrowHold
    }
    
    struct Request {
        let userId: String
        let goalPayload: StakableGoalPayload
        let stakeholders: [EscrowStakeholder]
        let distributionPlan: DistributionPlan
        let currency: String
        let idempotencyKey: String
    }
    
    struct Response: Equatable {
        let goalId: String
        let escrow: Escrow
    }
    
    func execute(_ request: Request) async throws -> Response {
        // Assume goal already created elsewhere; here we focus on escrow hold
        let escrow = try await startEscrowHold.execute(.init(goalId: request.goalPayload.goalId, stakeholders: request.stakeholders, currency: request.currency, idempotencyKey: request.idempotencyKey))
        return Response(goalId: request.goalPayload.goalId, escrow: escrow)
    }
}
