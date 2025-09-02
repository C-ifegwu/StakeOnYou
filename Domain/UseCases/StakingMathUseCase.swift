import Foundation

public struct StakingMathInput: Equatable {
    public let principal: Decimal
    public let elapsedSeconds: TimeInterval
    public let apr: Decimal // 0..1 annual
    public let compounding: Bool
    public let compoundingPeriodDays: Int
    public let stakingFeePercent: Decimal // 0..1
    public let withdrawalFeePercent: Decimal // 0..1
}

public struct StakingMathOutput: Equatable {
    public let accrued: Decimal
    public let totalBeforeFees: Decimal
    public let stakingFee: Decimal
    public let withdrawalFee: Decimal
    public let netIfWithdrawn: Decimal
}

public final class StakingMathUseCase {
    public init() {}

    public func calculate(_ input: StakingMathInput) -> StakingMathOutput {
        let secondsPerYear: Decimal = 365 * 24 * 60 * 60
        let t = max(0, Decimal(input.elapsedSeconds)) / secondsPerYear

        let accrued: Decimal
        if input.compounding {
            let periodsPerYear = Decimal(365) / Decimal(max(1, input.compoundingPeriodDays))
            let n = periodsPerYear * t
            // A = P*(1 + r/m)^(m*t); accrued = A - P
            let base = powDecimal(1 + input.apr / periodsPerYear, n)
            accrued = input.principal * base - input.principal
        } else {
            accrued = input.principal * input.apr * t
        }

        let totalBeforeFees = input.principal + accrued
        let stakingFee = input.principal * input.stakingFeePercent
        let withdrawalFee = totalBeforeFees * input.withdrawalFeePercent
        let netIfWithdrawn = totalBeforeFees - stakingFee - withdrawalFee
        return StakingMathOutput(
            accrued: max(0, accrued),
            totalBeforeFees: max(0, totalBeforeFees),
            stakingFee: max(0, stakingFee),
            withdrawalFee: max(0, withdrawalFee),
            netIfWithdrawn: max(0, netIfWithdrawn)
        )
    }

    private func powDecimal(_ a: Decimal, _ b: Decimal) -> Decimal {
        // Convert to Double for exponent; acceptable for UI-preview precision
        let r = pow((a as NSDecimalNumber).doubleValue, (b as NSDecimalNumber).doubleValue)
        return Decimal(r)
    }
}

import Foundation

// MARK: - Staking Math Use Case
struct StakingMathUseCase {
    private let appConfig: AppConfigurationService
    
    init(appConfig: AppConfigurationService) {
        self.appConfig = appConfig
    }
    
    // MARK: - Accrual Calculations
    func calculateAccruedAmount(
        stake: Stake,
        asOf: Date = Date()
    ) -> Decimal {
        guard stake.status.canAccrue else { return stake.accruedAmount }
        
        let startDate = stake.startAt
        let endDate = min(asOf, stake.lastAccrualAt)
        
        let interest = calculateCompoundInterest(
            principal: stake.principal,
            apr: getAPRForStake(stake),
            startDate: startDate,
            endDate: endDate,
            compoundingFrequency: stake.accrualMethod.compoundingFrequency
        )
        
        return stake.accruedAmount + interest
    }
    
    func calculateProjectedAccrual(
        stake: Stake,
        targetDate: Date
    ) -> Decimal {
        guard stake.status.canAccrue else { return stake.accruedAmount }
        
        let startDate = stake.startAt
        let endDate = min(targetDate, stake.lastAccrualAt)
        
        let interest = calculateCompoundInterest(
            principal: stake.principal,
            apr: getAPRForStake(stake),
            startDate: startDate,
            endDate: endDate,
            compoundingFrequency: stake.accrualMethod.compoundingFrequency
        )
        
        return stake.accruedAmount + interest
    }
    
    // MARK: - Interest Calculations
    func calculateSimpleInterest(
        principal: Decimal,
        apr: Decimal,
        startDate: Date,
        endDate: Date
    ) -> Decimal {
        let timeInYears = Decimal(endDate.timeIntervalSince(startDate) / 365.25 / 24 / 60 / 60)
        return principal * apr * timeInYears
    }
    
    func calculateCompoundInterest(
        principal: Decimal,
        apr: Decimal,
        startDate: Date,
        endDate: Date,
        compoundingFrequency: Int
    ) -> Decimal {
        let timeInYears = Decimal(endDate.timeIntervalSince(startDate) / 365.25 / 24 / 60 / 60)
        
        if compoundingFrequency == 0 {
            return calculateSimpleInterest(principal: principal, apr: apr, startDate: startDate, endDate: endDate)
        }
        
        let ratePerPeriod = apr / Decimal(compoundingFrequency)
        let numberOfPeriods = timeInYears * Decimal(compoundingFrequency)
        
        let compoundFactor = pow(1 + ratePerPeriod, numberOfPeriods)
        return principal * (compoundFactor - 1)
    }
    
    // MARK: - Fee Calculations
    func calculateStakeCreationFee(
        principal: Decimal,
        feeRate: Decimal
    ) -> Decimal {
        return principal * feeRate
    }
    
    func calculateWithdrawalFee(
        amount: Decimal,
        feeRate: Decimal
    ) -> Decimal {
        return amount * feeRate
    }
    
