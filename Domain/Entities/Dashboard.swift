import Foundation

// MARK: - Home Summary
struct HomeSummary: Identifiable, Codable, Equatable {
    let id: String
    let userId: String
    let lastUpdated: Date
    let activeGoalsCount: Int
    let totalStakeValue: Decimal
    let totalAccruedAmount: Decimal
    let upcomingDeadlines: [GoalSummary]
    let recentActivity: [ActivityItem]
    let aiNudges: [Nudge]
    let quickActions: [QuickAction]
    let notifications: [NotificationItem]
    
    init(
        id: String = UUID().uuidString,
        userId: String,
        lastUpdated: Date = Date(),
        activeGoalsCount: Int = 0,
        totalStakeValue: Decimal = 0,
        totalAccruedAmount: Decimal = 0,
        upcomingDeadlines: [GoalSummary] = [],
        recentActivity: [ActivityItem] = [],
        aiNudges: [Nudge] = [],
        quickActions: [QuickAction] = [],
        notifications: [NotificationItem] = []
    ) {
        self.id = id
        self.userId = userId
        self.lastUpdated = lastUpdated
        self.activeGoalsCount = activeGoalsCount
        self.totalStakeValue = totalStakeValue
        self.totalAccruedAmount = totalAccruedAmount
        self.upcomingDeadlines = upcomingDeadlines
        self.recentActivity = recentActivity
        self.aiNudges = aiNudges
        self.quickActions = quickActions
        self.notifications = notifications
    }
}

// MARK: - Goal Summary
struct GoalSummary: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let category: GoalCategory
    let deadline: Date
    let progress: Double
    let stakeAmount: Decimal
    let accruedAmount: Decimal
    let status: GoalStatus
    let verificationMethod: VerificationMethod
    let isGroupGoal: Bool
    let isCorporateGoal: Bool
    let daysRemaining: Int
    let isOverdue: Bool
    
    init(
        id: String,
        title: String,
        category: GoalCategory,
        deadline: Date,
        progress: Double = 0.0,
        stakeAmount: Decimal = 0,
        accruedAmount: Decimal = 0,
        status: GoalStatus = .active,
        verificationMethod: VerificationMethod = .none,
        isGroupGoal: Bool = false,
        isCorporateGoal: Bool = false
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.deadline = deadline
        self.progress = progress
        self.stakeAmount = stakeAmount
        self.accruedAmount = accruedAmount
        self.status = status
        self.verificationMethod = verificationMethod
        self.isGroupGoal = isGroupGoal
        self.isCorporateGoal = isCorporateGoal
        self.daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: deadline).day ?? 0
        self.isOverdue = Date() > deadline && status == .active
    }
}

// MARK: - Activity Item
struct ActivityItem: Identifiable, Codable, Equatable {
    let id: String
    let type: ActivityType
    let title: String
    let description: String
    let timestamp: Date
    let goalId: String?
    let stakeId: String?
    let userId: String
    let metadata: [String: String]
    
    init(
        id: String = UUID().uuidString,
        type: ActivityType,
        title: String,
        description: String,
        timestamp: Date = Date(),
        goalId: String? = nil,
        stakeId: String? = nil,
        userId: String,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.description = description
        self.timestamp = timestamp
        self.goalId = goalId
        self.stakeId = stakeId
        self.userId = userId
        self.metadata = metadata
    }
}

enum ActivityType: String, Codable, CaseIterable {
    case goalCreated = "goal_created"
    case goalCompleted = "goal_completed"
    case goalFailed = "goal_failed"
    case stakeCreated = "stake_created"
    case stakeAccrued = "stake_accrued"
    case stakeWithdrawn = "stake_withdrawn"
    case stakeForfeited = "stake_forfeited"
    case groupJoined = "group_joined"
    case groupLeft = "group_left"
    case corporateJoined = "corporate_joined"
    case verificationSubmitted = "verification_submitted"
    case verificationApproved = "verification_approved"
    case verificationRejected = "verification_rejected"
    case milestoneReached = "milestone_reached"
    case reminderSet = "reminder_set"
    case notificationReceived = "notification_received"
    
