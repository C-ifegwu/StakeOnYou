import Foundation

// MARK: - Escrow Repository
protocol EscrowRepository: AnyObject {
    func createEscrow(goalId: String, stakeholders: [EscrowStakeholder], currency: String, holdRef: String) async throws -> Escrow
    func getEscrow(_ escrowId: String) async throws -> Escrow
    func updateEscrow(_ escrow: Escrow) async throws -> Escrow
    func listEscrowsForGoal(_ goalId: String) async throws -> [Escrow]
    func setEscrowStatus(_ escrowId: String, status: EscrowStatus) async throws -> Escrow
    func appendTransaction(_ tx: EscrowTransaction) async throws -> EscrowTransaction
    func listTransactions(forEscrowId escrowId: String) async throws -> [EscrowTransaction]
}

// MARK: - Dispute Repository
protocol DisputeRepository: AnyObject {
    func createDispute(goalId: String, filedBy: String, reason: String, evidenceRefs: [String]) async throws -> Dispute
    func getDispute(_ disputeId: String) async throws -> Dispute
    func listDisputes(goalId: String?) async throws -> [Dispute]
    func setDecision(disputeId: String, status: DisputeStatus, notes: String?, actorId: String) async throws -> Dispute
}

// MARK: - Wallet Repository Additions
protocol WalletRepository: AnyObject {
    func holdFunds(walletId: String, amount: Decimal, holdId: String) async throws
    func releaseFunds(walletId: String, amount: Decimal, reason: String) async throws
    func refundFunds(walletId: String, amount: Decimal, reason: String) async throws
    func getBalance(walletId: String) async throws -> Decimal
}

// MARK: - Transaction Repository Additions
protocol TransactionRepository: AnyObject {
    func appendTransaction(_ transaction: EscrowTransaction) async throws
    func getTransactionsForGoal(_ goalId: String) async throws -> [EscrowTransaction]
    func queryByReference(_ ref: String) async throws -> [EscrowTransaction]
}

// MARK: - Accounting Repository Additions
protocol AccountingReconciliationRepository: AnyObject {
    func appendEntry(_ entry: LedgerEntry) async throws -> LedgerEntry
    func reconcileEntries(forEscrowId escrowId: String) async throws -> Bool
}
