import Foundation
import Combine

// MARK: - Create Wallet Use Case
class CreateWalletUseCase {
    private let walletService: WalletService
    
    init(walletService: WalletService) {
        self.walletService = walletService
    }
    
    func execute(for userId: String) async throws -> Wallet {
        return try await walletService.createWallet(for: userId)
    }
}

// MARK: - Get Wallet Use Case
class GetWalletUseCase {
    private let walletService: WalletService
    
    init(walletService: WalletService) {
        self.walletService = walletService
    }
    
    func execute(for userId: String) async throws -> Wallet {
        return try await walletService.getWallet(for: userId)
    }
}

// MARK: - Get Balance Use Case
class GetBalanceUseCase {
    private let walletService: WalletService
    
    init(walletService: WalletService) {
        self.walletService = walletService
    }
    
    func execute(for userId: String) async throws -> Decimal {
        return try await walletService.getBalance(for: userId)
    }
}

// MARK: - Deposit Use Case
class DepositUseCase {
    private let walletService: WalletService
    private let paymentProvider: PaymentProvider
    
    init(
        walletService: WalletService,
        paymentProvider: PaymentProvider
    ) {
        self.walletService = walletService
        self.paymentProvider = paymentProvider
    }
    
    func execute(
        amount: Decimal,
        method: PaymentMethod,
        userId: String,
        description: String
    ) async throws -> Payment {
        // Validate the deposit
        let validation = try await paymentProvider.validatePaymentMethod(method)
        guard validation.isValid else {
            throw WalletServiceError.invalidAmount
        }
        
        // Process the deposit
        return try await walletService.deposit(
            amount: amount,
            to: userId,
            method: method
        )
    }
}

// MARK: - Withdraw Use Case
class WithdrawUseCase {
    private let walletService: WalletService
    private let paymentProvider: PaymentProvider
    
    init(
        walletService: WalletService,
        paymentProvider: PaymentProvider
    ) {
        self.walletService = walletService
        self.paymentProvider = paymentProvider
    }
    
    func execute(
        amount: Decimal,
        method: PaymentMethod,
        userId: String,
        description: String
    ) async throws -> Payment {
        // Validate the withdrawal
        let validation = try await walletService.validateTransaction(
            amount: amount,
            type: .debit,
            for: userId
        )
        guard validation.isValid else {
            throw WalletServiceError.insufficientFunds
        }
        
        // Process the withdrawal
        return try await walletService.withdraw(
            amount: amount,
            from: userId,
            method: method
        )
    }
}

// MARK: - Hold Escrow Use Case
class HoldEscrowUseCase {
    private let walletService: WalletService
    
    init(walletService: WalletService) {
        self.walletService = walletService
    }
    
    func execute(
        amount: Decimal,
        for userId: String,
        goalId: String
    ) async throws -> Payment {
        // Validate the escrow hold
        let validation = try await walletService.validateTransaction(
            amount: amount,
            type: .escrowHold,
            for: userId
        )
        guard validation.isValid else {
            throw WalletServiceError.insufficientFunds
        }
        
        // Hold the escrow
        return try await walletService.holdEscrow(
            amount: amount,
            for: userId,
            goalId: goalId
        )
    }
}

// MARK: - Release Escrow Use Case
class ReleaseEscrowUseCase {
    private let walletService: WalletService
    
    init(walletService: WalletService) {
        self.walletService = walletService
    }
    
    func execute(
        amount: Decimal,
        for userId: String,
        goalId: String
    ) async throws -> Payment {
        // Release the escrow
        return try await walletService.releaseEscrow(
            amount: amount,
            for: userId,
            goalId: goalId
        )
    }
}

// MARK: - Refund Escrow Use Case
class RefundEscrowUseCase {
    private let walletService: WalletService
    
    init(walletService: WalletService) {
        self.walletService = walletService
    }
    
    func execute(
        amount: Decimal,
        for userId: String,
        goalId: String
    ) async throws -> Payment {
        // Refund the escrow
        return try await walletService.refundEscrow(
            amount: amount,
            for: userId,
            goalId: goalId
        )
    }
}

// MARK: - Apply Fees Use Case
class ApplyFeesUseCase {
    private let walletService: WalletService
    
    init(walletService: WalletService) {
        self.walletService = walletService
    }
    
    func execute(
        amount: Decimal,
        feeType: FeeType,
        for userId: String
    ) async throws -> Payment {
        // Apply the fees
        return try await walletService.applyFees(
            amount: amount,
            feeType: feeType,
            for: userId
        )
    }
}

// MARK: - Get Transaction History Use Case
class GetTransactionHistoryUseCase {
    private let walletService: WalletService
    
    init(walletService: WalletService) {
        self.walletService = walletService
    }
    
    func execute(
        for userId: String,
        type: TransactionType? = nil,
        limit: Int? = nil
    ) async throws -> [WalletTransaction] {
        return try await walletService.getTransactionHistory(
            for: userId,
            type: type,
            limit: limit
        )
    }
}

// MARK: - Validate Transaction Use Case
class ValidateTransactionUseCase {
    private let walletService: WalletService
    
    init(walletService: WalletService) {
        self.walletService = walletService
    }
    
    func execute(
        amount: Decimal,
        type: TransactionType,
        for userId: String
    ) async throws -> ValidationResult {
        return try await walletService.validateTransaction(
            amount: amount,
            type: type,
            for: userId
        )
    }
}

// MARK: - Wallet Use Case Factory
protocol WalletUseCaseFactory {
    func createCreateWalletUseCase() -> CreateWalletUseCase
    func createGetWalletUseCase() -> GetWalletUseCase
    func createGetBalanceUseCase() -> GetBalanceUseCase
    func createDepositUseCase() -> DepositUseCase
    func createWithdrawUseCase() -> WithdrawUseCase
    func createHoldEscrowUseCase() -> HoldEscrowUseCase
    func createReleaseEscrowUseCase() -> ReleaseEscrowUseCase
    func createRefundEscrowUseCase() -> RefundEscrowUseCase
    func createApplyFeesUseCase() -> ApplyFeesUseCase
    func createGetTransactionHistoryUseCase() -> GetTransactionHistoryUseCase
    func createValidateTransactionUseCase() -> ValidateTransactionUseCase
}

// MARK: - Wallet Use Case Error
enum WalletUseCaseError: LocalizedError, Equatable {
    case walletNotFound
    case insufficientFunds
    case invalidAmount
    case transactionFailed
    case escrowNotAvailable
    case userNotVerified
    case dailyLimitExceeded
    case monthlyLimitExceeded
    case walletSuspended
    case kycRequired
    case validationFailed
    
    var errorDescription: String? {
        switch self {
        case .walletNotFound:
            return "Wallet not found"
        case .insufficientFunds:
            return "Insufficient funds"
        case .invalidAmount:
            return "Invalid amount"
        case .transactionFailed:
            return "Transaction failed"
        case .escrowNotAvailable:
            return "Escrow not available"
        case .userNotVerified:
            return "User not verified"
        case .dailyLimitExceeded:
            return "Daily limit exceeded"
        case .monthlyLimitExceeded:
            return "Monthly limit exceeded"
        case .walletSuspended:
            return "Wallet is suspended"
        case .kycRequired:
            return "KYC verification required"
        case .validationFailed:
            return "Validation failed"
        }
    }
}
