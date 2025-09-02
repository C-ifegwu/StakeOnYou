import Foundation

// MARK: - Feature Flag Entity
struct FeatureFlag: Identifiable, Codable, Equatable {
    let id: String
    let key: String
    let enabled: Bool
    let variant: String?
    let description: String
    let category: FeatureCategory
    let createdAt: Date
    let updatedAt: Date
    
    // Optional fields
    let name: String?
    let owner: String?
    let tags: [String]
    let rolloutPercentage: Double?
    let targetUsers: [String]?
    let targetGroups: [String]?
    let targetCorporateAccounts: [String]?
    let conditions: [FeatureCondition]
    let metadata: [String: String]
    
    init(
        id: String = UUID().uuidString,
        key: String,
        enabled: Bool,
        variant: String? = nil,
        description: String = "",
        category: FeatureCategory = .general,
        name: String? = nil,
        owner: String? = nil,
        tags: [String] = [],
        rolloutPercentage: Double? = nil,
        targetUsers: [String]? = nil,
        targetGroups: [String]? = nil,
        targetCorporateAccounts: [String]? = nil,
        conditions: [FeatureCondition] = [],
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.key = key
        self.enabled = enabled
        self.variant = variant
        self.description = description
        self.category = category
        self.createdAt = Date()
        self.updatedAt = Date()
        self.name = name
        self.owner = owner
        self.tags = tags
        self.rolloutPercentage = rolloutPercentage
        self.targetUsers = targetUsers
        self.targetGroups = targetGroups
        self.targetCorporateAccounts = targetCorporateAccounts
        self.conditions = conditions
        self.metadata = metadata
    }
}

// MARK: - Feature Category
enum FeatureCategory: String, Codable, CaseIterable {
    case general = "general"
    case staking = "staking"
    case goals = "goals"
    case groups = "groups"
    case corporate = "corporate"
    case analytics = "analytics"
    case privacy = "privacy"
    case experimental = "experimental"
    case ui = "ui"
    case performance = "performance"
    case security = "security"
    case integration = "integration"
    
    var displayName: String {
        switch self {
        case .general: return "General"
        case .staking: return "Staking"
        case .goals: return "Goals"
        case .groups: return "Groups"
        case .corporate: return "Corporate"
        case .analytics: return "Analytics"
        case .privacy: return "Privacy"
        case .experimental: return "Experimental"
        case .ui: return "User Interface"
        case .performance: return "Performance"
        case .security: return "Security"
        case .integration: return "Integration"
        }
    }
    
    var iconName: String {
        switch self {
        case .general: return "star.fill"
        case .staking: return "dollarsign.circle.fill"
        case .goals: return "target"
        case .groups: return "person.3.fill"
        case .corporate: return "building.2.fill"
        case .analytics: return "chart.bar.fill"
        case .privacy: return "lock.shield.fill"
        case .experimental: return "flask.fill"
        case .ui: return "paintbrush.fill"
        case .performance: return "speedometer"
        case .security: return "shield.fill"
        case .integration: return "link.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .general: return "primary"
        case .staking: return "success"
        case .goals: return "info"
        case .groups: return "warning"
        case .corporate: return "secondary"
        case .analytics: return "purple"
        case .privacy: return "red"
        case .experimental: return "orange"
        case .ui: return "blue"
        case .performance: return "green"
        case .security: return "red"
        case .integration: return "indigo"
        }
    }
}

// MARK: - Feature Condition
struct FeatureCondition: Identifiable, Codable, Equatable {
    let id: String
    let type: ConditionType
    let field: String
    let operator: ConditionOperator
    let value: String
    let isActive: Bool
    
    init(
        id: String = UUID().uuidString,
        type: ConditionType,
        field: String,
        operator: ConditionOperator,
        value: String,
        isActive: Bool = true
    ) {
        self.id = id
        self.type = type
        self.field = field
        self.operator = operator
        self.value = value
        self.isActive = isActive
    }
}

enum ConditionType: String, Codable, CaseIterable {
    case user = "user"
    case device = "device"
    case location = "location"
    case time = "time"
    case version = "version"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .user: return "User"
        case .device: return "Device"
        case .location: return "Location"
        case .time: return "Time"
        case .version: return "Version"
        case .custom: return "Custom"
        }
    }
}

