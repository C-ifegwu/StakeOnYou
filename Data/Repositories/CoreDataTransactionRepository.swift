import Foundation

final class CoreDataTransactionRepository: TransactionRepository {
    private var transactions: [EscrowTransaction] = []

    func appendTransaction(_ transaction: EscrowTransaction) async throws {
        transactions.append(transaction)
    }

    func getTransactionsForGoal(_ goalId: String) async throws -> [EscrowTransaction] {
        transactions.filter { $0.escrowId == goalId || $0.relatedTxRef.contains(goalId) }
    }

    func queryByReference(_ ref: String) async throws -> [EscrowTransaction] {
        transactions.filter { $0.relatedTxRef == ref }
    }
}

import Foundation
import CoreData
import Combine

// MARK: - Core Data Transaction Repository Implementation
class CoreDataTransactionRepository: TransactionRepository {
    // MARK: - Properties
    private let coreDataStack: CoreDataStack
    private let logger: Logger
    
    // MARK: - Initialization
    init(coreDataStack: CoreDataStack, logger: Logger) {
        self.coreDataStack = coreDataStack
        self.logger = logger
    }
    
    // MARK: - CRUD Operations
    func createTransaction(_ transaction: Transaction) async throws -> Transaction {
        return try await coreDataStack.performBackgroundTask { context in
            let entity = TransactionEntity(context: context)
            
            // Map domain model to Core Data entity
            entity.id = transaction.id
            entity.amount = transaction.amount as NSDecimalNumber
            entity.currency = transaction.currency
            entity.transactionType = transaction.transactionType.rawValue
            entity.status = transaction.status.rawValue
            entity.description = transaction.description
            entity.feeAmount = transaction.feeAmount as NSDecimalNumber
            entity.userId = transaction.userId
            entity.createdAt = transaction.createdAt
            
            try context.save()
            
            self.logger.info("Created transaction with ID: \(transaction.id)")
            return transaction
        }
    }
    
