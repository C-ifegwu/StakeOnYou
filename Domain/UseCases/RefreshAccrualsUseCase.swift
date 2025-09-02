import Foundation
import Combine

// MARK: - Refresh Accruals Use Case
struct RefreshAccrualsUseCase {
    private let stakeRepository: StakeRepository
    private let stakingMathUseCase: StakingMathUseCase
    private let userRepository: UserRepository
    private let analyticsService: AnalyticsService
    
    init(
        stakeRepository: StakeRepository,
        stakingMathUseCase: StakingMathUseCase,
        userRepository: UserRepository,
        analyticsService: AnalyticsService
    ) {
        self.stakeRepository = stakeRepository
        self.stakingMathUseCase = stakingMathUseCase
        self.userRepository = userRepository
        self.analyticsService = analyticsService
    }
    
    func execute(userId: String? = nil) async throws -> AccrualRefreshResult {
        // Track analytics
        analyticsService.track(event: .accrualRefreshStarted(userId: userId))
        
        // Get stakes that require accrual updates
        let stakesToUpdate = try await getStakesRequiringAccrual(userId: userId)
        
        guard !stakesToUpdate.isEmpty else {
            return AccrualRefreshResult(
                stakesUpdated: 0,
                totalAccrued: 0,
                errors: [],
                timestamp: Date()
            )
        }
        
        var updatedStakes: [Stake] = []
        var totalAccrued: Decimal = 0
        var errors: [String] = []
        
        // Process each stake
        for stake in stakesToUpdate {
            do {
                let updatedStake = try await refreshStakeAccrual(stake)
                updatedStakes.append(updatedStake)
                totalAccrued += updatedStake.accruedAmount - stake.accruedAmount
            } catch {
                let errorMessage = "Failed to update stake \(stake.id): \(error.localizedDescription)"
                errors.append(errorMessage)
                analyticsService.track(event: .accrualUpdateFailed(
                    userId: stake.userId,
                    stakeId: stake.id,
                    error: error.localizedDescription
                ))
            }
        }
        
        // Batch update stakes in repository
        if !updatedStakes.isEmpty {
            try await stakeRepository.bulkUpdateStakes(updatedStakes)
        }
        
        // Track successful refresh
        analyticsService.track(event: .accrualRefreshCompleted(
            userId: userId,
            stakesUpdated: updatedStakes.count,
            totalAccrued: totalAccrued
        ))
        
        return AccrualRefreshResult(
            stakesUpdated: updatedStakes.count,
            totalAccrued: totalAccrued,
            errors: errors,
            timestamp: Date()
        )
    }
    
    func refreshStakeAccrual(_ stake: Stake) async throws -> Stake {
        // Calculate new accrued amount
        let newAccruedAmount = try await stakingMathUseCase.calculateAccruedAmount(
            stake: stake,
            asOf: Date()
        )
        
        // Create updated stake
        var updatedStake = stake
        updatedStake.accruedAmount = newAccruedAmount
        updatedStake.lastAccrualUpdate = Date()
        
        // Check if stake should be liquidated
        if shouldLiquidateStake(updatedStake) {
            updatedStake.status = .liquidated
            updatedStake.liquidatedAt = Date()
            
            // Track liquidation
            analyticsService.track(event: .stakeLiquidated(
                userId: stake.userId,
                stakeId: stake.id,
                reason: "deadline_passed"
            ))
        }
        
        return updatedStake
    }
    
    func refreshUserAccruals(userId: String) async throws -> UserAccrualResult {
        let userStakes = try await stakeRepository.getStakes(userId: userId, status: .active)
        
        var totalAccrued: Decimal = 0
        var updatedStakes: [Stake] = []
        
        for stake in userStakes {
            let updatedStake = try await refreshStakeAccrual(stake)
            updatedStakes.append(updatedStake)
            totalAccrued += updatedStake.accruedAmount
        }
        
        // Update stakes in repository
        if !updatedStakes.isEmpty {
            try await stakeRepository.bulkUpdateStakes(updatedStakes)
        }
        
        return UserAccrualResult(
            userId: userId,
            stakesCount: updatedStakes.count,
            totalAccrued: totalAccrued,
            timestamp: Date()
        )
    }
    
