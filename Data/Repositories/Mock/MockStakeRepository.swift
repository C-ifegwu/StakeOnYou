import Foundation
import Combine

// MARK: - Mock Stake Repository Implementation
class MockStakeRepository: StakeRepository {
    // MARK: - Properties
    private var stakes: [String: Stake] = [:]
    private let logger: Logger
    
    // MARK: - Initialization
    init(logger: Logger = ConsoleLogger()) {
        self.logger = logger
        setupMockData()
    }
    
    // MARK: - CRUD Operations
    func createStake(_ stake: Stake) async throws -> Stake {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        var newStake = stake
        if newStake.id.isEmpty {
            newStake = Stake(
                id: UUID().uuidString,
                principal: stake.principal,
                apr: stake.apr,
                accrualMethod: stake.accrualMethod,
                startDate: stake.startDate,
                endDate: stake.endDate,
                status: stake.status,
                userId: stake.userId,
                goalId: stake.goalId,
                currentAccruedAmount: stake.currentAccruedAmount,
                lastAccrualDate: stake.lastAccrualDate,
                bonusPercentage: stake.bonusPercentage,
                charityId: stake.charityId,
                notes: stake.notes,
                createdAt: Date(),
                updatedAt: Date()
            )
        }
        
        stakes[newStake.id] = newStake
        logger.info("Mock: Created stake with ID: \(newStake.id)")
        return newStake
    }
    
    func getStake(id: String) async throws -> Stake? {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 200_000_000)
        
