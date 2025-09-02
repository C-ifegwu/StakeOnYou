import Foundation
import CoreData
import Combine

// MARK: - Core Data Stake Repository Implementation
class CoreDataStakeRepository: StakeRepository {
    private let coreDataStack: CoreDataStack
    private let logger: Logger
    private let stakingMathUseCase: StakingMathUseCase
    
    init(coreDataStack: CoreDataStack, logger: Logger, stakingMathUseCase: StakingMathUseCase) {
        self.coreDataStack = coreDataStack
        self.logger = logger
        self.stakingMathUseCase = stakingMathUseCase
    }
    
    // MARK: - CRUD Operations
    func createStake(_ stake: Stake) async throws -> Stake {
        return try await coreDataStack.performBackgroundTask { context in
            let stakeEntity = StakeEntity(context: context)
            stakeEntity.id = stake.id
            stakeEntity.goalId = stake.goalId
            stakeEntity.userId = stake.userId
            stakeEntity.principal = NSDecimalNumber(decimal: stake.principal)
            stakeEntity.startAt = stake.startAt
            stakeEntity.aprModel = stake.aprModel.rawValue
            stakeEntity.accrualMethod = stake.accrualMethod.rawValue
            stakeEntity.accruedAmount = NSDecimalNumber(decimal: stake.accruedAmount)
            stakeEntity.feeRateOnStake = NSDecimalNumber(decimal: stake.feeRateOnStake)
            stakeEntity.feeRateOnWithdrawal = NSDecimalNumber(decimal: stake.feeRateOnWithdrawal)
            stakeEntity.lastAccrualAt = stake.lastAccrualAt
            stakeEntity.status = stake.status.rawValue
            stakeEntity.createdAt = stake.createdAt
            stakeEntity.updatedAt = stake.updatedAt
            stakeEntity.earlyCompletionBonus = stake.earlyCompletionBonus.map { NSDecimalNumber(decimal: $0) }
            stakeEntity.charityId = stake.charityId
            stakeEntity.groupId = stake.groupId
            stakeEntity.corporateAccountId = stake.corporateAccountId
            
            // Create stake notes
            for note in stake.notes {
                let noteEntity = StakeNoteEntity(context: context)
                noteEntity.id = note.id
                noteEntity.content = note.content
                noteEntity.authorId = note.authorId
                noteEntity.createdAt = note.createdAt
                noteEntity.updatedAt = note.updatedAt
                noteEntity.type = note.type.rawValue
                noteEntity.stake = stakeEntity
            }
            
            try context.save()
            
            self.logger.log(.info, "Created stake with ID: \(stake.id)")
            return stake
        }
    }
    