    var displayName: String {
        switch self {
        case .goalCreated: return "Goal Created"
        case .goalCompleted: return "Goal Completed"
        case .goalFailed: return "Goal Failed"
        case .stakeCreated: return "Stake Created"
        case .stakeAccrued: return "Stake Accrued"
        case .stakeWithdrawn: return "Stake Withdrawn"
        case .stakeForfeited: return "Stake Forfeited"
        case .groupJoined: return "Joined Group"
        case .groupLeft: return "Left Group"
        case .corporateJoined: return "Joined Corporate"
        case .verificationSubmitted: return "Verification Submitted"
        case .verificationApproved: return "Verification Approved"
        case .verificationRejected: return "Verification Rejected"
        case .milestoneReached: return "Milestone Reached"
        case .reminderSet: return "Reminder Set"
        case .notificationReceived: return "Notification Received"
        }
    }
    
    var iconName: String {
        switch self {
        case .goalCreated, .goalCompleted, .goalFailed:
            return "target"
        case .stakeCreated, .stakeAccrued, .stakeWithdrawn, .stakeForfeited:
            return "dollarsign.circle"
        case .groupJoined, .groupLeft:
            return "person.3"
        case .corporateJoined:
            return "building.2"
        case .verificationSubmitted, .verificationApproved, .verificationRejected:
            return "checkmark.shield"
        case .milestoneReached:
            return "flag"
        case .reminderSet:
            return "bell"
        case .notificationReceived:
            return "message"
        }
    }
}

// MARK: - AI Nudge
struct Nudge: Identifiable, Codable, Equatable {
    let id: String
    let type: NudgeType
    let title: String
    let message: String
    let category: NudgeCategory
    let priority: NudgePriority
    let createdAt: Date
    let expiresAt: Date?
    let goalId: String?
    let actionType: NudgeActionType?
    let actionData: [String: String]?
    let isRead: Bool
    let isApplied: Bool
    
    init(
        id: String = UUID().uuidString,
        type: NudgeType,
        title: String,
        message: String,
        category: NudgeCategory,
        priority: NudgePriority = .medium,
        createdAt: Date = Date(),
        expiresAt: Date? = nil,
        goalId: String? = nil,
        actionType: NudgeActionType? = nil,
        actionData: [String: String]? = nil,
        isRead: Bool = false,
        isApplied: Bool = false
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.message = message
        self.category = category
        self.priority = priority
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.goalId = goalId
        self.actionType = actionType
        self.actionData = actionData
        self.isRead = isRead
        self.isApplied = isApplied
    }
}

enum NudgeType: String, Codable, CaseIterable {
    case motivation = "motivation"
    case reminder = "reminder"
    case suggestion = "suggestion"
    case warning = "warning"
    case celebration = "celebration"
    case insight = "insight"
    
    var displayName: String {
        switch self {
        case .motivation: return "Motivation"
        case .reminder: return "Reminder"
        case .suggestion: return "Suggestion"
        case .warning: return "Warning"
        case .celebration: return "Celebration"
        case .insight: return "Insight"
        }
    }
    
    var iconName: String {
        switch self {
        case .motivation: return "heart.fill"
        case .reminder: return "bell.fill"
        case .suggestion: return "lightbulb.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .celebration: return "party.popper.fill"
        case .insight: return "brain.head.profile"
        }
    }
}

enum NudgeCategory: String, Codable, CaseIterable {
    case productivity = "productivity"
    case health = "health"
    case learning = "learning"
    case fitness = "fitness"
    case finance = "finance"
    case social = "social"
    case career = "career"
    case general = "general"
    
    var displayName: String {
        switch self {
        case .productivity: return "Productivity"
        case .health: return "Health"
        case .learning: return "Learning"
        case .fitness: return "Fitness"
        case .finance: return "Finance"
        case .social: return "Social"
        case .career: return "Career"
        case .general: return "General"
        }
    }
}

enum NudgePriority: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case urgent = "urgent"
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .urgent: return "Urgent"
        }
    }
    
    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "blue"
        case .high: return "orange"
        case .urgent: return "red"
        }
    }
}

