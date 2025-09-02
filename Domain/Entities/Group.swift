import Foundation

// MARK: - Group Entity
struct Group: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let description: String
    let ownerId: String
    let memberIds: [String]
    let rules: GroupRules
    let settings: GroupSettings
    let createdAt: Date
    let updatedAt: Date
    
    // Optional fields
    let avatarURL: URL?
    let tags: [String]
    let category: GroupCategory
    let maxMembers: Int?
    let isPublic: Bool
    let inviteCode: String?
    let goals: [String] // Goal IDs
    let stakes: [String] // Stake IDs
    
    init(
        id: String = UUID().uuidString,
        name: String,
        description: String,
        ownerId: String,
        memberIds: [String] = [],
        rules: GroupRules = GroupRules(),
        settings: GroupSettings = GroupSettings(),
        avatarURL: URL? = nil,
        tags: [String] = [],
        category: GroupCategory = .general,
        maxMembers: Int? = nil,
        isPublic: Bool = false,
        inviteCode: String? = nil,
        goals: [String] = [],
        stakes: [String] = []
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.ownerId = ownerId
        self.memberIds = memberIds
        self.rules = rules
        self.settings = settings
        self.createdAt = Date()
        self.updatedAt = Date()
        self.avatarURL = avatarURL
        self.tags = tags
        self.category = category
        self.maxMembers = maxMembers
        self.isPublic = isPublic
        self.inviteCode = inviteCode
        self.goals = goals
        self.stakes = stakes
    }
}

// MARK: - Group Category
enum GroupCategory: String, Codable, CaseIterable {
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
    case general = "general"
    
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
        case .general: return "General"
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
        case .general: return "star.fill"
        }
    }
}

// MARK: - Group Rules
struct GroupRules: Codable, Equatable {
    var goalCreationPolicy: GoalCreationPolicy
    var stakePolicy: StakePolicy
    var verificationPolicy: VerificationPolicy
    var disputeResolution: DisputeResolution
    var forfeitureDistribution: ForfeitDistributionPolicy
    var memberPermissions: MemberPermissions
    
    init(
        goalCreationPolicy: GoalCreationPolicy = .ownerOnly,
        stakePolicy: StakePolicy = .allMembers,
        verificationPolicy: VerificationPolicy = .peerReview,
        disputeResolution: DisputeResolution = .majorityVote,
        forfeitureDistribution: ForfeitDistributionPolicy = .proRata,
        memberPermissions: MemberPermissions = MemberPermissions()
    ) {
        self.goalCreationPolicy = goalCreationPolicy
        self.stakePolicy = stakePolicy
        self.verificationPolicy = verificationPolicy
        self.disputeResolution = disputeResolution
        self.forfeitureDistribution = forfeitureDistribution
        self.memberPermissions = memberPermissions
    }
}

enum GoalCreationPolicy: String, Codable, CaseIterable {
    case ownerOnly = "owner_only"
    case allMembers = "all_members"
    case approvedMembers = "approved_members"
    case adminOnly = "admin_only"
    
    var displayName: String {
        switch self {
        case .ownerOnly: return "Owner Only"
        case .allMembers: return "All Members"
        case .approvedMembers: return "Approved Members"
        case .adminOnly: return "Admins Only"
        }
    }
}

enum StakePolicy: String, Codable, CaseIterable {
    case allMembers = "all_members"
    case ownerOnly = "owner_only"
    case approvedMembers = "approved_members"
    case none = "none"
    
    var displayName: String {
        switch self {
        case .allMembers: return "All Members"
        case .ownerOnly: return "Owner Only"
        case .approvedMembers: return "Approved Members"
        case .none: return "No Staking"
        }
    }
}

enum VerificationPolicy: String, Codable, CaseIterable {
    case ownerOnly = "owner_only"
    case peerReview = "peer_review"
    case majorityVote = "majority_vote"
    case unanimous = "unanimous"
    case thirdParty = "third_party"
    
