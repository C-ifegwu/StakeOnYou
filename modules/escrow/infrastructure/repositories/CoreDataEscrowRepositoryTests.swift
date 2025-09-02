import Foundation
#if DEBUG
import XCTest
@testable import StakeOnYou

final class CoreDataEscrowRepositoryTests: XCTestCase {
    func testCRUDAndStatusAndAccrual() async throws {
        // Create repo with in-memory store
        let url = URL(fileURLWithPath: "/dev/null")
        let repo = CoreDataEscrowRepository(storeURL: url)

        // Create escrow
        let stakeholders = [EscrowStakeholder(userId: "u1", stakeId: "s1", principal: 100)]
        let created = try await repo.createEscrow(goalId: "g1", stakeholders: stakeholders, currency: "USD", holdRef: "hold1")
        XCTAssertEqual(created.goalId, "g1")

        // Fetch by id
        let fetched = try await repo.getEscrow(created.id)
        XCTAssertEqual(fetched.id, created.id)

        // List by goal
        let list = try await repo.listEscrowsForGoal("g1")
        XCTAssertEqual(list.count, 1)

        // Update status
        let updated = try await repo.setEscrowStatus(created.id, status: .pendingDistribution)
        XCTAssertEqual(updated.status, .pendingDistribution)

        // Accrue interest
        let accrued = try await repo.accrueInterest(escrowId: created.id, increment: 5)
        XCTAssertTrue(accrued.accruedAmount >= 5)

        // Delete
        try await repo.delete(escrowId: created.id)
        do {
            _ = try await repo.getEscrow(created.id)
            XCTFail("Should throw after delete")
        } catch {
            // expected
        }
    }
}
#endif