enum ConditionOperator: String, Codable, CaseIterable {
    case equals = "equals"
    case notEquals = "not_equals"
    case contains = "contains"
    case notContains = "not_contains"
    case greaterThan = "greater_than"
    case lessThan = "less_than"
    case greaterThanOrEqual = "greater_than_or_equal"
    case lessThanOrEqual = "less_than_or_equal"
    case startsWith = "starts_with"
    case endsWith = "ends_with"
    case regex = "regex"
    
    var displayName: String {
        switch self {
        case .equals: return "Equals"
        case .notEquals: return "Not Equals"
        case .contains: return "Contains"
        case .notContains: return "Not Contains"
        case .greaterThan: return "Greater Than"
        case .lessThan: return "Less Than"
        case .greaterThanOrEqual: return "Greater Than or Equal"
        case .lessThanOrEqual: return "Less Than or Equal"
        case .startsWith: return "Starts With"
        case .endsWith: return "Ends With"
        case .regex: return "Regex Match"
        }
    }
    
    var symbol: String {
        switch self {
        case .equals: return "="
        case .notEquals: return "≠"
        case .contains: return "⊃"
        case .notContains: return "⊅"
        case .greaterThan: return ">"
        case .lessThan: return "<"
        case .greaterThanOrEqual: return "≥"
        case .lessThanOrEqual: return "≤"
        case .startsWith: return "→"
        case .endsWith: return "←"
        case .regex: return "~"
        }
    }
}

// MARK: - Feature Flag Extensions
extension FeatureFlag {
    var displayName: String {
        return name ?? key
    }
    
    var isRolloutEnabled: Bool {
        return rolloutPercentage != nil && rolloutPercentage! > 0
    }
    
    var isTargeted: Bool {
        return targetUsers != nil || targetGroups != nil || targetCorporateAccounts != nil
    }
    
    var hasConditions: Bool {
        return !conditions.isEmpty
    }
    
    var isExperimental: Bool {
        return category == .experimental
    }
    
    var isPrivacyRelated: Bool {
        return category == .privacy
    }
    
    var isSecurityRelated: Bool {
        return category == .security
    }
    
    var isPerformanceRelated: Bool {
        return category == .performance
    }
    
    var isUIRelated: Bool {
        return category == .ui
    }
    
    var isStakingRelated: Bool {
        return category == .staking
    }
    
    var isGoalsRelated: Bool {
        return category == .goals
    }
    
    var isGroupsRelated: Bool {
        return category == .groups
    }
    
    var isCorporateRelated: Bool {
        return category == .corporate
    }
    
    var isAnalyticsRelated: Bool {
        return category == .analytics
    }
    
    var isIntegrationRelated: Bool {
        return category == .integration
    }
    
    var hasMetadata: Bool {
        return !metadata.isEmpty
    }
    
    var hasTags: Bool {
        return !tags.isEmpty
    }
    
    var hasOwner: Bool {
        return owner != nil
    }
    
    var isRecentlyCreated: Bool {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return createdAt >= thirtyDaysAgo
    }
    
    var isRecentlyUpdated: Bool {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return updatedAt >= sevenDaysAgo
    }
}

// MARK: - Feature Flag Validation
extension FeatureFlag {
    var validationErrors: [String] {
        var errors: [String] = []
        
        if key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Feature flag key is required")
        }
        
        if key.contains(" ") {
            errors.append("Feature flag key cannot contain spaces")
        }
        
        if key.contains(".") {
            errors.append("Feature flag key cannot contain dots")
        }
        
        if let rolloutPercentage = rolloutPercentage {
            if rolloutPercentage < 0 || rolloutPercentage > 100 {
                errors.append("Rollout percentage must be between 0 and 100")
            }
        }
        
        if let targetUsers = targetUsers, targetUsers.isEmpty {
            errors.append("Target users list cannot be empty")
        }
        
        if let targetGroups = targetGroups, targetGroups.isEmpty {
            errors.append("Target groups list cannot be empty")
        }
        
