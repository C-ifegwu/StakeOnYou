import Foundation
import Combine

// MARK: - Record Payment Use Case
class RecordPaymentUseCase {
    private let accountingService: AccountingService
    
    init(accountingService: AccountingService) {
        self.accountingService = accountingService
    }
    
    func execute(_ payment: Payment) async throws {
        try await accountingService.recordPayment(payment)
    }
}

// MARK: - Record Donation Use Case
class RecordDonationUseCase {
    private let accountingService: AccountingService
    
    init(accountingService: AccountingService) {
        self.accountingService = accountingService
    }
    
    func execute(_ donation: DonationRecord) async throws {
        try await accountingService.recordDonation(donation)
    }
}

// MARK: - Record Escrow Hold Use Case
class RecordEscrowHoldUseCase {
    private let accountingService: AccountingService
    
    init(accountingService: AccountingService) {
        self.accountingService = accountingService
    }
    
    func execute(_ escrow: EscrowRecord) async throws {
        try await accountingService.recordEscrowHold(escrow)
    }
}

// MARK: - Record Escrow Release Use Case
class RecordEscrowReleaseUseCase {
    private let accountingService: AccountingService
    
    init(accountingService: AccountingService) {
        self.accountingService = accountingService
    }
    
    func execute(_ escrow: EscrowRecord) async throws {
        try await accountingService.recordEscrowRelease(escrow)
    }
}

// MARK: - Record Fee Use Case
class RecordFeeUseCase {
    private let accountingService: AccountingService
    
    init(accountingService: AccountingService) {
        self.accountingService = accountingService
    }
    
    func execute(_ fee: FeeBreakdown, for userId: String) async throws {
        try await accountingService.recordFee(fee, for: userId)
    }
}

// MARK: - Create Ledger Entry Use Case
class CreateLedgerEntryUseCase {
    private let accountingRepository: AccountingRepository
    
    init(accountingRepository: AccountingRepository) {
        self.accountingRepository = accountingRepository
    }
    
    func execute(
        transactionId: String,
        accountId: String,
        accountType: AccountType,
        entryType: EntryType,
        amount: Decimal,
        description: String,
        reference: String,
        metadata: [String: String] = [:]
    ) async throws -> LedgerEntry {
        let entry = LedgerEntry(
            transactionId: transactionId,
            accountId: accountId,
            accountType: accountType,
            entryType: entryType,
            amount: amount,
            description: description,
            reference: reference,
            metadata: metadata
        )
        
        return try await accountingRepository.saveLedgerEntry(entry)
    }
}

// MARK: - Create Transaction Record Use Case
class CreateTransactionRecordUseCase {
    private let accountingRepository: AccountingRepository
    
    init(accountingRepository: AccountingRepository) {
        self.accountingRepository = accountingRepository
    }
    
    func execute(
        type: TransactionRecordType,
        amount: Decimal,
        description: String,
        ledgerEntries: [LedgerEntry],
        metadata: [String: String] = [:]
    ) async throws -> TransactionRecord {
        let transaction = TransactionRecord(
            type: type,
            amount: amount,
            description: description,
            ledgerEntries: ledgerEntries,
            metadata: metadata
        )
        
        return try await accountingRepository.saveTransactionRecord(transaction)
    }
}

// MARK: - Get Transaction History Use Case
class GetTransactionHistoryUseCase {
    private let accountingRepository: AccountingRepository
    
    init(accountingRepository: AccountingRepository) {
        self.accountingRepository = accountingRepository
    }
    
    func execute(
        accountId: String? = nil,
        accountType: AccountType? = nil,
        type: TransactionRecordType? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        limit: Int? = nil
    ) async throws -> [TransactionRecord] {
        return try await accountingRepository.getTransactionHistory(
            accountId: accountId,
            accountType: accountType,
            type: type,
            startDate: startDate,
            endDate: endDate,
            limit: limit
        )
    }
}

// MARK: - Get Ledger Entries Use Case
class GetLedgerEntriesUseCase {
    private let accountingRepository: AccountingRepository
    
    init(accountingRepository: AccountingRepository) {
        self.accountingRepository = accountingRepository
    }
    
    func execute(
        accountId: String? = nil,
        accountType: AccountType? = nil,
        entryType: EntryType? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        limit: Int? = nil
    ) async throws -> [LedgerEntry] {
        return try await accountingRepository.getLedgerEntries(
            accountId: accountId,
            accountType: accountType,
            entryType: entryType,
            startDate: startDate,
            endDate: endDate,
            limit: limit
        )
    }
}

// MARK: - Get Account Balance Use Case
class GetAccountBalanceUseCase {
    private let accountingRepository: AccountingRepository
    
    init(accountingRepository: AccountingRepository) {
        self.accountingRepository = accountingRepository
    }
    
    func execute(
        accountId: String,
        asOf date: Date = Date()
    ) async throws -> AccountBalance {
        return try await accountingRepository.getAccountBalance(
            accountId: accountId,
            asOf: date
        )
    }
}

