import Foundation

extension CoreDataStakeRepository {
    func calculateAccruedAmount(stake: Stake) -> Decimal {
        // Placeholder accrual based on time since lastAccrualAt and a fixed APR 3%
        let elapsed = Date().timeIntervalSince(stake.lastAccrualAt)
        let input = StakingMathInput(
            principal: stake.amount,
            elapsedSeconds: elapsed,
            apr: 0.03,
            compounding: true,
            compoundingPeriodDays: 1,
            stakingFeePercent: 0,
            withdrawalFeePercent: 0
        )
        let math = StakingMathUseCase()
        return math.calculate(input).accrued
    }
}


