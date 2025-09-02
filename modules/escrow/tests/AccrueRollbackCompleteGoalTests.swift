import Foundation
#if DEBUG
import XCTest

final class AccrueRollbackCompleteGoalTests: XCTestCase {
	func testAccrualSimpleAPR() async throws {
		let repo = MockCoreDataEscrowRepository()
		let stakeholders = [EscrowStakeholder(userId: "u1", stakeId: "s1", principal: 100)]
		let e = try await repo.createEscrow(goalId: "g1", stakeholders: stakeholders, currency: "USD", holdRef: "hold1")
		let accrual = DefaultAccrualService(escrowRepository: repo, annualInterestRate: 0.365)
		let uc = AccrueEscrowUseCase(escrowRepository: repo, accrualService: accrual)
		let updated = try await uc.execute(.init(escrowId: UUID(uuidString: e.id) ?? UUID(), period: 24*60*60))
		XCTAssertTrue(updated.accruedAmount > 0)
	}
	
	func testRollbackRefunds() async throws {
		let repo = MockEscrowRepository()
		let acc = MockAccountingService(accountingRepository: MockAccountingRepository())
		let wallet = MockWalletService()
		let dispute = MockDisputeRepository()
		let service = MockEscrowService(escrowRepository: repo, disputeRepository: dispute, accountingService: acc, walletService: wallet)
		let stakeholders = [EscrowStakeholder(userId: "u1", stakeId: "s1", principal: 75)]
		let e = try await repo.createEscrow(goalId: "g1", stakeholders: stakeholders, currency: "USD", holdRef: "hold1")
		let uc = RollbackEscrowUseCase(escrowRepository: repo, escrowService: service)
		let refunded = try await uc.execute(.init(escrowId: UUID(uuidString: e.id) ?? UUID(), reason: "cancel", idempotencyKey: "rb1"))
		XCTAssertEqual(refunded.status, .refunded)
	}
	
	func testCompleteGoalTriggersDistribution() async throws {
		let repo = MockEscrowRepository()
		let dispute = MockDisputeRepository()
		let distService = MockDistributionService()
		let ucDist = InitiateDistributionUseCase(service: distService, escrowRepository: repo, disputeRepository: dispute)
		let uc = CompleteGoalUseCase(escrowRepository: repo, disputeRepository: dispute, distributionUseCase: ucDist)
		let stakeholders = [EscrowStakeholder(userId: "u1", stakeId: "s1", principal: 50)]
		_ = try await repo.createEscrow(goalId: "g1", stakeholders: stakeholders, currency: "USD", holdRef: "hold1")
		let result = try await uc.execute(.init(goalId: UUID(uuidString: "g1") ?? UUID(), outcome: .success, idempotencyKey: "k1"))
		XCTAssertEqual(result.escrowStatus, .released)
	}
}
#endif
