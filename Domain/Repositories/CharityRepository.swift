import Foundation
import Combine

// MARK: - Charity Repository Protocol
protocol CharityRepository {
    // MARK: - CRUD Operations
    func createCharity(_ charity: Charity) async throws -> Charity
    func getCharity(id: String) async throws -> Charity?
    func updateCharity(_ charity: Charity) async throws -> Charity
    func deleteCharity(id: String) async throws -> Bool
    
    // MARK: - Query Operations
    func getAllCharities() async throws -> [Charity]
    func getCharities(byRegion: String) async throws -> [Charity]
    func getCharities(byCategory: String) async throws -> [Charity]
    func getCharities(byDateRange: DateInterval) async throws -> [Charity]
    func getVerifiedCharities() async throws -> [Charity]
    func getCharities(byVerificationStatus: String) async throws -> [Charity]
    
    // MARK: - Search Operations
    func searchCharities(query: String) async throws -> [Charity]
    func getCharitiesByTags(tags: [String]) async throws -> [Charity]
    func getCharitiesByDonationAmount(minAmount: Decimal, maxAmount: Decimal?) async throws -> [Charity]
    
    // MARK: - Verification Operations
    func verifyCharity(charityId: String, verifiedBy: String) async throws -> Charity
    func updateVerificationStatus(charityId: String, status: String, notes: String?) async throws -> Charity
    func getCharityVerificationHistory(charityId: String) async throws -> [CharityVerificationEvent]
    
    // MARK: - Analytics Operations
    func getCharityStatistics() async throws -> CharityStatistics
    func getCharityPerformance(charityId: String, timeRange: TimeRange) async throws -> CharityPerformance
    func getTopCharities(limit: Int, byMetric: CharityMetric) async throws -> [CharityWithStats]
    
    // MARK: - Bulk Operations
    func bulkUpdateCharities(_ charities: [Charity]) async throws -> [Charity]
    func deleteUnverifiedCharities(olderThan date: Date) async throws -> Int
}

// MARK: - Supporting Models
struct CharityVerificationEvent {
    let id: String
    let charityId: String
    let verifiedBy: String
    let status: String
    let notes: String?
    let timestamp: Date
    let previousStatus: String?
}

struct CharityStatistics {
    let totalCharities: Int
    let verifiedCharities: Int
    let pendingVerification: Int
    let totalDonations: Decimal
    let averageDonationAmount: Decimal
    let topCategories: [CharityCategoryStats]
}

struct CharityCategoryStats {
    let category: String
    let count: Int
    let totalDonations: Decimal
    let averageDonationAmount: Decimal
}

struct CharityPerformance {
    let totalDonations: Decimal
    let donationCount: Int
    let averageDonationAmount: Decimal
    let donorRetentionRate: Double
    let fundraisingEfficiency: Double
    let impactMetrics: [String: Any]
}

struct CharityWithStats {
    let charity: Charity
    let statistics: CharityStatistics
    let recentDonations: [CharityDonation]
}

struct CharityDonation {
    let id: String
    let amount: Decimal
    let donorId: String
    let donorName: String
    let timestamp: Date
    let isAnonymous: Bool
    let message: String?
}

enum CharityMetric: String, CaseIterable {
    case totalDonations = "total_donations"
    case donationCount = "donation_count"
    case averageDonation = "average_donation"
    case donorRetention = "donor_retention"
    case fundraisingEfficiency = "fundraising_efficiency"
    case verificationStatus = "verification_status"
    
    var displayName: String {
        switch self {
        case .totalDonations: return "Total Donations"
        case .donationCount: return "Donation Count"
        case .averageDonation: return "Average Donation"
        case .donorRetention: return "Donor Retention"
        case .fundraisingEfficiency: return "Fundraising Efficiency"
        case .verificationStatus: return "Verification Status"
        }
    }
}

// MARK: - Charity Repository Extensions
extension CharityRepository {
    // MARK: - Convenience Methods
    func getActiveCharities() async throws -> [Charity] {
        let charities = try await getVerifiedCharities()
        // Consider a charity active if it has recent donations or activity
        // This is a simplified check - in practice, you'd want more sophisticated logic
        return charities
    }
    
    func getCharitiesByCountry(country: String) async throws -> [Charity] {
        return try await getCharities(byRegion: country)
    }
    
    func getCharitiesByCategory(category: String) async throws -> [Charity] {
        return try await getCharities(byCategory: category)
    }
    
    func getCharitiesByVerificationStatus(status: String) async throws -> [Charity] {
        return try await getCharities(byVerificationStatus: status)
    }
    
    func getCharitiesWithHighDonations(minAmount: Decimal) async throws -> [Charity] {
        return try await getCharitiesByDonationAmount(minAmount: minAmount, maxAmount: nil)
    }
    
    func getCharitiesByPopularity(limit: Int) async throws -> [Charity] {
        return try await getTopCharities(limit: limit, byMetric: .donationCount)
    }
    
    func getCharitiesByTotalDonations(limit: Int) async throws -> [Charity] {
        return try await getTopCharities(limit: limit, byMetric: .totalDonations)
    }
    
    func getCharitiesByEfficiency(limit: Int) async throws -> [Charity] {
        return try await getTopCharities(limit: limit, byMetric: .fundraisingEfficiency)
    }
    
    func getCharitiesByDonorRetention(limit: Int) async throws -> [Charity] {
        return try await getTopCharities(limit: limit, byMetric: .donorRetention)
    }
    
    func getCharitiesByRegionAndCategory(region: String, category: String) async throws -> [Charity] {
        let regionCharities = try await getCharities(byRegion: region)
        let categoryCharities = try await getCharities(byCategory: category)
        
        let regionIds = Set(regionCharities.map { $0.id })
        let categoryIds = Set(categoryCharities.map { $0.id })
        
        let intersectionIds = regionIds.intersection(categoryIds)
        return regionCharities.filter { intersectionIds.contains($0.id) }
    }
    
    func getCharitiesByTags(tags: [String]) async throws -> [Charity] {
        return try await getCharitiesByTags(tags: tags)
    }
    
    func getCharitiesBySearchQuery(query: String) async throws -> [Charity] {
        return try await searchCharities(query: query)
    }
}

// MARK: - Charity Repository Error
enum CharityRepositoryError: LocalizedError {
    case charityNotFound
    case invalidCharityData
    case charityAlreadyExists
    case verificationFailed
    case insufficientPermissions
    case invalidVerificationData
    case databaseError(Error)
    case networkError(Error)
    case permissionDenied
    case quotaExceeded
    
    var errorDescription: String? {
        switch self {
        case .charityNotFound:
            return "Charity not found"
        case .invalidCharityData:
            return "Invalid charity data"
        case .charityAlreadyExists:
            return "Charity already exists"
        case .verificationFailed:
            return "Charity verification failed"
        case .insufficientPermissions:
            return "Insufficient permissions for this operation"
        case .invalidVerificationData:
            return "Invalid verification data"
        case .databaseError(let error):
            return "Database error: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .permissionDenied:
            return "Permission denied"
        case .quotaExceeded:
            return "Quota exceeded"
        }
    }
}
