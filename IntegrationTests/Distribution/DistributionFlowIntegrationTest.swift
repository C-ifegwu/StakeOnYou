import Foundation
#if DEBUG
import XCTest

final class DistributionFlowIntegrationTest: XCTestCase {
	func testHoldToDistributeFlow() async throws {
		let escrowRepo = MockEscrowRepository()
		let disputeRepo = MockDisputeRepository()
		let accounting = MockAccountingService(accountingRepository: MockAccountingRepository())
		let wallet = MockWalletService()
		let escrowService = MockEscrowService(escrowRepository: escrowRepo, disputeRepository: disputeRepo, accountingService: accounting, walletService: wallet)
		let stakeholders = [EscrowStakeholder(userId: "u1", stakeId: "s1", principal: 100)]
		let escrow = try await escrowService.hold(goalId: "g1", stakeholders: stakeholders, currency: "USD", idempotencyKey: "h1")
		XCTAssertEqual(escrow.status, .held)
		// Distribute
		let distService = MockDistributionService()
		let result = try await distService.distribute(goalId: UUID(uuidString: escrow.goalId) ?? UUID())
		XCTAssertEqual(result.status, .released)
	}
}
#endif
