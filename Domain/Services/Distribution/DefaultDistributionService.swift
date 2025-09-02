import Foundation

final class DefaultDistributionService: DistributionServiceProtocol {
	private let escrowRepository: EscrowRepository
	private let disputeRepository: DisputeRepository
	private let accountingService: AccountingService
	private let walletService: WalletService
	private var idempotencySet: Set<String> = []
	
	init(
		escrowRepository: EscrowRepository,
		disputeRepository: DisputeRepository,
		accountingService: AccountingService,
		walletService: WalletService
	) {
		self.escrowRepository = escrowRepository
		self.disputeRepository = disputeRepository
		self.accountingService = accountingService
		self.walletService = walletService
	}
	
	func distribute(goalId: UUID) async throws -> DistributionResult {
		let goalIdStr = goalId.uuidString
		guard var escrow = try await escrowRepository.listEscrowsForGoal(goalIdStr).first else {
			throw EscrowServiceError.escrowNotFound
		}
		
		// Check disputes
		let disputes = try await disputeRepository.listDisputes(goalId: goalIdStr)
		if disputes.contains(where: { $0.status == .open }) {
			return DistributionResult(goalId: goalIdStr, escrowId: escrow.id, status: .pendingDistribution, transactionRefs: [], partial: false, message: "Pending dispute")
		}
		
		// Determine distribution path by escrow.status and assumptions:
		// If status is HELD -> success path releases to stakeholders equally proportional to principal.
		// If status is FORFEITED/PENDING handled elsewhere; here we proceed based on flags stored externally.
		let totalPool = escrow.totalPrincipal + escrow.accruedAmount
		var txRefs: [String] = []
		var partial = false
		
		// Idempotency key per escrow distribution
		let idempotencyKey = "dist_\(escrow.id)"
		if idempotencySet.contains(idempotencyKey) {
			return DistributionResult(goalId: goalIdStr, escrowId: escrow.id, status: escrow.status, transactionRefs: txRefs, partial: false, message: "Already distributed")
		}
		idempotencySet.insert(idempotencyKey)
		
		// Simple default: release to stakeholders proportional to principal
		for s in escrow.stakeholders {
			let share = escrow.totalPrincipal == 0 ? 0 : (s.principal / escrow.totalPrincipal) * totalPool
			do {
				let payment = try await walletService.releaseEscrow(amount: share, for: s.userId, goalId: escrow.goalId)
				let tx = EscrowTransaction(escrowId: escrow.id, type: .release, amount: share, relatedTxRef: payment.id)
				let saved = try await escrowRepository.appendTransaction(tx)
				txRefs.append(saved.relatedTxRef)
				// Accounting (simplified)
				let entry = LedgerEntry(transactionId: payment.id, accountId: "user_wallet_\(s.userId)", accountType: .userWallet, entryType: .credit, amount: share, description: "Distribution release", reference: escrow.id)
				_ = try await (accountingService as? MockAccountingService)?.accountingRepository.saveLedgerEntry(entry)
			} catch {
				partial = true
			}
		}
		
		escrow.status = partial ? .partial : .released
		escrow.updatedAt = Date()
		escrow = try await escrowRepository.updateEscrow(escrow)
		return DistributionResult(goalId: goalIdStr, escrowId: escrow.id, status: escrow.status, transactionRefs: txRefs, partial: partial, message: partial ? "Partial distribution" : nil)
	}
}
