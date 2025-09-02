import Foundation
import Combine

// MARK: - Mock Charity Repository
class MockCharityRepository: CharityRepository {
    private var charities: [String: Charity] = [:]
    private var charitySelections: [String: CharitySelection] = [:]
    private var donationRecords: [String: DonationRecord] = [:]
    
    init() {
        setupMockData()
    }
    
    func getCharity(id: String) async throws -> Charity {
        guard let charity = charities[id] else {
            throw CharityUseCaseError.charityNotFound
        }
        return charity
    }
    
    func getCharities(
        category: CharityCategory?,
        searchQuery: String?,
        limit: Int?
    ) async throws -> [Charity] {
        var filteredCharities = Array(charities.values)
        
        // Filter by category
        if let category = category {
            filteredCharities = filteredCharities.filter { $0.category == category }
        }
        
        // Filter by search query
        if let searchQuery = searchQuery, !searchQuery.isEmpty {
            filteredCharities = filteredCharities.filter { charity in
                charity.name.localizedCaseInsensitiveContains(searchQuery) ||
                charity.description.localizedCaseInsensitiveContains(searchQuery) ||
                charity.category.displayName.localizedCaseInsensitiveContains(searchQuery)
            }
        }
        
        // Sort by name
        filteredCharities.sort { $0.name < $1.name }
        
        // Apply limit
        if let limit = limit {
            filteredCharities = Array(filteredCharities.prefix(limit))
        }
        
        return filteredCharities
    }
    
    func saveCharitySelection(_ selection: CharitySelection) async throws -> CharitySelection {
        let key = "\(selection.userId)_\(selection.goalId)"
        charitySelections[key] = selection
        return selection
    }
    
    func getCharitySelection(for goalId: String, userId: String) async throws -> CharitySelection? {
        let key = "\(userId)_\(goalId)"
        return charitySelections[key]
    }
    
    func saveDonationRecord(_ donation: DonationRecord) async throws -> DonationRecord {
        donationRecords[donation.id] = donation
        return donation
    }
    
    func getDonationRecord(id: String) async throws -> DonationRecord {
        guard let donation = donationRecords[id] else {
            throw CharityUseCaseError.donationFailed
        }
        return donation
    }
    
    func getDonationHistory(for userId: String, limit: Int?) async throws -> [DonationRecord] {
        var userDonations = donationRecords.values.filter { $0.userId == userId }
        
        // Sort by date (most recent first)
        userDonations.sort { $0.donationDate > $1.donationDate }
        
        // Apply limit
        if let limit = limit {
            userDonations = Array(userDonations.prefix(limit))
        }
        
        return userDonations
    }
    
    // MARK: - Private Methods
    
