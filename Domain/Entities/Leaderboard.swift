import Foundation

// MARK: - Leaderboard Entry
struct LeaderboardEntry: Identifiable, Codable, Equatable {
    let id: String
    let userId: String
    let displayName: String
    let avatarURL: String?
    let rank: Int
    let score: Double
    let scoreType: LeaderboardScoreType
    let category: LeaderboardCategory?
    let timeFrame: LeaderboardTimeFrame
    let metadata: [String: String]
    let lastUpdated: Date
    
    init(
        id: String = UUID().uuidString,
        userId: String,
        displayName: String,
        avatarURL: String? = nil,
        rank: Int,
        score: Double,
        scoreType: LeaderboardScoreType,
        category: LeaderboardCategory? = nil,
        timeFrame: LeaderboardTimeFrame,
        metadata: [String: String] = [:],
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.rank = rank
        self.score = score
        self.scoreType = scoreType
        self.category = category
        self.timeFrame = timeFrame
        self.metadata = metadata
        self.lastUpdated = lastUpdated
    }
}

// MARK: - Leaderboard Score Type
enum LeaderboardScoreType: String, Codable, CaseIterable {
    case goalsCompleted = "goals_completed"
    case totalStakeValue = "total_stake_value"
    case totalAccruedAmount = "total_accrued_amount"
    case successRate = "success_rate"
    case streakDays = "streak_days"
    case totalEarnings = "total_earnings"
    case charityDonations = "charity_donations"
    case groupContributions = "group_contributions"
    case corporatePerformance = "corporate_performance"
    case verificationAccuracy = "verification_accuracy"
    
    var displayName: String {
        switch self {
        case .goalsCompleted: return "Goals Completed"
        case .totalStakeValue: return "Total Stake Value"
        case .totalAccruedAmount: return "Total Accrued Amount"
        case .successRate: return "Success Rate"
        case .streakDays: return "Streak Days"
        case .totalEarnings: return "Total Earnings"
        case .charityDonations: return "Charity Donations"
        case .groupContributions: return "Group Contributions"
        case .corporatePerformance: return "Corporate Performance"
        case .verificationAccuracy: return "Verification Accuracy"
        }
    }
    
    var unit: String {
        switch self {
        case .goalsCompleted: return "goals"
        case .totalStakeValue: return "$"
        case .totalAccruedAmount: return "$"
        case .successRate: return "%"
        case .streakDays: return "days"
        case .totalEarnings: return "$"
        case .charityDonations: return "$"
        case .groupContributions: return "contributions"
        case .corporatePerformance: return "score"
        case .verificationAccuracy: return "%"
        }
    }
    
    var iconName: String {
        switch self {
        case .goalsCompleted: return "target"
        case .totalStakeValue: return "dollarsign.circle"
        case .totalAccruedAmount: return "chart.line.uptrend.xyaxis"
        case .successRate: return "percent"
        case .streakDays: return "flame"
        case .totalEarnings: return "banknote"
        case .charityDonations: return "heart"
        case .groupContributions: return "person.3"
        case .corporatePerformance: return "building.2"
        case .verificationAccuracy: return "checkmark.shield"
        }
    }
    
    var isHigherBetter: Bool {
        switch self {
        case .goalsCompleted, .totalStakeValue, .totalAccruedAmount, .streakDays, .totalEarnings, .charityDonations, .groupContributions, .corporatePerformance, .verificationAccuracy:
            return true
        case .successRate:
            return true
        }
    }
}

// MARK: - Leaderboard Category
enum LeaderboardCategory: String, Codable, CaseIterable {
    case productivity = "productivity"
    case health = "health"
    case learning = "learning"
    case fitness = "fitness"
    case finance = "finance"
    case social = "social"
    case career = "career"
    case creativity = "creativity"
    case technology = "technology"
    case environment = "environment"
    case all = "all"
    
    var displayName: String {
        switch self {
        case .productivity: return "Productivity"
        case .health: return "Health"
        case .learning: return "Learning"
        case .fitness: return "Fitness"
        case .finance: return "Finance"
        case .social: return "Social"
        case .career: return "Career"
        case .creativity: return "Creativity"
        case .technology: return "Technology"
        case .environment: return "Environment"
        case .all: return "All Categories"
        }
    }
    
    var iconName: String {
        switch self {
        case .productivity: return "bolt"
        case .health: return "heart"
        case .learning: return "book"
        case .fitness: return "figure.run"
        case .finance: return "dollarsign.circle"
        case .social: return "person.3"
        case .career: return "briefcase"
        case .creativity: return "paintbrush"
        case .technology: return "laptopcomputer"
        case .environment: return "leaf"
        case .all: return "square.grid.3x3"
        }
    }
}

// MARK: - Leaderboard Time Frame
enum LeaderboardTimeFrame: String, Codable, CaseIterable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case quarterly = "quarterly"
    case yearly = "yearly"
    case allTime = "all_time"
    
    var displayName: String {
        switch self {
        case .daily: return "Today"
        case .weekly: return "This Week"
        case .monthly: return "This Month"
        case .quarterly: return "This Quarter"
        case .yearly: return "This Year"
        case .allTime: return "All Time"
        }
    }
    
    var shortDisplayName: String {
        switch self {
        case .daily: return "Day"
        case .weekly: return "Week"
        case .monthly: return "Month"
        case .quarterly: return "Quarter"
        case .yearly: return "Year"
        case .allTime: return "All Time"
        }
    }
    
    var dateInterval: DateInterval? {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .daily:
            let startOfDay = calendar.startOfDay(for: now)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            return DateInterval(start: startOfDay, end: endOfDay)
        case .weekly:
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start
            return startOfWeek.map { DateInterval(start: $0, duration: 7 * 24 * 60 * 60) }
        case .monthly:
            let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start
            return startOfMonth.map { DateInterval(start: $0, duration: 30 * 24 * 60 * 60) }
        case .quarterly:
            let startOfQuarter = calendar.dateInterval(of: .quarter, for: now)?.start
            return startOfQuarter.map { DateInterval(start: $0, duration: 90 * 24 * 60 * 60) }
        case .yearly:
            let startOfYear = calendar.dateInterval(of: .year, for: now)?.start
            return startOfYear.map { DateInterval(start: $0, duration: 365 * 24 * 60 * 60) }
        case .allTime:
            return nil
        }
    }
}

