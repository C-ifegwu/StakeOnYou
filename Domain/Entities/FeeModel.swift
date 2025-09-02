import Foundation

// MARK: - Fee Model Entity
struct FeeModel: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let description: String
    let type: FeeType
    let rate: Decimal
    let rateType: RateType
    let minimumAmount: Decimal
    let maximumAmount: Decimal
    let currency: String
    let isActive: Bool
    let appliesTo: [PaymentType]
    let createdAt: Date
    let updatedAt: Date
    
    init(
        id: String = UUID().uuidString,
        name: String,
        description: String,
        type: FeeType,
        rate: Decimal,
        rateType: RateType,
        minimumAmount: Decimal = 0,
        maximumAmount: Decimal = 1000000,
        currency: String = "USD",
        isActive: Bool = true,
        appliesTo: [PaymentType] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.type = type
        self.rate = rate
        self.rateType = rateType
        self.minimumAmount = minimumAmount
        self.maximumAmount = maximumAmount
        self.currency = currency
        self.isActive = isActive
        self.appliesTo = appliesTo
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    func calculateFee(for amount: Decimal) -> Decimal {
        guard amount >= minimumAmount && amount <= maximumAmount else {
            return 0
        }
        
        switch rateType {
        case .percentage:
            return (amount * rate) / 100
        case .fixed:
            return rate
        case .tiered:
            return calculateTieredFee(for: amount)
        }
    }
    
    private func calculateTieredFee(for amount: Decimal) -> Decimal {
        // Default tiered calculation - can be overridden by specific implementations
        return (amount * rate) / 100
    }
}

// MARK: - Fee Type
enum FeeType: String, CaseIterable, Codable {
    case deposit = "deposit"
    case withdrawal = "withdrawal"
    case escrow = "escrow"
    case processing = "processing"
    case platform = "platform"
    case charity = "charity"
    
    var displayName: String {
        switch self {
        case .deposit: return "Deposit Fee"
        case .withdrawal: return "Withdrawal Fee"
        case .escrow: return "Escrow Fee"
        case .processing: return "Processing Fee"
        case .platform: return "Platform Fee"
        case .charity: return "Charity Fee"
        }
    }
    
    var defaultRate: Decimal {
        switch self {
        case .deposit: return 2.9
        case .withdrawal: return 1.0
        case .escrow: return 0.5
        case .processing: return 0.30
        case .platform: return 5.0
        case .charity: return 0.0
        }
    }
    
    var defaultRateType: RateType {
        switch self {
        case .deposit, .withdrawal, .escrow, .platform:
            return .percentage
        case .processing:
            return .fixed
        case .charity:
            return .percentage
        }
    }
}

// MARK: - Rate Type
enum RateType: String, CaseIterable, Codable {
    case percentage = "percentage"
    case fixed = "fixed"
    case tiered = "tiered"
    
    var displayName: String {
        switch self {
        case .percentage: return "Percentage"
        case .fixed: return "Fixed Amount"
        case .tiered: return "Tiered"
        }
    }
    
    var symbol: String {
        switch self {
        case .percentage: return "%"
        case .fixed: return "$"
        case .tiered: return "tiered"
        }
    }
}

// MARK: - Fee Calculation Result
struct FeeCalculation: Codable, Equatable {
    let baseAmount: Decimal
    let feeAmount: Decimal
    let totalAmount: Decimal
    let feeBreakdown: [FeeBreakdown]
    let currency: String
    
    init(
        baseAmount: Decimal,
        feeAmount: Decimal,
        totalAmount: Decimal,
        feeBreakdown: [FeeBreakdown],
        currency: String = "USD"
    ) {
        self.baseAmount = baseAmount
        self.feeAmount = feeAmount
        self.totalAmount = totalAmount
        self.feeBreakdown = feeBreakdown
        self.currency = currency
    }
}

// MARK: - Fee Breakdown
struct FeeBreakdown: Codable, Equatable {
    let feeType: FeeType
    let rate: Decimal
    let rateType: RateType
    let amount: Decimal
    let description: String
    
    init(
        feeType: FeeType,
        rate: Decimal,
        rateType: RateType,
        amount: Decimal,
        description: String
    ) {
        self.feeType = feeType
        self.rate = rate
        self.rateType = rateType
        self.amount = amount
        self.description = description
    }
}

// MARK: - Default Fee Models
extension FeeModel {
    static let defaultDepositFee = FeeModel(
        name: "Standard Deposit Fee",
        description: "Standard fee for deposits via credit card or bank transfer",
        type: .deposit,
        rate: 2.9,
        rateType: .percentage,
        appliesTo: [.deposit]
    )
    
    static let defaultWithdrawalFee = FeeModel(
        name: "Standard Withdrawal Fee",
        description: "Standard fee for withdrawals to bank accounts",
        type: .withdrawal,
        rate: 1.0,
        rateType: .percentage,
        appliesTo: [.withdrawal]
    )
    
    static let defaultProcessingFee = FeeModel(
        name: "Processing Fee",
        description: "Fixed processing fee for transactions",
        type: .processing,
        rate: 0.30,
        rateType: .fixed,
        appliesTo: [.deposit, .withdrawal]
    )
    
    static let defaultPlatformFee = FeeModel(
        name: "Platform Fee",
        description: "Platform fee for successful goal completions",
        type: .platform,
        rate: 5.0,
        rateType: .percentage,
        appliesTo: [.escrowRelease]
    )
}
