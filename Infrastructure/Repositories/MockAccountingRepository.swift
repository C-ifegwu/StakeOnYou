import Foundation
import Combine

// MARK: - Mock Accounting Repository
class MockAccountingRepository: AccountingRepository {
    private var ledgerEntries: [String: LedgerEntry] = [:]
    private var transactionRecords: [String: TransactionRecord] = [:]
    private var auditTrails: [String: AuditTrail] = [:]
    private var accountBalances: [String: AccountBalance] = [:]
    
    init() {
        setupMockData()
    }
    
    func saveLedgerEntry(_ entry: LedgerEntry) async throws -> LedgerEntry {
        ledgerEntries[entry.id] = entry
        
        // Update account balance
        updateAccountBalance(for: entry.accountId, with: entry)
        
        // Create audit trail
        let audit = AuditTrail(
            action: "ledger_entry_created",
            entityType: "LedgerEntry",
            entityId: entry.id,
            changes: ["amount": "\(entry.amount)", "type": entry.entryType.rawValue]
        )
        auditTrails[audit.id] = audit
        
        return entry
    }
    
    func saveTransactionRecord(_ transaction: TransactionRecord) async throws -> TransactionRecord {
        transactionRecords[transaction.id] = transaction
        
        // Create audit trail
        let audit = AuditTrail(
            action: "transaction_record_created",
            entityType: "TransactionRecord",
            entityId: transaction.id,
            changes: ["amount": "\(transaction.amount)", "type": transaction.type.rawValue]
        )
        auditTrails[audit.id] = audit
        
        return transaction
    }
    
    func saveAuditTrail(_ audit: AuditTrail) async throws -> AuditTrail {
        auditTrails[audit.id] = audit
        return audit
    }
    
    func getTransactionHistory(
        accountId: String?,
        accountType: AccountType?,
        type: TransactionRecordType?,
        startDate: Date?,
        endDate: Date?,
        limit: Int?
    ) async throws -> [TransactionRecord] {
        var filteredTransactions = Array(transactionRecords.values)
        
        // Filter by account ID
        if let accountId = accountId {
            filteredTransactions = filteredTransactions.filter { transaction in
                transaction.ledgerEntries.contains { $0.accountId == accountId }
            }
        }
        
        // Filter by account type
        if let accountType = accountType {
            filteredTransactions = filteredTransactions.filter { transaction in
                transaction.ledgerEntries.contains { $0.accountType == accountType }
            }
        }
        
        // Filter by type
        if let type = type {
            filteredTransactions = filteredTransactions.filter { $0.type == type }
        }
        
        // Filter by date range
        if let startDate = startDate {
            filteredTransactions = filteredTransactions.filter { $0.createdAt >= startDate }
        }
        if let endDate = endDate {
            filteredTransactions = filteredTransactions.filter { $0.createdAt <= endDate }
        }
        
        // Sort by date (most recent first)
        filteredTransactions.sort { $0.createdAt > $1.createdAt }
        
        // Apply limit
        if let limit = limit {
            filteredTransactions = Array(filteredTransactions.prefix(limit))
        }
        
        return filteredTransactions
    }
    
    func getLedgerEntries(
        accountId: String?,
        accountType: AccountType?,
        entryType: EntryType?,
        startDate: Date?,
        endDate: Date?,
        limit: Int?
    ) async throws -> [LedgerEntry] {
        var filteredEntries = Array(ledgerEntries.values)
        
        // Filter by account ID
        if let accountId = accountId {
            filteredEntries = filteredEntries.filter { $0.accountId == accountId }
        }
        
        // Filter by account type
        if let accountType = accountType {
            filteredEntries = filteredEntries.filter { $0.accountType == accountType }
        }
        
        // Filter by entry type
        if let entryType = entryType {
            filteredEntries = filteredEntries.filter { $0.entryType == entryType }
        }
        
        // Filter by date range
        if let startDate = startDate {
            filteredEntries = filteredEntries.filter { $0.createdAt >= startDate }
        }
        if let endDate = endDate {
            filteredEntries = filteredEntries.filter { $0.createdAt <= endDate }
        }
        
        // Sort by date (most recent first)
        filteredEntries.sort { $0.createdAt > $1.createdAt }
        
        // Apply limit
        if let limit = limit {
            filteredEntries = Array(filteredEntries.prefix(limit))
        }
        
        return filteredEntries
    }
    