// MARK: - Leaderboard Type
enum LeaderboardType: String, Codable, CaseIterable {
    case global = "global"
    case friends = "friends"
    case corporate = "corporate"
    case group = "group"
    case category = "category"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .global: return "Global"
        case .friends: return "Friends"
        case .corporate: return "Corporate"
        case .group: return "Group"
        case .category: return "Category"
        case .custom: return "Custom"
        }
    }
    
    var iconName: String {
        switch self {
        case .global: return "globe"
        case .friends: return "person.3"
        case .corporate: return "building.2"
        case .group: return "person.3.fill"
        case .category: return "folder"
        case .custom: return "slider.horizontal.3"
        }
    }
}

// MARK: - Leaderboard Request
struct LeaderboardRequest: Codable, Equatable {
    let type: LeaderboardType
    let scoreType: LeaderboardScoreType
    let category: LeaderboardCategory?
    let timeFrame: LeaderboardTimeFrame
    let limit: Int
    let offset: Int
    let groupId: String?
    let corporateId: String?
    let userId: String?
    
    init(
        type: LeaderboardType,
        scoreType: LeaderboardScoreType,
        category: LeaderboardCategory? = nil,
        timeFrame: LeaderboardTimeFrame = .allTime,
        limit: Int = 50,
        offset: Int = 0,
        groupId: String? = nil,
        corporateId: String? = nil,
        userId: String? = nil
    ) {
        self.type = type
        self.scoreType = scoreType
        self.category = category
        self.timeFrame = timeFrame
        self.limit = limit
        self.offset = offset
        self.groupId = groupId
        self.corporateId = corporateId
        self.userId = userId
    }
}

// MARK: - Leaderboard Result
struct LeaderboardResult: Codable, Equatable {
    let entries: [LeaderboardEntry]
    let totalCount: Int
    let hasMore: Bool
    let lastUpdated: Date
    let metadata: [String: String]
    
    init(
        entries: [LeaderboardEntry],
        totalCount: Int,
        hasMore: Bool = false,
        lastUpdated: Date = Date(),
        metadata: [String: String] = [:]
    ) {
        self.entries = entries
        self.totalCount = totalCount
        self.hasMore = hasMore
        self.lastUpdated = lastUpdated
        self.metadata = metadata
    }
}

// MARK: - User Leaderboard Stats
struct UserLeaderboardStats: Codable, Equatable {
    let userId: String
    let displayName: String
    let avatarURL: String?
    let currentRank: Int?
    let bestRank: Int?
    let totalScore: Double
    let scoreType: LeaderboardScoreType
    let category: LeaderboardCategory?
    let timeFrame: LeaderboardTimeFrame
    let rankHistory: [RankHistoryEntry]
    let achievements: [LeaderboardAchievement]
    
    init(
        userId: String,
        displayName: String,
        avatarURL: String? = nil,
        currentRank: Int? = nil,
        bestRank: Int? = nil,
        totalScore: Double = 0,
        scoreType: LeaderboardScoreType,
        category: LeaderboardCategory? = nil,
        timeFrame: LeaderboardTimeFrame,
        rankHistory: [RankHistoryEntry] = [],
        achievements: [LeaderboardAchievement] = []
    ) {
        self.userId = userId
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.currentRank = currentRank
        self.bestRank = bestRank
        self.totalScore = totalScore
        self.scoreType = scoreType
        self.category = category
        self.timeFrame = timeFrame
        self.rankHistory = rankHistory
        self.achievements = achievements
    }
}

// MARK: - Rank History Entry
struct RankHistoryEntry: Codable, Equatable {
    let date: Date
    let rank: Int
    let score: Double
    
    init(date: Date, rank: Int, score: Double) {
        self.date = date
        self.rank = rank
        self.score = score
    }
}

// MARK: - Leaderboard Achievement
struct LeaderboardAchievement: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let description: String
    let iconName: String
    let type: AchievementType
    let unlockedAt: Date
    let metadata: [String: String]
    
    init(
        id: String = UUID().uuidString,
        title: String,
        description: String,
        iconName: String,
        type: AchievementType,
        unlockedAt: Date = Date(),
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.iconName = iconName
        self.type = type
        self.unlockedAt = unlockedAt
        self.metadata = metadata
    }
}

enum AchievementType: String, Codable, CaseIterable {
    case firstPlace = "first_place"
    case topTen = "top_ten"
    case topHundred = "top_hundred"
    case streak = "streak"
    case milestone = "milestone"
    case categoryMaster = "category_master"
    case consistent = "consistent"
    case improver = "improver"
    
    var displayName: String {
        switch self {
        case .firstPlace: return "First Place"
        case .topTen: return "Top 10"
        case .topHundred: return "Top 100"
        case .streak: return "Streak Master"
        case .milestone: return "Milestone Reached"
        case .categoryMaster: return "Category Master"
        case .consistent: return "Consistent Performer"
        case .improver: return "Most Improved"
        }
    }
}
