import Foundation
import Combine

// MARK: - Mock Feature Flag Repository Implementation
class MockFeatureFlagRepository: FeatureFlagRepository {
    // MARK: - Properties
    private var featureFlags: [String: FeatureFlag] = [:]
    private let logger: Logger
    
    // MARK: - Initialization
    init(logger: Logger = ConsoleLogger()) {
        self.logger = logger
        setupMockData()
    }
    
    // MARK: - CRUD Operations
    func createFeatureFlag(_ featureFlag: FeatureFlag) async throws -> FeatureFlag {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 600_000_000)
        
        var newFeatureFlag = featureFlag
        if newFeatureFlag.id.isEmpty {
            newFeatureFlag = FeatureFlag(
                id: UUID().uuidString,
                name: featureFlag.name,
                key: featureFlag.key,
                description: featureFlag.description,
                isEnabled: featureFlag.isEnabled,
                rolloutPercentage: featureFlag.rolloutPercentage,
                targetAudience: featureFlag.targetAudience,
                conditions: featureFlag.conditions,
                createdAt: Date(),
                updatedAt: Date()
            )
        }
        
        featureFlags[newFeatureFlag.id] = newFeatureFlag
        logger.info("Mock: Created feature flag with ID: \(newFeatureFlag.id)")
        return newFeatureFlag
    }
    
    func getFeatureFlag(id: String) async throws -> FeatureFlag? {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 200_000_000)
        
        let featureFlag = featureFlags[id]
        logger.info("Mock: Retrieved feature flag with ID: \(id), found: \(featureFlag != nil)")
        return featureFlag
    }
    
    func updateFeatureFlag(_ featureFlag: FeatureFlag) async throws -> FeatureFlag {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        guard featureFlags[featureFlag.id] != nil else {
            throw FeatureFlagRepositoryError.featureFlagNotFound
        }
        
        var updatedFeatureFlag = featureFlag
        updatedFeatureFlag.updatedAt = Date()
        featureFlags[featureFlag.id] = updatedFeatureFlag
        
        logger.info("Mock: Updated feature flag with ID: \(featureFlag.id)")
        return updatedFeatureFlag
    }
    
    func deleteFeatureFlag(id: String) async throws -> Bool {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        guard featureFlags[id] != nil else {
            throw FeatureFlagRepositoryError.featureFlagNotFound
        }
        
        featureFlags.removeValue(forKey: id)
        logger.info("Mock: Deleted feature flag with ID: \(id)")
        return true
    }
    
    // MARK: - Query Operations
    func getFeatureFlag(byKey: String) async throws -> FeatureFlag? {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let featureFlag = featureFlags.values.first { $0.key == byKey }
        logger.info("Mock: Retrieved feature flag with key: \(byKey), found: \(featureFlag != nil)")
        return featureFlag
    }
    
    func getFeatureFlags(byName: String) async throws -> [FeatureFlag] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let nameFeatureFlags = featureFlags.values.filter { $0.name.localizedCaseInsensitiveContains(byName) }
        logger.info("Mock: Retrieved \(nameFeatureFlags.count) feature flags with name containing: \(byName)")
        return nameFeatureFlags
    }
    
    func getEnabledFeatureFlags() async throws -> [FeatureFlag] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let enabledFeatureFlags = featureFlags.values.filter { $0.isEnabled }
        logger.info("Mock: Retrieved \(enabledFeatureFlags.count) enabled feature flags")
        return enabledFeatureFlags
    }
    
    func getFeatureFlags(byAudience: String) async throws -> [FeatureFlag] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let audienceFeatureFlags = featureFlags.values.filter { $0.targetAudience == byAudience }
        logger.info("Mock: Retrieved \(audienceFeatureFlags.count) feature flags for audience: \(byAudience)")
        return audienceFeatureFlags
    }
    
    func getFeatureFlags(byRolloutPercentage: Double, comparison: ComparisonType) async throws -> [FeatureFlag] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let filteredFeatureFlags = featureFlags.values.filter { featureFlag in
            switch comparison {
            case .greaterThan:
                return featureFlag.rolloutPercentage > byRolloutPercentage
            case .greaterThanOrEqual:
                return featureFlag.rolloutPercentage >= byRolloutPercentage
            case .lessThan:
                return featureFlag.rolloutPercentage < byRolloutPercentage
            case .lessThanOrEqual:
                return featureFlag.rolloutPercentage <= byRolloutPercentage
            case .equal:
                return featureFlag.rolloutPercentage == byRolloutPercentage
            }
        }
        
        logger.info("Mock: Retrieved \(filteredFeatureFlags.count) feature flags with rollout percentage \(comparison.rawValue) \(byRolloutPercentage)")
        return filteredFeatureFlags
    }
    
    // MARK: - Feature Flag Evaluation
    func isFeatureEnabled(key: String, forUserId: String, context: [String: Any]) async throws -> Bool {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        guard let featureFlag = featureFlags.values.first(where: { $0.key == key }) else {
            logger.info("Mock: Feature flag not found for key: \(key)")
            return false
        }
        
        guard featureFlag.isEnabled else {
            logger.info("Mock: Feature flag is disabled for key: \(key)")
            return false
        }
        
        // Mock rollout percentage evaluation
        let shouldEnable = evaluateRolloutPercentage(featureFlag.rolloutPercentage, forUserId: forUserId)
        
        // Mock audience targeting
        let audienceMatch = evaluateAudienceTargeting(featureFlag.targetAudience, forUserId: forUserId)
        
        // Mock conditions evaluation
        let conditionsMatch = evaluateConditions(featureFlag.conditions, context: context)
        
        let isEnabled = shouldEnable && audienceMatch && conditionsMatch
        
        logger.info("Mock: Feature flag '\(key)' evaluation result: \(isEnabled)")
        return isEnabled
    }
    
    func getFeatureFlagValue(key: String, forUserId: String, context: [String: Any]) async throws -> FeatureFlagValue {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        guard let featureFlag = featureFlags.values.first(where: { $0.key == key }) else {
            throw FeatureFlagRepositoryError.featureFlagNotFound
        }
        
        let isEnabled = try await isFeatureEnabled(key: key, forUserId: forUserId, context: context)
        
        let value = FeatureFlagValue(
            key: key,
            isEnabled: isEnabled,
            rolloutPercentage: featureFlag.rolloutPercentage,
            targetAudience: featureFlag.targetAudience,
            conditions: featureFlag.conditions,
            evaluatedAt: Date()
        )
        
        logger.info("Mock: Retrieved feature flag value for key: \(key)")
        return value
    }
    
    func evaluateFeatureFlags(forUserId: String, context: [String: Any]) async throws -> [FeatureFlagValue] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 600_000_000)
        
        var evaluatedFlags: [FeatureFlagValue] = []
        
        for featureFlag in featureFlags.values {
            let isEnabled = try await isFeatureEnabled(key: featureFlag.key, forUserId: forUserId, context: context)
            
            let value = FeatureFlagValue(
                key: featureFlag.key,
                isEnabled: isEnabled,
                rolloutPercentage: featureFlag.rolloutPercentage,
                targetAudience: featureFlag.targetAudience,
                conditions: featureFlag.conditions,
                evaluatedAt: Date()
            )
            
            evaluatedFlags.append(value)
        }
        
        logger.info("Mock: Evaluated \(evaluatedFlags.count) feature flags for user: \(forUserId)")
        return evaluatedFlags
    }
    
    // MARK: - Feature Flag Management
    func enableFeatureFlag(id: String) async throws -> FeatureFlag {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        guard var featureFlag = featureFlags[id] else {
            throw FeatureFlagRepositoryError.featureFlagNotFound
        }
        
        featureFlag.isEnabled = true
        featureFlag.updatedAt = Date()
        featureFlags[id] = featureFlag
        
        logger.info("Mock: Enabled feature flag with ID: \(id)")
        return featureFlag
    }
    
    func disableFeatureFlag(id: String) async throws -> FeatureFlag {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        guard var featureFlag = featureFlags[id] else {
            throw FeatureFlagRepositoryError.featureFlagNotFound
        }
        
        featureFlag.isEnabled = false
        featureFlag.updatedAt = Date()
        featureFlags[id] = featureFlag
        
        logger.info("Mock: Disabled feature flag with ID: \(id)")
        return featureFlag
    }
    
    func updateRolloutPercentage(id: String, percentage: Double) async throws -> FeatureFlag {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        guard var featureFlag = featureFlags[id] else {
            throw FeatureFlagRepositoryError.featureFlagNotFound
        }
        
        featureFlag.rolloutPercentage = max(0.0, min(100.0, percentage))
        featureFlag.updatedAt = Date()
        featureFlags[id] = featureFlag
        
        logger.info("Mock: Updated rollout percentage for feature flag \(id) to \(percentage)%")
        return featureFlag
    }
    
    func updateTargetAudience(id: String, audience: String) async throws -> FeatureFlag {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        guard var featureFlag = featureFlags[id] else {
            throw FeatureFlagRepositoryError.featureFlagNotFound
        }
        
        featureFlag.targetAudience = audience
        featureFlag.updatedAt = Date()
        featureFlags[id] = featureFlag
        
        logger.info("Mock: Updated target audience for feature flag \(id) to \(audience)")
        return featureFlag
    }
    
    func updateConditions(id: String, conditions: [FeatureFlagCondition]) async throws -> FeatureFlag {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        guard var featureFlag = featureFlags[id] else {
            throw FeatureFlagRepositoryError.featureFlagNotFound
        }
        
        featureFlag.conditions = conditions
        featureFlag.updatedAt = Date()
        featureFlags[id] = featureFlag
        
        logger.info("Mock: Updated conditions for feature flag \(id)")
        return featureFlag
    }
    
    // MARK: - Bulk Operations
    func bulkUpdateFeatureFlags(_ featureFlags: [FeatureFlag]) async throws -> [FeatureFlag] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        var updatedFeatureFlags: [FeatureFlag] = []
        
        for featureFlag in featureFlags {
            let updatedFeatureFlag = try await updateFeatureFlag(featureFlag)
            updatedFeatureFlags.append(updatedFeatureFlag)
        }
        
        logger.info("Mock: Bulk updated \(updatedFeatureFlags.count) feature flags")
        return updatedFeatureFlags
    }
    
    func bulkEnableFeatureFlags(ids: [String]) async throws -> [FeatureFlag] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 800_000_000)
        
        var enabledFeatureFlags: [FeatureFlag] = []
        
        for id in ids {
            let enabledFeatureFlag = try await enableFeatureFlag(id: id)
            enabledFeatureFlags.append(enabledFeatureFlag)
        }
        
        logger.info("Mock: Bulk enabled \(enabledFeatureFlags.count) feature flags")
        return enabledFeatureFlags
    }
    
    func bulkDisableFeatureFlags(ids: [String]) async throws -> [FeatureFlag] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 800_000_000)
        
        var disabledFeatureFlags: [FeatureFlag] = []
        
        for id in ids {
            let disabledFeatureFlag = try await disableFeatureFlag(id: id)
            disabledFeatureFlags.append(disabledFeatureFlag)
        }
        
        logger.info("Mock: Bulk disabled \(disabledFeatureFlags.count) feature flags")
        return disabledFeatureFlags
    }
    
    // MARK: - Analytics and Reporting
    func getFeatureFlagUsage(forFeatureFlagId: String) async throws -> FeatureFlagUsage {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        guard featureFlags[forFeatureFlagId] != nil else {
            throw FeatureFlagRepositoryError.featureFlagNotFound
        }
        
        let usage = FeatureFlagUsage(
            featureFlagId: forFeatureFlagId,
            totalRequests: 1250,
            enabledRequests: 875,
            disabledRequests: 375,
            enableRate: 0.70, // 70%
            requestsByAudience: [
                "all_users": 800,
                "premium_users": 300,
                "beta_testers": 150
            ],
            requestsByDevice: [
                "iOS": 750,
                "Android": 400,
                "Web": 100
            ],
            lastUpdated: Date()
        )
        
        logger.info("Mock: Generated feature flag usage for ID: \(forFeatureFlagId)")
        return usage
    }
    
    func generateFeatureFlagReport(dateRange: DateInterval) async throws -> FeatureFlagReport {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 600_000_000)
        
        let report = FeatureFlagReport(
            dateRange: dateRange,
            totalFeatureFlags: featureFlags.count,
            enabledFeatureFlags: featureFlags.values.filter { $0.isEnabled }.count,
            disabledFeatureFlags: featureFlags.values.filter { !$0.isEnabled }.count,
            featureFlagsByAudience: Dictionary(grouping: featureFlags.values) { $0.targetAudience }.mapValues { $0.count },
            averageRolloutPercentage: featureFlags.values.map { $0.rolloutPercentage }.reduce(0, +) / Double(featureFlags.count),
            mostUsedFeatureFlags: Array(featureFlags.values.prefix(5).map { $0.key }),
            recommendations: [
                "Consider enabling 'AI_NUDGES' for premium users",
                "Review rollout percentage for 'CORPORATE_FEATURES'",
                "Monitor usage of 'EXPERIMENTAL_UI' feature"
            ],
            generatedAt: Date()
        )
        
        logger.info("Mock: Generated feature flag report")
        return report
    }
    
    // MARK: - Search and Filtering
    func searchFeatureFlags(query: String, filters: FeatureFlagSearchFilters?) async throws -> [FeatureFlag] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        var searchResults = featureFlags.values
        
        // Apply text search
        if !query.isEmpty {
            searchResults = searchResults.filter { featureFlag in
                featureFlag.name.localizedCaseInsensitiveContains(query) ||
                featureFlag.key.localizedCaseInsensitiveContains(query) ||
                featureFlag.description.localizedCaseInsensitiveContains(query)
            }
        }
        
        // Apply filters
        if let filters = filters {
            if let isEnabled = filters.isEnabled {
                searchResults = searchResults.filter { $0.isEnabled == isEnabled }
            }
            
            if let audience = filters.audience {
                searchResults = searchResults.filter { $0.targetAudience == audience }
            }
            
            if let minRollout = filters.minRolloutPercentage {
                searchResults = searchResults.filter { $0.rolloutPercentage >= minRollout }
            }
            
            if let maxRollout = filters.maxRolloutPercentage {
                searchResults = searchResults.filter { $0.rolloutPercentage <= maxRollout }
            }
        }
        
        logger.info("Mock: Search returned \(searchResults.count) feature flags for query: \(query)")
        return searchResults
    }
    
    // MARK: - Private Helper Methods
    private func evaluateRolloutPercentage(_ percentage: Double, forUserId: String) -> Bool {
        // Mock rollout percentage evaluation using user ID hash
        let hash = abs(forUserId.hashValue)
        let userPercentage = Double(hash % 100)
        return userPercentage < percentage
    }
    
    private func evaluateAudienceTargeting(_ audience: String, forUserId: String) -> Bool {
        // Mock audience targeting logic
        switch audience {
        case "all_users":
            return true
        case "premium_users":
            // Mock premium user check
            return forUserId.contains("premium") || forUserId.contains("vip")
        case "beta_testers":
            // Mock beta tester check
            return forUserId.contains("beta") || forUserId.contains("tester")
        default:
            return true
        }
    }
    
    private func evaluateConditions(_ conditions: [FeatureFlagCondition], context: [String: Any]) -> Bool {
        // Mock conditions evaluation
        guard !conditions.isEmpty else { return true }
        
        for condition in conditions {
            switch condition.type {
            case .userProperty:
                // Mock user property evaluation
                if let propertyValue = context[condition.property] as? String {
                    if condition.operator == .equals {
                        if propertyValue != condition.value { return false }
                    } else if condition.operator == .contains {
                        if !propertyValue.contains(condition.value) { return false }
                    }
                }
            case .deviceType:
                // Mock device type evaluation
                if let deviceType = context["deviceType"] as? String {
                    if condition.operator == .equals {
                        if deviceType != condition.value { return false }
                    }
                }
            case .appVersion:
                // Mock app version evaluation
                if let appVersion = context["appVersion"] as? String {
                    if condition.operator == .greaterThan {
                        if appVersion <= condition.value { return false }
                    } else if condition.operator == .lessThan {
                        if appVersion >= condition.value { return false }
                    }
                }
            case .timeBased:
                // Mock time-based evaluation
                let now = Date()
                if condition.operator == .before {
                    if now >= Date(timeIntervalSince1970: TimeInterval(condition.value) ?? 0) { return false }
                } else if condition.operator == .after {
                    if now <= Date(timeIntervalSince1970: TimeInterval(condition.value) ?? 0) { return false }
                }
            }
        }
        
        return true
    }
    
    private func setupMockData() {
        // Create some mock feature flags for testing
        let mockFeatureFlags = [
            FeatureFlag(
                id: "flag-1",
                name: "AI Nudges",
                key: "AI_NUDGES",
                description: "Enable AI-powered goal suggestions and nudges",
                isEnabled: true,
                rolloutPercentage: 75.0,
                targetAudience: "premium_users",
                conditions: [
                    FeatureFlagCondition(
                        type: .userProperty,
                        property: "subscription",
                        operator: .equals,
                        value: "premium"
                    )
                ],
                createdAt: Date().addingTimeInterval(-30 * 24 * 60 * 60),
                updatedAt: Date().addingTimeInterval(-7 * 24 * 60 * 60)
            ),
            FeatureFlag(
                id: "flag-2",
                name: "Corporate Features",
                key: "CORPORATE_FEATURES",
                description: "Enable corporate account management and team features",
                isEnabled: true,
                rolloutPercentage: 100.0,
                targetAudience: "all_users",
                conditions: [],
                createdAt: Date().addingTimeInterval(-60 * 24 * 60 * 60),
                updatedAt: Date().addingTimeInterval(-14 * 24 * 60 * 60)
            ),
            FeatureFlag(
                id: "flag-3",
                name: "Experimental UI",
                key: "EXPERIMENTAL_UI",
                description: "Enable new experimental UI components and layouts",
                isEnabled: false,
                rolloutPercentage: 25.0,
                targetAudience: "beta_testers",
                conditions: [
                    FeatureFlagCondition(
                        type: .userProperty,
                        property: "userType",
                        operator: .equals,
                        value: "beta_tester"
                    )
                ],
                createdAt: Date().addingTimeInterval(-45 * 24 * 60 * 60),
                updatedAt: Date().addingTimeInterval(-21 * 24 * 60 * 60)
            ),
            FeatureFlag(
                id: "flag-4",
                name: "Advanced Analytics",
                key: "ADVANCED_ANALYTICS",
                description: "Enable advanced goal tracking and analytics features",
                isEnabled: true,
                rolloutPercentage: 50.0,
                targetAudience: "premium_users",
                conditions: [
                    FeatureFlagCondition(
                        type: .userProperty,
                        property: "subscription",
                        operator: .equals,
                        value: "premium"
                    ),
                    FeatureFlagCondition(
                        type: .deviceType,
                        property: "deviceType",
                        operator: .equals,
                        value: "iOS"
                    )
                ],
                createdAt: Date().addingTimeInterval(-90 * 24 * 60 * 60),
                updatedAt: Date().addingTimeInterval(-30 * 24 * 60 * 60)
            ),
            FeatureFlag(
                id: "flag-5",
                name: "Social Features",
                key: "SOCIAL_FEATURES",
                description: "Enable social sharing and community features",
                isEnabled: true,
                rolloutPercentage: 100.0,
                targetAudience: "all_users",
                conditions: [],
                createdAt: Date().addingTimeInterval(-120 * 24 * 60 * 60),
                updatedAt: Date().addingTimeInterval(-60 * 24 * 60 * 60)
            ),
            FeatureFlag(
                id: "flag-6",
                name: "Dark Mode",
                key: "DARK_MODE",
                description: "Enable dark mode theme option",
                isEnabled: true,
                rolloutPercentage: 100.0,
                targetAudience: "all_users",
                conditions: [
                    FeatureFlagCondition(
                        type: .appVersion,
                        property: "appVersion",
                        operator: .greaterThan,
                        value: "2.0.0"
                    )
                ],
                createdAt: Date().addingTimeInterval(-180 * 24 * 60 * 60),
                updatedAt: Date().addingTimeInterval(-90 * 24 * 60 * 60)
            ),
            FeatureFlag(
                id: "flag-7",
                name: "Push Notifications",
                key: "PUSH_NOTIFICATIONS",
                description: "Enable enhanced push notification system",
                isEnabled: true,
                rolloutPercentage: 80.0,
                targetAudience: "all_users",
                conditions: [
                    FeatureFlagCondition(
                        type: .userProperty,
                        property: "notificationEnabled",
                        operator: .equals,
                        value: "true"
                    )
                ],
                createdAt: Date().addingTimeInterval(-150 * 24 * 60 * 60),
                updatedAt: Date().addingTimeInterval(-45 * 24 * 60 * 60)
            ),
            FeatureFlag(
                id: "flag-8",
                name: "Offline Mode",
                key: "OFFLINE_MODE",
                description: "Enable offline functionality and data sync",
                isEnabled: false,
                rolloutPercentage: 10.0,
                targetAudience: "beta_testers",
                conditions: [
                    FeatureFlagCondition(
                        type: .userProperty,
                        property: "userType",
                        operator: .equals,
                        value: "beta_tester"
                    ),
                    FeatureFlagCondition(
                        type: .deviceType,
                        property: "deviceType",
                        operator: .equals,
                        value: "iOS"
                    )
                ],
                createdAt: Date().addingTimeInterval(-75 * 24 * 60 * 60),
                updatedAt: Date().addingTimeInterval(-15 * 24 * 60 * 60)
            )
        ]
        
        for featureFlag in mockFeatureFlags {
            featureFlags[featureFlag.id] = featureFlag
        }
        
        logger.info("Mock: Setup \(mockFeatureFlags.count) mock feature flags")
    }
}
