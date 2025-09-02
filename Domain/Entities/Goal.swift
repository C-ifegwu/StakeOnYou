import Foundation

// MARK: - Goal Entity
struct Goal: Identifiable, Codable, Equatable {
    let id: String
    let ownerId: String
    let title: String
    let description: String
    let category: GoalCategory
    let startDate: Date
    let endDate: Date
    let stakeAmount: Decimal
    let stakeCurrency: String
    let verificationMethod: VerificationMethod
    let status: GoalStatus
    let createdAt: Date
    let updatedAt: Date
    
    // Optional fields
    let tags: [String]
    let milestones: [Milestone]
    let attachments: [GoalAttachment]
    let notes: [GoalNote]
    let collaborators: [String] // User IDs
    let groupId: String?
    let corporateAccountId: String?
    
    init(
        id: String = UUID().uuidString,
        ownerId: String,
        title: String,
        description: String,
        category: GoalCategory,
        startDate: Date,
        endDate: Date,
        stakeAmount: Decimal,
        stakeCurrency: String = "USD",
        verificationMethod: VerificationMethod,
        tags: [String] = [],
        milestones: [Milestone] = [],
        attachments: [GoalAttachment] = [],
        notes: [GoalNote] = [],
        collaborators: [String] = [],
        groupId: String? = nil,
        corporateAccountId: String? = nil
    ) {
        self.id = id
        self.ownerId = ownerId
        self.title = title
        self.description = description
        self.category = category
        self.startDate = startDate
        self.endDate = endDate
        self.stakeAmount = stakeAmount
        self.stakeCurrency = stakeCurrency
        self.verificationMethod = verificationMethod
        self.status = .active
        self.createdAt = Date()
        self.updatedAt = Date()
        self.tags = tags
        self.milestones = milestones
        self.attachments = attachments
        self.notes = notes
        self.collaborators = collaborators
        self.groupId = groupId
        self.corporateAccountId = corporateAccountId
    }
}

// MARK: - Goal Category
enum GoalCategory: String, Codable, CaseIterable {
    case fitness = "fitness"
    case learning = "learning"
    case career = "career"
    case health = "health"
    case finance = "finance"
    case social = "social"
    case creative = "creative"
    case travel = "travel"
    case home = "home"
    case spiritual = "spiritual"
    case environmental = "environmental"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .fitness: return "Fitness & Exercise"
        case .learning: return "Learning & Education"
        case .career: return "Career & Professional"
        case .health: return "Health & Wellness"
        case .finance: return "Finance & Money"
        case .social: return "Social & Relationships"
        case .creative: return "Creative & Arts"
        case .travel: return "Travel & Adventure"
        case .home: return "Home & Family"
        case .spiritual: return "Spiritual & Personal"
        case .environmental: return "Environmental"
        case .other: return "Other"
        }
    }
    
    var iconName: String {
        switch self {
        case .fitness: return "figure.run"
        case .learning: return "book.fill"
        case .career: return "briefcase.fill"
        case .health: return "heart.fill"
        case .finance: return "dollarsign.circle.fill"
        case .social: return "person.2.fill"
        case .creative: return "paintbrush.fill"
        case .travel: return "airplane"
        case .home: return "house.fill"
        case .spiritual: return "sparkles"
        case .environmental: return "leaf.fill"
        case .other: return "star.fill"
        }
    }
    
    var color: String {
        switch self {
        case .fitness: return "fitness"
        case .learning: return "learning"
        case .career: return "career"
        case .health: return "health"
        case .finance: return "finance"
        case .social: return "social"
        case .creative: return "creative"
        case .travel: return "travel"
        case .home: return "home"
        case .spiritual: return "spiritual"
        case .environmental: return "environmental"
        case .other: return "other"
        }
    }
}

// MARK: - Verification Method
enum VerificationMethod: String, Codable, CaseIterable {
    case manual = "manual"
    case photo = "photo"
    case video = "video"
    case document = "document"
    case thirdParty = "third_party"
    case screenTime = "screen_time"
    case healthKit = "health_kit"
    case location = "location"
    case timeTracking = "time_tracking"
    case peerReview = "peer_review"
    
    var displayName: String {
        switch self {
        case .manual: return "Manual Verification"
        case .photo: return "Photo Evidence"
        case .video: return "Video Evidence"
        case .document: return "Document Upload"
        case .thirdParty: return "Third-Party Verification"
        case .screenTime: return "Screen Time Data"
        case .healthKit: return "Health Data"
        case .location: return "Location Check-in"
        case .timeTracking: return "Time Tracking"
        case .peerReview: return "Peer Review"
        }
    }
    
    var requiresEvidence: Bool {
        switch self {
        case .manual: return false
        case .photo, .video, .document, .thirdParty: return true
        case .screenTime, .healthKit, .location, .timeTracking: return false
        case .peerReview: return true
        }
    }
}

// MARK: - Goal Status
enum GoalStatus: String, Codable, CaseIterable {
    case draft = "draft"
    case active = "active"
    case paused = "paused"
    case completed = "completed"
    case failed = "failed"
    case cancelled = "cancelled"
    case disputed = "disputed"
    
