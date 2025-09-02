import Foundation
#if DEBUG
import XCTest

final class DistributionCalculationTests: XCTestCase {
	func testProportionalSplit() {
		let total: Decimal = 300
		let principals: [Decimal] = [100, 200]
		let shares = principals.map { ($0 / principals.reduce(0, +)) * total }
		XCTAssertEqual(shares.count, 2)
		XCTAssertTrue((shares[0] + shares[1]) == total)
	}
	
	func testRoundingRules() {
		let total: Decimal = 1
		let parts = 3
		let base = (total / Decimal(parts))
		let remainder = total - (base * Decimal(parts))
		XCTAssertTrue(remainder >= 0)
	}
}
#endif
