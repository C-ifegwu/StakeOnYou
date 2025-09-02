import Foundation

extension CoreDataEscrowRepository {
	func accrue(escrowId: String, increment: Decimal) async throws -> Escrow {
		try await accrueInterest(escrowId: escrowId, increment: increment)
	}
	
	func rollback(escrowId: String) async throws {
		try await delete(escrowId: escrowId)
	}
	
	func complete(goalId: String, to status: EscrowStatus) async throws -> Escrow? {
		guard let e = try await listEscrowsForGoal(goalId).first else { return nil }
		return try await setEscrowStatus(e.id, status: status)
	}
}
