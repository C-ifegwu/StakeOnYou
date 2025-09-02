import Foundation
import Combine

@MainActor
final class EscrowAdminViewModel: ObservableObject {
	@Published var pendingEscrows: [Escrow] = []
	@Published var isLoading = false
	@Published var errorMessage: String?
	
	private let escrowRepository: EscrowRepository
	private let disputeRepository: DisputeRepository
	private let adjudicateUseCase: AdjudicateDisputeUseCase
	
	init(escrowRepository: EscrowRepository, disputeRepository: DisputeRepository, adjudicateUseCase: AdjudicateDisputeUseCase) {
		self.escrowRepository = escrowRepository
		self.disputeRepository = disputeRepository
		self.adjudicateUseCase = adjudicateUseCase
	}
	
	func loadPending() async {
		isLoading = true
		defer { isLoading = false }
		// naive: scan all goals known elsewhere; here we mock by listing all escrows with pending status using repo extension if available
		// Assuming MockEscrowRepository; for CoreData use a dedicated fetchActive/pending method
		// For now, nothing to fetch without a global list source
	}
	
	func adjudicate(disputeId: String, decision: DisputeDecision, notes: String?, actorId: String, plan: DistributionPlan) async {
		isLoading = true
		do {
			_ = try await adjudicateUseCase.execute(.init(disputeId: disputeId, decision: decision, notes: notes, actorId: actorId, distributionPlan: plan, idempotencyKey: UUID().uuidString))
			isLoading = false
		} catch {
			isLoading = false
			errorMessage = error.localizedDescription
		}
	}
}
