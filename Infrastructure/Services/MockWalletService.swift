import Foundation
import Combine

// MARK: - Mock Wallet Service
class MockWalletService: WalletService {
    private var wallets: [String: Wallet] = [:]
    private var transactions: [String: [WalletTransaction]] = [:]
    private var escrowRecords: [String: EscrowRecord] = [:]
    
    init() {
        // Initialize with some mock data
        setupMockData()
    }
    
    func createWallet(for userId: String) async throws -> Wallet {
        let wallet = Wallet(
            userId: userId,
            balance: 0,
            availableBalance: 0,
            escrowBalance: 0,
            kycStatus: .unverified
        )
        
        wallets[userId] = wallet
        transactions[userId] = []
        
        return wallet
    }
    
    func getWallet(for userId: String) async throws -> Wallet {
        guard let wallet = wallets[userId] else {
            throw WalletServiceError.walletNotFound
        }
        return wallet
    }
    
    func getBalance(for userId: String) async throws -> Decimal {
        guard let wallet = wallets[userId] else {
            throw WalletServiceError.walletNotFound
        }
        return wallet.availableBalance
    }
    
    func deposit(amount: Decimal, to userId: String, method: PaymentMethod) async throws -> Payment {
        guard var wallet = wallets[userId] else {
            throw WalletServiceError.walletNotFound
        }
        
        // Validate amount
        guard amount > 0 else {
            throw WalletServiceError.invalidAmount
        }
        
        // Check KYC limits
        let limits = WalletLimits(
            dailyLimit: wallet.dailyLimit,
            monthlyLimit: wallet.monthlyLimit,
            dailyUsed: 0, // Simplified for mock
            monthlyUsed: 0 // Simplified for mock
        )
        
        guard amount <= limits.dailyRemaining else {
            throw WalletServiceError.dailyLimitExceeded
        }
        
        // Create payment record
        let payment = Payment(
            userId: userId,
            amount: amount,
            type: .deposit,
            status: .completed,
            method: method,
            description: "Deposit via \(method.displayName)",
            metadata: ["source": "mock_service"]
        )
        
        // Update wallet balance
        wallet = Wallet(
            id: wallet.id,
            userId: wallet.userId,
            balance: wallet.balance + amount,
            availableBalance: wallet.availableBalance + amount,
            escrowBalance: wallet.escrowBalance,
            currency: wallet.currency,
            status: wallet.status,
            kycStatus: wallet.kycStatus,
            dailyLimit: wallet.dailyLimit,
            monthlyLimit: wallet.monthlyLimit,
            createdAt: wallet.createdAt,
            updatedAt: Date(),
            lastActivityAt: Date()
        )
        
        wallets[userId] = wallet
        
        // Create wallet transaction
        let transaction = WalletTransaction(
            walletId: wallet.id,
            paymentId: payment.id,
            type: .credit,
            amount: amount,
            balanceBefore: wallet.balance - amount,
            balanceAfter: wallet.balance,
            description: "Deposit via \(method.displayName)",
            reference: payment.id
        )
        
        transactions[userId, default: []].append(transaction)
        
        return payment
    }
    