    func getAccountBalance(accountId: String, asOf date: Date) async throws -> AccountBalance {
        guard let balance = accountBalances[accountId] else {
            // Create default balance if not found
            let defaultBalance = AccountBalance(
                accountId: accountId,
                accountType: .userWallet,
                balance: 0,
                lastUpdated: date
            )
            accountBalances[accountId] = defaultBalance
            return defaultBalance
        }
        return balance
    }
    
    func getAuditTrail(
        entityType: String?,
        entityId: String?,
        userId: String?,
        startDate: Date?,
        endDate: Date?,
        limit: Int?
    ) async throws -> [AuditTrail] {
        var filteredAudits = Array(auditTrails.values)
        
        // Filter by entity type
        if let entityType = entityType {
            filteredAudits = filteredAudits.filter { $0.entityType == entityType }
        }
        
        // Filter by entity ID
        if let entityId = entityId {
            filteredAudits = filteredAudits.filter { $0.entityId == entityId }
        }
        
        // Filter by user ID
        if let userId = userId {
            filteredAudits = filteredAudits.filter { $0.userId == userId }
        }
        
        // Filter by date range
        if let startDate = startDate {
            filteredAudits = filteredAudits.filter { $0.timestamp >= startDate }
        }
        if let endDate = endDate {
            filteredAudits = filteredAudits.filter { $0.timestamp <= endDate }
        }
        
        // Sort by timestamp (most recent first)
        filteredAudits.sort { $0.timestamp > $1.timestamp }
        
        // Apply limit
        if let limit = limit {
            filteredAudits = Array(filteredAudits.prefix(limit))
        }
        
        return filteredAudits
    }
    
    // MARK: - Private Methods
    
    private func setupMockData() {
        // Create sample account balances
        let userWalletBalance = AccountBalance(
            accountId: "user_wallet_1",
            accountType: .userWallet,
            balance: 1000.0
        )
        accountBalances[userWalletBalance.accountId] = userWalletBalance
        
        let escrowBalance = AccountBalance(
            accountId: "escrow_account_1",
            accountType: .escrowAccount,
            balance: 200.0
        )
        accountBalances[escrowBalance.accountId] = escrowBalance
        
        let feeBalance = AccountBalance(
            accountId: "fee_account_1",
            accountType: .feeAccount,
            balance: 50.0
        )
        accountBalances[feeBalance.accountId] = feeBalance
        
        // Create sample ledger entries
        let entry1 = LedgerEntry(
            transactionId: "tx_1",
            accountId: "user_wallet_1",
            accountType: .userWallet,
            entryType: .credit,
            amount: 1000.0,
            description: "Initial deposit",
            reference: "deposit_1"
        )
        ledgerEntries[entry1.id] = entry1
        
        let entry2 = LedgerEntry(
            transactionId: "tx_1",
            accountId: "escrow_account_1",
            accountType: .escrowAccount,
            entryType: .debit,
            amount: 200.0,
            description: "Escrow hold",
            reference: "escrow_1"
        )
        ledgerEntries[entry2.id] = entry2
        
        let entry3 = LedgerEntry(
            transactionId: "tx_2",
            accountId: "fee_account_1",
            accountType: .feeAccount,
            entryType: .credit,
            amount: 50.0,
            description: "Processing fee",
            reference: "fee_1"
        )
        ledgerEntries[entry3.id] = entry3
        
        // Create sample transaction records
        let transaction1 = TransactionRecord(
            type: .deposit,
            amount: 1000.0,
            description: "Initial deposit",
            ledgerEntries: [entry1]
        )
        transactionRecords[transaction1.id] = transaction1
        
        let transaction2 = TransactionRecord(
            type: .escrowHold,
            amount: 200.0,
            description: "Escrow hold for goal",
            ledgerEntries: [entry2]
        )
        transactionRecords[transaction2.id] = transaction2
        
        let transaction3 = TransactionRecord(
            type: .feeCapture,
            amount: 50.0,
            description: "Processing fee",
            ledgerEntries: [entry3]
        )
        transactionRecords[transaction3.id] = transaction3
        
        // Create sample audit trails
        let audit1 = AuditTrail(
            action: "account_created",
            entityType: "Account",
            entityId: "user_wallet_1",
            userId: "user_1"
        )
        auditTrails[audit1.id] = audit1
        
        let audit2 = AuditTrail(
            action: "deposit_processed",
            entityType: "Payment",
            entityId: "payment_1",
            userId: "user_1",
            changes: ["amount": "1000.0", "status": "completed"]
        )
        auditTrails[audit2.id] = audit2
    }
    