    private func setupMockData() {
        // Create sample charities
        let charity1 = Charity(
            name: "Red Cross",
            description: "Humanitarian organization providing emergency assistance, disaster relief, and education worldwide.",
            category: .disasterRelief,
            website: "https://www.redcross.org",
            logoUrl: "red_cross_logo",
            taxId: "53-0196605",
            isVerified: true,
            isActive: true,
            defaultPercentage: 50.0
        )
        charities[charity1.id] = charity1
        
        let charity2 = Charity(
            name: "Doctors Without Borders",
            description: "International medical humanitarian organization providing care in crisis zones.",
            category: .healthcare,
            website: "https://www.doctorswithoutborders.org",
            logoUrl: "msf_logo",
            taxId: "13-3433452",
            isVerified: true,
            isActive: true,
            defaultPercentage: 50.0
        )
        charities[charity2.id] = charity2
        
        let charity3 = Charity(
            name: "World Wildlife Fund",
            description: "Conservation organization working to preserve wildlife and their habitats.",
            category: .environment,
            website: "https://www.worldwildlife.org",
            logoUrl: "wwf_logo",
            taxId: "52-1693387",
            isVerified: true,
            isActive: true,
            defaultPercentage: 50.0
        )
        charities[charity3.id] = charity3
        
        let charity4 = Charity(
            name: "UNICEF",
            description: "United Nations agency providing humanitarian and developmental aid to children worldwide.",
            category: .education,
            website: "https://www.unicef.org",
            logoUrl: "unicef_logo",
            taxId: "13-1760110",
            isVerified: true,
            isActive: true,
            defaultPercentage: 50.0
        )
        charities[charity4.id] = charity4
        
        let charity5 = Charity(
            name: "Feeding America",
            description: "Network of food banks and pantries working to end hunger in the United States.",
            category: .poverty,
            website: "https://www.feedingamerica.org",
            logoUrl: "feeding_america_logo",
            taxId: "36-3673599",
            isVerified: true,
            isActive: true,
            defaultPercentage: 50.0
        )
        charities[charity5.id] = charity5
        
        let charity6 = Charity(
            name: "ASPCA",
            description: "American Society for the Prevention of Cruelty to Animals protecting animals from cruelty.",
            category: .animalWelfare,
            website: "https://www.aspca.org",
            logoUrl: "aspca_logo",
            taxId: "13-1623825",
            isVerified: true,
            isActive: true,
            defaultPercentage: 50.0
        )
        charities[charity6.id] = charity6
        
        let charity7 = Charity(
            name: "The Nature Conservancy",
            description: "Environmental organization working to conserve lands and waters for nature and people.",
            category: .environment,
            website: "https://www.nature.org",
            logoUrl: "nature_conservancy_logo",
            taxId: "53-0246862",
            isVerified: true,
            isActive: true,
            defaultPercentage: 50.0
        )
        charities[charity7.id] = charity7
        
        let charity8 = Charity(
            name: "Habitat for Humanity",
            description: "Nonprofit organization helping families build and improve places to call home.",
            category: .poverty,
            website: "https://www.habitat.org",
            logoUrl: "habitat_logo",
            taxId: "56-1169752",
            isVerified: true,
            isActive: true,
            defaultPercentage: 50.0
        )
        charities[charity8.id] = charity8
        
        // Create some sample charity selections
        let selection1 = CharitySelection(
            userId: "sample_user",
            goalId: "sample_goal_1",
            charityId: charity1.id,
            charityName: charity1.name,
            percentage: 50.0
        )
        charitySelections["\(selection1.userId)_\(selection1.goalId)"] = selection1
        
        let selection2 = CharitySelection(
            userId: "sample_user",
            goalId: "sample_goal_2",
            charityId: charity2.id,
            charityName: charity2.name,
            percentage: 75.0
        )
        charitySelections["\(selection2.userId)_\(selection2.goalId)"] = selection2
        
        // Create some sample donation records
        let donation1 = DonationRecord(
            userId: "sample_user",
            charityId: charity1.id,
            charityName: charity1.name,
            amount: 100.0,
            goalId: "sample_goal_1",
            goalTitle: "Sample Goal 1",
            paymentId: "sample_payment_1",
            isTaxDeductible: true
        )
        donationRecords[donation1.id] = donation1
        
        let donation2 = DonationRecord(
            userId: "sample_user",
            charityId: charity2.id,
            charityName: charity2.name,
            amount: 150.0,
            goalId: "sample_goal_2",
            goalTitle: "Sample Goal 2",
            paymentId: "sample_payment_2",
            isTaxDeductible: true
        )
        donationRecords[donation2.id] = donation2
    }
}

// MARK: - Charity Repository Factory
protocol CharityRepositoryFactory {
    func createCharityRepository() -> CharityRepository
}

// MARK: - Mock Charity Repository Factory
class MockCharityRepositoryFactory: CharityRepositoryFactory {
    func createCharityRepository() -> CharityRepository {
        return MockCharityRepository()
    }
}

// MARK: - Charity Extensions
extension Charity {
    var displayNameWithVerification: String {
        return isVerified ? "✓ \(name)" : name
    }
    
    var isRecommended: Bool {
        return isVerified && isActive
    }
    
    var categoryColor: String {
        switch category {
        case .education: return "blue"
        case .healthcare: return "red"
        case .environment: return "green"
        case .poverty: return "orange"
        case .animalWelfare: return "purple"
        case .disasterRelief: return "red"
        case .arts: return "pink"
        case .sports: return "yellow"
        case .technology: return "indigo"
        case .other: return "gray"
        }
    }
}

// MARK: - Charity Selection Extensions
extension CharitySelection {
    var isCustomPercentage: Bool {
        return percentage != 50.0
    }
    
    var formattedPercentage: String {
        return "\(percentage)%"
    }
}

// MARK: - Donation Record Extensions
extension DonationRecord {
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "\(amount)"
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: donationDate)
    }
    
    var hasReceipt: Bool {
        return receiptUrl != nil
    }
}
