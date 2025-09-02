import Foundation

public enum GoalCompletionOutcome: Equatable {
	case success
	case failure
}

public struct CompleteGoalRequest: Equatable {
	public let goalId: UUID
	public let outcome: GoalCompletionOutcome
	public let idempotencyKey: String
	public init(goalId: UUID, outcome: GoalCompletionOutcome, idempotencyKey: String) {
		self.goalId = goalId
		self.outcome = outcome
		self.idempotencyKey = idempotencyKey
	}
}

public struct CompleteGoalResult: Equatable {
	public let goalId: UUID
	public let escrowStatus: EscrowStatus
	public let transactionRefs: [String]
	public let partial: Bool
}

public final class CompleteGoalUseCase {
	private let escrowRepository: EscrowRepository
	private let disputeRepository: DisputeRepository
	private let distributionUseCase: InitiateDistributionUseCase
	private var idempotent: Set<String> = []
	
	public init(escrowRepository: EscrowRepository, disputeRepository: DisputeRepository, distributionUseCase: InitiateDistributionUseCase) {
		self.escrowRepository = escrowRepository
		self.disputeRepository = disputeRepository
		self.distributionUseCase = distributionUseCase
	}
	
	public func execute(_ request: CompleteGoalRequest) async throws -> CompleteGoalResult {
		let goalIdStr = request.goalId.uuidString
		let key = "complete_\(goalIdStr)_\(request.idempotencyKey)"
		if idempotent.contains(key) {
			let escrow = try await escrowRepository.listEscrowsForGoal(goalIdStr).first
			return CompleteGoalResult(goalId: request.goalId, escrowStatus: escrow?.status ?? .released, transactionRefs: [], partial: false)
		}
		idempotent.insert(key)
		
		guard let escrow = try await escrowRepository.listEscrowsForGoal(goalIdStr).first else {
			throw EscrowServiceError.escrowNotFound
		}
		
		// Pause if disputes
		let disputes = try await disputeRepository.listDisputes(goalId: goalIdStr)
		if disputes.contains(where: { $0.status == .open }) {
			_ = try await escrowRepository.setEscrowStatus(escrow.id, status: .pendingDistribution)
			return CompleteGoalResult(goalId: request.goalId, escrowStatus: .pendingDistribution, transactionRefs: [], partial: false)
		}
		
		// Trigger distribution via use case
		let result = try await distributionUseCase.execute(goalId: goalIdStr)
		return CompleteGoalResult(goalId: request.goalId, escrowStatus: result.status, transactionRefs: result.transactionRefs, partial: result.partial)
	}
}
