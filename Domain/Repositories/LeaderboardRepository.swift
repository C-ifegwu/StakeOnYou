import Foundation
import Combine

// MARK: - Leaderboard Repository Protocol
protocol LeaderboardRepository {
    // MARK: - Query Operations
    func getLeaderboard(type: LeaderboardType, category: LeaderboardCategory, timeFrame: LeaderboardTimeFrame, limit: Int) async throws -> LeaderboardResult
    func getLeaderboardEntry(userId: String, type: LeaderboardType, category: LeaderboardCategory, timeFrame: LeaderboardTimeFrame) async throws -> LeaderboardEntry?
    func getUserLeaderboardStats(userId: String) async throws -> UserLeaderboardStats
    func getLeaderboardHistory(userId: String, type: LeaderboardType, timeFrame: LeaderboardTimeFrame) async throws -> [RankHistoryEntry]
    
    // MARK: - Score Operations
    func updateUserScore(userId: String, type: LeaderboardType, category: LeaderboardCategory, score: Double) async throws -> LeaderboardEntry
    func incrementUserScore(userId: String, type: LeaderboardType, category: LeaderboardCategory, increment: Double) async throws -> LeaderboardEntry
    func resetUserScore(userId: String, type: LeaderboardType, category: LeaderboardCategory) async throws -> LeaderboardEntry
    
    // MARK: - Achievement Operations
    func getAchievements(forUserId: String) async throws -> [LeaderboardAchievement]
    func unlockAchievement(userId: String, achievementType: AchievementType) async throws -> LeaderboardAchievement
    func getAchievementProgress(userId: String, achievementType: AchievementType) async throws -> AchievementProgress
    
    // MARK: - Analytics Operations
    func getLeaderboardStatistics(type: LeaderboardType, category: LeaderboardCategory, timeFrame: LeaderboardTimeFrame) async throws -> LeaderboardStatistics
    func getTopPerformers(type: LeaderboardType, category: LeaderboardCategory, timeFrame: LeaderboardTimeFrame, limit: Int) async throws -> [LeaderboardEntry]
    func getUserRanking(userId: String, type: LeaderboardType, category: LeaderboardCategory, timeFrame: LeaderboardTimeFrame) async throws -> Int
    
    // MARK: - Bulk Operations
    func refreshAllLeaderboards() async throws -> [LeaderboardResult]
    func updateLeaderboardScores(type: LeaderboardType, category: LeaderboardCategory, timeFrame: LeaderboardTimeFrame) async throws -> [LeaderboardEntry]
    func cleanupOldLeaderboardData(olderThan date: Date) async throws -> Int
}

// MARK: - Supporting Models
struct LeaderboardStatistics {
    let totalParticipants: Int
    let averageScore: Double
    let highestScore: Double
    let lowestScore: Double
    let scoreDistribution: [ScoreRange: Int]
    let activeUsers: Int
    let newUsersThisPeriod: Int
}

struct ScoreRange: Hashable {
    let min: Double
    let max: Double
    
    var displayName: String {
        if max == Double.infinity {
            return "\(Int(min)+"
        } else {
            return "\(Int(min))-\(Int(max))"
        }
    }
}

struct AchievementProgress {
    let achievementType: AchievementType
    let currentProgress: Double
    let targetProgress: Double
    let isUnlocked: Bool
    let progressPercentage: Double
    let timeToUnlock: TimeInterval?
}

// MARK: - Leaderboard Repository Extensions
extension LeaderboardRepository {
    // MARK: - Convenience Methods
    func getGlobalLeaderboard(timeFrame: LeaderboardTimeFrame, limit: Int = 100) async throws -> LeaderboardResult {
        return try await getLeaderboard(
            type: .global,
            category: .overall,
            timeFrame: timeFrame,
            limit: limit
        )
    }
    
    func getFriendsLeaderboard(timeFrame: LeaderboardTimeFrame, limit: Int = 50) async throws -> LeaderboardResult {
        return try await getLeaderboard(
            type: .friends,
            category: .overall,
            timeFrame: timeFrame,
            limit: limit
        )
    }
    
    func getCorporateLeaderboard(corporateId: String, timeFrame: LeaderboardTimeFrame, limit: Int = 50) async throws -> LeaderboardResult {
        return try await getLeaderboard(
            type: .corporate,
            category: .overall,
            timeFrame: timeFrame,
            limit: limit
        )
    }
    
    func getCategoryLeaderboard(category: LeaderboardCategory, timeFrame: LeaderboardTimeFrame, limit: Int = 100) async throws -> LeaderboardResult {
        return try await getLeaderboard(
            type: .global,
            category: category,
            timeFrame: timeFrame,
            limit: limit
        )
    }
    
    func getWeeklyLeaderboard(category: LeaderboardCategory = .overall, limit: Int = 100) async throws -> LeaderboardResult {
        return try await getLeaderboard(
            type: .global,
            category: category,
            timeFrame: .week,
            limit: limit
        )
    }
    
