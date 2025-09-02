import Foundation
import Combine

// MARK: - Stake Repository Protocol
protocol StakeRepository {
    // MARK: - CRUD Operations
    func createStake(_ stake: Stake) async throws -> Stake
    func getStake(id: String) async throws -> Stake
    func getStake(forGoalId: String) async throws -> Stake?
    func updateStake(_ stake: Stake) async throws -> Stake
    func deleteStake(id: String) async throws -> Bool
    
    // MARK: - Query Operations
    func getStakes(forUserId: String) async throws -> [Stake]
    func getStakes(forGroupId: String) async throws -> [Stake]
    func getStakes(forCorporateAccountId: String) async throws -> [Stake]
    func getStakes(byStatus: StakeStatus) async throws -> [Stake]
    func getStakes(byAPRModel: APRModel) async throws -> [Stake]
    func getStakes(byAccrualMethod: AccrualMethod) async throws -> [Stake]
    
    // MARK: - Financial Operations
    func getTotalStakeValue(forUserId: String) async throws -> Decimal
    func getTotalAccruedAmount(forUserId: String) async throws -> Decimal
    func getStakesByValueRange(min: Decimal, max: Decimal) async throws -> [Stake]
    
    // MARK: - Accrual Operations
    func updateAccruedAmount(forStakeId: String, newAmount: Decimal) async throws -> Stake
    func processDailyAccrual() async throws -> [Stake]
    func getStakesRequiringAccrual() async throws -> [Stake]
    
    // MARK: - Analytics Operations
    func getStakeStatistics(forUserId: String) async throws -> StakeStatistics
    func getStakePerformance(forUserId: String, timeRange: TimeRange) async throws -> StakePerformance
    func getTopPerformingStakes(forUserId: String, limit: Int) async throws -> [StakeWithPerformance]
    
    // MARK: - Bulk Operations
    func bulkUpdateStakes(_ stakes: [Stake]) async throws -> [Stake]
    func processBatchAccrual(stakeIds: [String]) async throws -> [Stake]
}

// MARK: - Supporting Models
struct StakeWithPerformance {
    let stake: Stake
    let performance: StakePerformance
    let goal: Goal?
}

struct StakeStatistics {
    let totalStakes: Int
    let activeStakes: Int
    let completedStakes: Int
    let failedStakes: Int
    let totalPrincipal: Decimal
    let totalAccrued: Decimal
    let averageAPR: Decimal
    let successRate: Double
}

struct StakePerformance {
    let totalReturn: Decimal
    let returnRate: Decimal
    let duration: TimeInterval
    let riskScore: Double
    let volatility: Double
}

// MARK: - Stake Repository Extensions
extension StakeRepository {
    // MARK: - Convenience Methods
    func getActiveStakes(forUserId: String) async throws -> [Stake] {
        return try await getStakes(byStatus: .active)
            .filter { $0.userId == userId }
    }
    
    func getStakesWithGoals(forUserId: String) async throws -> [StakeWithGoal] {
        let stakes = try await getStakes(forUserId: userId)
        
        return stakes.map { stake in
            StakeWithGoal(
                stake: stake,
                goal: nil // This would be populated by the implementation
            )
        }
    }
    
    func getStakesByDeadline(forUserId: String, withinDays days: Int = 30) async throws -> [Stake] {
        let activeStakes = try await getActiveStakes(forUserId: userId)
        let cutoffDate = Date().addingTimeInterval(TimeInterval(days * 24 * 60 * 60))
        
        // Note: This would need to be implemented with goal data
        // For now, return active stakes
        return activeStakes
    }
    
    func getHighValueStakes(forUserId: String, threshold: Decimal) async throws -> [Stake] {
        let stakes = try await getStakes(forUserId: userId)
        return stakes.filter { $0.principal >= threshold }
    }
    
    func getStakesByCategory(forUserId: String, category: GoalCategory) async throws -> [Stake] {
        let stakes = try await getStakes(forUserId: userId)
        
        // Note: This would need to be implemented with goal data
        // For now, return all stakes
        return stakes
    }
    
    func getStakesRequiringAttention(forUserId: String) async throws -> [Stake] {
        let activeStakes = try await getActiveStakes(forUserId: userId)
        
        return activeStakes.filter { stake in
            // Stakes that are close to deadline or have unusual activity
            let daysActive = stake.daysActive
            return daysActive > 30 && daysActive < 365 // Between 1 month and 1 year
        }
    }
    
    func getStakesForLiquidation() async throws -> [Stake] {
        let activeStakes = try await getStakes(byStatus: .active)
        
        return activeStakes.filter { stake in
            stake.canBeLiquidated
        }
    }
    
    func getStakesForDistribution() async throws -> [Stake] {
        let completedStakes = try await getStakes(byStatus: .completed)
        let failedStakes = try await getStakes(byStatus: .failed)
        
        return completedStakes + failedStakes
    }
}

// MARK: - Additional Supporting Models
struct StakeWithGoal {
    let stake: Stake
    let goal: Goal?
}

// MARK: - Stake Repository Error
enum StakeRepositoryError: LocalizedError {
    case stakeNotFound
    case invalidStakeData
    case insufficientFunds
    case stakeAlreadyExists
    case databaseError(Error)
    case networkError(Error)
    case permissionDenied
    case quotaExceeded
    
    var errorDescription: String? {
        switch self {
        case .stakeNotFound:
            return "Stake not found"
        case .invalidStakeData:
            return "Invalid stake data"
        case .insufficientFunds:
            return "Insufficient funds"
        case .stakeAlreadyExists:
            return "Stake already exists for this goal"
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

// MARK: - Accrual Schedule
enum AccrualSchedule {
    case daily
    case weekly
    case monthly
    case quarterly
    case annually
    
    var interval: TimeInterval {
        switch self {
        case .daily:
            return 24 * 60 * 60
        case .weekly:
            return 7 * 24 * 60 * 60
        case .monthly:
            return 30 * 24 * 60 * 60
        case .quarterly:
            return 90 * 24 * 60 * 60
        case .annually:
            return 365 * 24 * 60 * 60
        }
    }
    
    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .quarterly: return "Quarterly"
        case .annually: return "Annually"
        }
    }
}

// MARK: - Stake Calculation Request
struct StakeCalculationRequest {
    let principal: Decimal
    let apr: Decimal
    let startDate: Date
    let endDate: Date
    let accrualMethod: AccrualMethod
    let includeFees: Bool
    let includeProjections: Bool
}

struct StakeCalculationResult {
    let principal: Decimal
    let accruedAmount: Decimal
    let totalValue: Decimal
    let fees: FeeBreakdown
    let projections: [StakeProjection]
    let riskMetrics: StakeRiskMetrics
}

struct StakeProjection {
    let date: Date
    let projectedValue: Decimal
    let projectedAccrued: Decimal
    let confidence: Double
}

struct StakeRiskMetrics {
    let volatility: Double
    let maxDrawdown: Decimal
    let sharpeRatio: Double
    let riskScore: Double
}
