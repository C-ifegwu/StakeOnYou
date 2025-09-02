import Foundation

final class CompleteGoalUseCase {
    private let escrowRepository: EscrowRepository
    private let initiateDistribution: InitiateDistributionUseCase
    private let disputeRepository: DisputeRepository
    
    init(escrowRepository: EscrowRepository, disputeRepository: DisputeRepository, initiateDistribution: InitiateDistributionUseCase) {
        self.escrowRepository = escrowRepository
        self.disputeRepository = disputeRepository
        self.initiateDistribution = initiateDistribution
    }
    
    struct Request {
        let goalId: String
        let success: Bool
        let distributionPlan: DistributionPlan
        let idempotencyKey: String
    }
    
    struct Result: Equatable {
        let outcome: GoalOutcome
        let distributionTxRefs: [String]
    }
    
    func execute(_ request: Request) async throws -> Result {
        // Find escrow for goal
        guard let escrow = try await escrowRepository.listEscrowsForGoal(request.goalId).first else {
            throw EscrowServiceError.escrowNotFound
        }
        
        // If any open dispute, mark pending and stop distribution
        let disputes = try await disputeRepository.listDisputes(goalId: request.goalId)
        if disputes.contains(where: { $0.status == .open }) {
            _ = try await escrowRepository.setEscrowStatus(escrow.id, status: .pendingDistribution)
            return Result(outcome: .pendingDispute, distributionTxRefs: [])
        }
        
        // Determine outcome
        let outcome: GoalOutcome = request.success ? .success : .failure
        
        // Initiate distribution
        let txRefs = try await initiateDistribution.execute(.init(
            escrowId: escrow.id,
            distributionPlan: request.distributionPlan,
            outcome: outcome,
            idempotencyKey: request.idempotencyKey
        ))
        
        return Result(outcome: outcome, distributionTxRefs: txRefs)
    }
}
