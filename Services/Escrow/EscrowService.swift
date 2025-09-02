import Foundation

// MARK: - Escrow Service Abstraction
protocol EscrowService: AnyObject {
    // Idempotent operations: provide idempotencyKey to avoid duplicates
    func hold(goalId: String, stakeholders: [EscrowStakeholder], currency: String, idempotencyKey: String) async throws -> Escrow
    func accrue(escrowId: String, asOf: Date) async throws -> Escrow
    func release(escrowId: String, distributionPlan: DistributionPlan, idempotencyKey: String) async throws -> [String] // return txRefs
    func forfeit(escrowId: String, distributionPlan: DistributionPlan, idempotencyKey: String) async throws -> [String]
    func refund(escrowId: String, idempotencyKey: String) async throws -> [String]
    func reconcile(escrowId: String) async throws -> Bool
}

enum EscrowServiceError: LocalizedError, Equatable {
    case escrowNotFound
    case invalidState
    case insufficientFunds
    case idempotentDuplicate
    case distributionPausedDueToDispute
    case partialDistribution
    case providerFailure(String)
    
    var errorDescription: String? {
        switch self {
        case .escrowNotFound: return "Escrow not found"
        case .invalidState: return "Invalid escrow state"
        case .insufficientFunds: return "Insufficient funds"
        case .idempotentDuplicate: return "Duplicate operation"
        case .distributionPausedDueToDispute: return "Distribution paused due to dispute"
        case .partialDistribution: return "Partial distribution executed"
        case .providerFailure(let msg): return msg
        }
    }
}