    private func updateAccountBalance(for accountId: String, with entry: LedgerEntry) {
        let currentBalance = accountBalances[accountId]?.balance ?? 0
        
        let newBalance: Decimal
        switch entry.entryType {
        case .credit:
            newBalance = currentBalance + entry.amount
        case .debit:
            newBalance = currentBalance - entry.amount
        }
        
        let updatedBalance = AccountBalance(
            accountId: accountId,
            accountType: entry.accountType,
            balance: newBalance,
            lastUpdated: Date()
        )
        
        accountBalances[accountId] = updatedBalance
    }
}

// MARK: - Accounting Repository Factory
protocol AccountingRepositoryFactory {
    func createAccountingRepository() -> AccountingRepository
}

// MARK: - Mock Accounting Repository Factory
class MockAccountingRepositoryFactory: AccountingRepositoryFactory {
    func createAccountingRepository() -> AccountingRepository {
        return MockAccountingRepository()
    }
}

// MARK: - Mock Accounting Service
class MockAccountingService: AccountingService {
    private let accountingRepository: AccountingRepository
    
    init(accountingRepository: AccountingRepository) {
        self.accountingRepository = accountingRepository
    }
    
    func recordDonation(_ donation: DonationRecord) async throws {
        // Create ledger entries for donation
        let donationEntry = LedgerEntry(
            transactionId: UUID().uuidString,
            accountId: "charity_account_\(donation.charityId)",
            accountType: .charityAccount,
            entryType: .credit,
            amount: donation.amount,
            description: "Donation to \(donation.charityName)",
            reference: donation.id
        )
        
        let userEntry = LedgerEntry(
            transactionId: donationEntry.transactionId,
            accountId: "user_wallet_\(donation.userId)",
            accountType: .userWallet,
            entryType: .debit,
            amount: donation.amount,
            description: "Donation to \(donation.charityName)",
            reference: donation.id
        )
        
        // Save ledger entries
        _ = try await accountingRepository.saveLedgerEntry(donationEntry)
        _ = try await accountingRepository.saveLedgerEntry(userEntry)
        
        // Create transaction record
        let transaction = TransactionRecord(
            type: .donation,
            amount: donation.amount,
            description: "Donation to \(donation.charityName)",
            ledgerEntries: [donationEntry, userEntry]
        )
        
        _ = try await accountingRepository.saveTransactionRecord(transaction)
    }
    
    func recordPayment(_ payment: Payment) async throws {
        // Create ledger entry for payment
        let entry = LedgerEntry(
            transactionId: payment.id,
            accountId: "user_wallet_\(payment.userId)",
            accountType: .userWallet,
            entryType: payment.type.isCredit ? .credit : .debit,
            amount: payment.amount,
            description: payment.description,
            reference: payment.id
        )
        
        _ = try await accountingRepository.saveLedgerEntry(entry)
        
        // Create transaction record
        let transaction = TransactionRecord(
            type: .deposit, // Simplified for mock
            amount: payment.amount,
            description: payment.description,
            ledgerEntries: [entry]
        )
        
        _ = try await accountingRepository.saveTransactionRecord(transaction)
    }
    
