import Foundation
import Combine

// MARK: - AI Nudge Repository Protocol
protocol AINudgeRepository {
    // MARK: - CRUD Operations
    func createNudge(_ nudge: Nudge) async throws -> Nudge
    func getNudge(id: String) async throws -> Nudge?
    func updateNudge(_ nudge: Nudge) async throws -> Nudge
    func deleteNudge(id: String) async throws -> Bool
    
    // MARK: - Query Operations
    func getNudges(forUserId: String) async throws -> [Nudge]
    func getNudges(byType: NudgeType) async throws -> [Nudge]
    func getNudges(byCategory: NudgeCategory) async throws -> [Nudge]
    func getNudges(byPriority: NudgePriority) async throws -> [Nudge]
    func getNudges(byDateRange: DateInterval) async throws -> [Nudge]
    
    // MARK: - Status Operations
    func markNudgeAsRead(id: String) async throws -> Nudge
    func markNudgeAsApplied(id: String) async throws -> Nudge
    func markNudgeAsDismissed(id: String) async throws -> Nudge
    func getUnreadNudges(forUserId: String) async throws -> [Nudge]
    func getAppliedNudges(forUserId: String) async throws -> [Nudge]
    func getDismissedNudges(forUserId: String) async throws -> [Nudge]
    
    // MARK: - AI Generation Operations
    func generatePersonalizedNudges(forUserId: String, context: UserContext) async throws -> [Nudge]
    func getNudgeSuggestions(forUserId: String, limit: Int) async throws -> [Nudge]
    func updateNudgeEffectiveness(nudgeId: String, wasEffective: Bool, feedback: String?) async throws -> Nudge
    
    // MARK: - Analytics Operations
    func getNudgeStatistics(forUserId: String) async throws -> NudgeStatistics
    func getNudgePerformance(forUserId: String, timeRange: TimeRange) async throws -> NudgePerformance
    func getNudgeEffectivenessMetrics(forUserId: String) async throws -> NudgeEffectivenessMetrics
    
    // MARK: - Bulk Operations
    func bulkUpdateNudges(_ nudges: [Nudge]) async throws -> [Nudge]
    func deleteOldNudges(olderThan date: Date) async throws -> Int
    func deleteDismissedNudges(olderThan date: Date) async throws -> Int
}

// MARK: - Supporting Models
struct NudgeStatistics {
    let totalNudges: Int
    let unreadNudges: Int
    let appliedNudges: Int
    let dismissedNudges: Int
    let nudgesByType: [NudgeTypeStats]
    let nudgesByCategory: [NudgeCategoryStats]
    let averageEffectiveness: Double
}

struct NudgeTypeStats {
    let type: NudgeType
    let count: Int
    let appliedCount: Int
    let dismissedCount: Int
    let effectiveness: Double
}

struct NudgeCategoryStats {
    let category: NudgeCategory
    let count: Int
    let appliedCount: Int
    let dismissedCount: Int
    let effectiveness: Double
}

struct NudgePerformance {
    let readRate: Double
    let applyRate: Double
    let dismissRate: Double
    let averageResponseTime: TimeInterval
    let userEngagementScore: Double
    let goalImpactScore: Double
}

struct NudgeEffectivenessMetrics {
    let overallEffectiveness: Double
    let effectivenessByType: [NudgeType: Double]
    let effectivenessByCategory: [NudgeCategory: Double]
    let effectivenessByPriority: [NudgePriority: Double]
    let userFeedback: [NudgeFeedback]
    let improvementSuggestions: [String]
}

struct NudgeFeedback {
    let nudgeId: String
    let userId: String
    let wasEffective: Bool
    let feedback: String?
    let timestamp: Date
    let goalImpact: GoalImpact?
}

struct GoalImpact {
    let goalId: String
    let impactType: ImpactType
    let impactScore: Double
    let description: String
}

enum ImpactType: String, CaseIterable {
    case positive = "positive"
    case neutral = "neutral"
    case negative = "negative"
    
    var displayName: String {
        switch self {
        case .positive: return "Positive"
        case .neutral: return "Neutral"
        case .negative: return "Negative"
        }
    }
}

// MARK: - AI Nudge Repository Extensions
extension AINudgeRepository {
    // MARK: - Convenience Methods
    func getRecentNudges(forUserId: String, limit: Int = 10) async throws -> [Nudge] {
        let nudges = try await getNudges(forUserId: userId)
        return Array(nudges.prefix(limit))
    }
    
    func getActiveNudges(forUserId: String) async throws -> [Nudge] {
        let nudges = try await getNudges(forUserId: userId)
        return nudges.filter { !$0.isRead && !$0.isApplied }
    }
    
    func getNudgesByPriority(forUserId: String, priority: NudgePriority) async throws -> [Nudge] {
        return try await getNudges(byPriority: priority).filter { $0.userId == userId }
    }
    
    func getNudgesByType(forUserId: String, type: NudgeType) async throws -> [Nudge] {
        return try await getNudges(byType: type).filter { $0.userId == userId }
    }
    
