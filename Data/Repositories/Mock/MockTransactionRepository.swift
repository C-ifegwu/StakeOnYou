import Foundation
import Combine

// MARK: - Mock Transaction Repository Implementation
class MockTransactionRepository: TransactionRepository {
    // MARK: - Properties
    private var transactions: [String: Transaction] = [:]
    private let logger: Logger
    
    // MARK: - Initialization
    init(logger: Logger = ConsoleLogger()) {
        self.logger = logger
        setupMockData()
    }
    
    // MARK: - CRUD Operations
    func createTransaction(_ transaction: Transaction) async throws -> Transaction {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 600_000_000)
        
        var newTransaction = transaction
        if newTransaction.id.isEmpty {
            newTransaction = Transaction(
                id: UUID().uuidString,
                type: transaction.type,
                amount: transaction.amount,
                currency: transaction.currency,
                status: transaction.status,
                userId: transaction.userId,
                goalId: transaction.goalId,
                stakeId: transaction.stakeId,
                description: transaction.description,
                metadata: transaction.metadata,
                createdAt: Date(),
                updatedAt: Date()
            )
        }
        
        transactions[newTransaction.id] = newTransaction
        logger.info("Mock: Created transaction with ID: \(newTransaction.id)")
        return newTransaction
    }
    
    func getTransaction(id: String) async throws -> Transaction? {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 200_000_000)
        
        let transaction = transactions[id]
        logger.info("Mock: Retrieved transaction with ID: \(id), found: \(transaction != nil)")
        return transaction
    }
    
    func updateTransaction(_ transaction: Transaction) async throws -> Transaction {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        guard transactions[transaction.id] != nil else {
            throw TransactionRepositoryError.transactionNotFound
        }
        
        var updatedTransaction = transaction
        updatedTransaction.updatedAt = Date()
        transactions[transaction.id] = updatedTransaction
        
        logger.info("Mock: Updated transaction with ID: \(transaction.id)")
        return updatedTransaction
    }
    
    func deleteTransaction(id: String) async throws -> Bool {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        guard transactions[id] != nil else {
            throw TransactionRepositoryError.transactionNotFound
        }
        
        transactions.removeValue(forKey: id)
        logger.info("Mock: Deleted transaction with ID: \(id)")
        return true
    }
    
    // MARK: - Query Operations
    func getTransactions(forUserId: String) async throws -> [Transaction] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let userTransactions = transactions.values.filter { $0.userId == forUserId }
        logger.info("Mock: Retrieved \(userTransactions.count) transactions for user: \(forUserId)")
        return userTransactions
    }
    
    func getTransactions(forGoalId: String) async throws -> [Transaction] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let goalTransactions = transactions.values.filter { $0.goalId == forGoalId }
        logger.info("Mock: Retrieved \(goalTransactions.count) transactions for goal: \(forGoalId)")
        return goalTransactions
    }
    
    func getTransactions(forStakeId: String) async throws -> [Transaction] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let stakeTransactions = transactions.values.filter { $0.stakeId == forStakeId }
        logger.info("Mock: Retrieved \(stakeTransactions.count) transactions for stake: \(forStakeId)")
        return stakeTransactions
    }
    
    func getTransactions(byType: TransactionType) async throws -> [Transaction] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let typeTransactions = transactions.values.filter { $0.type == byType }
        logger.info("Mock: Retrieved \(typeTransactions.count) transactions with type: \(byType)")
        return typeTransactions
    }
    
    func getTransactions(byStatus: TransactionStatus) async throws -> [Transaction] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let statusTransactions = transactions.values.filter { $0.status == byStatus }
        logger.info("Mock: Retrieved \(statusTransactions.count) transactions with status: \(byStatus)")
        return statusTransactions
    }
    
    func getTransactions(byDateRange: DateInterval) async throws -> [Transaction] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let dateRangeTransactions = transactions.values.filter { transaction in
            return transaction.createdAt >= dateRange.start && transaction.createdAt <= dateRange.end
        }
        
        logger.info("Mock: Retrieved \(dateRangeTransactions.count) transactions in date range")
        return dateRangeTransactions
    }
    
    func getTransactions(byAmount: Double, comparison: ComparisonType) async throws -> [Transaction] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let filteredTransactions = transactions.values.filter { transaction in
            switch comparison {
            case .greaterThan:
                return transaction.amount > byAmount
            case .greaterThanOrEqual:
                return transaction.amount >= byAmount
            case .lessThan:
                return transaction.amount < byAmount
            case .lessThanOrEqual:
                return transaction.amount <= byAmount
            case .equal:
                return transaction.amount == byAmount
            }
        }
        
        logger.info("Mock: Retrieved \(filteredTransactions.count) transactions with amount \(comparison.rawValue) \(byAmount)")
        return filteredTransactions
    }
    
    // MARK: - Status Management
    func updateTransactionStatus(id: String, newStatus: TransactionStatus) async throws -> Transaction {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        guard var transaction = transactions[id] else {
            throw TransactionRepositoryError.transactionNotFound
        }
        
        transaction.status = newStatus
        transaction.updatedAt = Date()
        transactions[id] = transaction
        
        logger.info("Mock: Updated transaction \(id) status to \(newStatus)")
        return transaction
    }
    
    func markTransactionAsCompleted(id: String) async throws -> Transaction {
        return try await updateTransactionStatus(id: id, newStatus: .completed)
    }
    
    func markTransactionAsFailed(id: String) async throws -> Transaction {
        return try await updateTransactionStatus(id: id, newStatus: .failed)
    }
    
    func markTransactionAsPending(id: String) async throws -> Transaction {
        return try await updateTransactionStatus(id: id, newStatus: .pending)
    }
    
    func markTransactionAsCancelled(id: String) async throws -> Transaction {
        return try await updateTransactionStatus(id: id, newStatus: .cancelled)
    }
    
    // MARK: - Financial Operations
    func getTransactionBalance(forUserId: String) async throws -> TransactionBalance {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        let userTransactions = transactions.values.filter { $0.userId == forUserId }
        
        let totalDeposits = userTransactions.filter { $0.type == .deposit && $0.status == .completed }.reduce(0) { $0 + $1.amount }
        let totalWithdrawals = userTransactions.filter { $0.type == .withdrawal && $0.status == .completed }.reduce(0) { $0 + $1.amount }
        let totalStakes = userTransactions.filter { $0.type == .stake && $0.status == .completed }.reduce(0) { $0 + $1.amount }
        let totalRewards = userTransactions.filter { $0.type == .reward && $0.status == .completed }.reduce(0) { $0 + $1.amount }
        let totalFees = userTransactions.filter { $0.type == .fee && $0.status == .completed }.reduce(0) { $0 + $1.amount }
        
        let balance = TransactionBalance(
            userId: forUserId,
            totalDeposits: totalDeposits,
            totalWithdrawals: totalWithdrawals,
            totalStakes: totalStakes,
            totalRewards: totalRewards,
            totalFees: totalFees,
            availableBalance: totalDeposits + totalRewards - totalWithdrawals - totalStakes - totalFees,
            lockedBalance: totalStakes,
            lastUpdated: Date()
        )
        
        logger.info("Mock: Generated transaction balance for user: \(forUserId)")
        return balance
    }
    
    func getTransactionHistory(forUserId: String, limit: Int) async throws -> [Transaction] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        let userTransactions = transactions.values.filter { $0.userId == forUserId }
        let sortedTransactions = userTransactions.sorted { $0.createdAt > $1.createdAt }
        let limitedTransactions = Array(sortedTransactions.prefix(limit))
        
        logger.info("Mock: Retrieved \(limitedTransactions.count) transaction history for user: \(forUserId)")
        return limitedTransactions
    }
    
    // MARK: - Analytics and Reporting
    func getTransactionStatistics(forUserId: String) async throws -> TransactionStatistics {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        let userTransactions = transactions.values.filter { $0.userId == forUserId }
        let completedTransactions = userTransactions.filter { $0.status == .completed }
        
        let totalTransactions = userTransactions.count
        let completedCount = completedTransactions.count
        let failedCount = userTransactions.filter { $0.status == .failed }.count
        let pendingCount = userTransactions.filter { $0.status == .pending }.count
        
        let totalAmount = completedTransactions.reduce(0) { $0 + $1.amount }
        let averageAmount = completedCount > 0 ? totalAmount / Double(completedCount) : 0
        
        let statistics = TransactionStatistics(
            totalTransactions: totalTransactions,
            completedTransactions: completedCount,
            failedTransactions: failedCount,
            pendingTransactions: pendingCount,
            totalAmount: totalAmount,
            averageAmount: averageAmount,
            successRate: totalTransactions > 0 ? Double(completedCount) / Double(totalTransactions) : 0,
            mostCommonType: getMostCommonTransactionType(userTransactions),
            lastTransactionDate: userTransactions.max(by: { $0.createdAt < $1.createdAt })?.createdAt
        )
        
        logger.info("Mock: Generated transaction statistics for user: \(forUserId)")
        return statistics
    }
    
    func getTransactionPerformance(forUserId: String, timeRange: TimeRange) async throws -> TransactionPerformance {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        let performance = TransactionPerformance(
            userId: forUserId,
            timeRange: timeRange,
            totalTransactions: 25,
            successfulTransactions: 23,
            failedTransactions: 2,
            totalVolume: 2500.0,
            averageTransactionValue: 100.0,
            processingTime: 2.5, // seconds
            successRate: 0.92,
            topTransactionTypes: [.deposit, .stake, .reward],
            growthRate: 0.15 // 15% growth
        )
        
        logger.info("Mock: Generated transaction performance for user: \(forUserId)")
        return performance
    }
    
    // MARK: - Bulk Operations
    func bulkCreateTransactions(_ transactions: [Transaction]) async throws -> [Transaction] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_500_000_000)
        
        var createdTransactions: [Transaction] = []
        
        for transaction in transactions {
            let createdTransaction = try await createTransaction(transaction)
            createdTransactions.append(createdTransaction)
        }
        
        logger.info("Mock: Bulk created \(createdTransactions.count) transactions")
        return createdTransactions
    }
    
    func bulkUpdateTransactions(_ transactions: [Transaction]) async throws -> [Transaction] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        var updatedTransactions: [Transaction] = []
        
        for transaction in transactions {
            let updatedTransaction = try await updateTransaction(transaction)
            updatedTransactions.append(updatedTransaction)
        }
        
        logger.info("Mock: Bulk updated \(updatedTransactions.count) transactions")
        return updatedTransactions
    }
    
    func getTransactionsByBatch(ids: [String]) async throws -> [Transaction] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        let batchTransactions = ids.compactMap { transactions[$0] }
        logger.info("Mock: Retrieved \(batchTransactions.count) transactions by batch")
        return batchTransactions
    }
    
    // MARK: - Search and Filtering
    func searchTransactions(query: String, filters: TransactionSearchFilters?) async throws -> [Transaction] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        var searchResults = transactions.values
        
        // Apply text search
        if !query.isEmpty {
            searchResults = searchResults.filter { transaction in
                transaction.description.localizedCaseInsensitiveContains(query) ||
                transaction.id.localizedCaseInsensitiveContains(query)
            }
        }
        
        // Apply filters
        if let filters = filters {
            if let type = filters.type {
                searchResults = searchResults.filter { $0.type == type }
            }
            
            if let status = filters.status {
                searchResults = searchResults.filter { $0.status == status }
            }
            
            if let minAmount = filters.minAmount {
                searchResults = searchResults.filter { $0.amount >= minAmount }
            }
            
            if let maxAmount = filters.maxAmount {
                searchResults = searchResults.filter { $0.amount <= maxAmount }
            }
            
            if let startDate = filters.startDate {
                searchResults = searchResults.filter { $0.createdAt >= startDate }
            }
            
            if let endDate = filters.endDate {
                searchResults = searchResults.filter { $0.createdAt <= endDate }
            }
        }
        
        logger.info("Mock: Search returned \(searchResults.count) transactions for query: \(query)")
        return searchResults
    }
    
    // MARK: - Private Helper Methods
    private func getMostCommonTransactionType(_ transactions: [Transaction]) -> TransactionType? {
        let typeCounts = Dictionary(grouping: transactions) { $0.type }
            .mapValues { $0.count }
        
        return typeCounts.max(by: { $0.value < $1.value })?.key
    }
    
    private func setupMockData() {
        // Create some mock transactions for testing
        let mockTransactions = [
            Transaction(
                id: "txn-1",
                type: .deposit,
                amount: 1000.0,
                currency: .usd,
                status: .completed,
                userId: "user-1",
                goalId: nil,
                stakeId: nil,
                description: "Initial deposit",
                metadata: ["source": "bank_transfer"],
                createdAt: Date().addingTimeInterval(-30 * 24 * 60 * 60),
                updatedAt: Date().addingTimeInterval(-30 * 24 * 60 * 60)
            ),
            Transaction(
                id: "txn-2",
                type: .stake,
                amount: 500.0,
                currency: .usd,
                status: .completed,
                userId: "user-1",
                goalId: "goal-1",
                stakeId: "stake-1",
                description: "Stake for fitness goal",
                metadata: ["goalTitle": "Run 5K", "apr": "0.05"],
                createdAt: Date().addingTimeInterval(-25 * 24 * 60 * 60),
                updatedAt: Date().addingTimeInterval(-25 * 24 * 60 * 60)
            ),
            Transaction(
                id: "txn-3",
                type: .reward,
                amount: 25.0,
                currency: .usd,
                status: .completed,
                userId: "user-1",
                goalId: "goal-1",
                stakeId: "stake-1",
                description: "Weekly stake accrual",
                metadata: ["period": "weekly", "apr": "0.05"],
                createdAt: Date().addingTimeInterval(-7 * 24 * 60 * 60),
                updatedAt: Date().addingTimeInterval(-7 * 24 * 60 * 60)
            ),
            Transaction(
                id: "txn-4",
                type: .fee,
                amount: 5.0,
                currency: .usd,
                status: .completed,
                userId: "user-1",
                goalId: "goal-1",
                stakeId: "stake-1",
                description: "Stake creation fee",
                metadata: ["feeType": "stake_creation"],
                createdAt: Date().addingTimeInterval(-25 * 24 * 60 * 60),
                updatedAt: Date().addingTimeInterval(-25 * 24 * 60 * 60)
            ),
            Transaction(
                id: "txn-5",
                type: .deposit,
                amount: 750.0,
                currency: .usd,
                status: .completed,
                userId: "user-2",
                goalId: nil,
                stakeId: nil,
                description: "Monthly deposit",
                metadata: ["source": "credit_card"],
                createdAt: Date().addingTimeInterval(-15 * 24 * 60 * 60),
                updatedAt: Date().addingTimeInterval(-15 * 24 * 60 * 60)
            ),
            Transaction(
                id: "txn-6",
                type: .stake,
                amount: 300.0,
                currency: .usd,
                status: .completed,
                userId: "user-2",
                goalId: "goal-2",
                stakeId: "stake-2",
                description: "Stake for reading goal",
                metadata: ["goalTitle": "Read 12 Books", "apr": "0.06"],
                createdAt: Date().addingTimeInterval(-10 * 24 * 60 * 60),
                updatedAt: Date().addingTimeInterval(-10 * 24 * 60 * 60)
            ),
            Transaction(
                id: "txn-7",
                type: .withdrawal,
                amount: 200.0,
                currency: .usd,
                status: .pending,
                userId: "user-1",
                goalId: nil,
                stakeId: nil,
                description: "Withdrawal request",
                metadata: ["destination": "bank_account"],
                createdAt: Date().addingTimeInterval(-2 * 24 * 60 * 60),
                updatedAt: Date().addingTimeInterval(-2 * 24 * 60 * 60)
            ),
            Transaction(
                id: "txn-8",
                type: .reward,
                amount: 18.0,
                currency: .usd,
                status: .completed,
                userId: "user-2",
                goalId: "goal-2",
                stakeId: "stake-2",
                description: "Weekly stake accrual",
                metadata: ["period": "weekly", "apr": "0.06"],
                createdAt: Date().addingTimeInterval(-3 * 24 * 60 * 60),
                updatedAt: Date().addingTimeInterval(-3 * 24 * 60 * 60)
            ),
            Transaction(
                id: "txn-9",
                type: .stake,
                amount: 1000.0,
                currency: .usd,
                status: .failed,
                userId: "user-3",
                goalId: "goal-3",
                stakeId: nil,
                description: "Failed stake creation",
                metadata: ["error": "insufficient_funds"],
                createdAt: Date().addingTimeInterval(-1 * 24 * 60 * 60),
                updatedAt: Date().addingTimeInterval(-1 * 24 * 60 * 60)
            ),
            Transaction(
                id: "txn-10",
                type: .deposit,
                amount: 2500.0,
                currency: .usd,
                status: .completed,
                userId: "user-4",
                goalId: nil,
                stakeId: nil,
                description: "Large deposit",
                metadata: ["source": "wire_transfer"],
                createdAt: Date().addingTimeInterval(-5 * 24 * 60 * 60),
                updatedAt: Date().addingTimeInterval(-5 * 24 * 60 * 60)
            )
        ]
        
        for transaction in mockTransactions {
            transactions[transaction.id] = transaction
        }
        
        logger.info("Mock: Setup \(mockTransactions.count) mock transactions")
    }
}
