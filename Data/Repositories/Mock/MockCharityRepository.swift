import Foundation
import Combine

// MARK: - Mock Charity Repository Implementation
class MockCharityRepository: CharityRepository {
    // MARK: - Properties
    private var charities: [String: Charity] = [:]
    private let logger: Logger
    
    // MARK: - Initialization
    init(logger: Logger = ConsoleLogger()) {
        self.logger = logger
        setupMockData()
    }
    
    // MARK: - CRUD Operations
    func createCharity(_ charity: Charity) async throws -> Charity {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 800_000_000)
        
        var newCharity = charity
        if newCharity.id.isEmpty {
            newCharity = Charity(
                id: UUID().uuidString,
                name: charity.name,
                description: charity.description,
                category: charity.category,
                website: charity.website,
                logoUrl: charity.logoUrl,
                isVerified: charity.isVerified,
                isActive: charity.isActive,
                createdAt: Date(),
                updatedAt: Date()
            )
        }
        
        charities[newCharity.id] = newCharity
        logger.info("Mock: Created charity with ID: \(newCharity.id)")
        return newCharity
    }
    
    func getCharity(id: String) async throws -> Charity? {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let charity = charities[id]
        logger.info("Mock: Retrieved charity with ID: \(id), found: \(charity != nil)")
        return charity
    }
    
    func updateCharity(_ charity: Charity) async throws -> Charity {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        guard charities[charity.id] != nil else {
            throw CharityRepositoryError.charityNotFound
        }
        
        var updatedCharity = charity
        updatedCharity.updatedAt = Date()
        charities[charity.id] = updatedCharity
        
        logger.info("Mock: Updated charity with ID: \(charity.id)")
        return updatedCharity
    }
    
    func deleteCharity(id: String) async throws -> Bool {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 600_000_000)
        
        guard charities[id] != nil else {
            throw CharityRepositoryError.charityNotFound
        }
        
        charities.removeValue(forKey: id)
        logger.info("Mock: Deleted charity with ID: \(id)")
        return true
    }
    
    // MARK: - Query Operations
    func getCharities(byCategory: CharityCategory) async throws -> [Charity] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let categoryCharities = charities.values.filter { $0.category == byCategory }
        logger.info("Mock: Retrieved \(categoryCharities.count) charities in category: \(byCategory)")
        return categoryCharities
    }
    
    func getVerifiedCharities() async throws -> [Charity] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let verifiedCharities = charities.values.filter { $0.isVerified }
        logger.info("Mock: Retrieved \(verifiedCharities.count) verified charities")
        return verifiedCharities
    }
    
    func getActiveCharities() async throws -> [Charity] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let activeCharities = charities.values.filter { $0.isActive }
        logger.info("Mock: Retrieved \(activeCharities.count) active charities")
        return activeCharities
    }
    
    func getCharities(byName: String) async throws -> [Charity] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let nameCharities = charities.values.filter { $0.name.localizedCaseInsensitiveContains(byName) }
        logger.info("Mock: Retrieved \(nameCharities.count) charities with name containing: \(byName)")
        return nameCharities
    }
    
    func getCharities(byLocation: String) async throws -> [Charity] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        // Mock location-based search - in real implementation this would use actual location data
        let locationCharities = charities.values.filter { _ in
            // Simulate some charities being in the specified location
            Bool.random()
        }
        
        logger.info("Mock: Retrieved \(locationCharities.count) charities in location: \(location)")
        return locationCharities
    }
    
    // MARK: - Featured and Popular Charities
    func getFeaturedCharities(limit: Int) async throws -> [Charity] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        let featuredCharities = charities.values.filter { $0.isVerified && $0.isActive }
        let limitedCharities = Array(featuredCharities.prefix(limit))
        
        logger.info("Mock: Retrieved \(limitedCharities.count) featured charities")
        return limitedCharities
    }
    
    func getPopularCharities(limit: Int) async throws -> [Charity] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        // Mock popularity ranking - in real implementation this would use actual donation/engagement data
        let popularCharities = charities.values.filter { $0.isVerified && $0.isActive }
        let limitedCharities = Array(popularCharities.prefix(limit))
        
        logger.info("Mock: Retrieved \(limitedCharities.count) popular charities")
        return limitedCharities
    }
    
    func getTrendingCharities(limit: Int) async throws -> [Charity] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        // Mock trending calculation - in real implementation this would use recent activity data
        let trendingCharities = charities.values.filter { $0.isVerified && $0.isActive }
        let limitedCharities = Array(trendingCharities.prefix(limit))
        
        logger.info("Mock: Retrieved \(limitedCharities.count) trending charities")
        return limitedCharities
    }
    
    // MARK: - Search and Discovery
    func searchCharities(query: String, filters: CharitySearchFilters?) async throws -> [Charity] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        var searchResults = charities.values
        
        // Apply text search
        if !query.isEmpty {
            searchResults = searchResults.filter { charity in
                charity.name.localizedCaseInsensitiveContains(query) ||
                charity.description.localizedCaseInsensitiveContains(query)
            }
        }
        
        // Apply filters
        if let filters = filters {
            if let category = filters.category {
                searchResults = searchResults.filter { $0.category == category }
            }
            
            if let isVerified = filters.isVerified {
                searchResults = searchResults.filter { $0.isVerified == isVerified }
            }
            
            if let isActive = filters.isActive {
                searchResults = searchResults.filter { $0.isActive == isActive }
            }
        }
        
        logger.info("Mock: Search returned \(searchResults.count) charities for query: \(query)")
        return searchResults
    }
    
    func getCharityRecommendations(forUserId: String, limit: Int) async throws -> [Charity] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        // Mock recommendation logic - in real implementation this would use user preferences and history
        let recommendedCharities = charities.values.filter { $0.isVerified && $0.isActive }
        let limitedCharities = Array(recommendedCharities.prefix(limit))
        
        logger.info("Mock: Generated \(limitedCharities.count) charity recommendations for user: \(forUserId)")
        return limitedCharities
    }
    
    // MARK: - Verification and Moderation
    func verifyCharity(id: String) async throws -> Charity {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 600_000_000)
        
        guard var charity = charities[id] else {
            throw CharityRepositoryError.charityNotFound
        }
        
        charity.isVerified = true
        charity.updatedAt = Date()
        charities[id] = charity
        
        logger.info("Mock: Verified charity with ID: \(id)")
        return charity
    }
    
    func unverifyCharity(id: String) async throws -> Charity {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        guard var charity = charities[id] else {
            throw CharityRepositoryError.charityNotFound
        }
        
        charity.isVerified = false
        charity.updatedAt = Date()
        charities[id] = charity
        
        logger.info("Mock: Unverified charity with ID: \(id)")
        return charity
    }
    
    func activateCharity(id: String) async throws -> Charity {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        guard var charity = charities[id] else {
            throw CharityRepositoryError.charityNotFound
        }
        
        charity.isActive = true
        charity.updatedAt = Date()
        charities[id] = charity
        
        logger.info("Mock: Activated charity with ID: \(id)")
        return charity
    }
    
    func deactivateCharity(id: String) async throws -> Charity {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        guard var charity = charities[id] else {
            throw CharityRepositoryError.charityNotFound
        }
        
        charity.isActive = false
        charity.updatedAt = Date()
        charities[id] = charity
        
        logger.info("Mock: Deactivated charity with ID: \(id)")
        return charity
    }
    
    // MARK: - Analytics and Reporting
    func getCharityStatistics(forCharityId: String) async throws -> CharityStatistics {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        guard charities[forCharityId] != nil else {
            throw CharityRepositoryError.charityNotFound
        }
        
        let statistics = CharityStatistics(
            totalDonations: 15000.0,
            totalDonors: 1250,
            averageDonation: 12.0,
            monthlyGrowth: 0.15, // 15% growth
            donorRetention: 0.78, // 78% retention
            topDonationCategories: ["health", "education", "environment"],
            engagementScore: 0.85
        )
        
        logger.info("Mock: Generated charity statistics for charity: \(forCharityId)")
        return statistics
    }
    
    func getCharityPerformance(forCharityId: String, timeRange: TimeRange) async throws -> CharityPerformance {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        guard charities[forCharityId] != nil else {
            throw CharityRepositoryError.charityNotFound
        }
        
        let performance = CharityPerformance(
            charityId: forCharityId,
            timeRange: timeRange,
            donationsReceived: 5000.0,
            newDonors: 150,
            repeatDonors: 75,
            averageDonation: 15.0,
            growthRate: 0.12, // 12% growth
            donorSatisfaction: 0.92,
            impactMetrics: [
                "lives_impacted": "500+",
                "communities_served": "25",
                "projects_completed": "12"
            ]
        )
        
        logger.info("Mock: Generated charity performance for charity: \(forCharityId)")
        return performance
    }
    
    func getCharityImpact(forCharityId: String) async throws -> CharityImpact {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        guard charities[forCharityId] != nil else {
            throw CharityRepositoryError.charityNotFound
        }
        
        let impact = CharityImpact(
            charityId: forCharityId,
            totalLivesImpacted: 5000,
            communitiesServed: 50,
            projectsCompleted: 25,
            volunteersMobilized: 500,
            partnerships: 15,
            sustainabilityScore: 0.88,
            transparencyRating: 0.92,
            impactAreas: ["health", "education", "environment", "poverty"]
        )
        
        logger.info("Mock: Generated charity impact for charity: \(forCharityId)")
        return impact
    }
    
    // MARK: - Bulk Operations
    func bulkUpdateCharities(_ charities: [Charity]) async throws -> [Charity] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        var updatedCharities: [Charity] = []
        
        for charity in charities {
            if self.charities[charity.id] != nil {
                var updatedCharity = charity
                updatedCharity.updatedAt = Date()
                self.charities[charity.id] = updatedCharity
                updatedCharities.append(updatedCharity)
            }
        }
        
        logger.info("Mock: Bulk updated \(updatedCharities.count) charities")
        return updatedCharities
    }
    
    func getCharitiesByBatch(ids: [String]) async throws -> [Charity] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        let batchCharities = ids.compactMap { charities[$0] }
        logger.info("Mock: Retrieved \(batchCharities.count) charities by batch")
        return batchCharities
    }
    
    // MARK: - Private Helper Methods
    private func setupMockData() {
        // Create some mock charities for testing
        let mockCharities = [
            Charity(
                id: "charity-1",
                name: "Red Cross",
                description: "Humanitarian organization providing emergency assistance, disaster relief, and education worldwide.",
                category: .health,
                website: "https://www.redcross.org",
                logoUrl: "https://example.com/redcross-logo.png",
                isVerified: true,
                isActive: true,
                createdAt: Date().addingTimeInterval(-365 * 24 * 60 * 60),
                updatedAt: Date().addingTimeInterval(-30 * 24 * 60 * 60)
            ),
            Charity(
                id: "charity-2",
                name: "UNICEF",
                description: "United Nations agency responsible for providing humanitarian and developmental aid to children worldwide.",
                category: .children,
                website: "https://www.unicef.org",
                logoUrl: "https://example.com/unicef-logo.png",
                isVerified: true,
                isActive: true,
                createdAt: Date().addingTimeInterval(-730 * 24 * 60 * 60),
                updatedAt: Date().addingTimeInterval(-60 * 24 * 60 * 60)
            ),
            Charity(
                id: "charity-3",
                name: "World Wildlife Fund",
                description: "International non-governmental organization working in the field of wilderness preservation and the reduction of human impact on the environment.",
                category: .environment,
                website: "https://www.worldwildlife.org",
                logoUrl: "https://example.com/wwf-logo.png",
                isVerified: true,
                isActive: true,
                createdAt: Date().addingTimeInterval(-1095 * 24 * 60 * 60),
                updatedAt: Date().addingTimeInterval(-90 * 24 * 60 * 60)
            ),
            Charity(
                id: "charity-4",
                name: "Doctors Without Borders",
                description: "International humanitarian medical non-governmental organization providing medical assistance in conflict zones and countries affected by endemic diseases.",
                category: .health,
                website: "https://www.msf.org",
                logoUrl: "https://example.com/msf-logo.png",
                isVerified: true,
                isActive: true,
                createdAt: Date().addingTimeInterval(-1825 * 24 * 60 * 60),
                updatedAt: Date().addingTimeInterval(-120 * 24 * 60 * 60)
            ),
            Charity(
                id: "charity-5",
                name: "Khan Academy",
                description: "Non-profit educational organization providing free, world-class education for anyone, anywhere.",
                category: .education,
                website: "https://www.khanacademy.org",
                logoUrl: "https://example.com/khan-logo.png",
                isVerified: true,
                isActive: true,
                createdAt: Date().addingTimeInterval(-1460 * 24 * 60 * 60),
                updatedAt: Date().addingTimeInterval(-45 * 24 * 60 * 60)
            ),
            Charity(
                id: "charity-6",
                name: "Local Food Bank",
                description: "Community food bank providing meals and groceries to families in need.",
                category: .poverty,
                website: "https://www.localfoodbank.org",
                logoUrl: "https://example.com/foodbank-logo.png",
                isVerified: false,
                isActive: true,
                createdAt: Date().addingTimeInterval(-180 * 24 * 60 * 60),
                updatedAt: Date().addingTimeInterval(-15 * 24 * 60 * 60)
            ),
            Charity(
                id: "charity-7",
                name: "Animal Rescue League",
                description: "Non-profit organization dedicated to rescuing, rehabilitating, and rehoming abandoned and abused animals.",
                category: .animals,
                website: "https://www.animalrescue.org",
                logoUrl: "https://example.com/arl-logo.png",
                isVerified: true,
                isActive: false,
                createdAt: Date().addingTimeInterval(-365 * 24 * 60 * 60),
                updatedAt: Date().addingTimeInterval(-90 * 24 * 60 * 60)
            ),
            Charity(
                id: "charity-8",
                name: "Clean Water Initiative",
                description: "Organization working to provide clean drinking water to communities in developing countries.",
                category: .environment,
                website: "https://www.cleanwater.org",
                logoUrl: "https://example.com/cwi-logo.png",
                isVerified: true,
                isActive: true,
                createdAt: Date().addingTimeInterval(-730 * 24 * 60 * 60),
                updatedAt: Date().addingTimeInterval(-30 * 24 * 60 * 60)
            )
        ]
        
        for charity in mockCharities {
            charities[charity.id] = charity
        }
        
        logger.info("Mock: Setup \(mockCharities.count) mock charities")
    }
}
