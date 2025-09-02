import Foundation

// MARK: - Wallet Entity
struct Wallet: Identifiable, Codable, Equatable {
    let id: String
    let userId: String
    let balance: Decimal
    let availableBalance: Decimal
    let escrowBalance: Decimal
    let currency: String
    let status: WalletStatus
    let kycStatus: KYCStatus
    let dailyLimit: Decimal
    let monthlyLimit: Decimal
    let createdAt: Date
    let updatedAt: Date
    let lastActivityAt: Date
    
    init(
        id: String = UUID().uuidString,
        userId: String,
        balance: Decimal = 0,
        availableBalance: Decimal = 0,
        escrowBalance: Decimal = 0,
        currency: String = "USD",
        status: WalletStatus = .active,
        kycStatus: KYCStatus = .unverified,
        dailyLimit: Decimal = 1000,
        monthlyLimit: Decimal = 10000,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        lastActivityAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.balance = balance
        self.availableBalance = availableBalance
        self.escrowBalance = escrowBalance
        self.currency = currency
        self.status = status
        self.kycStatus = kycStatus
        self.dailyLimit = dailyLimit
        self.monthlyLimit = monthlyLimit
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastActivityAt = lastActivityAt
    }
    
    var totalBalance: Decimal {
        balance + escrowBalance
    }
    
    var canDeposit: Bool {
        status == .active && kycStatus != .blocked
    }
    
    var canWithdraw: Bool {
        status == .active && kycStatus == .verified && availableBalance > 0
    }
    
    var canStake: Bool {
        status == .active && availableBalance > 0
    }
}

// MARK: - Wallet Status
enum WalletStatus: String, CaseIterable, Codable {
    case active = "active"
    case suspended = "suspended"
    case frozen = "frozen"
    case closed = "closed"
    
    var displayName: String {
        switch self {
        case .active: return "Active"
        case .suspended: return "Suspended"
        case .frozen: return "Frozen"
        case .closed: return "Closed"
        }
    }
    
    var isOperational: Bool {
        self == .active
    }
}

// MARK: - KYC Status
enum KYCStatus: String, CaseIterable, Codable {
    case unverified = "unverified"
    case limited = "limited"
    case verified = "verified"
    case blocked = "blocked"
    
    var displayName: String {
        switch self {
        case .unverified: return "Unverified"
        case .limited: return "Limited"
        case .verified: return "Verified"
        case .blocked: return "Blocked"
        }
    }
    
    var dailyLimit: Decimal {
        switch self {
        case .unverified: return 100
        case .limited: return 500
        case .verified: return 10000
        case .blocked: return 0
        }
    }
    
    var monthlyLimit: Decimal {
        switch self {
        case .unverified: return 1000
        case .limited: return 5000
        case .verified: return 100000
        case .blocked: return 0
        }
    }
    
    var canStake: Bool {
        self != .blocked
    }
}

// MARK: - Wallet Transaction
struct WalletTransaction: Identifiable, Codable, Equatable {
    let id: String
    let walletId: String
    let paymentId: String
    let type: TransactionType
    let amount: Decimal
    let balanceBefore: Decimal
    let balanceAfter: Decimal
    let description: String
    let reference: String
    let createdAt: Date
    
    init(
        id: String = UUID().uuidString,
        walletId: String,
        paymentId: String,
        type: TransactionType,
        amount: Decimal,
        balanceBefore: Decimal,
        balanceAfter: Decimal,
        description: String,
        reference: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.walletId = walletId
        self.paymentId = paymentId
        self.type = type
        self.amount = amount
        self.balanceBefore = balanceBefore
        self.balanceAfter = balanceAfter
        self.description = description
        self.reference = reference
        self.createdAt = createdAt
    }
}

// MARK: - Transaction Type
enum TransactionType: String, CaseIterable, Codable {
    case credit = "credit"
    case debit = "debit"
    case escrowHold = "escrow_hold"
    case escrowRelease = "escrow_release"
    case fee = "fee"
    
    var displayName: String {
        switch self {
        case .credit: return "Credit"
        case .debit: return "Debit"
        case .escrowHold: return "Escrow Hold"
        case .escrowRelease: return "Escrow Release"
        case .fee: return "Fee"
        }
    }
    
    var isCredit: Bool {
        self == .credit || self == .escrowRelease
    }
    
    var isDebit: Bool {
        self == .debit || self == .escrowHold || self == .fee
    }
}
