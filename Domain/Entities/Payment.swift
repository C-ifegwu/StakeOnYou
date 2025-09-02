import Foundation

// MARK: - Payment Entity
struct Payment: Identifiable, Codable, Equatable {
    let id: String
    let userId: String
    let amount: Decimal
    let currency: String
    let type: PaymentType
    let status: PaymentStatus
    let method: PaymentMethod
    let description: String
    let metadata: [String: String]
    let createdAt: Date
    let updatedAt: Date
    let processedAt: Date?
    let failureReason: String?
    let externalTransactionId: String?
    let chargebackFlag: Bool
    let chargebackDate: Date?
    
    init(
        id: String = UUID().uuidString,
        userId: String,
        amount: Decimal,
        currency: String = "USD",
        type: PaymentType,
        status: PaymentStatus = .pending,
        method: PaymentMethod,
        description: String,
        metadata: [String: String] = [:],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        processedAt: Date? = nil,
        failureReason: String? = nil,
        externalTransactionId: String? = nil,
        chargebackFlag: Bool = false,
        chargebackDate: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.amount = amount
        self.currency = currency
        self.type = type
        self.status = status
        self.method = method
        self.description = description
        self.metadata = metadata
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.processedAt = processedAt
        self.failureReason = failureReason
        self.externalTransactionId = externalTransactionId
        self.chargebackFlag = chargebackFlag
        self.chargebackDate = chargebackDate
    }
}

// MARK: - Payment Types
enum PaymentType: String, CaseIterable, Codable {
    case deposit = "deposit"
    case withdrawal = "withdrawal"
    case escrowHold = "escrow_hold"
    case escrowRelease = "escrow_release"
    case fee = "fee"
    case donation = "donation"
    case payout = "payout"
    case refund = "refund"
    
    var displayName: String {
        switch self {
        case .deposit: return "Deposit"
        case .withdrawal: return "Withdrawal"
        case .escrowHold: return "Escrow Hold"
        case .escrowRelease: return "Escrow Release"
        case .fee: return "Fee"
        case .donation: return "Donation"
        case .payout: return "Payout"
        case .refund: return "Refund"
        }
    }
    
    var isCredit: Bool {
        switch self {
        case .deposit, .escrowRelease, .payout, .refund:
            return true
        case .withdrawal, .escrowHold, .fee, .donation:
            return false
        }
    }
}

// MARK: - Payment Status
enum PaymentStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
    case cancelled = "cancelled"
    case disputed = "disputed"
    case refunded = "refunded"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .processing: return "Processing"
        case .completed: return "Completed"
        case .failed: return "Failed"
        case .cancelled: return "Cancelled"
        case .disputed: return "Disputed"
        case .refunded: return "Refunded"
        }
    }
    
    var isFinal: Bool {
        switch self {
        case .completed, .failed, .cancelled, .refunded:
            return true
        case .pending, .processing, .disputed:
            return false
        }
    }
}

// MARK: - Payment Method
enum PaymentMethod: String, CaseIterable, Codable {
    case stripe = "stripe"
    case applePay = "apple_pay"
    case bankTransfer = "bank_transfer"
    case internal = "internal"
    
    var displayName: String {
        switch self {
        case .stripe: return "Credit Card"
        case .applePay: return "Apple Pay"
        case .bankTransfer: return "Bank Transfer"
        case .internal: return "Internal Transfer"
        }
    }
    
    var iconName: String {
        switch self {
        case .stripe: return "creditcard"
        case .applePay: return "applelogo"
        case .bankTransfer: return "building.columns"
        case .internal: return "arrow.left.arrow.right"
        }
    }
}
