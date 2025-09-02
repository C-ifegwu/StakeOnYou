import Foundation

// Lifecycle helpers for CoreDataEscrowRepository
extension CoreDataEscrowRepository {
    @discardableResult
    func accrueInterest(escrowId: String, increment: Decimal) async throws -> Escrow {
        var escrow = try await getEscrow(escrowId)
        escrow.accruedAmount += increment
        escrow.updatedAt = Date()
        return try await updateEscrow(escrow)
    }

    @discardableResult
    func setEscrowStatus(_ escrowId: String, status: EscrowStatus) async throws -> Escrow {
        var escrow = try await getEscrow(escrowId)
        escrow.status = status
        escrow.updatedAt = Date()
        return try await updateEscrow(escrow)
    }
}


