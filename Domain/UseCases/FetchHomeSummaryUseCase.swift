import Foundation
import Combine

// MARK: - Fetch Home Summary Use Case
struct FetchHomeSummaryUseCase {
    private let goalRepository: GoalRepository
    private let stakeRepository: StakeRepository
    private let userRepository: UserRepository
    private let activityRepository: ActivityRepository
    private let aiNudgeRepository: AINudgeRepository
    private let notificationRepository: NotificationRepository
    private let analyticsService: AnalyticsService
    
    init(
        goalRepository: GoalRepository,
        stakeRepository: StakeRepository,
        userRepository: UserRepository,
        activityRepository: ActivityRepository,
        aiNudgeRepository: AI NudgeRepository,
        notificationRepository: NotificationRepository,
        analyticsService: AnalyticsService
    ) {
        self.goalRepository = goalRepository
        self.stakeRepository = stakeRepository
        self.userRepository = userRepository
        self.activityRepository = activityRepository
        self.aiNudgeRepository = aiNudgeRepository
        self.notificationRepository = notificationRepository
        self.analyticsService = analyticsService
    }
    
    func execute(userId: String) async throws -> HomeSummary {
        // Track analytics
        analyticsService.track(event: .dashboardOpened(userId: userId))
        
        // Fetch data concurrently
        async let goalsTask = goalRepository.getGoals(userId: userId, status: .active)
        async let stakesTask = stakeRepository.getStakes(userId: userId, status: .active)
        async let recentActivityTask = activityRepository.getRecentActivity(userId: userId, limit: 10)
        async let aiNudgesTask = aiNudgeRepository.getNudges(userId: userId, limit: 5)
        async let notificationsTask = notificationRepository.getUnreadNotifications(userId: userId, limit: 5)
        
        // Wait for all tasks to complete
        let (goals, stakes, recentActivity, aiNudges, notifications) = try await (
            goalsTask,
            stakesTask,
            recentActivityTask,
            aiNudgesTask,
            notificationsTask
        )
        
        // Calculate summary statistics
        let activeGoalsCount = goals.count
        let totalStakeValue = stakes.reduce(0) { $0 + $1.amount }
        let totalAccruedAmount = stakes.reduce(0) { $0 + $1.accruedAmount }
        
        // Create goal summaries for upcoming deadlines
        let upcomingDeadlines = goals
            .filter { $0.deadline > Date() }
            .sorted { $0.deadline < $1.deadline }
            .prefix(5)
            .map { goal in
                let stake = stakes.first { $0.goalId == goal.id }
                return GoalSummary(
                    id: goal.id,
                    title: goal.title,
                    category: goal.category,
                    deadline: goal.deadline,
                    progress: goal.progress,
                    stakeAmount: stake?.amount ?? 0,
                    accruedAmount: stake?.accruedAmount ?? 0,
                    status: goal.status,
                    verificationMethod: goal.verificationMethod,
                    isGroupGoal: goal.isGroupGoal,
                    isCorporateGoal: goal.isCorporateGoal
                )
            }
        
        // Create quick actions
        let quickActions = createQuickActions(for: userId)
        
        // Create home summary
        let homeSummary = HomeSummary(
            userId: userId,
            activeGoalsCount: activeGoalsCount,
            totalStakeValue: totalStakeValue,
            totalAccruedAmount: totalAccruedAmount,
            upcomingDeadlines: Array(upcomingDeadlines),
            recentActivity: recentActivity,
            aiNudges: aiNudges,
            quickActions: quickActions,
            notifications: notifications
        )
        
        return homeSummary
    }
    
    private func createQuickActions(for userId: String) -> [QuickAction] {
        var actions: [QuickAction] = []
        
        // Always available actions
        actions.append(QuickAction(
            title: "Create Goal",
            description: "Set a new goal and stake",
            iconName: "target",
            actionType: .createGoal
        ))
        
        actions.append(QuickAction(
            title: "View Progress",
            description: "Check your goal progress",
            iconName: "chart.line.uptrend.xyaxis",
            actionType: .checkProgress
        ))
        
        // Conditional actions based on user state
        // These would be determined by checking user's current state
        actions.append(QuickAction(
            title: "Join Group",
            description: "Find and join goal groups",
            iconName: "person.3",
            actionType: .joinGroup
        ))
        
        actions.append(QuickAction(
            title: "Leaderboard",
            description: "See how you rank",
            iconName: "trophy",
            actionType: .viewLeaderboard
        ))
        
        actions.append(QuickAction(
            title: "Set Reminder",
            description: "Schedule goal reminders",
            iconName: "bell",
            actionType: .setReminder
        ))
        
        actions.append(QuickAction(
            title: "Share Progress",
            description: "Share your achievements",
            iconName: "square.and.arrow.up",
            actionType: .shareProgress
        ))
        
        return actions
    }
}

// MARK: - Supporting Protocols
protocol ActivityRepository {
    func getRecentActivity(userId: String, limit: Int) async throws -> [ActivityItem]
}

protocol AINudgeRepository {
    func getNudges(userId: String, limit: Int) async throws -> [Nudge]
}

protocol NotificationRepository {
    func getUnreadNotifications(userId: String, limit: Int) async throws -> [NotificationItem]
}

// MARK: - Analytics Events
extension AnalyticsEvent {
    static func dashboardOpened(userId: String) -> AnalyticsEvent {
        AnalyticsEvent(
            name: "dashboard_opened",
            properties: [
                "user_id": userId,
                "timestamp": Date().timeIntervalSince1970
            ]
        )
    }
}
