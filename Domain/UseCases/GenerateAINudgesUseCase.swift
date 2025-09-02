import Foundation
import Combine

// MARK: - Generate AI Nudges Use Case
struct GenerateAINudgesUseCase {
    private let aiNudgeService: AINudgeService
    private let goalRepository: GoalRepository
    private let stakeRepository: StakeRepository
    private let userRepository: UserRepository
    private let analyticsService: AnalyticsService
    
    init(
        aiNudgeService: AINudgeService,
        goalRepository: GoalRepository,
        stakeRepository: StakeRepository,
        userRepository: UserRepository,
        analyticsService: AnalyticsService
    ) {
        self.aiNudgeService = aiNudgeService
        self.goalRepository = goalRepository
        self.stakeRepository = stakeRepository
        self.userRepository = userRepository
        self.analyticsService = analyticsService
    }
    
    func execute(userId: String, limit: Int = 5) async throws -> [Nudge] {
        // Track analytics
        analyticsService.track(event: .aiNudgeGenerationRequested(userId: userId))
        
        // Fetch user context data
        let userContext = try await buildUserContext(userId: userId)
        
        // Generate nudges using AI service
        let nudges = try await aiNudgeService.generateNudges(
            for: userId,
            context: userContext,
            limit: limit
        )
        
        // Track successful generation
        analyticsService.track(event: .aiNudgesGenerated(
            userId: userId,
            count: nudges.count,
            categories: nudges.map { $0.category.rawValue }
        ))
        
        return nudges
    }
    
    func getPersonalizedNudges(userId: String, category: NudgeCategory? = nil) async throws -> [Nudge] {
        let userContext = try await buildUserContext(userId: userId)
        
        let nudges = try await aiNudgeService.getPersonalizedNudges(
            for: userId,
            context: userContext,
            category: category
        )
        
        return nudges
    }
    
    func markNudgeAsRead(nudgeId: String, userId: String) async throws {
        try await aiNudgeService.markNudgeAsRead(nudgeId: nudgeId, userId: userId)
        
        analyticsService.track(event: .aiNudgeRead(
            userId: userId,
            nudgeId: nudgeId
        ))
    }
    
    func markNudgeAsApplied(nudgeId: String, userId: String) async throws {
        try await aiNudgeService.markNudgeAsApplied(nudgeId: nudgeId, userId: userId)
        
        analyticsService.track(event: .aiNudgeApplied(
            userId: userId,
            nudgeId: nudgeId
        ))
    }
    
    func getNudgeSuggestions(userId: String, goalId: String? = nil) async throws -> [Nudge] {
        let userContext = try await buildUserContext(userId: userId)
        
        let suggestions = try await aiNudgeService.getNudgeSuggestions(
            for: userId,
            context: userContext,
            goalId: goalId
        )
        
        return suggestions
    }
    
    // MARK: - Private Methods
    
    private func buildUserContext(userId: String) async throws -> UserContext {
        async let goalsTask = goalRepository.getGoals(userId: userId, status: .active)
        async let stakesTask = stakeRepository.getStakes(userId: userId, status: .active)
        async let userTask = userRepository.getUser(id: userId)
        
        let (goals, stakes, user) = try await (goalsTask, stakesTask, userTask)
        
        let context = UserContext(
            userId: userId,
            currentGoals: goals,
            activeStakes: stakes,
            userProfile: user,
            lastActivity: Date(),
            preferences: buildUserPreferences(from: user)
        )
        
        return context
    }
    
    private func buildUserPreferences(from user: User?) -> UserPreferences {
        // Build user preferences based on user data
        // This would include things like preferred categories, notification settings, etc.
        return UserPreferences(
            preferredCategories: [.productivity, .health, .learning],
            notificationFrequency: .daily,
            nudgeIntensity: .medium,
            learningStyle: .visual,
            motivationFactors: [.achievement, .social, .financial]
        )
    }
}

// MARK: - User Context
struct UserContext: Codable, Equatable {
    let userId: String
    let currentGoals: [Goal]
    let activeStakes: [Stake]
    let userProfile: User?
    let lastActivity: Date
    let preferences: UserPreferences
    
    var hasActiveGoals: Bool {
        !currentGoals.isEmpty
    }
    
    var totalStakeValue: Decimal {
        activeStakes.reduce(0) { $0 + $1.amount }
    }
    
    var averageGoalProgress: Double {
        guard !currentGoals.isEmpty else { return 0.0 }
        let totalProgress = currentGoals.reduce(0.0) { $0 + $1.progress }
        return totalProgress / Double(currentGoals.count)
    }
    
