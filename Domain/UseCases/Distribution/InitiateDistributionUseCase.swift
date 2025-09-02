import Foundation

final class InitiateDistributionUseCase {
	private let service: DistributionServiceProtocol
	private let escrowRepository: EscrowRepository
	private let disputeRepository: DisputeRepository
	
	init(service: DistributionServiceProtocol, escrowRepository: EscrowRepository, disputeRepository: DisputeRepository) {
		self.service = service
		self.escrowRepository = escrowRepository
		self.disputeRepository = disputeRepository
	}
	
	func execute(goalId: String) async throws -> DistributionResult {
		// Do not proceed if there is an open dispute
		let disputes = try await disputeRepository.listDisputes(goalId: goalId)
		if disputes.contains(where: { $0.status == .open }) {
			return DistributionResult(goalId: goalId, escrowId: "", status: .pendingDistribution, transactionRefs: [], partial: false, message: "Pending dispute")
		}
		
		let result = try await service.distribute(goalId: UUID(uuidString: goalId) ?? UUID())
		// Ensure escrow status is updated to reflect distribution outcome when possible
		if let escrow = try await escrowRepository.listEscrowsForGoal(goalId).first {
			let targetStatus: EscrowStatus = result.partial ? .partial : result.status
			_ = try await escrowRepository.setEscrowStatus(escrow.id, status: targetStatus)
		}
		return result
	}
}
