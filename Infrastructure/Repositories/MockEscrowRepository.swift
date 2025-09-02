import Foundation

final class MockEscrowRepository: EscrowRepository {
    private var escrows: [String: Escrow] = [:]
    private var goalToEscrowIds: [String: [String]] = [:]
    private var transactions: [String: [EscrowTransaction]] = [:]
    
    func createEscrow(goalId: String, stakeholders: [EscrowStakeholder], currency: String, holdRef: String) async throws -> Escrow {
        let escrow = Escrow(goalId: goalId, stakeholders: stakeholders, holdRef: holdRef, currency: currency)
        escrows[escrow.id] = escrow
        goalToEscrowIds[goalId, default: []].append(escrow.id)
        transactions[escrow.id] = []
        return escrow
    }
    
    func getEscrow(_ escrowId: String) async throws -> Escrow {
        guard let e = escrows[escrowId] else { throw EscrowServiceError.escrowNotFound }
        return e
    }
    
    func updateEscrow(_ escrow: Escrow) async throws -> Escrow {
        escrows[escrow.id] = escrow
        return escrow
    }
    
    func listEscrowsForGoal(_ goalId: String) async throws -> [Escrow] {
        let ids = goalToEscrowIds[goalId] ?? []
        return ids.compactMap { escrows[$0] }
    }
    
    func setEscrowStatus(_ escrowId: String, status: EscrowStatus) async throws -> Escrow {
        guard var e = escrows[escrowId] else { throw EscrowServiceError.escrowNotFound }
        e.status = status
        e.updatedAt = Date()
        escrows[escrowId] = e
        return e
    }
    
    func appendTransaction(_ tx: EscrowTransaction) async throws -> EscrowTransaction {
        transactions[tx.escrowId, default: []].append(tx)
        return tx
    }
    
    func listTransactions(forEscrowId escrowId: String) async throws -> [EscrowTransaction] {
        return (transactions[escrowId] ?? []).sorted { $0.createdAt > $1.createdAt }
    }
}
