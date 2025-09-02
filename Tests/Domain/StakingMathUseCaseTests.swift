import XCTest

final class StakingMathUseCaseTests: XCTestCase {
    func testSimpleAccrualPositive() {
        let math = StakingMathUseCase()
        let input = StakingMathInput(principal: 1000, elapsedSeconds: 365*24*60*60, apr: 0.05, compounding: false, compoundingPeriodDays: 1, stakingFeePercent: 0, withdrawalFeePercent: 0)
        let out = math.calculate(input)
        XCTAssertGreaterThan(out.accrued, 49)
        XCTAssertLessThan(out.accrued, 51)
    }
}