    func withdraw(amount: Decimal, from userId: String, method: PaymentMethod) async throws -> Payment {
        guard var wallet = wallets[userId] else {
            throw WalletServiceError.walletNotFound
        }
        
        // Validate amount
        guard amount > 0 else {
            throw WalletServiceError.invalidAmount
        }
        
        // Check available balance
        guard amount <= wallet.availableBalance else {
            throw WalletServiceError.insufficientFunds
        }
        
        // Check KYC status for withdrawals
        guard wallet.kycStatus == .verified else {
            throw WalletServiceError.kycRequired
        }
        
        // Create payment record
        let payment = Payment(
            userId: userId,
            amount: amount,
            type: .withdrawal,
            status: .completed,
            method: method,
            description: "Withdrawal via \(method.displayName)",
            metadata: ["source": "mock_service"]
        )
        
        // Update wallet balance
        wallet = Wallet(
            id: wallet.id,
            userId: wallet.userId,
            balance: wallet.balance - amount,
            availableBalance: wallet.availableBalance - amount,
            escrowBalance: wallet.escrowBalance,
            currency: wallet.currency,
            status: wallet.status,
            kycStatus: wallet.kycStatus,
            dailyLimit: wallet.dailyLimit,
            monthlyLimit: wallet.monthlyLimit,
            createdAt: wallet.createdAt,
            updatedAt: Date(),
            lastActivityAt: Date()
        )
        
        wallets[userId] = wallet
        
        // Create wallet transaction
        let transaction = WalletTransaction(
            walletId: wallet.id,
            paymentId: payment.id,
            type: .debit,
            amount: amount,
            balanceBefore: wallet.balance + amount,
            balanceAfter: wallet.balance,
            description: "Withdrawal via \(method.displayName)",
            reference: payment.id
        )
        
        transactions[userId, default: []].append(transaction)
        
        return payment
    }
    
    func holdEscrow(amount: Decimal, for userId: String, goalId: String) async throws -> Payment {
        guard var wallet = wallets[userId] else {
            throw WalletServiceError.walletNotFound
        }
        
        // Validate amount
        guard amount > 0 else {
            throw WalletServiceError.invalidAmount
        }
        
        // Check available balance
        guard amount <= wallet.availableBalance else {
            throw WalletServiceError.insufficientFunds
        }
        
        // Create escrow record
        let escrow = EscrowRecord(
            userId: userId,
            goalId: goalId,
            amount: amount,
            status: .held
        )
        
        escrowRecords[goalId] = escrow
        
        // Create payment record
        let payment = Payment(
            userId: userId,
            amount: amount,
            type: .escrowHold,
            status: .completed,
            method: .internal,
            description: "Escrow hold for goal: \(goalId)",
            metadata: ["goalId": goalId, "source": "mock_service"]
        )
        
        // Update wallet balance
        wallet = Wallet(
            id: wallet.id,
            userId: wallet.userId,
            balance: wallet.balance,
            availableBalance: wallet.availableBalance - amount,
            escrowBalance: wallet.escrowBalance + amount,
            currency: wallet.currency,
            status: wallet.status,
            kycStatus: wallet.kycStatus,
            dailyLimit: wallet.dailyLimit,
            monthlyLimit: wallet.monthlyLimit,
            createdAt: wallet.createdAt,
            updatedAt: Date(),
            lastActivityAt: Date()
        )
        
        wallets[userId] = wallet
        
        // Create wallet transaction
        let transaction = WalletTransaction(
            walletId: wallet.id,
            paymentId: payment.id,
            type: .escrowHold,
            amount: amount,
            balanceBefore: wallet.availableBalance + amount,
            balanceAfter: wallet.availableBalance,
            description: "Escrow hold for goal: \(goalId)",
            reference: payment.id
        )
        
        transactions[userId, default: []].append(transaction)
        
        return payment
    }
    
