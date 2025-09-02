import Foundation
import Combine

// MARK: - Get Leaderboards Use Case
struct GetLeaderboardsUseCase {
    private let leaderboardRepository: LeaderboardRepository
    private let userRepository: UserRepository
    private let analyticsService: AnalyticsService
    
    init(
        leaderboardRepository: LeaderboardRepository,
        userRepository: UserRepository,
        analyticsService: AnalyticsService
    ) {
        self.leaderboardRepository = leaderboardRepository
        self.userRepository = userRepository
        self.analyticsService = analyticsService
    }
    
    func execute(request: LeaderboardRequest) async throws -> LeaderboardResult {
        // Track analytics
        analyticsService.track(event: .leaderboardViewed(
            type: request.type,
            scoreType: request.scoreType,
            category: request.category,
            timeFrame: request.timeFrame
        ))
        
        // Fetch leaderboard data
        let result = try await leaderboardRepository.getLeaderboard(request: request)
        
        // Enrich entries with additional user data if needed
        let enrichedEntries = try await enrichLeaderboardEntries(result.entries)
        
        // Create enriched result
        let enrichedResult = LeaderboardResult(
            entries: enrichedEntries,
            totalCount: result.totalCount,
            hasMore: result.hasMore,
            lastUpdated: result.lastUpdated,
            metadata: result.metadata
        )
        
        return enrichedResult
    }
    
    func getUserStats(
        userId: String,
        scoreType: LeaderboardScoreType,
        category: LeaderboardCategory? = nil,
        timeFrame: LeaderboardTimeFrame = .allTime
    ) async throws -> UserLeaderboardStats {
        let stats = try await leaderboardRepository.getUserStats(
            userId: userId,
            scoreType: scoreType,
            category: category,
            timeFrame: timeFrame
        )
        
        return stats
    }
    
    func getLeaderboardTypes() -> [LeaderboardType] {
        return LeaderboardType.allCases
    }
    
    func getScoreTypes() -> [LeaderboardScoreType] {
        return LeaderboardScoreType.allCases
    }
    
    func getCategories() -> [LeaderboardCategory] {
        return LeaderboardCategory.allCases
    }
    
    func getTimeFrames() -> [LeaderboardTimeFrame] {
        return LeaderboardTimeFrame.allCases
    }
    
    // MARK: - Private Methods
    
    private func enrichLeaderboardEntries(_ entries: [LeaderboardEntry]) async throws -> [LeaderboardEntry] {
        // For now, return entries as-is
        // In a real implementation, you might want to fetch additional user data
        // like profile pictures, online status, etc.
        return entries
    }
}

// MARK: - Leaderboard Repository Protocol
protocol LeaderboardRepository {
    func getLeaderboard(request: LeaderboardRequest) async throws -> LeaderboardResult
    func getUserStats(
        userId: String,
        scoreType: LeaderboardScoreType,
        category: LeaderboardCategory?,
        timeFrame: LeaderboardTimeFrame
    ) async throws -> UserLeaderboardStats
    func updateUserScore(
        userId: String,
        scoreType: LeaderboardScoreType,
        category: LeaderboardCategory?,
        timeFrame: LeaderboardTimeFrame,
        score: Double
    ) async throws
    func getTopPerformers(
        scoreType: LeaderboardScoreType,
        category: LeaderboardCategory?,
        timeFrame: LeaderboardTimeFrame,
        limit: Int
    ) async throws -> [LeaderboardEntry]
    func getUserRank(
        userId: String,
        scoreType: LeaderboardScoreType,
        category: LeaderboardCategory?,
        timeFrame: LeaderboardTimeFrame
    ) async throws -> Int?
}

// MARK: - Analytics Events
extension AnalyticsEvent {
    static func leaderboardViewed(
        type: LeaderboardType,
        scoreType: LeaderboardScoreType,
        category: LeaderboardCategory?,
        timeFrame: LeaderboardTimeFrame
    ) -> AnalyticsEvent {
        var properties: [String: Any] = [
            "leaderboard_type": type.rawValue,
            "score_type": scoreType.rawValue,
            "time_frame": timeFrame.rawValue,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if let category = category {
            properties["category"] = category.rawValue
        }
        
        return AnalyticsEvent(
            name: "leaderboard_viewed",
            properties: properties
        )
    }
    
    static func leaderboardEntryViewed(
        leaderboardType: LeaderboardType,
        rank: Int,
        scoreType: LeaderboardScoreType
    ) -> AnalyticsEvent {
        AnalyticsEvent(
            name: "leaderboard_entry_viewed",
            properties: [
                "leaderboard_type": leaderboardType.rawValue,
                "rank": rank,
                "score_type": scoreType.rawValue,
                "timestamp": Date().timeIntervalSince1970
            ]
        )
    }
}
