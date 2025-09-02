import Foundation
import Combine

// MARK: - Feature Flag System
struct FeatureFlag: Codable, Identifiable {
    let id: String
    let key: String
    let enabled: Bool
    let variant: String?
    let description: String
    let category: FeatureCategory
    let createdAt: Date
    let updatedAt: Date
    
    init(key: String, enabled: Bool, variant: String? = nil, description: String = "", category: FeatureCategory = .general) {
        self.id = UUID().uuidString
        self.key = key
        self.enabled = enabled
        self.variant = variant
        self.description = description
        self.category = category
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

enum FeatureCategory: String, Codable, CaseIterable {
    case general = "general"
    case staking = "staking"
    case goals = "goals"
    case groups = "groups"
    case corporate = "corporate"
    case analytics = "analytics"
    case privacy = "privacy"
    case experimental = "experimental"
}

// MARK: - Feature Flags Service
class FeatureFlagsService: ObservableObject {
    static let shared = FeatureFlagsService()
    
    @Published private(set) var flags: [FeatureFlag] = []
    @Published private(set) var isLoading = false
    
    private let userDefaults = UserDefaults.standard
    private let flagsKey = "FeatureFlags"
    private let lastUpdateKey = "FeatureFlagsLastUpdate"
    
    private init() {
        loadLocalFlags()
    }
    
    // MARK: - Public Methods
    func loadFlags() async {
        await MainActor.run {
            isLoading = true
        }
        
        // Load local flags first
        await loadLocalFlags()
        
        // TODO: Fetch remote flags from server
        // await fetchRemoteFlags()
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    func isEnabled(_ key: String) -> Bool {
        return flags.first { $0.key == key }?.enabled ?? false
    }
    
    func getVariant(_ key: String) -> String? {
        return flags.first { $0.key == key }?.variant
    }
    
    func getFlag(_ key: String) -> FeatureFlag? {
        return flags.first { $0.key == key }
    }
    
    func updateFlag(_ flag: FeatureFlag) {
        if let index = flags.firstIndex(where: { $0.key == flag.key }) {
            flags[index] = flag
        } else {
            flags.append(flag)
        }
        saveLocalFlags()
    }
    
    func resetToDefaults() {
        flags = defaultFlags
        saveLocalFlags()
    }
    
    // MARK: - Private Methods
    private func loadLocalFlags() {
        if let data = userDefaults.data(forKey: flagsKey),
           let decodedFlags = try? JSONDecoder().decode([FeatureFlag].self, from: data) {
            flags = decodedFlags
        } else {
            flags = defaultFlags
            saveLocalFlags()
        }
    }
    
    private func saveLocalFlags() {
        if let data = try? JSONEncoder().encode(flags) {
            userDefaults.set(data, forKey: flagsKey)
            userDefaults.set(Date(), forKey: lastUpdateKey)
        }
    }
    
    private func fetchRemoteFlags() async {
        // TODO: Implement remote flag fetching
        // This would typically involve:
        // 1. Making a network request to your feature flag service
        // 2. Merging remote flags with local defaults
        // 3. Handling conflicts (remote usually wins)
        // 4. Updating local storage
        
        logInfo("Remote feature flags fetching not yet implemented", category: "FeatureFlags")
    }
    
    // MARK: - Default Flags
    private var defaultFlags: [FeatureFlag] {
        [
            // Core Features
            FeatureFlag(key: "goals_enabled", enabled: true, description: "Enable goal creation and management", category: .goals),
            FeatureFlag(key: "staking_enabled", enabled: true, description: "Enable staking functionality", category: .staking),
            FeatureFlag(key: "groups_enabled", enabled: true, description: "Enable group challenges", category: .groups),
            FeatureFlag(key: "corporate_enabled", enabled: true, description: "Enable corporate accounts", category: .corporate),
            
            // Staking Features
            FeatureFlag(key: "compound_interest", enabled: false, description: "Enable compound interest for stakes", category: .staking),
            FeatureFlag(key: "early_completion_bonus", enabled: true, description: "Bonus for completing goals early", category: .staking),
            FeatureFlag(key: "charity_integration", enabled: true, description: "Enable charity forfeiture", category: .staking),
            
            // Privacy Features
            FeatureFlag(key: "screen_time_tracking", enabled: false, description: "Enable Screen Time integration", category: .privacy),
            FeatureFlag(key: "health_kit_integration", enabled: false, description: "Enable HealthKit integration", category: .privacy),
            FeatureFlag(key: "analytics_enhanced", enabled: false, description: "Enable enhanced analytics", category: .analytics),
            
            // Experimental Features
            FeatureFlag(key: "ai_goal_suggestions", enabled: false, description: "AI-powered goal suggestions", category: .experimental),
            FeatureFlag(key: "social_challenges", enabled: false, description: "Social media integration for challenges", category: .experimental),
            
            // UI Features
            FeatureFlag(key: "dark_mode_auto", enabled: true, description: "Automatic dark mode switching", category: .general),
            FeatureFlag(key: "haptic_feedback", enabled: true, description: "Enhanced haptic feedback", category: .general),
            FeatureFlag(key: "voice_commands", enabled: false, description: "Voice command support", category: .experimental)
        ]
    }
}

// MARK: - Feature Flag Extensions
extension FeatureFlagsService {
    // Convenience methods for common feature checks
    var isGoalsEnabled: Bool { isEnabled("goals_enabled") }
    var isStakingEnabled: Bool { isEnabled("staking_enabled") }
    var isGroupsEnabled: Bool { isEnabled("groups_enabled") }
    var isCorporateEnabled: Bool { isEnabled("corporate_enabled") }
    var isCompoundInterestEnabled: Bool { isEnabled("compound_interest") }
    var isScreenTimeTrackingEnabled: Bool { isEnabled("screen_time_tracking") }
    var isHealthKitEnabled: Bool { isEnabled("health_kit_integration") }
    var isAnalyticsEnhanced: Bool { isEnabled("analytics_enhanced") }
}

// MARK: - Feature Flag Environment
struct FeatureFlagEnvironmentKey: EnvironmentKey {
    static let defaultValue = FeatureFlagsService.shared
}

extension EnvironmentValues {
    var featureFlags: FeatureFlagsService {
        get { self[FeatureFlagEnvironmentKey.self] }
        set { self[FeatureFlagEnvironmentKey.self] = newValue }
    }
}
