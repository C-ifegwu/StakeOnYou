import Foundation

// MARK: - Stake Entity
struct Stake: Identifiable, Codable, Equatable {
    let id: String
    let goalId: String
    let userId: String
    let principal: Decimal
    let startAt: Date
    let aprModel: APRModel
    let accrualMethod: AccrualMethod
    let accruedAmount: Decimal
    let feeRateOnStake: Decimal
    let feeRateOnWithdrawal: Decimal
    let lastAccrualAt: Date
    let status: StakeStatus
    let createdAt: Date
    let updatedAt: Date
    
    // Optional fields
    let earlyCompletionBonus: Decimal?
    let charityId: String?
    let groupId: String?
    let corporateAccountId: String?
    let notes: [StakeNote]
    
    init(
        id: String = UUID().uuidString,
        goalId: String,
        userId: String,
        principal: Decimal,
        aprModel: APRModel,
        accrualMethod: AccrualMethod = .simple,
        feeRateOnStake: Decimal = 0.05, // 5% fee on stake creation
        feeRateOnWithdrawal: Decimal = 0.02, // 2% fee on withdrawal
        earlyCompletionBonus: Decimal? = nil,
        charityId: String? = nil,
        groupId: String? = nil,
        corporateAccountId: String? = nil,
        notes: [StakeNote] = []
    ) {
        self.id = id
        self.goalId = goalId
        self.userId = userId
        self.principal = principal
        self.startAt = Date()
        self.aprModel = aprModel
        self.accrualMethod = accrualMethod
        self.accruedAmount = 0
        self.feeRateOnStake = feeRateOnStake
        self.feeRateOnWithdrawal = feeRateOnWithdrawal
        self.lastAccrualAt = Date()
        self.status = .active
        self.createdAt = Date()
        self.updatedAt = Date()
        self.earlyCompletionBonus = earlyCompletionBonus
        self.charityId = charityId
        self.groupId = groupId
        self.corporateAccountId = corporateAccountId
        self.notes = notes
    }
}

// MARK: - APR Model
enum APRModel: String, Codable, CaseIterable {
    case fixed = "fixed"
    case tiered = "tiered"
    case dynamic = "dynamic"
    case promotional = "promotional"
    
    var displayName: String {
        switch self {
        case .fixed: return "Fixed Rate"
        case .tiered: return "Tiered Rate"
        case .dynamic: return "Dynamic Rate"
        case .promotional: return "Promotional Rate"
        }
    }
}

// MARK: - Accrual Method
enum AccrualMethod: String, Codable, CaseIterable {
    case simple = "simple"
    case compound = "compound"
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    
    var displayName: String {
        switch self {
        case .simple: return "Simple Interest"
        case .compound: return "Compound Interest"
        case .daily: return "Daily Compounding"
        case .weekly: return "Weekly Compounding"
        case .monthly: return "Monthly Compounding"
        }
    }
    
    var compoundingFrequency: Int {
        switch self {
        case .simple: return 0
        case .compound: return 1
        case .daily: return 365
        case .weekly: return 52
        case .monthly: return 12
        }
    }
}

// MARK: - Stake Status
enum StakeStatus: String, Codable, CaseIterable {
    case active = "active"
    case paused = "paused"
    case completed = "completed"
    case failed = "failed"
    case cancelled = "cancelled"
    case disputed = "disputed"
    case liquidated = "liquidated"
    
    var displayName: String {
        switch self {
        case .active: return "Active"
        case .paused: return "Paused"
        case .completed: return "Completed"
        case .failed: return "Failed"
        case .cancelled: return "Cancelled"
        case .disputed: return "Disputed"
        case .liquidated: return "Liquidated"
        }
    }
    
    var isActive: Bool {
        return self == .active || self == .paused
    }
    
    var isFinal: Bool {
        return self == .completed || self == .failed || self == .cancelled || self == .liquidated
    }
    
    var canAccrue: Bool {
        return self == .active
    }
}

// MARK: - Stake Note
struct StakeNote: Identifiable, Codable, Equatable {
    let id: String
    let content: String
    let authorId: String
    let createdAt: Date
    let updatedAt: Date
    let type: NoteType
    
    init(
        id: String = UUID().uuidString,
        content: String,
        authorId: String,
        type: NoteType = .general
    ) {
        self.id = id
        self.content = content
        self.authorId = authorId
        self.createdAt = Date()
        self.updatedAt = Date()
        self.type = type
    }
}

enum NoteType: String, Codable, CaseIterable {
    case general = "general"
    case adjustment = "adjustment"
    case dispute = "dispute"
    case resolution = "resolution"
    case system = "system"
}