    var upcomingDeadlines: [Goal] {
        let now = Date()
        return currentGoals
            .filter { $0.deadline > now }
            .sorted { $0.deadline < $1.deadline }
    }
    
    var overdueGoals: [Goal] {
        let now = Date()
        return currentGoals.filter { $0.deadline < now && $0.status == .active }
    }
}

// MARK: - User Preferences
struct UserPreferences: Codable, Equatable {
    let preferredCategories: [NudgeCategory]
    let notificationFrequency: NotificationFrequency
    let nudgeIntensity: NudgeIntensity
    let learningStyle: LearningStyle
    let motivationFactors: [MotivationFactor]
    
    init(
        preferredCategories: [NudgeCategory] = [],
        notificationFrequency: NotificationFrequency = .daily,
        nudgeIntensity: NudgeIntensity = .medium,
        learningStyle: LearningStyle = .visual,
        motivationFactors: [MotivationFactor] = []
    ) {
        self.preferredCategories = preferredCategories
        self.notificationFrequency = notificationFrequency
        self.nudgeIntensity = nudgeIntensity
        self.learningStyle = learningStyle
        self.motivationFactors = motivationFactors
    }
}

enum NotificationFrequency: String, Codable, CaseIterable {
    case hourly = "hourly"
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    
    var displayName: String {
        switch self {
        case .hourly: return "Hourly"
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        }
    }
}

enum NudgeIntensity: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }
}

enum LearningStyle: String, Codable, CaseIterable {
    case visual = "visual"
    case auditory = "auditory"
    case kinesthetic = "kinesthetic"
    case reading = "reading"
    
    var displayName: String {
        switch self {
        case .visual: return "Visual"
        case .auditory: return "Auditory"
        case .kinesthetic: return "Kinesthetic"
        case .reading: return "Reading"
        }
    }
}

enum MotivationFactor: String, Codable, CaseIterable {
    case achievement = "achievement"
    case social = "social"
    case financial = "financial"
    case health = "health"
    case learning = "learning"
    case competition = "competition"
    case recognition = "recognition"
    
    var displayName: String {
        switch self {
        case .achievement: return "Achievement"
        case .social: return "Social"
        case .financial: return "Financial"
        case .health: return "Health"
        case .learning: return "Learning"
        case .competition: return "Competition"
        case .recognition: return "Recognition"
        }
    }
}

// MARK: - AI Nudge Service Protocol
protocol AINudgeService {
    func generateNudges(
        for userId: String,
        context: UserContext,
        limit: Int
    ) async throws -> [Nudge]
    
    func getPersonalizedNudges(
        for userId: String,
        context: UserContext,
        category: NudgeCategory?
    ) async throws -> [Nudge]
    
    func markNudgeAsRead(nudgeId: String, userId: String) async throws
    func markNudgeAsApplied(nudgeId: String, userId: String) async throws
    
    func getNudgeSuggestions(
        for userId: String,
        context: UserContext,
        goalId: String?
    ) async throws -> [Nudge]
}

// MARK: - Analytics Events
extension AnalyticsEvent {
    static func aiNudgeGenerationRequested(userId: String) -> AnalyticsEvent {
        AnalyticsEvent(
            name: "ai_nudge_generation_requested",
            properties: [
                "user_id": userId,
                "timestamp": Date().timeIntervalSince1970
            ]
        )
    }
    
    static func aiNudgesGenerated(
        userId: String,
        count: Int,
        categories: [String]
    ) -> AnalyticsEvent {
        AnalyticsEvent(
            name: "ai_nudges_generated",
            properties: [
                "user_id": userId,
                "count": count,
                "categories": categories,
                "timestamp": Date().timeIntervalSince1970
            ]
        )
    }
    
    static func aiNudgeRead(userId: String, nudgeId: String) -> AnalyticsEvent {
        AnalyticsEvent(
            name: "ai_nudge_read",
            properties: [
                "user_id": userId,
                "nudge_id": nudgeId,
                "timestamp": Date().timeIntervalSince1970
            ]
        )
    }
    
    static func aiNudgeApplied(userId: String, nudgeId: String) -> AnalyticsEvent {
        AnalyticsEvent(
            name: "ai_nudge_applied",
            properties: [
                "user_id": userId,
                "nudge_id": nudgeId,
                "timestamp": Date().timeIntervalSince1970
            ]
        )
    }
}
