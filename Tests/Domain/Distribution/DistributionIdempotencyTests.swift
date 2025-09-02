import Foundation
#if DEBUG
import XCTest

final class DistributionIdempotencyTests: XCTestCase {
	func testIdempotentDistribution() async throws {
		let service = MockDistributionService()
		let first = try await service.distribute(goalId: UUID())
		let second = try await service.distribute(goalId: UUID(uuidString: first.goalId) ?? UUID())
		XCTAssertEqual(first.transactionRefs, second.transactionRefs)
	}
}
#endif
