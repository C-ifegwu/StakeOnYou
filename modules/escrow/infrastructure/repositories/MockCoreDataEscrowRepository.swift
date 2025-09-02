import Foundation

final class MockCoreDataEscrowRepository: EscrowRepository {
    private var escrows: [String: Escrow] = [:]
    
    func createEscrow(goalId: String, stakeholders: [EscrowStakeholder], currency: String, holdRef: String) async throws -> Escrow {
        let e = Escrow(goalId: goalId, stakeholders: stakeholders, holdRef: holdRef, currency: currency)
        escrows[e.id] = e
        return e
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
        escrows.values.filter { $0.goalId == goalId }
    }
    
    func setEscrowStatus(_ escrowId: String, status: EscrowStatus) async throws -> Escrow {
        guard var e = escrows[escrowId] else { throw EscrowServiceError.escrowNotFound }
        e.status = status
        e.updatedAt = Date()
        escrows[escrowId] = e
        return e
    }
    
    func appendTransaction(_ tx: EscrowTransaction) async throws -> EscrowTransaction { tx }
    func listTransactions(forEscrowId escrowId: String) async throws -> [EscrowTransaction] { [] }
}