        if let targetCorporateAccounts = targetCorporateAccounts, targetCorporateAccounts.isEmpty {
            errors.append("Target corporate accounts list cannot be empty")
        }
        
        return errors
    }
    
    var isValid: Bool {
        return validationErrors.isEmpty
    }
}

// MARK: - Feature Flag Evaluation
extension FeatureFlag {
    func isEnabledForUser(_ userId: String, in groupId: String? = nil, in corporateAccountId: String? = nil) -> Bool {
        // Check if feature is globally disabled
        guard enabled else { return false }
        
        // Check if user is specifically targeted
        if let targetUsers = targetUsers, targetUsers.contains(userId) {
            return true
        }
        
        // Check if user's group is targeted
        if let groupId = groupId, let targetGroups = targetGroups, targetGroups.contains(groupId) {
            return true
        }
        
        // Check if user's corporate account is targeted
        if let corporateAccountId = corporateAccountId, let targetCorporateAccounts = targetCorporateAccounts, targetCorporateAccounts.contains(corporateAccountId) {
            return true
        }
        
        // Check rollout percentage if no specific targeting
        if !isTargeted, let rolloutPercentage = rolloutPercentage {
            let hash = userId.hashValue
            let normalizedHash = abs(hash) % 100
            return Double(normalizedHash) < rolloutPercentage
        }
        
        // Check conditions
        if hasConditions {
            return evaluateConditions(for: userId, in: groupId, in: corporateAccountId)
        }
        
        // Default to enabled if no specific targeting or conditions
        return true
    }
    
    private func evaluateConditions(for userId: String, in groupId: String?, in corporateAccountId: String?) -> Bool {
        // TODO: Implement condition evaluation logic
        // This would evaluate user properties, device info, location, time, etc.
        return true
    }
}

// MARK: - Feature Flag Filtering
extension FeatureFlag {
    func matchesCategory(_ category: FeatureCategory?) -> Bool {
        guard let category = category else { return true }
        return self.category == category
    }
    
    func matchesEnabled(_ enabled: Bool?) -> Bool {
        guard let enabled = enabled else { return true }
        return self.enabled == enabled
    }
    
    func matchesSearch(_ query: String) -> Bool {
        let searchQuery = query.lowercased()
        return key.lowercased().contains(searchQuery) ||
               (name?.lowercased().contains(searchQuery) ?? false) ||
               description.lowercased().contains(searchQuery) ||
               category.displayName.lowercased().contains(searchQuery) ||
               tags.contains { $0.lowercased().contains(searchQuery) }
    }
    
    func matchesOwner(_ owner: String?) -> Bool {
        guard let owner = owner else { return true }
        return self.owner == owner
    }
    
    func matchesTag(_ tag: String?) -> Bool {
        guard let tag = tag else { return true }
        return tags.contains(tag)
    }
}

// MARK: - Feature Flag Analytics
extension FeatureFlag {
    var usageMetrics: [String: Any] {
        var metrics: [String: Any] = [:]
        
        metrics["enabled"] = enabled
        metrics["has_variant"] = variant != nil
        metrics["is_targeted"] = isTargeted
        metrics["has_conditions"] = hasConditions
        metrics["is_rollout_enabled"] = isRolloutEnabled
        metrics["category"] = category.rawValue
        metrics["created_date"] = createdAt
        metrics["updated_date"] = updatedAt
        
        if let rolloutPercentage = rolloutPercentage {
            metrics["rollout_percentage"] = rolloutPercentage
        }
        
        if let targetUsers = targetUsers {
            metrics["target_users_count"] = targetUsers.count
        }
        
        if let targetGroups = targetGroups {
            metrics["target_groups_count"] = targetGroups.count
        }
        
        if let targetCorporateAccounts = targetCorporateAccounts {
            metrics["target_corporate_accounts_count"] = targetCorporateAccounts.count
        }
        
        if !tags.isEmpty {
            metrics["tags"] = tags
        }
        
        if !conditions.isEmpty {
            metrics["conditions_count"] = conditions.count
        }
        
        return metrics
    }
}
