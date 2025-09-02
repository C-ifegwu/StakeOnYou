import Foundation

// MARK: - Escrow Status
enum EscrowStatus: String, Codable, CaseIterable, Equatable {
    case held = "HELD"
    case released = "RELEASED"
    case forfeited = "FORFEITED"
    case refunded = "REFUNDED"
    case pendingDistribution = "PENDING_DISTRIBUTION"
    case partial = "PARTIAL"
}

// MARK: - Escrow Stakeholder
struct EscrowStakeholder: Codable, Equatable, Identifiable {
    let id: String
    let userId: String
    let stakeId: String
    let principal: Decimal
    
    init(id: String = UUID().uuidString, userId: String, stakeId: String, principal: Decimal) {
        self.id = id
        self.userId = userId
        self.stakeId = stakeId
        self.principal = principal
    }
}

// MARK: - Escrow
struct Escrow: Identifiable, Codable, Equatable {
    let id: String
    let goalId: String
    let stakeholders: [EscrowStakeholder]
    let totalPrincipal: Decimal
    var accruedAmount: Decimal
    let holdRef: String
    let currency: String
    var status: EscrowStatus
    let createdAt: Date
    var updatedAt: Date
    var releaseTxRefs: [String]
    
    init(
        id: String = UUID().uuidString,
        goalId: String,
        stakeholders: [EscrowStakeholder],
        accruedAmount: Decimal = 0,
        holdRef: String,
        currency: String = "USD",
        status: EscrowStatus = .held,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        releaseTxRefs: [String] = []
    ) {
        self.id = id
        self.goalId = goalId
        self.stakeholders = stakeholders
        self.totalPrincipal = stakeholders.reduce(0) { $0 + $1.principal }
        self.accruedAmount = accruedAmount
        self.holdRef = holdRef
        self.currency = currency
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.releaseTxRefs = releaseTxRefs
    }
}

// MARK: - Distribution Plan
enum DistributionType: String, Codable, CaseIterable, Equatable {
    case individual = "INDIVIDUAL"
    case group = "GROUP"
    case corporate = "CORPORATE"
}

struct DistributionWinner: Codable, Equatable, Identifiable {
    let id: String
    let userId: String
    let sharePercent: Decimal
    
    init(id: String = UUID().uuidString, userId: String, sharePercent: Decimal) {
        self.id = id
        self.userId = userId
        self.sharePercent = sharePercent
    }
}

struct DistributionRules: Codable, Equatable {
    var charityPercent: Decimal
    var appPercent: Decimal
    var winnersRule: String?
}

struct DistributionPlan: Identifiable, Codable, Equatable {
    let id: String
    let goalId: String
    let type: DistributionType
    let rules: DistributionRules
    let charityId: String?
    let winners: [DistributionWinner]
    
    init(
        id: String = UUID().uuidString,
        goalId: String,
        type: DistributionType,
        rules: DistributionRules,
        charityId: String? = nil,
        winners: [DistributionWinner] = []
    ) {
        self.id = id
        self.goalId = goalId
        self.type = type
        self.rules = rules
        self.charityId = charityId
        self.winners = winners
    }
}

// MARK: - Dispute
enum DisputeStatus: String, Codable, CaseIterable, Equatable {
    case open = "OPEN"
    case resolved = "RESOLVED"
    case rejected = "REJECTED"
}

struct Dispute: Identifiable, Codable, Equatable {
    let id: String
    let goalId: String
    let filedBy: String
    let reason: String
    let evidenceRefs: [String]
    var status: DisputeStatus
    let createdAt: Date
    var resolvedAt: Date?
    var decisionBy: String?
}

// MARK: - Escrow Transaction
enum EscrowTransactionType: String, Codable, CaseIterable, Equatable {
    case hold = "HOLD"
    case release = "RELEASE"
    case forfeit = "FORFEIT"
    case refund = "REFUND"
    case fee = "FEE"
}

struct EscrowTransaction: Identifiable, Codable, Equatable {
    let id: String
    let escrowId: String
    let type: EscrowTransactionType
    let amount: Decimal
    let currency: String
    let feeApplied: Decimal
    let relatedTxRef: String
    let createdAt: Date
    
    init(
        id: String = UUID().uuidString,
        escrowId: String,
        type: EscrowTransactionType,
        amount: Decimal,
        currency: String = "USD",
        feeApplied: Decimal = 0,
        relatedTxRef: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.escrowId = escrowId
        self.type = type
        self.amount = amount
        self.currency = currency
        self.feeApplied = feeApplied
        self.relatedTxRef = relatedTxRef
        self.createdAt = createdAt
    }
}

// MARK: - Goal Escrow Summary
struct GoalEscrowSummary: Codable, Equatable {
    let goalId: String
    let escrowId: String
    let totalPrincipal: Decimal
    let accruedAmount: Decimal
    let pendingDistribution: Bool
    let nextActionAt: Date?
}