    func releaseEscrow(amount: Decimal, for userId: String, goalId: String) async throws -> Payment {
        guard var wallet = wallets[userId] else {
            throw WalletServiceError.walletNotFound
        }
        
        guard let escrow = escrowRecords[goalId] else {
            throw WalletServiceError.escrowNotAvailable
        }
        
        // Validate amount
        guard amount > 0 && amount <= escrow.amount else {
            throw WalletServiceError.invalidAmount
        }
        
        // Create payment record
        let payment = Payment(
            userId: userId,
            amount: amount,
            type: .escrowRelease,
            status: .completed,
            method: .internal,
            description: "Escrow release for goal: \(goalId)",
            metadata: ["goalId": goalId, "source": "mock_service"]
        )
        
        // Update escrow record
        var updatedEscrow = escrow
        updatedEscrow = EscrowRecord(
            id: escrow.id,
            userId: escrow.userId,
            goalId: escrow.goalId,
            amount: escrow.amount,
            currency: escrow.currency,
            status: .released,
            heldAt: escrow.heldAt,
            releasedAt: Date()
        )
        
        escrowRecords[goalId] = updatedEscrow
        
        // Update wallet balance
        wallet = Wallet(
            id: wallet.id,
            userId: wallet.userId,
            balance: wallet.balance + amount,
            availableBalance: wallet.availableBalance + amount,
            escrowBalance: wallet.escrowBalance - amount,
            currency: wallet.currency,
            status: wallet.status,
            kycStatus: wallet.kycStatus,
            dailyLimit: wallet.dailyLimit,
            monthlyLimit: wallet.monthlyLimit,
            createdAt: wallet.createdAt,
            updatedAt: Date(),
            lastActivityAt: Date()
        )
        
        wallets[userId] = wallet
        
        // Create wallet transaction
        let transaction = WalletTransaction(
            walletId: wallet.id,
            paymentId: payment.id,
            type: .escrowRelease,
            amount: amount,
            balanceBefore: wallet.balance - amount,
            balanceAfter: wallet.balance,
            description: "Escrow release for goal: \(goalId)",
            reference: payment.id
        )
        
        transactions[userId, default: []].append(transaction)
        
        return payment
    }
    
    func refundEscrow(amount: Decimal, for userId: String, goalId: String) async throws -> Payment {
        guard var wallet = wallets[userId] else {
            throw WalletServiceError.walletNotFound
        }
        
        guard let escrow = escrowRecords[goalId] else {
            throw WalletServiceError.escrowNotAvailable
        }
        
        // Validate amount
        guard amount > 0 && amount <= escrow.amount else {
            throw WalletServiceError.invalidAmount
        }
        
        // Create payment record
        let payment = Payment(
            userId: userId,
            amount: amount,
            type: .refund,
            status: .completed,
            method: .internal,
            description: "Escrow refund for goal: \(goalId)",
            metadata: ["goalId": goalId, "source": "mock_service"]
        )
        
        // Update escrow record
        var updatedEscrow = escrow
        updatedEscrow = EscrowRecord(
            id: escrow.id,
            userId: escrow.userId,
            goalId: escrow.goalId,
            amount: escrow.amount,
            currency: escrow.currency,
            status: .refunded,
            heldAt: escrow.heldAt,
            refundedAt: Date()
        )
        
        escrowRecords[goalId] = updatedEscrow
        
        // Update wallet balance
        wallet = Wallet(
            id: wallet.id,
            userId: wallet.userId,
            balance: wallet.balance,
            availableBalance: wallet.availableBalance + amount,
            escrowBalance: wallet.escrowBalance - amount,
            currency: wallet.currency,
            status: wallet.status,
            kycStatus: wallet.kycStatus,
            dailyLimit: wallet.dailyLimit,
            monthlyLimit: wallet.monthlyLimit,
            createdAt: wallet.createdAt,
            updatedAt: Date(),
            lastActivityAt: Date()
        )
        
        wallets[userId] = wallet
        
        // Create wallet transaction
        let transaction = WalletTransaction(
            walletId: wallet.id,
            paymentId: payment.id,
            type: .credit,
            amount: amount,
            balanceBefore: wallet.availableBalance - amount,
            balanceAfter: wallet.availableBalance,
            description: "Escrow refund for goal: \(goalId)",
            reference: payment.id
        )
        
        transactions[userId, default: []].append(transaction)
        
        return payment
    }
    