    func getStake(id: String) async throws -> Stake {
        return try await coreDataStack.performBackgroundTask { context in
            let fetchRequest: NSFetchRequest<StakeEntity> = StakeEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id)
            fetchRequest.fetchLimit = 1
            
            let results = try context.fetch(fetchRequest)
            guard let stakeEntity = results.first else {
                throw StakeRepositoryError.stakeNotFound
            }
            
            return try self.mapEntityToStake(stakeEntity)
        }
    }
    
    func getStake(forGoalId: String) async throws -> Stake? {
        return try await coreDataStack.performBackgroundTask { context in
            let fetchRequest: NSFetchRequest<StakeEntity> = StakeEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "goalId == %@", forGoalId)
            fetchRequest.fetchLimit = 1
            
            let results = try context.fetch(fetchRequest)
            guard let stakeEntity = results.first else {
                return nil
            }
            
            return try self.mapEntityToStake(stakeEntity)
        }
    }
    
    func updateStake(_ stake: Stake) async throws -> Stake {
        return try await coreDataStack.performBackgroundTask { context in
            let fetchRequest: NSFetchRequest<StakeEntity> = StakeEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", stake.id)
            fetchRequest.fetchLimit = 1
            
            let results = try context.fetch(fetchRequest)
            guard let stakeEntity = results.first else {
                throw StakeRepositoryError.stakeNotFound
            }
            
            // Update fields
            stakeEntity.principal = NSDecimalNumber(decimal: stake.principal)
            stakeEntity.accruedAmount = NSDecimalNumber(decimal: stake.accruedAmount)
            stakeEntity.feeRateOnStake = NSDecimalNumber(decimal: stake.feeRateOnStake)
            stakeEntity.feeRateOnWithdrawal = NSDecimalNumber(decimal: stake.feeRateOnWithdrawal)
            stakeEntity.lastAccrualAt = stake.lastAccrualAt
            stakeEntity.status = stake.status.rawValue
            stakeEntity.updatedAt = Date()
            stakeEntity.earlyCompletionBonus = stake.earlyCompletionBonus.map { NSDecimalNumber(decimal: $0) }
            stakeEntity.charityId = stake.charityId
            stakeEntity.groupId = stake.groupId
            stakeEntity.corporateAccountId = stake.corporateAccountId
            
            try context.save()
            
            self.logger.log(.info, "Updated stake with ID: \(stake.id)")
            return stake
        }
    }
    
    func deleteStake(id: String) async throws -> Bool {
        return try await coreDataStack.performBackgroundTask { context in
            let fetchRequest: NSFetchRequest<StakeEntity> = StakeEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id)
            fetchRequest.fetchLimit = 1
            
            let results = try context.fetch(fetchRequest)
            guard let stakeEntity = results.first else {
                throw StakeRepositoryError.stakeNotFound
            }
            
            context.delete(stakeEntity)
            try context.save()
            
            self.logger.log(.info, "Deleted stake with ID: \(id)")
            return true
        }
    }
    
    // MARK: - Query Operations
    func getStakes(forUserId: String) async throws -> [Stake] {
        return try await coreDataStack.performBackgroundTask { context in
            let fetchRequest: NSFetchRequest<StakeEntity> = StakeEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "userId == %@", forUserId)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            
            let results = try context.fetch(fetchRequest)
            return try results.map { try self.mapEntityToStake($0) }
        }
    }
    
    func getStakes(forGroupId: String) async throws -> [Stake] {
        return try await coreDataStack.performBackgroundTask { context in
            let fetchRequest: NSFetchRequest<StakeEntity> = StakeEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "groupId == %@", forGroupId)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            
            let results = try context.fetch(fetchRequest)
            return try results.map { try self.mapEntityToStake($0) }
        }
    }
    
    func getStakes(forCorporateAccountId: String) async throws -> [Stake] {
        return try await coreDataStack.performBackgroundTask { context in
            let fetchRequest: NSFetchRequest<StakeEntity> = StakeEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "corporateAccountId == %@", forCorporateAccountId)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            
            let results = try context.fetch(fetchRequest)
            return try results.map { try self.mapEntityToStake($0) }
        }
    }
    
    func getStakes(byStatus: StakeStatus) async throws -> [Stake] {
        return try await coreDataStack.performBackgroundTask { context in
            let fetchRequest: NSFetchRequest<StakeEntity> = StakeEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "status == %@", byStatus.rawValue)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            
            let results = try context.fetch(fetchRequest)
            return try results.map { try self.mapEntityToStake($0) }
        }
    }
    
    func getStakes(byAPRModel: APRModel) async throws -> [Stake] {
        return try await coreDataStack.performBackgroundTask { context in
            let fetchRequest: NSFetchRequest<StakeEntity> = StakeEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "aprModel == %@", byAPRModel.rawValue)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            
            let results = try context.fetch(fetchRequest)
            return try results.map { try self.mapEntityToStake($0) }
        }
    }
    
    func getStakes(byAccrualMethod: AccrualMethod) async throws -> [Stake] {
        return try await coreDataStack.performBackgroundTask { context in
            let fetchRequest: NSFetchRequest<StakeEntity> = StakeEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "accrualMethod == %@", byAccrualMethod.rawValue)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            
            let results = try context.fetch(fetchRequest)
            return try results.map { try self.mapEntityToStake($0) }
        }
    }
    
    // MARK: - Financial Operations
    func getTotalStakeValue(forUserId: String) async throws -> Decimal {
        return try await coreDataStack.performBackgroundTask { context in
            let fetchRequest: NSFetchRequest<StakeEntity> = StakeEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "userId == %@", forUserId)
            
            let results = try context.fetch(fetchRequest)
            
            return results.reduce(Decimal(0)) { total, entity in
                let principal = entity.principal?.decimalValue ?? 0
                let accrued = entity.accruedAmount?.decimalValue ?? 0
                return total + principal + accrued
            }
        }
    }
    
    func getTotalAccruedAmount(forUserId: String) async throws -> Decimal {
        return try await coreDataStack.performBackgroundTask { context in
            let fetchRequest: NSFetchRequest<StakeEntity> = StakeEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "userId == %@", forUserId)
            
            let results = try context.fetch(fetchRequest)
            
            return results.reduce(Decimal(0)) { total, entity in
                total + (entity.accruedAmount?.decimalValue ?? 0)
            }
        }
    }
    
    func getStakesByValueRange(min: Decimal, max: Decimal) async throws -> [Stake] {
        return try await coreDataStack.performBackgroundTask { context in
            let fetchRequest: NSFetchRequest<StakeEntity> = StakeEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(
                format: "principal >= %@ AND principal <= %@",
                NSDecimalNumber(decimal: min),
                NSDecimalNumber(decimal: max)
            )
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "principal", ascending: false)]
            
            let results = try context.fetch(fetchRequest)
            return try results.map { try self.mapEntityToStake($0) }
        }
    }
    
    // MARK: - Accrual Operations
    func updateAccruedAmount(forStakeId: String, newAmount: Decimal) async throws -> Stake {
        return try await coreDataStack.performBackgroundTask { context in
            let fetchRequest: NSFetchRequest<StakeEntity> = StakeEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", forStakeId)
            fetchRequest.fetchLimit = 1
            
            let results = try context.fetch(fetchRequest)
            guard let stakeEntity = results.first else {
                throw StakeRepositoryError.stakeNotFound
            }
            
            stakeEntity.accruedAmount = NSDecimalNumber(decimal: newAmount)
            stakeEntity.lastAccrualAt = Date()
            stakeEntity.updatedAt = Date()
            
            try context.save()
            
            return try self.mapEntityToStake(stakeEntity)
        }
    }
    
    func processDailyAccrual() async throws -> [Stake] {
        return try await coreDataStack.performBackgroundTask { context in
            let fetchRequest: NSFetchRequest<StakeEntity> = StakeEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "status == %@", StakeStatus.active.rawValue)
            
            let results = try context.fetch(fetchRequest)
            var updatedStakes: [Stake] = []
            
            for stakeEntity in results {
                let stake = try self.mapEntityToStake(stakeEntity)
                let newAccruedAmount = self.stakingMathUseCase.calculateAccruedAmount(stake: stake)
                
                if newAccruedAmount != stake.accruedAmount {
                    stakeEntity.accruedAmount = NSDecimalNumber(decimal: newAccruedAmount)
                    stakeEntity.lastAccrualAt = Date()
                    stakeEntity.updatedAt = Date()
                    
                    let updatedStake = try self.mapEntityToStake(stakeEntity)
                    updatedStakes.append(updatedStake)
                }
            }
            
            try context.save()
            return updatedStakes
        }
    }
    
    func getStakesRequiringAccrual() async throws -> [Stake] {
        return try await coreDataStack.performBackgroundTask { context in
            let fetchRequest: NSFetchRequest<StakeEntity> = StakeEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "status == %@", StakeStatus.active.rawValue)
            
            let results = try context.fetch(fetchRequest)
            let now = Date()
            
            return try results.compactMap { stakeEntity in
                let stake = try self.mapEntityToStake(stakeEntity)
                
                // Check if accrual is needed (e.g., daily accrual)
                let calendar = Calendar.current
                let lastAccrualDate = calendar.startOfDay(for: stake.lastAccrualAt)
                let currentDate = calendar.startOfDay(for: now)
                
                if lastAccrualDate < currentDate {
                    return stake
                }
                return nil
            }
        }
    }
    
    // MARK: - Analytics Operations
    func getStakeStatistics(forUserId: String) async throws -> StakeStatistics {
        return try await coreDataStack.performBackgroundTask { context in
            let fetchRequest: NSFetchRequest<StakeEntity> = StakeEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "userId == %@", forUserId)
            
            let results = try context.fetch(fetchRequest)
            
            let totalStakes = results.count
            let activeStakes = results.filter { $0.status == StakeStatus.active.rawValue }.count
            let completedStakes = results.filter { $0.status == StakeStatus.completed.rawValue }.count
            let failedStakes = results.filter { $0.status == StakeStatus.failed.rawValue }.count
            
            let totalPrincipal = results.reduce(Decimal(0)) { total, entity in
                total + (entity.principal?.decimalValue ?? 0)
            }
            
            let totalAccrued = results.reduce(Decimal(0)) { total, entity in
                total + (entity.accruedAmount?.decimalValue ?? 0)
            }
            
            let averageAPR = results.reduce(Decimal(0)) { total, entity in
                // This would need to be calculated based on APR model
                total + 0.12 // Default APR for now
            } / Decimal(max(results.count, 1))
            
            let successRate = totalStakes > 0 ? Double(completedStakes) / Double(totalStakes) : 0.0
            
            return StakeStatistics(
                totalStakes: totalStakes,
                activeStakes: activeStakes,
                completedStakes: completedStakes,
                failedStakes: failedStakes,
                totalPrincipal: totalPrincipal,
                totalAccrued: totalAccrued,
                averageAPR: averageAPR,
                successRate: successRate
            )
        }
    }
    
    func getStakePerformance(forUserId: String, timeRange: TimeRange) async throws -> StakePerformance {
        return try await coreDataStack.performBackgroundTask { context in
            let fetchRequest: NSFetchRequest<StakeEntity> = StakeEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(
                format: "userId == %@ AND createdAt >= %@",
                forUserId,
                timeRange.dateInterval.start as NSDate
            )
            
            let results = try context.fetch(fetchRequest)
            
            let totalReturn = results.reduce(Decimal(0)) { total, entity in
                total + (entity.accruedAmount?.decimalValue ?? 0)
            }
            
            let totalPrincipal = results.reduce(Decimal(0)) { total, entity in
                total + (entity.principal?.decimalValue ?? 0)
            }
            
            let returnRate = totalPrincipal > 0 ? totalReturn / totalPrincipal : 0
            
            return StakePerformance(
                totalReturn: totalReturn,
                returnRate: returnRate,
                duration: timeRange.dateInterval.duration,
                riskScore: 0.5, // Would need to calculate
                volatility: 0.1 // Would need to calculate
            )
        }
    }
    
    func getTopPerformingStakes(forUserId: String, limit: Int) async throws -> [StakeWithPerformance] {
        return try await coreDataStack.performBackgroundTask { context in
            let fetchRequest: NSFetchRequest<StakeEntity> = StakeEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "userId == %@", forUserId)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "accruedAmount", ascending: false)]
            fetchRequest.fetchLimit = limit
            
            let results = try context.fetch(fetchRequest)
            
            return try results.map { stakeEntity in
                let stake = try self.mapEntityToStake(stakeEntity)
                let performance = StakePerformance(
                    totalReturn: stake.accruedAmount,
                    returnRate: stake.principal > 0 ? stake.accruedAmount / stake.principal : 0,
                    duration: stake.duration,
                    riskScore: 0.5,
                    volatility: 0.1
                )
                
                return StakeWithPerformance(
                    stake: stake,
                    performance: performance,
                    goal: nil // Would need to fetch goal separately
                )
            }
        }
    }
    
    // MARK: - Bulk Operations
    func bulkUpdateStakes(_ stakes: [Stake]) async throws -> [Stake] {
        return try await coreDataStack.performBackgroundTask { context in
            var updatedStakes: [Stake] = []
            
            for stake in stakes {
                let fetchRequest: NSFetchRequest<StakeEntity> = StakeEntity.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", stake.id)
                fetchRequest.fetchLimit = 1
                
                let results = try context.fetch(fetchRequest)
                if let stakeEntity = results.first {
                    // Update existing stake
                    stakeEntity.accruedAmount = NSDecimalNumber(decimal: stake.accruedAmount)
                    stakeEntity.status = stake.status.rawValue
                    stakeEntity.updatedAt = Date()
                    
                    updatedStakes.append(stake)
                }
            }
            
            try context.save()
            return updatedStakes
        }
    }
    
    func processBatchAccrual(stakeIds: [String]) async throws -> [Stake] {
        return try await coreDataStack.performBackgroundTask { context in
            let fetchRequest: NSFetchRequest<StakeEntity> = StakeEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id IN %@", stakeIds)
            
            let results = try context.fetch(fetchRequest)
            var updatedStakes: [Stake] = []
            
            for stakeEntity in results {
                let stake = try self.mapEntityToStake(stakeEntity)
                let newAccruedAmount = self.stakingMathUseCase.calculateAccruedAmount(stake: stake)
                
                if newAccruedAmount != stake.accruedAmount {
                    stakeEntity.accruedAmount = NSDecimalNumber(decimal: newAccruedAmount)
                    stakeEntity.lastAccrualAt = Date()
                    stakeEntity.updatedAt = Date()
                    
                    let updatedStake = try self.mapEntityToStake(stakeEntity)
                    updatedStakes.append(updatedStake)
                }
            }
            
            try context.save()
            return updatedStakes
        }
    }
    
    // MARK: - Private Helper Methods
    private func mapEntityToStake(_ entity: StakeEntity) throws -> Stake {
        guard let id = entity.id,
              let goalId = entity.goalId,
              let userId = entity.userId,
              let principal = entity.principal,
              let startAt = entity.startAt,
              let aprModelString = entity.aprModel,
              let aprModel = APRModel(rawValue: aprModelString),
              let accrualMethodString = entity.accrualMethod,
              let accrualMethod = AccrualMethod(rawValue: accrualMethodString),
              let accruedAmount = entity.accruedAmount,
              let feeRateOnStake = entity.feeRateOnStake,
              let feeRateOnWithdrawal = entity.feeRateOnWithdrawal,
              let lastAccrualAt = entity.lastAccrualAt,
              let statusString = entity.status,
              let status = StakeStatus(rawValue: statusString),
              let createdAt = entity.createdAt,
              let updatedAt = entity.updatedAt else {
            throw StakeRepositoryError.invalidStakeData
        }
        
        let notes = (entity.notes?.allObjects as? [StakeNoteEntity])?.compactMap { noteEntity in
            try? mapNoteEntityToNote(noteEntity)
        } ?? []
        
        return Stake(
            id: id,
            goalId: goalId,
            userId: userId,
            principal: principal.decimalValue,
            startAt: startAt,
            aprModel: aprModel,
            accrualMethod: accrualMethod,
            feeRateOnStake: feeRateOnStake.decimalValue,
            feeRateOnWithdrawal: feeRateOnWithdrawal.decimalValue,
            earlyCompletionBonus: entity.earlyCompletionBonus?.decimalValue,
            charityId: entity.charityId,
            groupId: entity.groupId,
            corporateAccountId: entity.corporateAccountId,
            notes: notes
        )
    }
    
    private func mapNoteEntityToNote(_ entity: StakeNoteEntity) throws -> StakeNote {
        guard let id = entity.id,
              let content = entity.content,
              let authorId = entity.authorId,
              let createdAt = entity.createdAt,
              let updatedAt = entity.updatedAt,
              let typeString = entity.type,
              let type = NoteType(rawValue: typeString) else {
            throw StakeRepositoryError.invalidStakeData
        }
        
        return StakeNote(
            id: id,
            content: content,
            authorId: authorId,
            type: type
        )
    }
}

// MARK: - Core Data Entity Extensions
extension DateInterval {
    var duration: TimeInterval {
        return end.timeIntervalSince(start)
    }
}
