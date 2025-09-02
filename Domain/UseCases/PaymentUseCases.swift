import Foundation
import Combine

// MARK: - Process Payment Use Case
class ProcessPaymentUseCase {
    private let paymentProvider: PaymentProvider
    private let walletService: WalletService
    private let feeService: FeeService
    
    init(
        paymentProvider: PaymentProvider,
        walletService: WalletService,
        feeService: FeeService
    ) {
        self.paymentProvider = paymentProvider
        self.walletService = walletService
        self.feeService = feeService
    }
    
    func execute(
        amount: Decimal,
        method: PaymentMethod,
        userId: String,
        description: String
    ) async throws -> PaymentResult {
        // Validate the payment request
        let validation = try await paymentProvider.validatePaymentMethod(method)
        guard validation.isValid else {
            throw PaymentProviderError.invalidRequest
        }
        
        // Calculate fees
        let feeCalculation = try await feeService.calculateFees(
            for: amount,
            method: method,
            type: .deposit
        )
        
        // Create payment request
        let paymentRequest = PaymentRequest(
            amount: amount,
            paymentMethod: method,
            description: description,
            metadata: ["userId": userId]
        )
        
        // Process payment through provider
        let result = try await paymentProvider.processPayment(paymentRequest)
        
        // If successful, update wallet
        if result.success {
            try await walletService.deposit(
                amount: result.amount,
                to: userId,
                method: method
            )
        }
        
        return result
    }
}

// MARK: - Process Withdrawal Use Case
class ProcessWithdrawalUseCase {
    private let paymentProvider: PaymentProvider
    private let walletService: WalletService
    private let feeService: FeeService
    
    init(
        paymentProvider: PaymentProvider,
        walletService: WalletService,
        feeService: FeeService
    ) {
        self.paymentProvider = paymentProvider
        self.walletService = walletService
        self.feeService = feeService
    }
    
    func execute(
        amount: Decimal,
        method: PaymentMethod,
        userId: String,
        description: String
    ) async throws -> PaymentResult {
        // Validate withdrawal amount
        let validation = try await walletService.validateTransaction(
            amount: amount,
            type: .debit,
            for: userId
        )
        guard validation.isValid else {
            throw WalletServiceError.insufficientFunds
        }
        
        // Calculate fees
        let feeCalculation = try await feeService.calculateFees(
            for: amount,
            method: method,
            type: .withdrawal
        )
        
        // Create withdrawal request
        let paymentRequest = PaymentRequest(
            amount: amount,
            paymentMethod: method,
            description: description,
            metadata: ["userId": userId, "type": "withdrawal"]
        )
        
        // Process withdrawal through provider
        let result = try await paymentProvider.processPayment(paymentRequest)
        
        // If successful, update wallet
        if result.success {
            try await walletService.withdraw(
                amount: result.amount,
                from: userId,
                method: method
            )
        }
        
        return result
    }
}

// MARK: - Process Refund Use Case
class ProcessRefundUseCase {
    private let paymentProvider: PaymentProvider
    private let walletService: WalletService
    
    init(
        paymentProvider: PaymentProvider,
        walletService: WalletService
    ) {
        self.paymentProvider = paymentProvider
        self.walletService = walletService
    }
    
    func execute(
        paymentId: String,
        amount: Decimal,
        reason: String,
        userId: String
    ) async throws -> RefundResult {
        // Create refund request
        let refundRequest = RefundRequest(
            paymentId: paymentId,
            amount: amount,
            reason: reason,
            metadata: ["userId": userId]
        )
        
        // Process refund through provider
        let result = try await paymentProvider.refundPayment(refundRequest)
        
        // If successful, update wallet
        if result.success {
            // Add refund amount back to wallet
            try await walletService.deposit(
                amount: result.amount,
                to: userId,
                method: .internal
            )
        }
        
        return result
    }
}

// MARK: - Get Payment Status Use Case
class GetPaymentStatusUseCase {
    private let paymentProvider: PaymentProvider
    
    init(paymentProvider: PaymentProvider) {
        self.paymentProvider = paymentProvider
    }
    
    func execute(paymentId: String) async throws -> PaymentStatus {
        return try await paymentProvider.getPaymentStatus(paymentId)
    }
}

// MARK: - Validate Payment Method Use Case
class ValidatePaymentMethodUseCase {
    private let paymentProvider: PaymentProvider
    
    init(paymentProvider: PaymentProvider) {
        self.paymentProvider = paymentProvider
    }
    
    func execute(method: PaymentMethod) async throws -> ValidationResult {
        return try await paymentProvider.validatePaymentMethod(method)
    }
}

// MARK: - Fee Service Protocol
protocol FeeService: AnyObject {
    func calculateFees(
        for amount: Decimal,
        method: PaymentMethod,
        type: PaymentType
    ) async throws -> FeeCalculation
    
    func getFeeModels(for type: FeeType) async throws -> [FeeModel]
    func updateFeeModel(_ feeModel: FeeModel) async throws
}

// MARK: - Payment Use Case Factory
protocol PaymentUseCaseFactory {
    func createProcessPaymentUseCase() -> ProcessPaymentUseCase
    func createProcessWithdrawalUseCase() -> ProcessWithdrawalUseCase
    func createProcessRefundUseCase() -> ProcessRefundUseCase
    func createGetPaymentStatusUseCase() -> GetPaymentStatusUseCase
    func createValidatePaymentMethodUseCase() -> ValidatePaymentMethodUseCase
}

// MARK: - Payment Use Case Error
enum PaymentUseCaseError: LocalizedError, Equatable {
    case invalidAmount
    case invalidPaymentMethod
    case insufficientFunds
    case paymentProcessingFailed
    case walletUpdateFailed
    case feeCalculationFailed
    case validationFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidAmount:
            return "Invalid payment amount"
        case .invalidPaymentMethod:
            return "Invalid payment method"
        case .insufficientFunds:
            return "Insufficient funds"
        case .paymentProcessingFailed:
            return "Payment processing failed"
        case .walletUpdateFailed:
            return "Wallet update failed"
        case .feeCalculationFailed:
            return "Fee calculation failed"
        case .validationFailed:
            return "Validation failed"
        }
    }
}