    func calculateTotalFees(
        stake: Stake,
        includeProjected: Bool = false
    ) -> FeeBreakdown {
        let creationFee = calculateStakeCreationFee(
            principal: stake.principal,
            feeRate: stake.feeRateOnStake
        )
        
        let currentAccrued = calculateAccruedAmount(stake: stake)
        let withdrawalFee = calculateWithdrawalFee(
            amount: currentAccrued,
            feeRate: stake.feeRateOnWithdrawal
        )
        
        var projectedWithdrawalFee: Decimal = 0
        if includeProjected {
            let projectedAccrued = calculateProjectedAccrual(stake: stake, targetDate: stake.startAt.addingTimeInterval(365 * 24 * 60 * 60))
            projectedWithdrawalFee = calculateWithdrawalFee(
                amount: projectedAccrued,
                feeRate: stake.feeRateOnWithdrawal
            )
        }
        
        return FeeBreakdown(
            creationFee: creationFee,
            currentWithdrawalFee: withdrawalFee,
            projectedWithdrawalFee: projectedWithdrawalFee,
            totalFees: creationFee + withdrawalFee
        )
    }
    
    // MARK: - Distribution Calculations
    func calculateForfeitDistribution(
        stake: Stake,
        forfeitureType: ForfeitType
    ) -> ForfeitDistribution {
        let totalAmount = stake.principal + stake.accruedAmount
        let creationFee = calculateStakeCreationFee(
            principal: stake.principal,
            feeRate: stake.feeRateOnStake
        )
        
        let netAmount = totalAmount - creationFee
        
        // Get distribution rates from app config
        let rates = getForfeitDistributionRates(forfeitType: forfeitureType)
        
        return ForfeitDistribution(
            charityAmount: netAmount * rates.charityRate,
            appAmount: netAmount * rates.appRate,
            userAmount: netAmount * rates.userRate,
            totalAmount: netAmount
        )
    }
    
    func calculateSuccessPayout(
        stake: Stake,
        earlyCompletionBonus: Decimal? = nil
    ) -> SuccessPayout {
        let totalAccrued = calculateAccruedAmount(stake: stake)
        let withdrawalFee = calculateWithdrawalFee(
            amount: totalAccrued,
            feeRate: stake.feeRateOnWithdrawal
        )
        
        let bonus = earlyCompletionBonus ?? 0
        let netPayout = stake.principal + totalAccrued + bonus - withdrawalFee
        
        return SuccessPayout(
            principal: stake.principal,
            accruedAmount: totalAccrued,
            bonus: bonus,
            fees: withdrawalFee,
            netPayout: netPayout
        )
    }
    
    func calculateGroupDistribution(
        stakes: [Stake],
        winningUserIds: [String]
    ) -> GroupDistributionResult {
        guard !winningUserIds.isEmpty else {
            return GroupDistributionResult(distributions: [], totalDistributed: 0)
        }
        
        let totalForfeited = stakes
            .filter { !winningUserIds.contains($0.userId) }
            .reduce(0) { total, stake in
                total + stake.principal + stake.accruedAmount
            }
        
        let distributionPerWinner = totalForfeited / Decimal(winningUserIds.count)
        
        let distributions = winningUserIds.map { userId in
            UserDistribution(
                userId: userId,
                amount: distributionPerWinner
            )
        }
        
        return GroupDistributionResult(
            distributions: distributions,
            totalDistributed: totalForfeited
        )
    }
    
    // MARK: - Helper Methods
    private func getAPRForStake(_ stake: Stake) -> Decimal {
        // Get APR from app config or use defaults
        let defaultAPR: Decimal
        switch stake.aprModel {
        case .fixed:
            defaultAPR = appConfig.getDecimalValue(for: "staking.apr.fixed") ?? 0.12
        case .tiered:
            defaultAPR = appConfig.getDecimalValue(for: "staking.apr.tiered") ?? 0.15
        case .dynamic:
            defaultAPR = appConfig.getDecimalValue(for: "staking.apr.dynamic") ?? 0.18
        case .promotional:
            defaultAPR = appConfig.getDecimalValue(for: "staking.apr.promotional") ?? 0.25
        }
        
        return defaultAPR
    }
    
    private func getForfeitDistributionRates(forfeitType: ForfeitType) -> ForfeitRates {
        switch forfeitureType {
        case .individual:
            return ForfeitRates(
                charityRate: appConfig.getDecimalValue(for: "staking.forfeit.individual.charity") ?? 0.5,
                appRate: appConfig.getDecimalValue(for: "staking.forfeit.individual.app") ?? 0.5,
                userRate: 0
            )
            
        case .corporate:
            return ForfeitRates(
                charityRate: appConfig.getDecimalValue(for: "staking.forfeit.corporate.charity") ?? 0.5,
                appRate: appConfig.getDecimalValue(for: "staking.forfeit.corporate.app") ?? 0.5,
                userRate: 0
            )
            
        case .group:
            return ForfeitRates(
                charityRate: appConfig.getDecimalValue(for: "staking.forfeit.group.charity") ?? 0.3,
                appRate: appConfig.getDecimalValue(for: "staking.forfeit.group.app") ?? 0.2,
                userRate: appConfig.getDecimalValue(for: "staking.forfeit.group.user") ?? 0.5
            )
        }
    }
}

// MARK: - Supporting Structures
struct FeeBreakdown {
    let creationFee: Decimal
    let currentWithdrawalFee: Decimal
    let projectedWithdrawalFee: Decimal
    let totalFees: Decimal
    
    var totalProjectedFees: Decimal {
        return creationFee + projectedWithdrawalFee
    }
}

struct ForfeitRates {
    let charityRate: Decimal
    let appRate: Decimal
    let userRate: Decimal
    
    var total: Decimal {
        return charityRate + appRate + userRate
    }
}

struct UserDistribution {
    let userId: String
    let amount: Decimal
}

struct GroupDistributionResult {
    let distributions: [UserDistribution]
    let totalDistributed: Decimal
}

// MARK: - Extensions
extension Date {
    func addingTimeInterval(_ interval: TimeInterval) -> Date {
        return self.addingTimeInterval(interval)
    }
}
