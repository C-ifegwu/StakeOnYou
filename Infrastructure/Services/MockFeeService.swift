import Foundation
import Combine

// MARK: - Mock Fee Service
class MockFeeService: FeeService {
    private var feeModels: [FeeType: FeeModel] = [:]
    
    init() {
        setupDefaultFeeModels()
    }
    
    func calculateFees(
        for amount: Decimal,
        method: PaymentMethod,
        type: PaymentType
    ) async throws -> FeeCalculation {
        // Simulate network delay
        try await Task.sleep(nanoseconds: UInt64(0.5 * 1_000_000_000))
        
        var feeBreakdown: [FeeBreakdown] = []
        var totalFeeAmount: Decimal = 0
        
        // Get applicable fee models
        let applicableFees = getApplicableFees(for: type, method: method)
        
        // Calculate fees for each applicable model
        for feeModel in applicableFees {
            let feeAmount = feeModel.calculateFee(for: amount)
            totalFeeAmount += feeAmount
            
            let breakdown = FeeBreakdown(
                feeType: feeModel.type,
                rate: feeModel.rate,
                rateType: feeModel.rateType,
                amount: feeAmount,
                description: feeModel.description
            )
            feeBreakdown.append(breakdown)
        }
        
        return FeeCalculation(
            baseAmount: amount,
            feeAmount: totalFeeAmount,
            totalAmount: amount + totalFeeAmount,
            feeBreakdown: feeBreakdown
        )
    }
    
    func getFeeModels(for type: FeeType) async throws -> [FeeModel] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: UInt64(0.3 * 1_000_000_000))
        
        if let feeModel = feeModels[type] {
            return [feeModel]
        }
        
        return []
    }
    
    func updateFeeModel(_ feeModel: FeeModel) async throws {
        // Simulate network delay
        try await Task.sleep(nanoseconds: UInt64(0.2 * 1_000_000_000))
        
        feeModels[feeModel.type] = feeModel
    }
    
    // MARK: - Private Methods
    
    private func setupDefaultFeeModels() {
        // Default deposit fee
        let depositFee = FeeModel(
            name: "Standard Deposit Fee",
            description: "Standard fee for deposits via credit card or bank transfer",
            type: .deposit,
            rate: 2.9,
            rateType: .percentage,
            appliesTo: [.deposit]
        )
        feeModels[.deposit] = depositFee
        
        // Default withdrawal fee
        let withdrawalFee = FeeModel(
            name: "Standard Withdrawal Fee",
            description: "Standard fee for withdrawals to bank accounts",
            type: .withdrawal,
            rate: 1.0,
            rateType: .percentage,
            appliesTo: [.withdrawal]
        )
        feeModels[.withdrawal] = withdrawalFee
        
        // Default processing fee
        let processingFee = FeeModel(
            name: "Processing Fee",
            description: "Fixed processing fee for transactions",
            type: .processing,
            rate: 0.30,
            rateType: .fixed,
            appliesTo: [.deposit, .withdrawal]
        )
        feeModels[.processing] = processingFee
        
        // Default platform fee
        let platformFee = FeeModel(
            name: "Platform Fee",
            description: "Platform fee for successful goal completions",
            type: .platform,
            rate: 5.0,
            rateType: .percentage,
            appliesTo: [.escrowRelease]
        )
        feeModels[.platform] = platformFee
        
        // Default escrow fee
        let escrowFee = FeeModel(
            name: "Escrow Fee",
            description: "Fee for holding funds in escrow",
            type: .escrow,
            rate: 0.5,
            rateType: .percentage,
            appliesTo: [.escrowHold]
        )
        feeModels[.escrow] = escrowFee
        
        // Default charity fee (usually 0%)
        let charityFee = FeeModel(
            name: "Charity Fee",
            description: "Fee for charity donations",
            type: .charity,
            rate: 0.0,
            rateType: .percentage,
            appliesTo: [.donation]
        )
        feeModels[.charity] = charityFee
    }
    
    private func getApplicableFees(for type: PaymentType, method: PaymentMethod) -> [FeeModel] {
        var applicableFees: [FeeModel] = []
        
        // Always add processing fee for deposits and withdrawals
        if type == .deposit || type == .withdrawal {
            if let processingFee = feeModels[.processing] {
                applicableFees.append(processingFee)
            }
        }
        
        // Add method-specific fees
        switch method {
        case .stripe:
            if type == .deposit, let depositFee = feeModels[.deposit] {
                applicableFees.append(depositFee)
            }
        case .applePay:
            if type == .deposit {
                // Apple Pay has lower fees
                let applePayFee = FeeModel(
                    name: "Apple Pay Fee",
                    description: "Apple Pay processing fee",
                    type: .deposit,
                    rate: 2.0,
                    rateType: .percentage
                )
                applicableFees.append(applePayFee)
            }
        case .bankTransfer:
            if type == .deposit, let depositFee = feeModels[.deposit] {
                // Bank transfers have lower fees
                let bankFee = FeeModel(
                    name: "Bank Transfer Fee",
                    description: "Bank transfer processing fee",
                    type: .deposit,
                    rate: 1.0,
                    rateType: .percentage
                )
                applicableFees.append(bankFee)
            }
        case .internal:
            // No fees for internal transfers
            break
        }
        
        // Add type-specific fees
        switch type {
        case .escrowHold:
            if let escrowFee = feeModels[.escrow] {
                applicableFees.append(escrowFee)
            }
        case .escrowRelease:
            if let platformFee = feeModels[.platform] {
                applicableFees.append(platformFee)
            }
        case .donation:
            if let charityFee = feeModels[.charity] {
                applicableFees.append(charityFee)
            }
        default:
            break
        }
        
        return applicableFees
    }
}

// MARK: - Fee Service Factory
protocol FeeServiceFactory {
    func createFeeService() -> FeeService
}

// MARK: - Mock Fee Service Factory
class MockFeeServiceFactory: FeeServiceFactory {
    func createFeeService() -> FeeService {
        return MockFeeService()
    }
}

// MARK: - Fee Calculation Extensions
extension FeeCalculation {
    var formattedBaseAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSDecimalNumber(decimal: baseAmount)) ?? "\(baseAmount)"
    }
    
    var formattedFeeAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSDecimalNumber(decimal: feeAmount)) ?? "\(feeAmount)"
    }
    
    var formattedTotalAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSDecimalNumber(decimal: totalAmount)) ?? "\(totalAmount)"
    }
    
    var feePercentage: Decimal {
        guard baseAmount > 0 else { return 0 }
        return (feeAmount / baseAmount) * 100
    }
    
    var formattedFeePercentage: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return "\(formatter.string(from: NSDecimalNumber(decimal: feePercentage)) ?? "\(feePercentage)")%"
    }
}

// MARK: - Fee Breakdown Extensions
extension FeeBreakdown {
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD" // Default to USD for now
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "\(amount)"
    }
    
    var formattedRate: String {
        switch rateType {
        case .percentage:
            return "\(rate)%"
        case .fixed:
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = "USD"
            return formatter.string(from: NSDecimalNumber(decimal: rate)) ?? "\(rate)"
        case .tiered:
            return "Tiered"
        }
    }
}