    func recordEscrowHold(_ escrow: EscrowRecord) async throws {
        // Create ledger entries for escrow hold
        let escrowEntry = LedgerEntry(
            transactionId: escrow.id,
            accountId: "escrow_account_\(escrow.goalId)",
            accountType: .escrowAccount,
            entryType: .credit,
            amount: escrow.amount,
            description: "Escrow hold for goal",
            reference: escrow.id
        )
        
        let userEntry = LedgerEntry(
            transactionId: escrow.id,
            accountId: "user_wallet_\(escrow.userId)",
            accountType: .userWallet,
            entryType: .debit,
            amount: escrow.amount,
            description: "Escrow hold for goal",
            reference: escrow.id
        )
        
        // Save ledger entries
        _ = try await accountingRepository.saveLedgerEntry(escrowEntry)
        _ = try await accountingRepository.saveLedgerEntry(userEntry)
        
        // Create transaction record
        let transaction = TransactionRecord(
            type: .escrowHold,
            amount: escrow.amount,
            description: "Escrow hold for goal",
            ledgerEntries: [escrowEntry, userEntry]
        )
        
        _ = try await accountingRepository.saveTransactionRecord(transaction)
    }
    
    func recordEscrowRelease(_ escrow: EscrowRecord) async throws {
        // Create ledger entries for escrow release
        let escrowEntry = LedgerEntry(
            transactionId: escrow.id,
            accountId: "escrow_account_\(escrow.goalId)",
            accountType: .escrowAccount,
            entryType: .debit,
            amount: escrow.amount,
            description: "Escrow release for goal",
            reference: escrow.id
        )
        
        let userEntry = LedgerEntry(
            transactionId: escrow.id,
            accountId: "user_wallet_\(escrow.userId)",
            accountType: .userWallet,
            entryType: .credit,
            amount: escrow.amount,
            description: "Escrow release for goal",
            reference: escrow.id
        )
        
        // Save ledger entries
        _ = try await accountingRepository.saveLedgerEntry(escrowEntry)
        _ = try await accountingRepository.saveLedgerEntry(userEntry)
        
        // Create transaction record
        let transaction = TransactionRecord(
            type: .escrowRelease,
            amount: escrow.amount,
            description: "Escrow release for goal",
            ledgerEntries: [escrowEntry, userEntry]
        )
        
        _ = try await accountingRepository.saveTransactionRecord(transaction)
    }
    
    func recordFee(_ fee: FeeBreakdown, for userId: String) async throws {
        // Create ledger entry for fee
        let entry = LedgerEntry(
            transactionId: UUID().uuidString,
            accountId: "fee_account_1",
            accountType: .feeAccount,
            entryType: .credit,
            amount: fee.amount,
            description: "Fee: \(fee.description)",
            reference: "fee_\(UUID().uuidString)"
        )
        
        _ = try await accountingRepository.saveLedgerEntry(entry)
        
        // Create transaction record
        let transaction = TransactionRecord(
            type: .feeCapture,
            amount: fee.amount,
            description: "Fee: \(fee.description)",
            ledgerEntries: [entry]
        )
        
        _ = try await accountingRepository.saveTransactionRecord(transaction)
    }
}

// MARK: - Accounting Service Factory
protocol AccountingServiceFactory {
    func createAccountingService() -> AccountingService
}

// MARK: - Mock Accounting Service Factory
class MockAccountingServiceFactory: AccountingServiceFactory {
    func createAccountingService() -> AccountingService {
        let repository = MockAccountingRepository()
        return MockAccountingService(accountingRepository: repository)
    }
}