enum NudgeActionType: String, Codable, CaseIterable {
    case setReminder = "set_reminder"
    case adjustGoal = "adjust_goal"
    case addMilestone = "add_milestone"
    case changeVerification = "change_verification"
    case increaseStake = "increase_stake"
    case joinGroup = "join_group"
    case shareProgress = "share_progress"
    case none = "none"
    
    var displayName: String {
        switch self {
        case .setReminder: return "Set Reminder"
        case .adjustGoal: return "Adjust Goal"
        case .addMilestone: return "Add Milestone"
        case .changeVerification: return "Change Verification"
        case .increaseStake: return "Increase Stake"
        case .joinGroup: return "Join Group"
        case .shareProgress: return "Share Progress"
        case .none: return "None"
        }
    }
}

// MARK: - Quick Action
struct QuickAction: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let description: String
    let iconName: String
    let actionType: QuickActionType
    let isEnabled: Bool
    let requiresAuthentication: Bool
    
    init(
        id: String = UUID().uuidString,
        title: String,
        description: String,
        iconName: String,
        actionType: QuickActionType,
        isEnabled: Bool = true,
        requiresAuthentication: Bool = true
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.iconName = iconName
        self.actionType = actionType
        self.isEnabled = isEnabled
        self.requiresAuthentication = requiresAuthentication
    }
}

enum QuickActionType: String, Codable, CaseIterable {
    case createGoal = "create_goal"
    case joinGroup = "join_group"
    case viewLeaderboard = "view_leaderboard"
    case checkProgress = "check_progress"
    case setReminder = "set_reminder"
    case shareProgress = "share_progress"
    case viewAnalytics = "view_analytics"
    case contactSupport = "contact_support"
    
    var displayName: String {
        switch self {
        case .createGoal: return "Create Goal"
        case .joinGroup: return "Join Group"
        case .viewLeaderboard: return "View Leaderboard"
        case .checkProgress: return "Check Progress"
        case .setReminder: return "Set Reminder"
        case .shareProgress: return "Share Progress"
        case .viewAnalytics: return "View Analytics"
        case .contactSupport: return "Contact Support"
        }
    }
}

// MARK: - Notification Item
struct NotificationItem: Identifiable, Codable, Equatable {
    let id: String
    let type: NotificationType
    let title: String
    let message: String
    let timestamp: Date
    let isRead: Bool
    let goalId: String?
    let stakeId: String?
    let actionData: [String: String]?
    
    init(
        id: String = UUID().uuidString,
        type: NotificationType,
        title: String,
        message: String,
        timestamp: Date = Date(),
        isRead: Bool = false,
        goalId: String? = nil,
        stakeId: String? = nil,
        actionData: [String: String]? = nil
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.message = message
        self.timestamp = timestamp
        self.isRead = isRead
        self.goalId = goalId
        self.stakeId = stakeId
        self.actionData = actionData
    }
}

enum NotificationType: String, Codable, CaseIterable {
    case deadline = "deadline"
    case milestone = "milestone"
    case stakeAccrual = "stake_accrual"
    case groupUpdate = "group_update"
    case corporateUpdate = "corporate_update"
    case verification = "verification"
    case system = "system"
    case achievement = "achievement"
    
    var displayName: String {
        switch self {
        case .deadline: return "Deadline"
        case .milestone: return "Milestone"
        case .stakeAccrual: return "Stake Accrual"
        case .groupUpdate: return "Group Update"
        case .corporateUpdate: return "Corporate Update"
        case .verification: return "Verification"
        case .system: return "System"
        case .achievement: return "Achievement"
        }
    }
    
    var iconName: String {
        switch self {
        case .deadline: return "clock"
        case .milestone: return "flag"
        case .stakeAccrual: return "dollarsign.circle"
        case .groupUpdate: return "person.3"
        case .corporateUpdate: return "building.2"
        case .verification: return "checkmark.shield"
        case .system: return "gear"
        case .achievement: return "trophy"
        }
    }
}