    func getAccrualProjections(for stake: Stake, days: Int = 30) async throws -> [AccrualProjection] {
        var projections: [AccrualProjection] = []
        let calendar = Calendar.current
        let today = Date()
        
        for day in 0...days {
            guard let futureDate = calendar.date(byAdding: .day, value: day, to: today) else {
                continue
            }
            
            let projectedAmount = try await stakingMathUseCase.calculateProjectedAccrual(
                stake: stake,
                asOf: futureDate
            )
            
            let projection = AccrualProjection(
                date: futureDate,
                accruedAmount: projectedAmount,
                dailyAccrual: projectedAmount - stake.accruedAmount,
                totalValue: stake.amount + projectedAmount
            )
            
            projections.append(projection)
        }
        
        return projections
    }
    
    func processDailyAccruals() async throws -> DailyAccrualResult {
        // Get all active stakes
        let activeStakes = try await stakeRepository.getStakes(status: .active)
        
        var processedCount = 0
        var totalAccrued: Decimal = 0
        var errors: [String] = []
        
        // Group stakes by user for batch processing
        let stakesByUser = Dictionary(grouping: activeStakes) { $0.userId }
        
        for (userId, userStakes) in stakesByUser {
            do {
                let userResult = try await refreshUserAccruals(userId: userId)
                processedCount += userResult.stakesCount
                totalAccrued += userResult.totalAccrued
            } catch {
                let errorMessage = "Failed to process accruals for user \(userId): \(error.localizedDescription)"
                errors.append(errorMessage)
            }
        }
        
        return DailyAccrualResult(
            processedCount: processedCount,
            totalAccrued: totalAccrued,
            errors: errors,
            timestamp: Date()
        )
    }
    
    func getAccrualSummary(userId: String) async throws -> AccrualSummary {
        let userStakes = try await stakeRepository.getStakes(userId: userId, status: .active)
        
        let totalStakeValue = userStakes.reduce(0) { $0 + $1.amount }
        let totalAccrued = userStakes.reduce(0) { $0 + $1.accruedAmount }
        let averageAPR = userStakes.isEmpty ? 0 : userStakes.reduce(0) { $0 + $1.apr } / Decimal(userStakes.count)
        
        let todayAccrual = try await calculateTodayAccrual(for: userStakes)
        let weeklyAccrual = try await calculateWeeklyAccrual(for: userStakes)
        let monthlyAccrual = try await calculateMonthlyAccrual(for: userStakes)
        
        return AccrualSummary(
            userId: userId,
            totalStakes: userStakes.count,
            totalStakeValue: totalStakeValue,
            totalAccrued: totalAccrued,
            averageAPR: averageAPR,
            todayAccrual: todayAccrual,
            weeklyAccrual: weeklyAccrual,
            monthlyAccrual: monthlyAccrual,
            lastUpdated: Date()
        )
    }
    
    // MARK: - Private Methods
    
    private func getStakesRequiringAccrual(userId: String?) async throws -> [Stake] {
        if let userId = userId {
            return try await stakeRepository.getStakesRequiringAccrual(userId: userId)
        } else {
            return try await stakeRepository.getStakesRequiringAccrual()
        }
    }
    
    private func shouldLiquidateStake(_ stake: Stake) -> Bool {
        // Check if stake deadline has passed
        if Date() > stake.deadline {
            return true
        }
        
        // Check if stake has reached maximum value (if applicable)
        if let maxValue = stake.maxValue, stake.amount + stake.accruedAmount >= maxValue {
            return true
        }
        
        // Check if user has requested liquidation
        if stake.status == .pendingLiquidation {
            return true
        }
        
        return false
    }
    
