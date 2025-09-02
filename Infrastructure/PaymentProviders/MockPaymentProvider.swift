import Foundation
import Combine

// MARK: - Mock Payment Provider
class MockPaymentProvider: PaymentProvider {
    let providerName: String = "Mock Payment Provider"
    let isAvailable: Bool = true
    let supportedPaymentTypes: [PaymentType] = [.deposit, .withdrawal, .refund]
    
    private var payments: [String: Payment] = [:]
    private var processingDelays: [String: TimeInterval] = [:]
    
    init() {
        // Add some default processing delays for realistic simulation
        processingDelays["stripe"] = 2.0
        processingDelays["apple_pay"] = 1.5
        processingDelays["bank_transfer"] = 5.0
        processingDelays["internal"] = 0.1
    }
    
    func processPayment(_ request: PaymentRequest) async throws -> PaymentResult {
        // Simulate network delay
        let delay = processingDelays[request.paymentMethod.rawValue] ?? 1.0
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        
        // Simulate occasional failures
        if shouldSimulateFailure(for: request) {
            return PaymentResult(
                success: false,
                paymentId: request.id,
                status: .failed,
                amount: request.amount,
                currency: request.currency,
                errorMessage: "Simulated payment failure for testing",
                metadata: request.metadata
            )
        }
        
        // Create successful payment result
        let payment = Payment(
            id: request.id,
            userId: request.metadata["userId"] ?? "unknown",
            amount: request.amount,
            currency: request.currency,
            type: .deposit,
            status: .completed,
            method: request.paymentMethod,
            description: request.description,
            metadata: request.metadata,
            externalTransactionId: "mock_\(UUID().uuidString)",
            processedAt: Date()
        )
        
        // Store payment for later reference
        payments[request.id] = payment
        
        // Calculate mock fees
        let fees = calculateMockFees(for: request)
        
        return PaymentResult(
            success: true,
            paymentId: request.id,
            externalTransactionId: payment.externalTransactionId,
            status: .completed,
            amount: request.amount,
            currency: request.currency,
            fees: fees,
            metadata: request.metadata
        )
    }
    
    func refundPayment(_ refundRequest: RefundRequest) async throws -> RefundResult {
        // Simulate network delay
        try await Task.sleep(nanoseconds: UInt64(1.0 * 1_000_000_000))
        
        // Check if original payment exists
        guard let originalPayment = payments[refundRequest.paymentId] else {
            return RefundResult(
                success: false,
                refundId: UUID().uuidString,
                paymentId: refundRequest.paymentId,
                amount: refundRequest.amount,
                status: .failed,
                errorMessage: "Original payment not found"
            )
        }
        
        // Validate refund amount
        guard refundRequest.amount <= originalPayment.amount else {
            return RefundResult(
                success: false,
                refundId: UUID().uuidString,
                paymentId: refundRequest.paymentId,
                amount: refundRequest.amount,
                status: .failed,
                errorMessage: "Refund amount exceeds original payment"
            )
        }
        
        // Create successful refund result
        return RefundResult(
            success: true,
            refundId: UUID().uuidString,
            paymentId: refundRequest.paymentId,
            amount: refundRequest.amount,
            status: .completed
        )
    }
    
    func getPaymentStatus(_ paymentId: String) async throws -> PaymentStatus {
        // Simulate network delay
        try await Task.sleep(nanoseconds: UInt64(0.5 * 1_000_000_000))
        
        guard let payment = payments[paymentId] else {
            throw PaymentProviderError.invalidRequest
        }
        
        return payment.status
    }
    
    func validatePaymentMethod(_ method: PaymentMethod) async throws -> ValidationResult {
        // Simulate network delay
        try await Task.sleep(nanoseconds: UInt64(0.3 * 1_000_000_000))
        
        // Mock validation logic
        switch method {
        case .stripe:
            return ValidationResult(
                isValid: true,
                supportedAmounts: 0.01...10000.0,
                supportedCurrencies: ["USD", "EUR", "GBP"]
            )
        case .applePay:
            return ValidationResult(
                isValid: true,
                supportedAmounts: 0.01...1000.0,
                supportedCurrencies: ["USD", "EUR", "GBP"]
            )
        case .bankTransfer:
            return ValidationResult(
                isValid: true,
                supportedAmounts: 1.0...100000.0,
                supportedCurrencies: ["USD"]
            )
        case .internal:
            return ValidationResult(
                isValid: true,
                supportedAmounts: 0.01...1000000.0,
                supportedCurrencies: ["USD"]
            )
        }
    }
    
    // MARK: - Private Methods
    
    private func shouldSimulateFailure(for request: PaymentRequest) -> Bool {
        // Simulate 5% failure rate for testing
        let random = Double.random(in: 0...1)
        return random < 0.05
    }
    
    private func calculateMockFees(for request: PaymentRequest) -> [FeeBreakdown] {
        var fees: [FeeBreakdown] = []
        
        // Add processing fee
        let processingFee = FeeBreakdown(
            feeType: .processing,
            rate: 0.30,
            rateType: .fixed,
            amount: 0.30,
            description: "Processing fee"
        )
        fees.append(processingFee)
        
        // Add percentage fee for certain methods
        switch request.paymentMethod {
        case .stripe:
            let stripeFee = FeeBreakdown(
                feeType: .deposit,
                rate: 2.9,
                rateType: .percentage,
                amount: (request.amount * 2.9) / 100,
                description: "Stripe processing fee"
            )
            fees.append(stripeFee)
        case .applePay:
            let applePayFee = FeeBreakdown(
                feeType: .deposit,
                rate: 2.0,
                rateType: .percentage,
                amount: (request.amount * 2.0) / 100,
                description: "Apple Pay processing fee"
            )
            fees.append(applePayFee)
        case .bankTransfer:
            let bankFee = FeeBreakdown(
                feeType: .deposit,
                rate: 1.0,
                rateType: .percentage,
                amount: (request.amount * 1.0) / 100,
                description: "Bank transfer fee"
            )
            fees.append(bankFee)
        case .internal:
            // No additional fees for internal transfers
            break
        }
        
        return fees
    }
}

// MARK: - Mock Payment Provider Factory
class MockPaymentProviderFactory: PaymentProviderFactory {
    func createProvider(for method: PaymentMethod) -> PaymentProvider? {
        return MockPaymentProvider()
    }
    
    func getAvailableProviders() -> [PaymentProvider] {
        return [MockPaymentProvider()]
    }
}

// MARK: - Mock Payment Provider Configuration
struct MockPaymentProviderConfig {
    let failureRate: Double
    let processingDelays: [PaymentMethod: TimeInterval]
    let supportedCurrencies: [String]
    let maxAmount: Decimal
    let minAmount: Decimal
    
    static let `default` = MockPaymentProviderConfig(
        failureRate: 0.05,
        processingDelays: [
            .stripe: 2.0,
            .applePay: 1.5,
            .bankTransfer: 5.0,
            .internal: 0.1
        ],
        supportedCurrencies: ["USD", "EUR", "GBP"],
        maxAmount: 1000000.0,
        minAmount: 0.01
    )
}