    var displayName: String {
        switch self {
        case .ownerOnly: return "Owner Only"
        case .peerReview: return "Peer Review"
        case .majorityVote: return "Majority Vote"
        case .unanimous: return "Unanimous"
        case .thirdParty: return "Third Party"
        }
    }
}

enum DisputeResolution: String, Codable, CaseIterable {
    case ownerDecision = "owner_decision"
    case majorityVote = "majority_vote"
    case unanimous = "unanimous"
    case thirdParty = "third_party"
    case appSupport = "app_support"
    
    var displayName: String {
        switch self {
        case .ownerDecision: return "Owner Decision"
        case .majorityVote: return "Majority Vote"
        case .unanimous: return "Unanimous"
        case .thirdParty: return "Third Party"
        case .appSupport: return "App Support"
        }
    }
}

enum ForfeitDistributionPolicy: String, Codable, CaseIterable {
    case proRata = "pro_rata"
    case equal = "equal"
    case winnerTakesAll = "winner_takes_all"
    case charityOnly = "charity_only"
    
    var displayName: String {
        switch self {
        case .proRata: return "Pro Rata"
        case .equal: return "Equal Split"
        case .winnerTakesAll: return "Winner Takes All"
        case .charityOnly: return "Charity Only"
        }
    }
}

// MARK: - Member Permissions
struct MemberPermissions: Codable, Equatable {
    var canInviteMembers: Bool
    var canRemoveMembers: Bool
    var canModifyRules: Bool
    var canCreateGoals: Bool
    var canCreateStakes: Bool
    var canVerifyGoals: Bool
    var canViewAnalytics: Bool
    var canModifySettings: Bool
    
    init(
        canInviteMembers: Bool = false,
        canRemoveMembers: Bool = false,
        canModifyRules: Bool = false,
        canCreateGoals: Bool = true,
        canCreateStakes: Bool = true,
        canVerifyGoals: Bool = true,
        canViewAnalytics: Bool = true,
        canModifySettings: Bool = false
    ) {
        self.canInviteMembers = canInviteMembers
        self.canRemoveMembers = canRemoveMembers
        self.canModifyRules = canModifyRules
        self.canCreateGoals = canCreateGoals
        self.canCreateStakes = canCreateStakes
        self.canVerifyGoals = canVerifyGoals
        self.canViewAnalytics = canViewAnalytics
        self.canModifySettings = canModifySettings
    }
}

// MARK: - Group Settings
struct GroupSettings: Codable, Equatable {
    var notifications: GroupNotificationSettings
    var privacy: GroupPrivacySettings
    var moderation: GroupModerationSettings
    var analytics: GroupAnalyticsSettings
    
    init(
        notifications: GroupNotificationSettings = GroupNotificationSettings(),
        privacy: GroupPrivacySettings = GroupPrivacySettings(),
        moderation: GroupModerationSettings = GroupModerationSettings(),
        analytics: GroupAnalyticsSettings = GroupAnalyticsSettings()
    ) {
        self.notifications = notifications
        self.privacy = privacy
        self.moderation = moderation
        self.analytics = analytics
    }
}

struct GroupNotificationSettings: Codable, Equatable {
    var newMemberJoined: Bool
    var goalCreated: Bool
    var goalCompleted: Bool
    var goalFailed: Bool
    var stakeCreated: Bool
    var disputeRaised: Bool
    var weeklyReport: Bool
    
    init(
        newMemberJoined: Bool = true,
        goalCreated: Bool = true,
        goalCompleted: Bool = true,
        goalFailed: Bool = true,
        stakeCreated: Bool = true,
        disputeRaised: Bool = true,
        weeklyReport: Bool = false
    ) {
        self.newMemberJoined = newMemberJoined
        self.goalCreated = goalCreated
        self.goalCompleted = goalCompleted
        self.goalFailed = goalFailed
        self.stakeCreated = stakeCreated
        self.disputeRaised = disputeRaised
        self.weeklyReport = weeklyReport
    }
}