        let stake = stakes[id]
        logger.info("Mock: Retrieved stake with ID: \(id), found: \(stake != nil)")
        return stake
    }
    
    func updateStake(_ stake: Stake) async throws -> Stake {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        guard stakes[stake.id] != nil else {
            throw StakeRepositoryError.stakeNotFound
        }
        
        var updatedStake = stake
        updatedStake.updatedAt = Date()
        stakes[stake.id] = updatedStake
        
        logger.info("Mock: Updated stake with ID: \(stake.id)")
        return updatedStake
    }
    
    func deleteStake(id: String) async throws -> Bool {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        guard stakes[id] != nil else {
            throw StakeRepositoryError.stakeNotFound
        }
        
        stakes.removeValue(forKey: id)
        logger.info("Mock: Deleted stake with ID: \(id)")
        return true
    }
    
    // MARK: - Query Operations
    func getStakes(forUserId: String) async throws -> [Stake] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let userStakes = stakes.values.filter { $0.userId == userId }
        logger.info("Mock: Retrieved \(userStakes.count) stakes for user: \(userId)")
        return userStakes
    }
    
    func getStakes(byGroupId: String) async throws -> [Stake] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        // Mock implementation - return stakes that might be group-related
        let groupStakes = stakes.values.filter { $0.status == .active }
        logger.info("Mock: Retrieved \(groupStakes.count) group stakes for group: \(groupId)")
        return groupStakes
    }
    
    func getStakes(byCorporateId: String) async throws -> [Stake] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        // Mock implementation - return stakes that might be corporate-related
        let corporateStakes = stakes.values.filter { $0.principal >= 1000 }
        logger.info("Mock: Retrieved \(corporateStakes.count) corporate stakes for corporate: \(corporateId)")
        return corporateStakes
    }
    
    func getStakes(byStatus: StakeStatus) async throws -> [Stake] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 200_000_000)
        
        let statusStakes = stakes.values.filter { $0.status == status }
        logger.info("Mock: Retrieved \(statusStakes.count) stakes with status: \(status)")
        return statusStakes
    }
    
    func getStakes(byAPRModel: APRModel) async throws -> [Stake] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 200_000_000)
        
        let aprStakes = stakes.values.filter { $0.apr == APRModel.fixed(rate: 0.05).rate }
        logger.info("Mock: Retrieved \(aprStakes.count) stakes with APR model: \(aprModel)")
        return aprStakes
    }
    
    func getStakes(byAccrualMethod: AccrualMethod) async throws -> [Stake] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 200_000_000)
        
        let accrualStakes = stakes.values.filter { $0.accrualMethod == accrualMethod }
        logger.info("Mock: Retrieved \(accrualStakes.count) stakes with accrual method: \(accrualMethod)")
        return accrualStakes
    }
    
    func getStakes(byDateRange: DateInterval) async throws -> [Stake] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let dateRangeStakes = stakes.values.filter { stake in
            guard let startDate = stake.startDate, let endDate = stake.endDate else { return false }
            return startDate >= dateRange.start && endDate <= dateRange.end
        }
        
        logger.info("Mock: Retrieved \(dateRangeStakes.count) stakes in date range")
        return dateRangeStakes
    }
    
    // MARK: - Financial Operations
    func getTotalStakeValue(forUserId: String) async throws -> Decimal {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 200_000_000)
        
        let userStakes = stakes.values.filter { $0.userId == userId }
        let totalValue = userStakes.reduce(Decimal.zero) { $0 + $1.principal + $1.currentAccruedAmount }
        
        logger.info("Mock: Calculated total stake value: \(totalValue) for user: \(userId)")
        return totalValue
    }
    
    func getTotalAccruedAmount(forUserId: String) async throws -> Decimal {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 200_000_000)
        
        let userStakes = stakes.values.filter { $0.userId == userId }
        let totalAccrued = userStakes.reduce(Decimal.zero) { $0 + $1.currentAccruedAmount }
        
        logger.info("Mock: Calculated total accrued amount: \(totalAccrued) for user: \(userId)")
        return totalAccrued
    }
    
    func getStakes(byValueRange: ClosedRange<Decimal>) async throws -> [Stake] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let valueRangeStakes = stakes.values.filter { stake in
            let totalValue = stake.principal + stake.currentAccruedAmount
            return totalValue >= valueRange.lowerBound && totalValue <= valueRange.upperBound
        }
        
        logger.info("Mock: Retrieved \(valueRangeStakes.count) stakes in value range")
        return valueRangeStakes
    }
    
    // MARK: - Accrual Operations
    func updateAccruedAmount(stakeId: String, newAmount: Decimal) async throws -> Stake {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        guard var stake = stakes[stakeId] else {
            throw StakeRepositoryError.stakeNotFound
        }
        
        stake.currentAccruedAmount = newAmount
        stake.lastAccrualDate = Date()
        stake.updatedAt = Date()
        
        stakes[stakeId] = stake
        logger.info("Mock: Updated accrued amount to \(newAmount) for stake: \(stakeId)")
        return stake
    }
    
    func processDailyAccrual() async throws -> [Stake] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        let activeStakes = stakes.values.filter { $0.status == .active }
        var updatedStakes: [Stake] = []
        
        for var stake in activeStakes {
            // Simple daily accrual calculation (5% APR / 365 days)
            let dailyRate = stake.apr / 365
            let dailyAccrual = stake.principal * dailyRate
            
            stake.currentAccruedAmount += dailyAccrual
            stake.lastAccrualDate = Date()
            stake.updatedAt = Date()
            
            stakes[stake.id] = stake
            updatedStakes.append(stake)
        }
        
        logger.info("Mock: Processed daily accrual for \(updatedStakes.count) stakes")
        return updatedStakes
    }
    
    func getStakesRequiringAccrual() async throws -> [Stake] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 200_000_000)
        
        let now = Date()
        let oneDayAgo = now.addingTimeInterval(-24 * 60 * 60)
        
        let stakesRequiringAccrual = stakes.values.filter { stake in
            guard stake.status == .active else { return false }
            guard let lastAccrual = stake.lastAccrualDate else { return true }
            return lastAccrual < oneDayAgo
        }
        
        logger.info("Mock: Found \(stakesRequiringAccrual.count) stakes requiring accrual")
        return stakesRequiringAccrual
    }
    
    // MARK: - Analytics Operations
    func getStakeStatistics(forUserId: String) async throws -> StakeStatistics {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        let userStakes = stakes.values.filter { $0.ownerId == userId }
        let totalStakes = userStakes.count
        let activeStakes = userStakes.filter { $0.status == .active }.count
        let completedStakes = userStakes.filter { $0.status == .completed }.count
        let forfeitedStakes = userStakes.filter { $0.status == .forfeited }.count
        
        let totalPrincipal = userStakes.reduce(Decimal.zero) { $0 + $1.principal }
        let totalAccrued = userStakes.reduce(Decimal.zero) { $0 + $1.currentAccruedAmount }
        let averageAPR = userStakes.reduce(Decimal.zero) { $0 + $1.apr } / Decimal(max(userStakes.count, 1))
        
        let statistics = StakeStatistics(
            totalStakes: totalStakes,
            activeStakes: activeStakes,
            completedStakes: completedStakes,
            forfeitedStakes: forfeitedStakes,
            totalPrincipal: totalPrincipal,
            totalAccrued: totalAccrued,
            averageAPR: averageAPR,
            successRate: totalStakes > 0 ? Double(completedStakes) / Double(totalStakes) : 0.0
        )
        
        logger.info("Mock: Generated stake statistics for user: \(userId)")
        return statistics
    }
    
    func getStakePerformance(forUserId: String, timeRange: TimeRange) async throws -> StakePerformance {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let userStakes = stakes.values.filter { $0.ownerId == userId }
        let stakesInTimeRange = userStakes.filter { stake in
            guard let startDate = stake.startDate else { return false }
            return startDate >= timeRange.start && startDate <= timeRange.end
        }
        
        let totalReturn = stakesInTimeRange.reduce(Decimal.zero) { $0 + $1.currentAccruedAmount }
        let totalPrincipal = stakesInTimeRange.reduce(Decimal.zero) { $0 + $1.principal }
        let returnRate = totalPrincipal > 0 ? totalReturn / totalPrincipal : Decimal.zero
        
        let performance = StakePerformance(
            totalStakes: stakesInTimeRange.count,
            totalPrincipal: totalPrincipal,
            totalReturn: totalReturn,
            returnRate: returnRate,
            averageStakeDuration: 0.0, // Would need actual calculation
            topPerformingStakes: []
        )
        
        logger.info("Mock: Generated stake performance for user: \(userId)")
        return performance
    }
    
    func getTopPerformingStakes(limit: Int) async throws -> [StakeWithPerformance] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        let activeStakes = stakes.values.filter { $0.status == .active }
        let stakesWithPerformance = activeStakes.map { stake in
            StakeWithPerformance(
                stake: stake,
                returnRate: stake.currentAccruedAmount / stake.principal,
                daysActive: Calendar.current.dateComponents([.day], from: stake.startDate, to: Date()).day ?? 0,
                projectedReturn: stake.currentAccruedAmount * 1.1 // Mock projection
            )
        }
        
        let sortedStakes = stakesWithPerformance.sorted { $0.returnRate > $1.returnRate }
        let topStakes = Array(sortedStakes.prefix(limit))
        
        logger.info("Mock: Retrieved top \(topStakes.count) performing stakes")
        return topStakes
    }
    
    // MARK: - Bulk Operations
    func bulkUpdateStakes(_ stakes: [Stake]) async throws -> [Stake] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        var updatedStakes: [Stake] = []
        
        for stake in stakes {
            if let existingStake = self.stakes[stake.id] {
                var updatedStake = stake
                updatedStake.updatedAt = Date()
                self.stakes[stake.id] = updatedStake
                updatedStakes.append(updatedStake)
            }
        }
        
        logger.info("Mock: Bulk updated \(updatedStakes.count) stakes")
        return updatedStakes
    }
    
    func processBatchAccrual(stakeIds: [String]) async throws -> [Stake] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 800_000_000)
        
        var updatedStakes: [Stake] = []
        
        for stakeId in stakeIds {
            if var stake = stakes[stakeId] {
                // Simple daily accrual calculation
                let dailyRate = stake.apr / 365
                let dailyAccrual = stake.principal * dailyRate
                
                stake.currentAccruedAmount += dailyAccrual
                stake.lastAccrualDate = Date()
                stake.updatedAt = Date()
                
                stakes[stakeId] = stake
                updatedStakes.append(stake)
            }
        }
        
        logger.info("Mock: Processed batch accrual for \(updatedStakes.count) stakes")
        return updatedStakes
    }
    
    // MARK: - Private Helper Methods
    private func setupMockData() {
        // Create some mock stakes for testing
        let mockStakes = [
            Stake(
                id: "stake-1",
                principal: 100.0,
                apr: 0.05, // 5% APR
                accrualMethod: .daily,
                startDate: Date().addingTimeInterval(-7 * 24 * 60 * 60), // 7 days ago
                endDate: Date().addingTimeInterval(30 * 24 * 60 * 60), // 30 days from now
                status: .active,
                userId: "user-1",
                goalId: "goal-1",
                currentAccruedAmount: 2.0, // 7 days of accrual
                lastAccrualDate: Date().addingTimeInterval(-24 * 60 * 60), // 1 day ago
                bonusPercentage: 0.0,
                charityId: nil,
                notes: [],
                createdAt: Date().addingTimeInterval(-7 * 24 * 60 * 60),
                updatedAt: Date().addingTimeInterval(-24 * 60 * 60)
            ),
            Stake(
                id: "stake-2",
                principal: 50.0,
                apr: 0.06, // 6% APR
                accrualMethod: .daily,
                startDate: Date().addingTimeInterval(-14 * 24 * 60 * 60), // 14 days ago
                endDate: Date().addingTimeInterval(21 * 24 * 60 * 60), // 21 days from now
                status: .active,
                userId: "user-1",
                goalId: "goal-2",
                currentAccruedAmount: 1.5, // 14 days of accrual
                lastAccrualDate: Date().addingTimeInterval(-24 * 60 * 60), // 1 day ago
                bonusPercentage: 0.0,
                charityId: nil,
                notes: [],
                createdAt: Date().addingTimeInterval(-14 * 24 * 60 * 60),
                updatedAt: Date().addingTimeInterval(-24 * 60 * 60)
            ),
            Stake(
                id: "stake-3",
                principal: 200.0,
                apr: 0.04, // 4% APR
                accrualMethod: .daily,
                startDate: Date(timeIntervalSince1970: 1640995200), // January 1, 2022
                endDate: Date(timeIntervalSince1970: 1672531200), // December 31, 2022
                status: .completed,
                userId: "user-1",
                goalId: "goal-3",
                currentAccruedAmount: 8.0, // Full year of accrual
                lastAccrualDate: Date(timeIntervalSince1970: 1672531200),
                bonusPercentage: 0.0,
                charityId: nil,
                notes: [],
                createdAt: Date(timeIntervalSince1970: 1640995200),
                updatedAt: Date(timeIntervalSince1970: 1672531200)
            )
        ]
        
        for stake in mockStakes {
            stakes[stake.id] = stake
        }
        
        logger.info("Mock: Setup \(mockStakes.count) mock stakes")
    }
}
