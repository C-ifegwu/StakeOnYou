import Foundation

// MARK: - Transaction Entity
struct Transaction: Identifiable, Codable, Equatable {
    let id: String
    let type: TransactionType
    let amount: Decimal
    let currency: String
    let feeApplied: Decimal
    let status: TransactionStatus
    let createdAt: Date
    let updatedAt: Date
    
    // Optional fields
    let description: String?
    let goalId: String?
    let stakeId: String?
    let userId: String?
    let groupId: String?
    let corporateAccountId: String?
    let charityId: String?
    let referenceId: String?
    let metadata: [String: String]
    let notes: [TransactionNote]
    
    init(
        id: String = UUID().uuidString,
        type: TransactionType,
        amount: Decimal,
        currency: String = "USD",
        feeApplied: Decimal = 0,
        status: TransactionStatus = .pending,
        description: String? = nil,
        goalId: String? = nil,
        stakeId: String? = nil,
        userId: String? = nil,
        groupId: String? = nil,
        corporateAccountId: String? = nil,
        charityId: String? = nil,
        referenceId: String? = nil,
        metadata: [String: String] = [:],
        notes: [TransactionNote] = []
    ) {
        self.id = id
        self.type = type
        self.amount = amount
        self.currency = currency
        self.feeApplied = feeApplied
        self.status = status
        self.createdAt = Date()
        self.updatedAt = Date()
        self.description = description
        self.goalId = goalId
        self.stakeId = stakeId
        self.userId = userId
        self.groupId = groupId
        self.corporateAccountId = corporateAccountId
        self.charityId = charityId
        self.referenceId = referenceId
        self.metadata = metadata
        self.notes = notes
    }
}

// MARK: - Transaction Type
enum TransactionType: String, Codable, CaseIterable {
    case stakeCreation = "stake_creation"
    case stakeWithdrawal = "stake_withdrawal"
    case stakeForfeiture = "stake_forfeiture"
    case stakeCompletion = "stake_completion"
    case feeCollection = "fee_collection"
    case charityDonation = "charity_donation"
    case corporateMatching = "corporate_matching"
    case groupDistribution = "group_distribution"
    case refund = "refund"
    case adjustment = "adjustment"
    
    var displayName: String {
        switch self {
        case .stakeCreation: return "Stake Creation"
        case .stakeWithdrawal: return "Stake Withdrawal"
        case .stakeForfeiture: return "Stake Forfeiture"
        case .stakeCompletion: return "Stake Completion"
        case .feeCollection: return "Fee Collection"
        case .charityDonation: return "Charity Donation"
        case .corporateMatching: return "Corporate Matching"
        case .groupDistribution: return "Group Distribution"
        case .refund: return "Refund"
        case .adjustment: return "Adjustment"
        }
    }
    
    var isDebit: Bool {
        switch self {
        case .stakeCreation, .feeCollection, .charityDonation:
            return true
        case .stakeWithdrawal, .stakeCompletion, .corporateMatching, .groupDistribution, .refund, .adjustment:
            return false
        }
    }
    
    var isCredit: Bool {
        return !isDebit
    }
    
    var requiresApproval: Bool {
        switch self {
        case .stakeWithdrawal, .refund, .adjustment:
            return true
        default:
            return false
        }
    }
    
    var isReversible: Bool {
        switch self {
        case .stakeCreation, .stakeWithdrawal, .feeCollection:
            return true
        default:
            return false
        }
    }
}

// MARK: - Transaction Status
enum TransactionStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
    case cancelled = "cancelled"
    case disputed = "disputed"
    case reversed = "reversed"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .processing: return "Processing"
        case .completed: return "Completed"
        case .failed: return "Failed"
        case .cancelled: return "Cancelled"
        case .disputed: return "Disputed"
        case .reversed: return "Reversed"
        }
    }
    
    var isFinal: Bool {
        return self == .completed || self == .failed || self == .cancelled
    }
    
    var isActive: Bool {
        return self == .pending || self == .processing
    }
    
    var canBeReversed: Bool {
        return self == .completed
    }
    
    var color: String {
        switch self {
        case .pending: return "warning"
        case .processing: return "info"
        case .completed: return "success"
        case .failed: return "error"
        case .cancelled: return "secondary"
        case .disputed: return "warning"
        case .reversed: return "secondary"
        }
    }
}

// MARK: - Transaction Note
struct TransactionNote: Identifiable, Codable, Equatable {
    let id: String
    let content: String
    let authorId: String
    let createdAt: Date
    let updatedAt: Date
    let type: NoteType
    let isInternal: Bool
    
    init(
        id: String = UUID().uuidString,
        content: String,
        authorId: String,
        type: NoteType = .general,
        isInternal: Bool = false
    ) {
        self.id = id
        self.content = content
        self.authorId = authorId
        self.createdAt = Date()
        self.updatedAt = Date()
        self.type = type
        self.isInternal = isInternal
    }
}

enum NoteType: String, Codable, CaseIterable {
    case general = "general"
    case approval = "approval"
    case rejection = "rejection"
    case dispute = "dispute"
    case resolution = "resolution"
    case system = "system"
    
