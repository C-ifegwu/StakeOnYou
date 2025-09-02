import Foundation

// MARK: - Ledger Entry Entity
struct LedgerEntry: Identifiable, Codable, Equatable {
    let id: String
    let transactionId: String
    let accountId: String
    let accountType: AccountType
    let entryType: EntryType
    let amount: Decimal
    let currency: String
    let description: String
    let reference: String
    let metadata: [String: String]
    let createdAt: Date
    let auditId: String
    
    init(
        id: String = UUID().uuidString,
        transactionId: String,
        accountId: String,
        accountType: AccountType,
        entryType: EntryType,
        amount: Decimal,
        currency: String = "USD",
        description: String,
        reference: String,
        metadata: [String: String] = [:],
        createdAt: Date = Date(),
        auditId: String = UUID().uuidString
    ) {
        self.id = id
        self.transactionId = transactionId
        self.accountId = accountId
        self.accountType = accountType
        self.entryType = entryType
        self.amount = amount
        self.currency = currency
        self.description = description
        self.reference = reference
        self.metadata = metadata
        self.createdAt = createdAt
        self.auditId = auditId
    }
}

// MARK: - Account Type
enum AccountType: String, CaseIterable, Codable {
    case userWallet = "user_wallet"
    case escrowAccount = "escrow_account"
    case feeAccount = "fee_account"
    case charityAccount = "charity_account"
    case appRevenue = "app_revenue"
    case corporateAccount = "corporate_account"
    case groupPool = "group_pool"
    
    var displayName: String {
        switch self {
        case .userWallet: return "User Wallet"
        case .escrowAccount: return "Escrow Account"
        case .feeAccount: return "Fee Account"
        case .charityAccount: return "Charity Account"
        case .appRevenue: return "App Revenue"
        case .corporateAccount: return "Corporate Account"
        case .groupPool: return "Group Pool"
        }
    }
    
    var isLiability: Bool {
        switch self {
        case .userWallet, .escrowAccount, .groupPool:
            return true
        case .feeAccount, .charityAccount, .appRevenue, .corporateAccount:
            return false
        }
    }
    
    var isAsset: Bool {
        !isLiability
    }
}

// MARK: - Entry Type
enum EntryType: String, CaseIterable, Codable {
    case debit = "debit"
    case credit = "credit"
    
    var displayName: String {
        switch self {
        case .debit: return "Debit"
        case .credit: return "Credit"
        }
    }
    
    var opposite: EntryType {
        self == .debit ? .credit : .debit
    }
}

// MARK: - Transaction Record
struct TransactionRecord: Identifiable, Codable, Equatable {
    let id: String
    let type: TransactionRecordType
    let amount: Decimal
    let currency: String
    let description: String
    let status: TransactionStatus
    let ledgerEntries: [LedgerEntry]
    let metadata: [String: String]
    let createdAt: Date
    let processedAt: Date?
    let auditId: String
    
    init(
        id: String = UUID().uuidString,
        type: TransactionRecordType,
        amount: Decimal,
        currency: String = "USD",
        description: String,
        status: TransactionStatus = .pending,
        ledgerEntries: [LedgerEntry] = [],
        metadata: [String: String] = [:],
        createdAt: Date = Date(),
        processedAt: Date? = nil,
        auditId: String = UUID().uuidString
    ) {
        self.id = id
        self.type = type
        self.amount = amount
        self.currency = currency
        self.description = description
        self.status = status
        self.ledgerEntries = ledgerEntries
        self.metadata = metadata
        self.createdAt = createdAt
        self.processedAt = processedAt
        self.auditId = auditId
    }
    
    var isBalanced: Bool {
        let debits = ledgerEntries.filter { $0.entryType == .debit }.reduce(0) { $0 + $1.amount }
        let credits = ledgerEntries.filter { $0.entryType == .credit }.reduce(0) { $0 + $1.amount }
        return debits == credits
    }
    
    var totalDebits: Decimal {
        ledgerEntries.filter { $0.entryType == .debit }.reduce(0) { $0 + $1.amount }
    }
    
    var totalCredits: Decimal {
        ledgerEntries.filter { $0.entryType == .credit }.reduce(0) { $0 + $1.amount }
    }
}

// MARK: - Transaction Record Type
enum TransactionRecordType: String, CaseIterable, Codable {
    case deposit = "deposit"
    case withdrawal = "withdrawal"
    case escrowHold = "escrow_hold"
    case escrowRelease = "escrow_release"
    case feeCapture = "fee_capture"
    case donation = "donation"
    case payout = "payout"
    case refund = "refund"
    case groupDistribution = "group_distribution"
    case corporateTransfer = "corporate_transfer"
    
    var displayName: String {
        switch self {
        case .deposit: return "Deposit"
        case .withdrawal: return "Withdrawal"
        case .escrowHold: return "Escrow Hold"
        case .escrowRelease: return "Escrow Release"
        case .feeCapture: return "Fee Capture"
        case .donation: return "Donation"
        case .payout: return "Payout"
        case .refund: return "Refund"
        case .groupDistribution: return "Group Distribution"
        case .corporateTransfer: return "Corporate Transfer"
        }
    }
}

// MARK: - Transaction Status
enum TransactionStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
    case cancelled = "cancelled"
    case disputed = "disputed"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .processing: return "Processing"
        case .completed: return "Completed"
        case .failed: return "Failed"
        case .cancelled: return "Cancelled"
        case .disputed: return "Disputed"
        }
    }
    
    var isFinal: Bool {
        switch self {
        case .completed, .failed, .cancelled:
            return true
        case .pending, .processing, .disputed:
            return false
        }
    }
}

// MARK: - Audit Trail
struct AuditTrail: Identifiable, Codable, Equatable {
    let id: String
    let action: String
    let entityType: String
    let entityId: String
    let userId: String?
    let changes: [String: String]
    let timestamp: Date
    let ipAddress: String?
    let userAgent: String?
    
    init(
        id: String = UUID().uuidString,
        action: String,
        entityType: String,
        entityId: String,
        userId: String? = nil,
        changes: [String: String] = [:],
        timestamp: Date = Date(),
        ipAddress: String? = nil,
        userAgent: String? = nil
    ) {
        self.id = id
        self.action = action
        self.entityType = entityType
        self.entityId = entityId
        self.userId = userId
        self.changes = changes
        self.timestamp = timestamp
        self.ipAddress = ipAddress
        self.userAgent = userAgent
    }
}

// MARK: - Account Balance
struct AccountBalance: Identifiable, Codable, Equatable {
    let id: String
    let accountId: String
    let accountType: AccountType
    let balance: Decimal
    let currency: String
    let lastUpdated: Date
    
    init(
        id: String = UUID().uuidString,
        accountId: String,
        accountType: AccountType,
        balance: Decimal = 0,
        currency: String = "USD",
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.accountId = accountId
        self.accountType = accountType
        self.balance = balance
        self.currency = currency
        self.lastUpdated = lastUpdated
    }
}