    func getTransaction(id: String) async throws -> Transaction? {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(TransactionEntity.self, predicate: CoreDataUtilities.createPredicate(format: "id == %@", arguments: [id]))
            request.fetchLimit = 1
            
            let results = try context.fetch(request)
            guard let entity = results.first else { return nil }
            
            return self.mapEntityToTransaction(entity)
        }
    }
    
    func updateTransaction(_ transaction: Transaction) async throws -> Transaction {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(TransactionEntity.self, predicate: CoreDataUtilities.createPredicate(format: "id == %@", arguments: [transaction.id]))
            request.fetchLimit = 1
            
            let results = try context.fetch(request)
            guard let entity = results.first else {
                throw TransactionRepositoryError.transactionNotFound
            }
            
            // Update entity with new values
            entity.amount = transaction.amount as NSDecimalNumber
            entity.currency = transaction.currency
            entity.transactionType = transaction.transactionType.rawValue
            entity.status = transaction.status.rawValue
            entity.description = transaction.description
            entity.feeAmount = transaction.feeAmount as NSDecimalNumber
            entity.userId = transaction.userId
            
            try context.save()
            
            self.logger.info("Updated transaction with ID: \(transaction.id)")
            return transaction
        }
    }
    
    func deleteTransaction(id: String) async throws -> Bool {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(TransactionEntity.self, predicate: CoreDataUtilities.createPredicate(format: "id == %@", arguments: [id]))
            request.fetchLimit = 1
            
            let results = try context.fetch(request)
            guard let entity = results.first else {
                throw TransactionRepositoryError.transactionNotFound
            }
            
            context.delete(entity)
            try context.save()
            
            self.logger.info("Deleted transaction with ID: \(id)")
            return true
        }
    }
    
    // MARK: - Query Operations
    func getTransactions(forUserId: String) async throws -> [Transaction] {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(TransactionEntity.self, predicate: CoreDataUtilities.createPredicate(format: "userId == %@", arguments: [userId]), sortDescriptors: [CoreDataUtilities.createSortDescriptor(key: "createdAt", ascending: false)])
            let results = try context.fetch(request)
            
            return results.map { self.mapEntityToTransaction($0) }
        }
    }
    
    func getTransactions(byType: TransactionType) async throws -> [Transaction] {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(TransactionEntity.self, predicate: CoreDataUtilities.createPredicate(format: "transactionType == %@", arguments: [type.rawValue]), sortDescriptors: [CoreDataUtilities.createSortDescriptor(key: "createdAt", ascending: false)])
            let results = try context.fetch(request)
            
            return results.map { self.mapEntityToTransaction($0) }
        }
    }
    
    func getTransactions(byStatus: TransactionStatus) async throws -> [Transaction] {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(TransactionEntity.self, predicate: CoreDataUtilities.createPredicate(format: "status == %@", arguments: [status.rawValue]), sortDescriptors: [CoreDataUtilities.createSortDescriptor(key: "createdAt", ascending: false)])
            let results = try context.fetch(request)
            
            return results.map { self.mapEntityToTransaction($0) }
        }
    }
    
    func getTransactions(byDateRange: DateInterval) async throws -> [Transaction] {
        return try await coreDataStack.performBackgroundTask { context in
            let predicate = CoreDataUtilities.createPredicate(format: "createdAt >= %@ AND createdAt <= %@", arguments: [dateRange.start, dateRange.end])
            let request = CoreDataUtilities.createFetchRequest(TransactionEntity.self, predicate: predicate, sortDescriptors: [CoreDataUtilities.createSortDescriptor(key: "createdAt", ascending: false)])
            let results = try context.fetch(request)
            
            return results.map { self.mapEntityToTransaction($0) }
        }
    }
    
    func getTransactions(byAmountRange: ClosedRange<Decimal>) async throws -> [Transaction] {
        return try await coreDataStack.performBackgroundTask { context in
            let predicate = CoreDataUtilities.createPredicate(format: "amount >= %@ AND amount <= %@", arguments: [amountRange.lowerBound as NSDecimalNumber, amountRange.upperBound as NSDecimalNumber])
            let request = CoreDataUtilities.createFetchRequest(TransactionEntity.self, predicate: predicate, sortDescriptors: [CoreDataUtilities.createSortDescriptor(key: "createdAt", ascending: false)])
            let results = try context.fetch(request)
            
            return results.map { self.mapEntityToTransaction($0) }
        }
    }
    
    func getTransactions(byCurrency: String) async throws -> [Transaction] {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(TransactionEntity.self, predicate: CoreDataUtilities.createPredicate(format: "currency == %@", arguments: [currency]), sortDescriptors: [CoreDataUtilities.createSortDescriptor(key: "createdAt", ascending: false)])
            let results = try context.fetch(request)
            
            return results.map { self.mapEntityToTransaction($0) }
        }
    }
    
    // MARK: - Financial Operations
    func getTotalTransactionAmount(forUserId: String, inCurrency: String) async throws -> Decimal {
        return try await coreDataStack.performBackgroundTask { context in
            let predicate = CoreDataUtilities.createPredicate(format: "userId == %@ AND currency == %@", arguments: [userId, inCurrency])
            let request = CoreDataUtilities.createFetchRequest(TransactionEntity.self, predicate: predicate)
            let results = try context.fetch(request)
            
            let total = results.reduce(Decimal.zero) { sum, entity in
                sum + (entity.amount?.decimalValue ?? Decimal.zero)
            }
            
            return total
        }
    }
    
    func getTotalFees(forUserId: String, inCurrency: String) async throws -> Decimal {
        return try await coreDataStack.performBackgroundTask { context in
            let predicate = CoreDataUtilities.createPredicate(format: "userId == %@ AND currency == %@", arguments: [userId, inCurrency])
            let request = CoreDataUtilities.createFetchRequest(TransactionEntity.self, predicate: predicate)
            let results = try context.fetch(request)
            
            let totalFees = results.reduce(Decimal.zero) { sum, entity in
                sum + (entity.feeAmount?.decimalValue ?? Decimal.zero)
            }
            
            return totalFees
        }
    }
    
    func getTransactionBalance(forUserId: String, inCurrency: String) async throws -> Decimal {
        return try await coreDataStack.performBackgroundTask { context in
            let predicate = CoreDataUtilities.createPredicate(format: "userId == %@ AND currency == %@", arguments: [userId, inCurrency])
            let request = CoreDataUtilities.createFetchRequest(TransactionEntity.self, predicate: predicate)
            let results = try context.fetch(request)
            
            let balance = results.reduce(Decimal.zero) { balance, entity in
                let amount = entity.amount?.decimalValue ?? Decimal.zero
                let fee = entity.feeAmount?.decimalValue ?? Decimal.zero
                
                switch TransactionType(rawValue: entity.transactionType ?? "unknown") ?? .unknown {
                case .deposit, .stakeWon, .refund:
                    return balance + amount - fee
                case .withdrawal, .stakeLost, .fee:
                    return balance - amount - fee
                case .transfer:
                    // For transfers, we need to determine if it's incoming or outgoing
                    // This is a simplified implementation
                    return balance
                case .unknown:
                    return balance
                }
            }
            
            return balance
        }
    }
    
    func getTransactionsByCategory(forUserId: String, category: String) async throws -> [Transaction] {
        // This would need to be implemented with actual category tracking
        // For now, return empty array
        return []
    }
    
    // MARK: - Analytics Operations
    func getTransactionStatistics(forUserId: String) async throws -> TransactionStatistics {
        return try await coreDataStack.performBackgroundTask { context in
            let predicate = CoreDataUtilities.createPredicate(format: "userId == %@", arguments: [userId])
            let request = CoreDataUtilities.createFetchRequest(TransactionEntity.self, predicate: predicate)
            let results = try context.fetch(request)
            
            let totalTransactions = results.count
            let totalAmount = results.reduce(Decimal.zero) { sum, entity in
                sum + (entity.amount?.decimalValue ?? Decimal.zero)
            }
            let totalFees = results.reduce(Decimal.zero) { sum, entity in
                sum + (entity.feeAmount?.decimalValue ?? Decimal.zero)
            }
            
            // Group by type
            let typeGroups = Dictionary(grouping: results) { $0.transactionType ?? "unknown" }
            let transactionsByType = typeGroups.map { type, transactions in
                TransactionTypeStats(
                    type: TransactionType(rawValue: type) ?? .unknown,
                    count: transactions.count,
                    totalAmount: transactions.reduce(Decimal.zero) { sum, entity in
                        sum + (entity.amount?.decimalValue ?? Decimal.zero)
                    },
                    totalFees: transactions.reduce(Decimal.zero) { sum, entity in
                        sum + (entity.feeAmount?.decimalValue ?? Decimal.zero)
                    }
                )
            }
            
            // Group by status
            let statusGroups = Dictionary(grouping: results) { $0.status ?? "unknown" }
            let transactionsByStatus = statusGroups.map { status, transactions in
                TransactionStatusStats(
                    status: TransactionStatus(rawValue: status) ?? .pending,
                    count: transactions.count,
                    totalAmount: transactions.reduce(Decimal.zero) { sum, entity in
                        sum + (entity.amount?.decimalValue ?? Decimal.zero)
                    }
                )
            }
            
            // Group by currency
            let currencyGroups = Dictionary(grouping: results) { $0.currency ?? "unknown" }
            let transactionsByCurrency = currencyGroups.map { currency, transactions in
                TransactionCurrencyStats(
                    currency: currency,
                    count: transactions.count,
                    totalAmount: transactions.reduce(Decimal.zero) { sum, entity in
                        sum + (entity.amount?.decimalValue ?? Decimal.zero)
                    },
                    totalFees: transactions.reduce(Decimal.zero) { sum, entity in
                        sum + (entity.feeAmount?.decimalValue ?? Decimal.zero)
                    }
                )
            }
            
            return TransactionStatistics(
                totalTransactions: totalTransactions,
                totalAmount: totalAmount,
                totalFees: totalFees,
                transactionsByType: transactionsByType,
                transactionsByStatus: transactionsByStatus,
                transactionsByCurrency: transactionsByCurrency,
                averageTransactionAmount: totalTransactions > 0 ? totalAmount / Decimal(totalTransactions) : Decimal.zero,
                averageFeeAmount: totalTransactions > 0 ? totalFees / Decimal(totalTransactions) : Decimal.zero
            )
        }
    }
    
    func getTransactionPerformance(forUserId: String, timeRange: TimeRange) async throws -> TransactionPerformance {
        // This would need to be implemented with actual performance data
        return TransactionPerformance(
            successRate: 0.98,
            averageProcessingTime: 2.5, // 2.5 seconds
            failureRate: 0.02,
            commonFailureReasons: ["insufficient_funds", "network_error"],
            userSatisfactionScore: 0.9
        )
    }
    
    func getTransactionTrends(forUserId: String, timeRange: TimeRange) async throws -> TransactionTrends {
        // This would need to be implemented with actual trend analysis
        return TransactionTrends(
            totalTransactions: 0,
            transactionsByDay: [:],
            transactionsByWeek: [:],
            transactionsByMonth: [:],
            peakTransactionTimes: [],
            commonTransactionTypes: [],
            averageTransactionAmount: Decimal.zero
        )
    }
    
    // MARK: - Bulk Operations
    func bulkUpdateTransactions(_ transactions: [Transaction]) async throws -> [Transaction] {
        return try await coreDataStack.performBackgroundTask { context in
            var updatedTransactions: [Transaction] = []
            
            for transaction in transactions {
                let request = CoreDataUtilities.createFetchRequest(TransactionEntity.self, predicate: CoreDataUtilities.createPredicate(format: "id == %@", arguments: [transaction.id]))
                request.fetchLimit = 1
                
                let results = try context.fetch(request)
                if let entity = results.first {
                    // Update existing entity
                    entity.amount = transaction.amount as NSDecimalNumber
                    entity.currency = transaction.currency
                    entity.transactionType = transaction.transactionType.rawValue
                    entity.status = transaction.status.rawValue
                    entity.description = transaction.description
                    entity.feeAmount = transaction.feeAmount as NSDecimalNumber
                    entity.userId = transaction.userId
                    
                    updatedTransactions.append(transaction)
                }
            }
            
            try context.save()
            self.logger.info("Bulk updated \(updatedTransactions.count) transactions")
            return updatedTransactions
        }
    }
    
    func deleteOldTransactions(olderThan date: Date) async throws -> Int {
        return try await coreDataStack.performBackgroundTask { context in
            let predicate = CoreDataUtilities.createPredicate(format: "createdAt < %@", arguments: [date])
            let request = CoreDataUtilities.createFetchRequest(TransactionEntity.self, predicate: predicate)
            let results = try context.fetch(request)
            
            let count = results.count
            for entity in results {
                context.delete(entity)
            }
            
            try context.save()
            self.logger.info("Deleted \(count) old transactions")
            return count
        }
    }
    
    func deleteFailedTransactions(olderThan date: Date) async throws -> Int {
        return try await coreDataStack.performBackgroundTask { context in
            let predicate = CoreDataUtilities.createPredicate(format: "status == %@ AND createdAt < %@", arguments: [TransactionStatus.failed.rawValue, date])
            let request = CoreDataUtilities.createFetchRequest(TransactionEntity.self, predicate: predicate)
            let results = try context.fetch(request)
            
            let count = results.count
            for entity in results {
                context.delete(entity)
            }
            
            try context.save()
            self.logger.info("Deleted \(count) old failed transactions")
            return count
        }
    }
    
    // MARK: - Private Helper Methods
    private func mapEntityToTransaction(_ entity: TransactionEntity) -> Transaction {
        return Transaction(
            id: entity.id ?? "",
            amount: entity.amount?.decimalValue ?? Decimal.zero,
            currency: entity.currency ?? "USD",
            transactionType: TransactionType(rawValue: entity.transactionType ?? "unknown") ?? .unknown,
            status: TransactionStatus(rawValue: entity.status ?? "pending") ?? .pending,
            description: entity.description ?? "",
            feeAmount: entity.feeAmount?.decimalValue ?? Decimal.zero,
            userId: entity.userId ?? "",
            createdAt: entity.createdAt ?? Date()
        )
    }
}
