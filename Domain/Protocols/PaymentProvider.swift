import Foundation
import Combine

// MARK: - Payment Provider Protocol
protocol PaymentProvider: AnyObject {
    var providerName: String { get }
    var isAvailable: Bool { get }
    var supportedPaymentTypes: [PaymentType] { get }
    
    func processPayment(_ request: PaymentRequest) async throws -> PaymentResult
    func refundPayment(_ refundRequest: RefundRequest) async throws -> RefundResult
    func getPaymentStatus(_ paymentId: String) async throws -> PaymentStatus
    func validatePaymentMethod(_ method: PaymentMethod) async throws -> ValidationResult
}

// MARK: - Payment Request
struct PaymentRequest: Codable, Equatable {
    let id: String
    let amount: Decimal
    let currency: String
    let paymentMethod: PaymentMethod
    let description: String
    let metadata: [String: String]
    let customerId: String?
    let paymentIntentId: String?
    
    init(
        id: String = UUID().uuidString,
        amount: Decimal,
        currency: String = "USD",
        paymentMethod: PaymentMethod,
        description: String,
        metadata: [String: String] = [:],
        customerId: String? = nil,
        paymentIntentId: String? = nil
    ) {
        self.id = id
        self.amount = amount
        self.currency = currency
        self.paymentMethod = paymentMethod
        self.description = description
        self.metadata = metadata
        self.customerId = customerId
        self.paymentIntentId = paymentIntentId
    }
}

// MARK: - Payment Result
struct PaymentResult: Codable, Equatable {
    let success: Bool
    let paymentId: String
    let externalTransactionId: String?
    let status: PaymentStatus
    let amount: Decimal
    let currency: String
    let fees: [FeeBreakdown]
    let errorMessage: String?
    let metadata: [String: String]
    let processedAt: Date
    
    init(
        success: Bool,
        paymentId: String,
        externalTransactionId: String? = nil,
        status: PaymentStatus,
        amount: Decimal,
        currency: String = "USD",
        fees: [FeeBreakdown] = [],
        errorMessage: String? = nil,
        metadata: [String: String] = [:],
        processedAt: Date = Date()
    ) {
        self.success = success
        self.paymentId = paymentId
        self.externalTransactionId = externalTransactionId
        self.status = status
        self.amount = amount
        self.currency = currency
        self.fees = fees
        self.errorMessage = errorMessage
        self.metadata = metadata
        self.processedAt = processedAt
    }
}

// MARK: - Refund Request
struct RefundRequest: Codable, Equatable {
    let paymentId: String
    let amount: Decimal
    let reason: String
    let metadata: [String: String]
    
    init(
        paymentId: String,
        amount: Decimal,
        reason: String,
        metadata: [String: String] = [:]
    ) {
        self.paymentId = paymentId
        self.amount = amount
        self.reason = reason
        self.metadata = metadata
    }
}

// MARK: - Refund Result
struct RefundResult: Codable, Equatable {
    let success: Bool
    let refundId: String
    let paymentId: String
    let amount: Decimal
    let currency: String
    let status: PaymentStatus
    let errorMessage: String?
    let processedAt: Date
    
    init(
        success: Bool,
        refundId: String,
        paymentId: String,
        amount: Decimal,
        currency: String = "USD",
        status: PaymentStatus,
        errorMessage: String? = nil,
        processedAt: Date = Date()
    ) {
        self.success = success
        self.refundId = refundId
        self.paymentId = paymentId
        self.amount = amount
        self.currency = currency
        self.status = status
        self.errorMessage = errorMessage
        self.processedAt = processedAt
    }
}

// MARK: - Validation Result
struct ValidationResult: Codable, Equatable {
    let isValid: Bool
    let errorMessage: String?
    let supportedAmounts: ClosedRange<Decimal>?
    let supportedCurrencies: [String]
    
    init(
        isValid: Bool,
        errorMessage: String? = nil,
        supportedAmounts: ClosedRange<Decimal>? = nil,
        supportedCurrencies: [String] = ["USD"]
    ) {
        self.isValid = isValid
        self.errorMessage = errorMessage
        self.supportedAmounts = supportedAmounts
        self.supportedCurrencies = supportedCurrencies
    }
}

// MARK: - Payment Provider Factory
protocol PaymentProviderFactory {
    func createProvider(for method: PaymentMethod) -> PaymentProvider?
    func getAvailableProviders() -> [PaymentProvider]
}

// MARK: - Payment Provider Error
enum PaymentProviderError: LocalizedError, Equatable {
    case providerUnavailable
    case invalidAmount
    case invalidCurrency
    case paymentMethodNotSupported
    case insufficientFunds
    case networkError
    case authenticationFailed
    case invalidRequest
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .providerUnavailable:
            return "Payment provider is currently unavailable"
        case .invalidAmount:
            return "Invalid payment amount"
        case .invalidCurrency:
            return "Unsupported currency"
        case .paymentMethodNotSupported:
            return "Payment method not supported"
        case .insufficientFunds:
            return "Insufficient funds"
        case .networkError:
            return "Network error occurred"
        case .authenticationFailed:
            return "Authentication failed"
        case .invalidRequest:
            return "Invalid request"
        case .unknownError(let message):
            return message
        }
    }
}

// MARK: - Payment Provider Status
struct PaymentProviderStatus: Codable, Equatable {
    let providerName: String
    let isAvailable: Bool
    let lastCheck: Date
    let errorMessage: String?
    let supportedMethods: [PaymentMethod]
    let processingTime: TimeInterval?
    
    init(
        providerName: String,
        isAvailable: Bool,
        lastCheck: Date = Date(),
        errorMessage: String? = nil,
        supportedMethods: [PaymentMethod] = [],
        processingTime: TimeInterval? = nil
    ) {
        self.providerName = providerName
        self.isAvailable = isAvailable
        self.lastCheck = lastCheck
        self.errorMessage = errorMessage
        self.supportedMethods = supportedMethods
        self.processingTime = processingTime
    }
}
