import Foundation
import Combine

// MARK: - Wallet Service Protocol
protocol WalletService: AnyObject {
    func createWallet(for userId: String) async throws -> Wallet
    func getWallet(for userId: String) async throws -> Wallet
    func getBalance(for userId: String) async throws -> Decimal
    func deposit(amount: Decimal, to userId: String, method: PaymentMethod) async throws -> Payment
    func withdraw(amount: Decimal, from userId: String, method: PaymentMethod) async throws -> Payment
    func holdEscrow(amount: Decimal, for userId: String, goalId: String) async throws -> Payment
    func releaseEscrow(amount: Decimal, for userId: String, goalId: String) async throws -> Payment
    func refundEscrow(amount: Decimal, for userId: String, goalId: String) async throws -> Payment
    func applyFees(amount: Decimal, feeType: FeeType, for userId: String) async throws -> Payment
    func getTransactionHistory(for userId: String, limit: Int?) async throws -> [WalletTransaction]
    func getTransactionHistory(for userId: String, type: TransactionType?, limit: Int?) async throws -> [WalletTransaction]
    func validateTransaction(amount: Decimal, type: TransactionType, for userId: String) async throws -> ValidationResult
}

// MARK: - Wallet Service Error
enum WalletServiceError: LocalizedError, Equatable {
    case walletNotFound
    case insufficientFunds
    case invalidAmount
    case transactionFailed
    case escrowNotAvailable
    case userNotVerified
    case dailyLimitExceeded
    case monthlyLimitExceeded
    case walletSuspended
    case kycRequired
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .walletNotFound:
            return "Wallet not found"
        case .insufficientFunds:
            return "Insufficient funds"
        case .invalidAmount:
            return "Invalid amount"
        case .transactionFailed:
            return "Transaction failed"
        case .escrowNotAvailable:
            return "Escrow not available"
        case .userNotVerified:
            return "User not verified"
        case .dailyLimitExceeded:
            return "Daily limit exceeded"
        case .monthlyLimitExceeded:
            return "Monthly limit exceeded"
        case .walletSuspended:
            return "Wallet is suspended"
        case .kycRequired:
            return "KYC verification required"
        case .unknownError(let message):
            return message
        }
    }
}

// MARK: - Wallet Transaction Request
struct WalletTransactionRequest: Codable, Equatable {
    let userId: String
    let amount: Decimal
    let type: TransactionType
    let description: String
    let reference: String
    let metadata: [String: String]
    
    init(
        userId: String,
        amount: Decimal,
        type: TransactionType,
        description: String,
        reference: String,
        metadata: [String: String] = [:]
    ) {
        self.userId = userId
        self.amount = amount
        self.type = type
        self.description = description
        self.reference = reference
        self.metadata = metadata
    }
}

// MARK: - Wallet Balance Update
struct WalletBalanceUpdate: Codable, Equatable {
    let userId: String
    let balanceBefore: Decimal
    let balanceAfter: Decimal
    let escrowBefore: Decimal
    let escrowAfter: Decimal
    let transactionId: String
    let timestamp: Date
    
    init(
        userId: String,
        balanceBefore: Decimal,
        balanceAfter: Decimal,
        escrowBefore: Decimal,
        escrowAfter: Decimal,
        transactionId: String,
        timestamp: Date = Date()
    ) {
        self.userId = userId
        self.balanceBefore = balanceBefore
        self.balanceAfter = balanceAfter
        self.escrowBefore = escrowBefore
        self.escrowAfter = escrowAfter
        self.transactionId = transactionId
        self.timestamp = timestamp
    }
}

// MARK: - Escrow Request
struct EscrowRequest: Codable, Equatable {
    let userId: String
    let goalId: String
    let amount: Decimal
    let description: String
    let metadata: [String: String]
    
    init(
        userId: String,
        goalId: String,
        amount: Decimal,
        description: String,
        metadata: [String: String] = [:]
    ) {
        self.userId = userId
        self.goalId = goalId
        self.amount = amount
        self.description = description
        self.metadata = metadata
    }
}

// MARK: - Escrow Status
enum EscrowStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case held = "held"
    case released = "released"
    case refunded = "refunded"
    case expired = "expired"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .held: return "Held"
        case .released: return "Released"
        case .refunded: return "Refunded"
        case .expired: return "Expired"
        }
    }
    
    var isActive: Bool {
        switch self {
        case .pending, .held:
            return true
        case .released, .refunded, .expired:
            return false
        }
    }
}

// MARK: - Escrow Record
struct EscrowRecord: Identifiable, Codable, Equatable {
    let id: String
    let userId: String
    let goalId: String
    let amount: Decimal
    let currency: String
    let status: EscrowStatus
    let heldAt: Date
    let releasedAt: Date?
    let refundedAt: Date?
    let expiredAt: Date?
    let metadata: [String: String]
    
    init(
        id: String = UUID().uuidString,
        userId: String,
        goalId: String,
        amount: Decimal,
        currency: String = "USD",
        status: EscrowStatus = .pending,
        heldAt: Date = Date(),
        releasedAt: Date? = nil,
        refundedAt: Date? = nil,
        expiredAt: Date? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.userId = userId
        self.goalId = goalId
        self.amount = amount
        self.currency = currency
        self.status = status
        self.heldAt = heldAt
        self.releasedAt = releasedAt
        self.refundedAt = refundedAt
        self.expiredAt = expiredAt
        self.metadata = metadata
    }
}

// MARK: - Wallet Limits
struct WalletLimits: Codable, Equatable {
    let dailyLimit: Decimal
    let monthlyLimit: Decimal
    let dailyUsed: Decimal
    let monthlyUsed: Decimal
    let currency: String
    let lastReset: Date
    
    init(
        dailyLimit: Decimal,
        monthlyLimit: Decimal,
        dailyUsed: Decimal = 0,
        monthlyUsed: Decimal = 0,
        currency: String = "USD",
        lastReset: Date = Date()
    ) {
        self.dailyLimit = dailyLimit
        self.monthlyLimit = monthlyLimit
        self.dailyUsed = dailyUsed
        self.monthlyUsed = monthlyUsed
        self.currency = currency
        self.lastReset = lastReset
    }
    
    var dailyRemaining: Decimal {
        max(0, dailyLimit - dailyUsed)
    }
    
    var monthlyRemaining: Decimal {
        max(0, monthlyLimit - monthlyUsed)
    }
    
    var isDailyLimitExceeded: Bool {
        dailyUsed >= dailyLimit
    }
    
    var isMonthlyLimitExceeded: Bool {
        monthlyUsed >= monthlyLimit
    }
}