// MARK: - Create Audit Trail Use Case
class CreateAuditTrailUseCase {
    private let accountingRepository: AccountingRepository
    
    init(accountingRepository: AccountingRepository) {
        self.accountingRepository = accountingRepository
    }
    
    func execute(
        action: String,
        entityType: String,
        entityId: String,
        userId: String? = nil,
        changes: [String: String] = [:],
        ipAddress: String? = nil,
        userAgent: String? = nil
    ) async throws -> AuditTrail {
        let audit = AuditTrail(
            action: action,
            entityType: entityType,
            entityId: entityId,
            userId: userId,
            changes: changes,
            ipAddress: ipAddress,
            userAgent: userAgent
        )
        
        return try await accountingRepository.saveAuditTrail(audit)
    }
}

// MARK: - Get Audit Trail Use Case
class GetAuditTrailUseCase {
    private let accountingRepository: AccountingRepository
    
    init(accountingRepository: AccountingRepository) {
        self.accountingRepository = accountingRepository
    }
    
    func execute(
        entityType: String? = nil,
        entityId: String? = nil,
        userId: String? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        limit: Int? = nil
    ) async throws -> [AuditTrail] {
        return try await accountingRepository.getAuditTrail(
            entityType: entityType,
            entityId: entityId,
            userId: userId,
            startDate: startDate,
            endDate: endDate,
            limit: limit
        )
    }
}

// MARK: - Validate Transaction Balance Use Case
class ValidateTransactionBalanceUseCase {
    func execute(_ transaction: TransactionRecord) -> Bool {
        return transaction.isBalanced
    }
    
    func execute(_ ledgerEntries: [LedgerEntry]) -> Bool {
        let debits = ledgerEntries.filter { $0.entryType == .debit }.reduce(0) { $0 + $1.amount }
        let credits = ledgerEntries.filter { $0.entryType == .credit }.reduce(0) { $0 + $1.amount }
        return debits == credits
    }
}

// MARK: - Accounting Repository Protocol
protocol AccountingRepository: AnyObject {
    func saveLedgerEntry(_ entry: LedgerEntry) async throws -> LedgerEntry
    func saveTransactionRecord(_ transaction: TransactionRecord) async throws -> TransactionRecord
    func saveAuditTrail(_ audit: AuditTrail) async throws -> AuditTrail
    func getTransactionHistory(
        accountId: String?,
        accountType: AccountType?,
        type: TransactionRecordType?,
        startDate: Date?,
        endDate: Date?,
        limit: Int?
    ) async throws -> [TransactionRecord]
    func getLedgerEntries(
        accountId: String?,
        accountType: AccountType?,
        entryType: EntryType?,
        startDate: Date?,
        endDate: Date?,
        limit: Int?
    ) async throws -> [LedgerEntry]
    func getAccountBalance(accountId: String, asOf date: Date) async throws -> AccountBalance
    func getAuditTrail(
        entityType: String?,
        entityId: String?,
        userId: String?,
        startDate: Date?,
        endDate: Date?,
        limit: Int?
    ) async throws -> [AuditTrail]
}

// MARK: - Accounting Use Case Factory
protocol AccountingUseCaseFactory {
    func createRecordPaymentUseCase() -> RecordPaymentUseCase
    func createRecordDonationUseCase() -> RecordDonationUseCase
    func createRecordEscrowHoldUseCase() -> RecordEscrowHoldUseCase
    func createRecordEscrowReleaseUseCase() -> RecordEscrowReleaseUseCase
    func createRecordFeeUseCase() -> RecordFeeUseCase
    func createCreateLedgerEntryUseCase() -> CreateLedgerEntryUseCase
    func createCreateTransactionRecordUseCase() -> CreateTransactionRecordUseCase
    func createGetTransactionHistoryUseCase() -> GetTransactionHistoryUseCase
    func createGetLedgerEntriesUseCase() -> GetLedgerEntriesUseCase
    func createGetAccountBalanceUseCase() -> GetAccountBalanceUseCase
    func createCreateAuditTrailUseCase() -> CreateAuditTrailUseCase
    func createGetAuditTrailUseCase() -> GetAuditTrailUseCase
    func createValidateTransactionBalanceUseCase() -> ValidateTransactionBalanceUseCase
}

// MARK: - Accounting Use Case Error
enum AccountingUseCaseError: LocalizedError, Equatable {
    case invalidTransaction
    case unbalancedTransaction
    case invalidLedgerEntry
    case accountNotFound
    case auditTrailCreationFailed
    case validationFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidTransaction:
            return "Invalid transaction"
        case .unbalancedTransaction:
            return "Transaction is not balanced"
        case .invalidLedgerEntry:
            return "Invalid ledger entry"
        case .accountNotFound:
            return "Account not found"
        case .auditTrailCreationFailed:
            return "Audit trail creation failed"
        case .validationFailed:
            return "Validation failed"
        }
    }
}