    var displayName: String {
        switch self {
        case .general: return "General"
        case .approval: return "Approval"
        case .rejection: return "Rejection"
        case .dispute: return "Dispute"
        case .resolution: return "Resolution"
        case .system: return "System"
        }
    }
}

// MARK: - Transaction Extensions
extension Transaction {
    var netAmount: Decimal {
        return isDebit ? amount + feeApplied : amount - feeApplied
    }
    
    var totalAmount: Decimal {
        return amount + feeApplied
    }
    
    var isStakeRelated: Bool {
        return stakeId != nil
    }
    
    var isGoalRelated: Bool {
        return goalId != nil
    }
    
    var isGroupRelated: Bool {
        return groupId != nil
    }
    
    var isCorporateRelated: Bool {
        return corporateAccountId != nil
    }
    
    var isCharityRelated: Bool {
        return charityId != nil
    }
    
    var isFeeTransaction: Bool {
        return type == .feeCollection
    }
    
    var isDonationTransaction: Bool {
        return type == .charityDonation
    }
    
    var isMatchingTransaction: Bool {
        return type == .corporateMatching
    }
    
    var canBeDisputed: Bool {
        return status == .completed && type.isReversible
    }
    
    var canBeReversed: Bool {
        return status.canBeReversed && type.isReversible
    }
    
    var requiresUserApproval: Bool {
        return type.requiresApproval && userId != nil
    }
    
    var displayDescription: String {
        if let description = description, !description.isEmpty {
            return description
        }
        return type.displayName
    }
}

// MARK: - Transaction Validation
extension Transaction {
    var validationErrors: [String] {
        var errors: [String] = []
        
        if amount <= 0 {
            errors.append("Transaction amount must be greater than zero")
        }
        
        if feeApplied < 0 {
            errors.append("Fee cannot be negative")
        }
        
        if currency.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Currency is required")
        }
        
        if type == .stakeCreation && stakeId == nil {
            errors.append("Stake ID is required for stake creation")
        }
        
        if type == .stakeWithdrawal && stakeId == nil {
            errors.append("Stake ID is required for stake withdrawal")
        }
        
        if type == .charityDonation && charityId == nil {
            errors.append("Charity ID is required for charity donation")
        }
        
        if type == .corporateMatching && corporateAccountId == nil {
            errors.append("Corporate account ID is required for corporate matching")
        }
        
        return errors
    }
    
    var isValid: Bool {
        return validationErrors.isEmpty
    }
}

// MARK: - Transaction Filtering
extension Transaction {
    func matchesType(_ type: TransactionType?) -> Bool {
        guard let type = type else { return true }
        return self.type == type
    }
    
    func matchesStatus(_ status: TransactionStatus?) -> Bool {
        guard let status = status else { return true }
        return self.status == status
    }
    
    func matchesUser(_ userId: String?) -> Bool {
        guard let userId = userId else { return true }
        return self.userId == userId
    }
    
    func matchesGoal(_ goalId: String?) -> Bool {
        guard let goalId = goalId else { return true }
        return self.goalId == goalId
    }
    
    func matchesStake(_ stakeId: String?) -> Bool {
        guard let stakeId = stakeId else { return true }
        return self.stakeId == stakeId
    }
    
    func matchesGroup(_ groupId: String?) -> Bool {
        guard let groupId = groupId else { return true }
        return self.groupId == groupId
    }
    
    func matchesCorporateAccount(_ corporateAccountId: String?) -> Bool {
        guard let corporateAccountId = corporateAccountId else { return true }
        return self.corporateAccountId == corporateAccountId
    }
    
    func matchesCharity(_ charityId: String?) -> Bool {
        guard let charityId = charityId else { return true }
        return self.charityId == charityId
    }
    
    func matchesDateRange(_ startDate: Date?, _ endDate: Date?) -> Bool {
        if let startDate = startDate, createdAt < startDate {
            return false
        }
        if let endDate = endDate, createdAt > endDate {
            return false
        }
        return true
    }
    
    func matchesAmountRange(_ minAmount: Decimal?, _ maxAmount: Decimal?) -> Bool {
        if let minAmount = minAmount, amount < minAmount {
            return false
        }
        if let maxAmount = maxAmount, amount > maxAmount {
            return false
        }
        return true
    }
}

// MARK: - Transaction Analytics
extension Transaction {
    var isSuccessful: Bool {
        return status == .completed
    }
    
    var isFailed: Bool {
        return status == .failed
    }
    
    var isPending: Bool {
        return status == .pending || status == .processing
    }
    
    var processingTime: TimeInterval? {
        guard status == .completed else { return nil }
        return updatedAt.timeIntervalSince(createdAt)
    }
    
    var isHighValue: Bool {
        return amount >= 1000 // $1000 threshold
    }
    
    var isLowValue: Bool {
        return amount <= 10 // $10 threshold
    }
    
    var feePercentage: Decimal {
        guard amount > 0 else { return 0 }
        return (feeApplied / amount) * 100
    }
    
    var isHighFeeTransaction: Bool {
        return feePercentage > 10 // 10% threshold
    }
}