    private func calculateTodayAccrual(for stakes: [Stake]) async throws -> Decimal {
        var totalAccrual: Decimal = 0
        
        for stake in stakes {
            let todayAccrual = try await stakingMathUseCase.calculateAccruedAmount(
                stake: stake,
                asOf: Date()
            ) - stake.accruedAmount
            
            totalAccrual += todayAccrual
        }
        
        return totalAccrual
    }
    
    private func calculateWeeklyAccrual(for stakes: [Stake]) async throws -> Decimal {
        var totalAccrual: Decimal = 0
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        for stake in stakes {
            let weeklyAccrual = try await stakingMathUseCase.calculateAccruedAmount(
                stake: stake,
                asOf: Date()
            ) - (stake.lastAccrualUpdate ?? weekAgo)
            
            totalAccrual += weeklyAccrual
        }
        
        return totalAccrual
    }
    
    private func calculateMonthlyAccrual(for stakes: [Stake]) async throws -> Decimal {
        var totalAccrual: Decimal = 0
        let calendar = Calendar.current
        let monthAgo = calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        
        for stake in stakes {
            let monthlyAccrual = try await stakingMathUseCase.calculateAccruedAmount(
                stake: stake,
                asOf: Date()
            ) - (stake.lastAccrualUpdate ?? monthAgo)
            
            totalAccrual += monthlyAccrual
        }
        
        return totalAccrual
    }
}

// MARK: - Supporting Structures
struct AccrualRefreshResult: Codable, Equatable {
    let stakesUpdated: Int
    let totalAccrued: Decimal
    let errors: [String]
    let timestamp: Date
}

struct UserAccrualResult: Codable, Equatable {
    let userId: String
    let stakesCount: Int
    let totalAccrued: Decimal
    let timestamp: Date
}

struct DailyAccrualResult: Codable, Equatable {
    let processedCount: Int
    let totalAccrued: Decimal
    let errors: [String]
    let timestamp: Date
}

struct AccrualProjection: Codable, Equatable {
    let date: Date
    let accruedAmount: Decimal
    let dailyAccrual: Decimal
    let totalValue: Decimal
}

struct AccrualSummary: Codable, Equatable {
    let userId: String
    let totalStakes: Int
    let totalStakeValue: Decimal
    let totalAccrued: Decimal
    let averageAPR: Decimal
    let todayAccrual: Decimal
    let weeklyAccrual: Decimal
    let monthlyAccrual: Decimal
    let lastUpdated: Date
}

// MARK: - Analytics Events
extension AnalyticsEvent {
    static func accrualRefreshStarted(userId: String?) -> AnalyticsEvent {
        var properties: [String: Any] = [
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if let userId = userId {
            properties["user_id"] = userId
        }
        
        return AnalyticsEvent(
            name: "accrual_refresh_started",
            properties: properties
        )
    }
    
    static func accrualRefreshCompleted(
        userId: String?,
        stakesUpdated: Int,
        totalAccrued: Decimal
    ) -> AnalyticsEvent {
        var properties: [String: Any] = [
            "stakes_updated": stakesUpdated,
            "total_accrued": Double(truncating: totalAccrued as NSDecimalNumber),
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if let userId = userId {
            properties["user_id"] = userId
        }
        
        return AnalyticsEvent(
            name: "accrual_refresh_completed",
            properties: properties
        )
    }
    
    static func accrualUpdateFailed(
        userId: String,
        stakeId: String,
        error: String
    ) -> AnalyticsEvent {
        AnalyticsEvent(
            name: "accrual_update_failed",
            properties: [
                "user_id": userId,
                "stake_id": stakeId,
                "error": error,
                "timestamp": Date().timeIntervalSince1970
            ]
        )
    }
    
    static func stakeLiquidated(
        userId: String,
        stakeId: String,
        reason: String
    ) -> AnalyticsEvent {
        AnalyticsEvent(
            name: "stake_liquidated",
            properties: [
                "user_id": userId,
                "stake_id": stakeId,
                "reason": reason,
                "timestamp": Date().timeIntervalSince1970
            ]
        )
    }
}