    func getNudgesByCategory(forUserId: String, category: NudgeCategory) async throws -> [Nudge] {
        return try await getNudges(byCategory: category).filter { $0.userId == userId }
    }
    
    func getNudgesByStatus(forUserId: String, isRead: Bool, isApplied: Bool) async throws -> [Nudge] {
        let nudges = try await getNudges(forUserId: userId)
        return nudges.filter { $0.isRead == isRead && $0.isApplied == isApplied }
    }
    
    func getNudgesByDate(forUserId: String, date: Date) async throws -> [Nudge] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
        
        let dateInterval = DateInterval(start: startOfDay, end: endOfDay)
        return try await getNudges(byDateRange: dateInterval).filter { $0.userId == userId }
    }
    
    func getNudgesByWeek(forUserId: String, weekOfYear: Int, year: Int) async throws -> [Nudge] {
        let calendar = Calendar.current
        let dateComponents = DateComponents(weekOfYear: weekOfYear, yearForWeekOfYear: year)
        guard let startOfWeek = calendar.date(from: dateComponents),
              let endOfWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: startOfWeek) else {
            return []
        }
        
        let dateInterval = DateInterval(start: startOfWeek, end: endOfWeek)
        return try await getNudges(byDateRange: dateInterval).filter { $0.userId == userId }
    }
    
    func getNudgesByMonth(forUserId: String, month: Int, year: Int) async throws -> [Nudge] {
        let calendar = Calendar.current
        let dateComponents = DateComponents(month: month, year: year)
        guard let startOfMonth = calendar.date(from: dateComponents),
              let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) else {
            return []
        }
        
        let dateInterval = DateInterval(start: startOfMonth, end: endOfMonth)
        return try await getNudges(byDateRange: dateInterval).filter { $0.userId == userId }
    }
    
    func getNudgeCount(forUserId: String) async throws -> Int {
        let nudges = try await getNudges(forUserId: userId)
        return nudges.count
    }
    
    func getUnreadNudgeCount(forUserId: String) async throws -> Int {
        let unreadNudges = try await getUnreadNudges(forUserId: userId)
        return unreadNudges.count
    }
    
    func getAppliedNudgeCount(forUserId: String) async throws -> Int {
        let appliedNudges = try await getAppliedNudges(forUserId: userId)
        return appliedNudges.count
    }
    
    func getDismissedNudgeCount(forUserId: String) async throws -> Int {
        let dismissedNudges = try await getDismissedNudges(forUserId: userId)
        return dismissedNudges.count
    }
    
    func hasUnreadNudges(forUserId: String) async throws -> Bool {
        let unreadCount = try await getUnreadNudgeCount(forUserId: userId)
        return unreadCount > 0
    }
    
    func getNudgesByTypeAndStatus(forUserId: String, type: NudgeType, isRead: Bool, isApplied: Bool) async throws -> [Nudge] {
        let nudges = try await getNudges(forUserId: userId)
        return nudges.filter { $0.type == type && $0.isRead == isRead && $0.isApplied == isApplied }
    }
    
    func getNudgesByCategoryAndPriority(forUserId: String, category: NudgeCategory, priority: NudgePriority) async throws -> [Nudge] {
        let nudges = try await getNudges(forUserId: userId)
        return nudges.filter { $0.category == category && $0.priority == priority }
    }
    
    func getNudgesByDateRangeAndType(forUserId: String, dateRange: DateInterval, type: NudgeType) async throws -> [Nudge] {
        let nudges = try await getNudges(byDateRange: dateRange)
        return nudges.filter { $0.userId == userId && $0.type == type }
    }
    
    func getHighPriorityNudges(forUserId: String) async throws -> [Nudge] {
        let nudges = try await getNudges(forUserId: userId)
        return nudges.filter { $0.priority == .high && !$0.isRead }
    }
    
    func getWeeklyNudges(forUserId: String) async throws -> [Nudge] {
        let nudges = try await getNudges(forUserId: userId)
        let oneWeekAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60)
        return nudges.filter { $0.createdAt >= oneWeekAgo }
    }
}

// MARK: - AI Nudge Repository Error
enum AINudgeRepositoryError: LocalizedError {
    case nudgeNotFound
    case invalidNudgeData
    case nudgeAlreadyExists
    case invalidUserContext
    case nudgeGenerationFailed
    case insufficientPermissions
    case databaseError(Error)
    case networkError(Error)
    case permissionDenied
    case quotaExceeded
    
    var errorDescription: String? {
        switch self {
        case .nudgeNotFound:
            return "Nudge not found"
        case .invalidNudgeData:
            return "Invalid nudge data"
        case .nudgeAlreadyExists:
            return "Nudge already exists"
        case .invalidUserContext:
            return "Invalid user context for nudge generation"
        case .nudgeGenerationFailed:
            return "Failed to generate personalized nudge"
        case .insufficientPermissions:
            return "Insufficient permissions for this operation"
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
