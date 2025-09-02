import Foundation
import Combine

// MARK: - Goal Repository Protocol
protocol GoalRepository {
    // MARK: - CRUD Operations
    func createGoal(_ goal: Goal) async throws -> Goal
    func getGoal(id: String) async throws -> Goal
    func updateGoal(_ goal: Goal) async throws -> Goal
    func deleteGoal(id: String) async throws -> Bool
    
    // MARK: - Query Operations
    func getGoals(forUserId: String) async throws -> [Goal]
    func getGoals(forGroupId: String) async throws -> [Goal]
    func getGoals(forCorporateAccountId: String) async throws -> [Goal]
    func getGoals(byStatus: GoalStatus) async throws -> [Goal]
    func getGoals(byCategory: GoalCategory) async throws -> [Goal]
    func getGoals(byDateRange: DateInterval) async throws -> [Goal]
    
    // MARK: - Search Operations
    func searchGoals(query: String, userId: String?) async throws -> [Goal]
    func getGoalsWithStakes(forUserId: String) async throws -> [GoalWithStake]
    
    // MARK: - Analytics Operations
    func getGoalStatistics(forUserId: String) async throws -> GoalStatistics
    func getGoalCompletionRate(forUserId: String, timeRange: TimeRange) async throws -> Double
    
    // MARK: - Bulk Operations
    func bulkUpdateGoals(_ goals: [Goal]) async throws -> [Goal]
    func deleteExpiredGoals() async throws -> Int
}

// MARK: - Supporting Models
struct GoalWithStake {
    let goal: Goal
    let stake: Stake?
}

struct GoalStatistics {
    let totalGoals: Int
    let activeGoals: Int
    let completedGoals: Int
    let failedGoals: Int
    let totalStakeAmount: Decimal
    let averageCompletionTime: TimeInterval
    let successRate: Double
}

enum TimeRange {
    case week
    case month
    case quarter
    case year
    case custom(DateInterval)
    
    var dateInterval: DateInterval {
        let now = Date()
        let calendar = Calendar.current
        
        switch self {
        case .week:
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            return DateInterval(start: startOfWeek, end: now)
            
        case .month:
            let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
            return DateInterval(start: startOfMonth, end: now)
            
        case .quarter:
            let quarter = (calendar.component(.month, from: now) - 1) / 3
            let startOfQuarter = calendar.date(from: DateComponents(year: calendar.component(.year, from: now), month: quarter * 3 + 1, day: 1)) ?? now
            return DateInterval(start: startOfQuarter, end: now)
            
        case .year:
            let startOfYear = calendar.dateInterval(of: .year, for: now)?.start ?? now
            return DateInterval(start: startOfYear, end: now)
            
        case .custom(let interval):
            return interval
        }
    }
}

// MARK: - Goal Repository Extensions
extension GoalRepository {
    // MARK: - Convenience Methods
    func getActiveGoals(forUserId: String) async throws -> [Goal] {
        return try await getGoals(byStatus: .active)
            .filter { $0.ownerId == userId }
    }
    
    func getOverdueGoals(forUserId: String) async throws -> [Goal] {
        let activeGoals = try await getActiveGoals(forUserId: userId)
        return activeGoals.filter { $0.isOverdue }
    }
    
    func getUpcomingDeadlines(forUserId: String, withinDays days: Int = 7) async throws -> [Goal] {
        let activeGoals = try await getActiveGoals(forUserId: userId)
        let cutoffDate = Date().addingTimeInterval(TimeInterval(days * 24 * 60 * 60))
        
        return activeGoals.filter { goal in
            goal.endDate <= cutoffDate && goal.endDate > Date()
        }
    }
    
    func getGoalsByPriority(forUserId: String) async throws -> [Goal] {
        let goals = try await getGoals(forUserId: userId)
        
        return goals.sorted { goal1, goal2 in
            // Sort by deadline (closest first), then by stake amount (highest first)
            if goal1.daysRemaining != goal2.daysRemaining {
                return goal1.daysRemaining < goal2.daysRemaining
            } else {
                return goal1.stakeAmount > goal2.stakeAmount
            }
        }
    }
    
    func getGoalsWithProgress(forUserId: String) async throws -> [GoalWithProgress] {
        let goals = try await getGoals(forUserId: userId)
        
        return goals.map { goal in
            GoalWithProgress(
                goal: goal,
                progress: goal.progress,
                daysRemaining: goal.daysRemaining,
                isOverdue: goal.isOverdue
            )
        }
    }
}

// MARK: - Additional Supporting Models
struct GoalWithProgress {
    let goal: Goal
    let progress: Double
    let daysRemaining: Int
    let isOverdue: Bool
}

// MARK: - Goal Repository Error
enum GoalRepositoryError: LocalizedError {
    case goalNotFound
    case invalidGoalData
    case databaseError(Error)
    case networkError(Error)
    case permissionDenied
    case quotaExceeded
    
    var errorDescription: String? {
        switch self {
        case .goalNotFound:
            return "Goal not found"
        case .invalidGoalData:
            return "Invalid goal data"
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