// MARK: - Staking Math Functions
struct StakingMath {
    
    // MARK: - Simple Interest Calculation
    static func calculateSimpleInterest(
        principal: Decimal,
        apr: Decimal,
        startDate: Date,
        endDate: Date
    ) -> Decimal {
        let timeInYears = Decimal(endDate.timeIntervalSince(startDate) / 365.25 / 24 / 60 / 60)
        return principal * apr * timeInYears
    }
    
    // MARK: - Compound Interest Calculation
    static func calculateCompoundInterest(
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
    
    // MARK: - Accrued Amount Calculation
    static func calculateAccruedAmount(
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
    
    // MARK: - Fee Calculations
    static func calculateStakeCreationFee(
        principal: Decimal,
        feeRate: Decimal
    ) -> Decimal {
        return principal * feeRate
    }
    
    static func calculateWithdrawalFee(
        amount: Decimal,
        feeRate: Decimal
    ) -> Decimal {
        return amount * feeRate
    }
    
    // MARK: - Distribution Calculations
    static func calculateForfeitDistribution(
        stake: Stake,
        forfeitureType: ForfeitType
    ) -> ForfeitDistribution {
        let totalAmount = stake.principal + stake.accruedAmount
        let stakeCreationFee = calculateStakeCreationFee(
            principal: stake.principal,
            feeRate: stake.feeRateOnStake
        )
        
        let netAmount = totalAmount - stakeCreationFee
        
        switch forfeitureType {
        case .individual:
            return ForfeitDistribution(
                charityAmount: netAmount * 0.5,
                appAmount: netAmount * 0.5,
                userAmount: 0
            )
            
        case .corporate:
            return ForfeitDistribution(
                charityAmount: netAmount * 0.5,
                appAmount: netAmount * 0.5,
                userAmount: 0
            )
            
        case .group:
            return ForfeitDistribution(
                charityAmount: netAmount * 0.3,
                appAmount: netAmount * 0.2,
                userAmount: netAmount * 0.5 // Redistributed to winning members
            )
        }
    }
    
    // MARK: - Success Payout Calculation
    static func calculateSuccessPayout(
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
    
    // MARK: - Helper Functions
    private static func getAPRForStake(_ stake: Stake) -> Decimal {
        // TODO: Implement dynamic APR calculation based on stake model
        // For now, return a default APR
        switch stake.aprModel {
        case .fixed:
            return 0.12 // 12% APR
        case .tiered:
            return 0.15 // 15% APR for tiered
        case .dynamic:
            return 0.18 // 18% APR for dynamic
        case .promotional:
            return 0.25 // 25% APR for promotional
        }
    }
}

// MARK: - Supporting Structures
struct ForfeitDistribution {
    let charityAmount: Decimal
    let appAmount: Decimal
    let userAmount: Decimal
    
    var total: Decimal {
        return charityAmount + appAmount + userAmount
    }
}

struct SuccessPayout {
    let principal: Decimal
    let accruedAmount: Decimal
    let bonus: Decimal
    let fees: Decimal
    let netPayout: Decimal
    
    var totalBeforeFees: Decimal {
        return principal + accruedAmount + bonus
    }
}

enum ForfeitType {
    case individual
    case corporate
    case group
}

// MARK: - Stake Extensions
extension Stake {
    var totalValue: Decimal {
        return principal + accruedAmount
    }
    
    var duration: TimeInterval {
        return Date().timeIntervalSince(startAt)
    }
    
    var daysActive: Int {
        return Int(duration / 86400)
    }
    
    var currentAccruedAmount: Decimal {
        return StakingMath.calculateAccruedAmount(stake: self)
    }
    
    var canBeLiquidated: Bool {
        return status == .active && daysActive > 365 // 1 year
    }
    
    var isGroupStake: Bool {
        return groupId != nil
    }
    
    var isCorporateStake: Bool {
        return corporateAccountId != nil
    }
    
    var hasCharity: Bool {
        return charityId != nil
    }
}

// MARK: - Stake Validation
extension Stake {
    var validationErrors: [String] {
        var errors: [String] = []
        
        if principal <= 0 {
            errors.append("Stake principal must be greater than zero")
        }
        
        if feeRateOnStake < 0 || feeRateOnStake > 1 {
            errors.append("Stake creation fee rate must be between 0 and 1")
        }
        
        if feeRateOnWithdrawal < 0 || feeRateOnWithdrawal > 1 {
            errors.append("Withdrawal fee rate must be between 0 and 1")
        }
        
        return errors
    }
    
    var isValid: Bool {
        return validationErrors.isEmpty
    }
}