    var displayName: String {
        switch self {
        case .draft: return "Draft"
        case .active: return "Active"
        case .paused: return "Paused"
        case .completed: return "Completed"
        case .failed: return "Failed"
        case .cancelled: return "Cancelled"
        case .disputed: return "Disputed"
        }
    }
    
    var isActive: Bool {
        return self == .active || self == .paused
    }
    
    var isFinal: Bool {
        return self == .completed || self == .failed || self == .cancelled
    }
    
    var canBeModified: Bool {
        return self == .draft || self == .active
    }
}

// MARK: - Milestone
struct Milestone: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let description: String
    let targetDate: Date
    let isCompleted: Bool
    let completedAt: Date?
    let evidence: [MilestoneEvidence]
    
    init(
        id: String = UUID().uuidString,
        title: String,
        description: String,
        targetDate: Date,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        evidence: [MilestoneEvidence] = []
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.targetDate = targetDate
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.evidence = evidence
    }
}

struct MilestoneEvidence: Identifiable, Codable, Equatable {
    let id: String
    let type: EvidenceType
    let url: URL?
    let description: String
    let submittedAt: Date
    let verified: Bool
    let verifiedAt: Date?
    let verifiedBy: String?
    
    init(
        id: String = UUID().uuidString,
        type: EvidenceType,
        url: URL? = nil,
        description: String,
        submittedAt: Date = Date(),
        verified: Bool = false,
        verifiedAt: Date? = nil,
        verifiedBy: String? = nil
    ) {
        self.id = id
        self.type = type
        self.url = url
        self.description = description
        self.submittedAt = submittedAt
        self.verified = verified
        self.verifiedAt = verifiedAt
        self.verifiedBy = verifiedBy
    }
}

enum EvidenceType: String, Codable, CaseIterable {
    case photo = "photo"
    case video = "video"
    case document = "document"
    case link = "link"
    case text = "text"
    case data = "data"
}

// MARK: - Goal Attachment
struct GoalAttachment: Identifiable, Codable, Equatable {
    let id: String
    let type: AttachmentType
    let url: URL
    let filename: String
    let size: Int64
    let mimeType: String
    let uploadedAt: Date
    let uploadedBy: String
    
    init(
        id: String = UUID().uuidString,
        type: AttachmentType,
        url: URL,
        filename: String,
        size: Int64,
        mimeType: String,
        uploadedBy: String
    ) {
        self.id = id
        self.type = type
        self.url = url
        self.filename = filename
        self.size = size
        self.mimeType = mimeType
        self.uploadedAt = Date()
        self.uploadedBy = uploadedBy
    }
}

enum AttachmentType: String, Codable, CaseIterable {
    case image = "image"
    case video = "video"
    case document = "document"
    case audio = "audio"
    case archive = "archive"
    case other = "other"
}

// MARK: - Goal Note
struct GoalNote: Identifiable, Codable, Equatable {
    let id: String
    let content: String
    let authorId: String
    let createdAt: Date
    let updatedAt: Date
    let isPrivate: Bool
    
    init(
        id: String = UUID().uuidString,
        content: String,
        authorId: String,
        isPrivate: Bool = false
    ) {
        self.id = id
        self.content = content
        self.authorId = authorId
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isPrivate = isPrivate
    }
}

// MARK: - Goal Extensions
extension Goal {
    var duration: TimeInterval {
        return endDate.timeIntervalSince(startDate)
    }
    
    var daysRemaining: Int {
        let remaining = endDate.timeIntervalSinceNow
        return max(0, Int(remaining / 86400))
    }
    
    var isOverdue: Bool {
        return endDate < Date() && status == .active
    }
    
    var progress: Double {
        let totalMilestones = milestones.count
        guard totalMilestones > 0 else { return 0.0 }
        
        let completedMilestones = milestones.filter { $0.isCompleted }.count
        return Double(completedMilestones) / Double(totalMilestones)
    }
    
    var nextMilestone: Milestone? {
        return milestones
            .filter { !$0.isCompleted }
            .sorted { $0.targetDate < $1.targetDate }
            .first
    }
    
    var isGroupGoal: Bool {
        return groupId != nil
    }
    
    var isCorporateGoal: Bool {
        return corporateAccountId != nil
    }
    
    var canBeCompleted: Bool {
        return status == .active && !isOverdue
    }
    
    var requiresVerification: Bool {
        return verificationMethod.requiresEvidence
    }
}

// MARK: - Goal Validation
extension Goal {
    var validationErrors: [String] {
        var errors: [String] = []
        
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Goal title is required")
        }
        
        if description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Goal description is required")
        }
        
        if startDate >= endDate {
            errors.append("Start date must be before end date")
        }
        
        if stakeAmount <= 0 {
            errors.append("Stake amount must be greater than zero")
        }
        
        if endDate < Date() {
            errors.append("End date cannot be in the past")
        }
        
        return errors
    }
    
    var isValid: Bool {
        return validationErrors.isEmpty
    }
}