    func getMonthlyLeaderboard(category: LeaderboardCategory = .overall, limit: Int = 100) async throws -> LeaderboardResult {
        return try await getLeaderboard(
            type: .global,
            category: category,
            timeFrame: .month,
            limit: limit
        )
    }
    
    func getYearlyLeaderboard(category: LeaderboardCategory = .overall, limit: Int = 100) async throws -> LeaderboardResult {
        return try await getLeaderboard(
            type: .global,
            category: category,
            timeFrame: .year,
            limit: limit
        )
    }
    
    func getUserGlobalRanking(userId: String) async throws -> Int {
        return try await getUserRanking(
            userId: userId,
            type: .global,
            category: .overall,
            timeFrame: .allTime
        )
    }
    
    func getUserFriendsRanking(userId: String) async throws -> Int {
        return try await getUserRanking(
            userId: userId,
            type: .friends,
            category: .overall,
            timeFrame: .allTime
        )
    }
    
    func getUserCorporateRanking(userId: String) async throws -> Int {
        return try await getUserRanking(
            userId: userId,
            type: .corporate,
            category: .overall,
            timeFrame: .allTime
        )
    }
    
    func getTopUsers(limit: Int = 10) async throws -> [LeaderboardEntry] {
        return try await getTopPerformers(
            type: .global,
            category: .overall,
            timeFrame: .allTime,
            limit: limit
        )
    }
    
    func getTopUsersByCategory(category: LeaderboardCategory, limit: Int = 10) async throws -> [LeaderboardEntry] {
        return try await getTopPerformers(
            type: .global,
            category: category,
            timeFrame: .allTime,
            limit: limit
        )
    }
    
    func getTopUsersByTimeFrame(timeFrame: LeaderboardTimeFrame, limit: Int = 10) async throws -> [LeaderboardEntry] {
        return try await getTopPerformers(
            type: .global,
            category: .overall,
            timeFrame: timeFrame,
            limit: limit
        )
    }
    
    func getLeaderboardAroundUser(userId: String, type: LeaderboardType, category: LeaderboardCategory, timeFrame: LeaderboardTimeFrame, contextSize: Int = 5) async throws -> [LeaderboardEntry] {
        let userRanking = try await getUserRanking(userId: userId, type: type, category: category, timeFrame: timeFrame)
        let startRank = max(1, userRanking - contextSize)
        let endRank = userRanking + contextSize
        
        let leaderboard = try await getLeaderboard(type: type, category: category, timeFrame: timeFrame, limit: endRank)
        return Array(leaderboard.entries.prefix(endRank)).suffix(contextSize * 2 + 1)
    }
    
    func getLeaderboardByScoreRange(type: LeaderboardType, category: LeaderboardCategory, timeFrame: LeaderboardTimeFrame, minScore: Double, maxScore: Double) async throws -> [LeaderboardEntry] {
        let leaderboard = try await getLeaderboard(type: type, category: category, timeFrame: timeFrame, limit: 1000)
        return leaderboard.entries.filter { $0.score >= minScore && $0.score <= maxScore }
    }
    
    func getLeaderboardByRankRange(type: LeaderboardType, category: LeaderboardCategory, timeFrame: LeaderboardTimeFrame, startRank: Int, endRank: Int) async throws -> [LeaderboardEntry] {
        let leaderboard = try await getLeaderboard(type: type, category: category, timeFrame: timeFrame, limit: endRank)
        return Array(leaderboard.entries.prefix(endRank)).suffix(endRank - startRank + 1)
    }
    
    func getLeaderboardTrends(type: LeaderboardType, category: LeaderboardCategory, timeFrame: LeaderboardTimeFrame) async throws -> LeaderboardTrends {
        // This would need to be implemented with historical data
        // For now, return empty trends
        return LeaderboardTrends(
            topGainers: [],
            topLosers: [],
            mostActiveUsers: [],
            trendingCategories: []
        )
    }
}

// MARK: - Additional Supporting Models
struct LeaderboardTrends {
    let topGainers: [LeaderboardEntry]
    let topLosers: [LeaderboardEntry]
    let mostActiveUsers: [LeaderboardEntry]
    let trendingCategories: [LeaderboardCategory]
}

// MARK: - Leaderboard Repository Error
enum LeaderboardRepositoryError: LocalizedError {
    case leaderboardNotFound
    case invalidLeaderboardData
    case userNotFound
    case invalidScore
    case insufficientPermissions
    case leaderboardUpdateFailed
    case databaseError(Error)
    case networkError(Error)
    case permissionDenied
    case quotaExceeded
    
    var errorDescription: String? {
        switch self {
        case .leaderboardNotFound:
            return "Leaderboard not found"
        case .invalidLeaderboardData:
            return "Invalid leaderboard data"
        case .userNotFound:
            return "User not found"
        case .invalidScore:
            return "Invalid score value"
        case .insufficientPermissions:
            return "Insufficient permissions for this operation"
        case .leaderboardUpdateFailed:
            return "Failed to update leaderboard"
        case .databaseError(let error):
            return "Database error: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .permissionDenied:
            return "Permission denied"
        case .quotaExceeded:
            return "Quota exceeded"
        }
    }
}