struct GroupPrivacySettings: Codable, Equatable {
    var isVisibleToPublic: Bool
    var showMemberList: Bool
    var showGoalProgress: Bool
    var showStakeAmounts: Bool
    var allowMemberInvites: Bool
    var requireApprovalToJoin: Bool
    
    init(
        isVisibleToPublic: Bool = false,
        showMemberList: Bool = true,
        showGoalProgress: Bool = true,
        showStakeAmounts: Bool = false,
        allowMemberInvites: Bool = true,
        requireApprovalToJoin: Bool = false
    ) {
        self.isVisibleToPublic = isVisibleToPublic
        self.showMemberList = showMemberList
        self.showGoalProgress = showGoalProgress
        self.showStakeAmounts = showStakeAmounts
        self.allowMemberInvites = allowMemberInvites
        self.requireApprovalToJoin = requireApprovalToJoin
    }
}

struct GroupModerationSettings: Codable, Equatable {
    var autoApproveMembers: Bool
    var requireGoalApproval: Bool
    var allowDisputes: Bool
    var maxDisputesPerMember: Int
    var autoResolveDisputes: Bool
    var disputeResolutionTime: TimeInterval
    
    init(
        autoApproveMembers: Bool = true,
        requireGoalApproval: Bool = false,
        allowDisputes: Bool = true,
        maxDisputesPerMember: Int = 3,
        autoResolveDisputes: Bool = false,
        disputeResolutionTime: TimeInterval = 7 * 24 * 60 * 60 // 7 days
    ) {
        self.autoApproveMembers = autoApproveMembers
        self.requireGoalApproval = requireGoalApproval
        self.allowDisputes = allowDisputes
        self.maxDisputesPerMember = maxDisputesPerMember
        self.autoResolveDisputes = autoResolveDisputes
        self.disputeResolutionTime = disputeResolutionTime
    }
}

struct GroupAnalyticsSettings: Codable, Equatable {
    var trackMemberActivity: Bool
    var trackGoalProgress: Bool
    var trackStakePerformance: Bool
    var generateWeeklyReports: Bool
    var shareAnalyticsWithMembers: Bool
    
    init(
        trackMemberActivity: Bool = true,
        trackGoalProgress: Bool = true,
        trackStakePerformance: Bool = true,
        generateWeeklyReports: Bool = false,
        shareAnalyticsWithMembers: Bool = true
    ) {
        self.trackMemberActivity = trackMemberActivity
        self.trackGoalProgress = trackGoalProgress
        self.trackStakePerformance = trackStakePerformance
        self.generateWeeklyReports = generateWeeklyReports
        self.shareAnalyticsWithMembers = shareAnalyticsWithMembers
    }
}

// MARK: - Group Extensions
extension Group {
    var memberCount: Int {
        return memberIds.count
    }
    
    var isFull: Bool {
        guard let maxMembers = maxMembers else { return false }
        return memberCount >= maxMembers
    }
    
    var canJoin: Bool {
        return !isFull && (isPublic || inviteCode != nil)
    }
    
    var isOwner: Bool {
        // This would be set by the caller based on current user
        return false
    }
    
    var isMember: Bool {
        // This would be set by the caller based on current user
        return false
    }
    
    var activeGoalsCount: Int {
        return goals.count
    }
    
    var activeStakesCount: Int {
        return stakes.count
    }
    
    var totalStakeValue: Decimal {
        // This would be calculated from actual stake data
        return 0
    }
}

// MARK: - Group Validation
extension Group {
    var validationErrors: [String] {
        var errors: [String] = []
        
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Group name is required")
        }
        
        if description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Group description is required")
        }
        
        if memberIds.isEmpty {
            errors.append("Group must have at least one member")
        }
        
        if let maxMembers = maxMembers, maxMembers < 2 {
            errors.append("Maximum members must be at least 2")
        }
        
        return errors
    }
    
    var isValid: Bool {
        return validationErrors.isEmpty
    }
}
