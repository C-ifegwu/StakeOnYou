import Foundation

final class MockDistributionService: DistributionServiceProtocol {
	private var idempotent: Set<String> = []
	
	func distribute(goalId: UUID) async throws -> DistributionResult {
		let escrowId = goalId.uuidString + "_escrow"
		let key = "dist_\(escrowId)"
		if idempotent.contains(key) {
			return DistributionResult(goalId: goalId.uuidString, escrowId: escrowId, status: .released, transactionRefs: ["tx_mock_1", "tx_mock_2"], partial: false, message: "Already distributed")
		}
		idempotent.insert(key)
		return DistributionResult(goalId: goalId.uuidString, escrowId: escrowId, status: .released, transactionRefs: ["tx_mock_1", "tx_mock_2"], partial: false, message: nil)
	}
}
