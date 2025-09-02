import Foundation
import Combine

// MARK: - Select Charity Use Case
class SelectCharityUseCase {
    private let charityRepository: CharityRepository
    
    init(charityRepository: CharityRepository) {
        self.charityRepository = charityRepository
    }
    
    func execute(
        for goalId: String,
        userId: String,
        charityId: String,
        percentage: Decimal = 50.0
    ) async throws -> CharitySelection {
        // Validate the charity exists and is active
        let charity = try await charityRepository.getCharity(id: charityId)
        guard charity.isActive else {
            throw CharityUseCaseError.charityNotActive
        }
        
        // Validate percentage is within valid range
        guard percentage >= 0 && percentage <= 100 else {
            throw CharityUseCaseError.invalidPercentage
        }
        
        // Create or update charity selection
        let selection = CharitySelection(
            userId: userId,
            goalId: goalId,
            charityId: charityId,
            charityName: charity.name,
            percentage: percentage
        )
        
        return try await charityRepository.saveCharitySelection(selection)
    }
}

// MARK: - Process Donation Use Case
class ProcessDonationUseCase {
    private let charityRepository: CharityRepository
    private let walletService: WalletService
    private let accountingService: AccountingService
    
    init(
        charityRepository: CharityRepository,
        walletService: WalletService,
        accountingService: AccountingService
    ) {
        self.charityRepository = charityRepository
        self.walletService = walletService
        self.accountingService = accountingService
    }
    
    func execute(
        amount: Decimal,
        goalId: String,
        userId: String,
        charityId: String
    ) async throws -> DonationRecord {
        // Get charity information
        let charity = try await charityRepository.getCharity(id: charityId)
        guard charity.isActive else {
            throw CharityUseCaseError.charityNotActive
        }
        
        // Create donation record
        let donation = DonationRecord(
            userId: userId,
            charityId: charityId,
            charityName: charity.name,
            amount: amount,
            goalId: goalId,
            paymentId: UUID().uuidString // This would come from the actual payment
        )
        
        // Save donation record
        let savedDonation = try await charityRepository.saveDonationRecord(donation)
        
        // Process the donation through accounting
        try await accountingService.recordDonation(donation)
        
        return savedDonation
    }
}

// MARK: - Get Charity Use Case
class GetCharityUseCase {
    private let charityRepository: CharityRepository
    
    init(charityRepository: CharityRepository) {
        self.charityRepository = charityRepository
    }
    
    func execute(id: String) async throws -> Charity {
        return try await charityRepository.getCharity(id: id)
    }
}

// MARK: - Get Charities Use Case
class GetCharitiesUseCase {
    private let charityRepository: CharityRepository
    
    init(charityRepository: CharityRepository) {
        self.charityRepository = charityRepository
    }
    
    func execute(
        category: CharityCategory? = nil,
        searchQuery: String? = nil,
        limit: Int? = nil
    ) async throws -> [Charity] {
        return try await charityRepository.getCharities(
            category: category,
            searchQuery: searchQuery,
            limit: limit
        )
    }
}

// MARK: - Get Charity Selection Use Case
class GetCharitySelectionUseCase {
    private let charityRepository: CharityRepository
    
    init(charityRepository: CharityRepository) {
        self.charityRepository = charityRepository
    }
    
    func execute(for goalId: String, userId: String) async throws -> CharitySelection? {
        return try await charityRepository.getCharitySelection(
            for: goalId,
            userId: userId
        )
    }
}

// MARK: - Get Donation History Use Case
class GetDonationHistoryUseCase {
    private let charityRepository: CharityRepository
    
    init(charityRepository: CharityRepository) {
        self.charityRepository = charityRepository
    }
    
    func execute(
        for userId: String,
        limit: Int? = nil
    ) async throws -> [DonationRecord] {
        return try await charityRepository.getDonationHistory(
            for: userId,
            limit: limit
        )
    }
}

// MARK: - Generate Receipt Use Case
class GenerateReceiptUseCase {
    private let charityRepository: CharityRepository
    private let accountingService: AccountingService
    
    init(
        charityRepository: CharityRepository,
        accountingService: AccountingService
    ) {
        self.charityRepository = charityRepository
        self.accountingService = accountingService
    }
    
    func execute(for donationId: String) async throws -> ReceiptData {
        // Get donation record
        let donation = try await charityRepository.getDonationRecord(id: donationId)
        
        // Get charity information
        let charity = try await charityRepository.getCharity(id: donation.charityId)
        
        // Generate receipt data
        let receipt = ReceiptData(
            donationId: donation.id,
            charityName: charity.name,
            amount: donation.amount,
            currency: donation.currency,
            date: donation.donationDate,
            isTaxDeductible: donation.isTaxDeductible,
            charityTaxId: charity.taxId
        )
        
        return receipt
    }
}

// MARK: - Receipt Data
struct ReceiptData: Codable, Equatable {
    let donationId: String
    let charityName: String
    let amount: Decimal
    let currency: String
    let date: Date
    let isTaxDeductible: Bool
    let charityTaxId: String?
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "\(amount)"
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Charity Repository Protocol
protocol CharityRepository: AnyObject {
    func getCharity(id: String) async throws -> Charity
    func getCharities(
        category: CharityCategory?,
        searchQuery: String?,
        limit: Int?
    ) async throws -> [Charity]
    func saveCharitySelection(_ selection: CharitySelection) async throws -> CharitySelection
    func getCharitySelection(for goalId: String, userId: String) async throws -> CharitySelection?
    func saveDonationRecord(_ donation: DonationRecord) async throws -> DonationRecord
    func getDonationRecord(id: String) async throws -> DonationRecord
    func getDonationHistory(for userId: String, limit: Int?) async throws -> [DonationRecord]
}

// MARK: - Accounting Service Protocol
protocol AccountingService: AnyObject {
    func recordDonation(_ donation: DonationRecord) async throws
    func recordPayment(_ payment: Payment) async throws
    func recordEscrowHold(_ escrow: EscrowRecord) async throws
    func recordEscrowRelease(_ escrow: EscrowRecord) async throws
    func recordFee(_ fee: FeeBreakdown, for userId: String) async throws
}

// MARK: - Charity Use Case Factory
protocol CharityUseCaseFactory {
    func createSelectCharityUseCase() -> SelectCharityUseCase
    func createProcessDonationUseCase() -> ProcessDonationUseCase
    func createGetCharityUseCase() -> GetCharityUseCase
    func createGetCharitiesUseCase() -> GetCharitiesUseCase
    func createGetCharitySelectionUseCase() -> GetCharitySelectionUseCase
    func createGetDonationHistoryUseCase() -> GetDonationHistoryUseCase
    func createGenerateReceiptUseCase() -> GenerateReceiptUseCase
}

// MARK: - Charity Use Case Error
enum CharityUseCaseError: LocalizedError, Equatable {
    case charityNotFound
    case charityNotActive
    case invalidPercentage
    case donationFailed
    case receiptGenerationFailed
    case validationFailed
    
    var errorDescription: String? {
        switch self {
        case .charityNotFound:
            return "Charity not found"
        case .charityNotActive:
            return "Charity is not active"
        case .invalidPercentage:
            return "Invalid percentage value"
        case .donationFailed:
            return "Donation processing failed"
        case .receiptGenerationFailed:
            return "Receipt generation failed"
        case .validationFailed:
            return "Validation failed"
        }
    }
}