    func applyFees(amount: Decimal, feeType: FeeType, for userId: String) async throws -> Payment {
        guard var wallet = wallets[userId] else {
            throw WalletServiceError.walletNotFound
        }
        
        // Validate amount
        guard amount > 0 else {
            throw WalletServiceError.invalidAmount
        }
        
        // Check available balance
        guard amount <= wallet.availableBalance else {
            throw WalletServiceError.insufficientFunds
        }
        
        // Create payment record
        let payment = Payment(
            userId: userId,
            amount: amount,
            type: .fee,
            status: .completed,
            method: .internal,
            description: "Fee: \(feeType.displayName)",
            metadata: ["feeType": feeType.rawValue, "source": "mock_service"]
        )
        
        // Update wallet balance
        wallet = Wallet(
            id: wallet.id,
            userId: wallet.userId,
            balance: wallet.balance,
            availableBalance: wallet.availableBalance - amount,
            escrowBalance: wallet.escrowBalance,
            currency: wallet.currency,
            status: wallet.status,
            kycStatus: wallet.kycStatus,
            dailyLimit: wallet.dailyLimit,
            monthlyLimit: wallet.monthlyLimit,
            createdAt: wallet.createdAt,
            updatedAt: Date(),
            lastActivityAt: Date()
        )
        
        wallets[userId] = wallet
        
        // Create wallet transaction
        let transaction = WalletTransaction(
            walletId: wallet.id,
            paymentId: payment.id,
            type: .fee,
            amount: amount,
            balanceBefore: wallet.availableBalance + amount,
            balanceAfter: wallet.availableBalance,
            description: "Fee: \(feeType.displayName)",
            reference: payment.id
        )
        
        transactions[userId, default: []].append(transaction)
        
        return payment
    }
    
    func getTransactionHistory(for userId: String, limit: Int?) async throws -> [WalletTransaction] {
        guard let userTransactions = transactions[userId] else {
            return []
        }
        
        let sortedTransactions = userTransactions.sorted { $0.createdAt > $1.createdAt }
        
        if let limit = limit {
            return Array(sortedTransactions.prefix(limit))
        }
        
        return sortedTransactions
    }
    
    func getTransactionHistory(for userId: String, type: TransactionType?, limit: Int?) async throws -> [WalletTransaction] {
        var userTransactions = transactions[userId] ?? []
        
        if let type = type {
            userTransactions = userTransactions.filter { $0.type == type }
        }
        
        let sortedTransactions = userTransactions.sorted { $0.createdAt > $1.createdAt }
        
        if let limit = limit {
            return Array(sortedTransactions.prefix(limit))
        }
        
        return sortedTransactions
    }
    
    func validateTransaction(amount: Decimal, type: TransactionType, for userId: String) async throws -> ValidationResult {
        guard let wallet = wallets[userId] else {
            return ValidationResult(
                isValid: false,
                errorMessage: "Wallet not found"
            )
        }
        
        // Validate amount
        guard amount > 0 else {
            return ValidationResult(
                isValid: false,
                errorMessage: "Amount must be greater than 0"
            )
        }
        
        // Check balance for debits
        if type.isDebit && amount > wallet.availableBalance {
            return ValidationResult(
                isValid: false,
                errorMessage: "Insufficient funds"
            )
        }
        
        // Check KYC status for withdrawals
        if type == .debit && wallet.kycStatus != .verified {
            return ValidationResult(
                isValid: false,
                errorMessage: "KYC verification required for withdrawals"
            )
        }
        
        return ValidationResult(isValid: true)
    }
    
    // MARK: - Private Methods
    
    private func setupMockData() {
        // Create some sample wallets for testing
        let sampleWallet = Wallet(
            userId: "sample_user",
            balance: 1000.0,
            availableBalance: 800.0,
            escrowBalance: 200.0,
            kycStatus: .verified
        )
        
        wallets["sample_user"] = sampleWallet
        transactions["sample_user"] = []
        
        // Create some sample transactions
        let sampleTransaction = WalletTransaction(
            walletId: sampleWallet.id,
            paymentId: "sample_payment",
            type: .credit,
            amount: 1000.0,
            balanceBefore: 0,
            balanceAfter: 1000.0,
            description: "Initial deposit",
            reference: "sample_payment"
        )
        
        transactions["sample_user"] = [sampleTransaction]
    }
}
