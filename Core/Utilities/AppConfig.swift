import Foundation

// MARK: - App Configuration
struct AppConfig: Codable, Equatable {
    let version: String
    let buildNumber: String
    let environment: Environment
    let apiBaseURL: String
    let webSocketURL: String?
    let analyticsEnabled: Bool
    let crashReportingEnabled: Bool
    let loggingLevel: LogLevel
    let maxRetryAttempts: Int
    let requestTimeout: TimeInterval
    let cacheExpirationTime: TimeInterval
    
    // Feature-specific configurations
    let staking: StakingConfig
    let goals: GoalsConfig
    let groups: GroupsConfig
    let corporate: CorporateConfig
    let privacy: PrivacyConfig
    let security: SecurityConfig
    let performance: PerformanceConfig
    
    // Remote configuration
    let lastUpdated: Date
    let source: ConfigSource
    
    init(
        version: String = "1.0.0",
        buildNumber: String = "1",
        environment: Environment = .development,
        apiBaseURL: String = "https://api.stakeonyou.com",
        webSocketURL: String? = nil,
        analyticsEnabled: Bool = true,
        crashReportingEnabled: Bool = true,
        loggingLevel: LogLevel = .info,
        maxRetryAttempts: Int = 3,
        requestTimeout: TimeInterval = 30,
        cacheExpirationTime: TimeInterval = 3600,
        staking: StakingConfig = StakingConfig(),
        goals: GoalsConfig = GoalsConfig(),
        groups: GroupsConfig = GroupsConfig(),
        corporate: CorporateConfig = CorporateConfig(),
        privacy: PrivacyConfig = PrivacyConfig(),
        security: SecurityConfig = SecurityConfig(),
        performance: PerformanceConfig = PerformanceConfig(),
        lastUpdated: Date = Date(),
        source: ConfigSource = .local
    ) {
        self.version = version
        self.buildNumber = buildNumber
        self.environment = environment
        self.apiBaseURL = apiBaseURL
        self.webSocketURL = webSocketURL
        self.analyticsEnabled = analyticsEnabled
        self.crashReportingEnabled = crashReportingEnabled
        self.loggingLevel = loggingLevel
        self.maxRetryAttempts = maxRetryAttempts
        self.requestTimeout = requestTimeout
        self.cacheExpirationTime = cacheExpirationTime
        self.staking = staking
        self.goals = goals
        self.groups = groups
        self.corporate = corporate
        self.privacy = privacy
        self.security = security
        self.performance = performance
        self.lastUpdated = lastUpdated
        self.source = source
    }
}

// MARK: - Environment
enum Environment: String, Codable, CaseIterable {
    case development = "development"
    case staging = "staging"
    case production = "production"
    case testing = "testing"
    
    var displayName: String {
        switch self {
        case .development: return "Development"
        case .staging: return "Staging"
        case .production: return "Production"
        case .testing: return "Testing"
        }
    }
    
    var isProduction: Bool {
        return self == .production
    }
    
    var isDevelopment: Bool {
        return self == .development
    }
    
    var isStaging: Bool {
        return self == .staging
    }
    
    var isTesting: Bool {
        return self == .testing
    }
    
    var allowsDebugging: Bool {
        return !isProduction
    }
    
    var allowsAnalytics: Bool {
        return isProduction || isStaging
    }
    
    var allowsCrashReporting: Bool {
        return isProduction || isStaging
    }
}

// MARK: - Config Source
enum ConfigSource: String, Codable, CaseIterable {
    case local = "local"
    case remote = "remote"
    case cached = "cached"
    case fallback = "fallback"
    
    var displayName: String {
        switch self {
        case .local: return "Local"
        case .remote: return "Remote"
        case .cached: return "Cached"
        case .fallback: return "Fallback"
        }
    }
}

// MARK: - Staking Configuration
struct StakingConfig: Codable, Equatable {
    let enabled: Bool
    let minStakeAmount: Decimal
    let maxStakeAmount: Decimal
    let defaultAPR: Decimal
    let maxAPR: Decimal
    let feeRateOnStake: Decimal
    let feeRateOnWithdrawal: Decimal
    let earlyCompletionBonus: Decimal
    let charitySplitPercentage: Decimal
    let appSplitPercentage: Decimal
    let maxStakesPerUser: Int
    let maxStakesPerGoal: Int
    let allowCompoundInterest: Bool
    let allowEarlyWithdrawal: Bool
    let withdrawalPenalty: Decimal
    
    init(
        enabled: Bool = true,
        minStakeAmount: Decimal = 1.0,
        maxStakeAmount: Decimal = 10000.0,
        defaultAPR: Decimal = 0.12,
        maxAPR: Decimal = 0.25,
        feeRateOnStake: Decimal = 0.05,
        feeRateOnWithdrawal: Decimal = 0.02,
        earlyCompletionBonus: Decimal = 0.1,
        charitySplitPercentage: Decimal = 0.5,
        appSplitPercentage: Decimal = 0.5,
        maxStakesPerUser: Int = 10,
        maxStakesPerGoal: Int = 5,
        allowCompoundInterest: Bool = false,
        allowEarlyWithdrawal: Bool = false,
        withdrawalPenalty: Decimal = 0.1
    ) {
        self.enabled = enabled
        self.minStakeAmount = minStakeAmount
        self.maxStakeAmount = maxStakeAmount
        self.defaultAPR = defaultAPR
        self.maxAPR = maxAPR
        self.feeRateOnStake = feeRateOnStake
        self.feeRateOnWithdrawal = feeRateOnWithdrawal
        self.earlyCompletionBonus = earlyCompletionBonus
        self.charitySplitPercentage = charitySplitPercentage
        self.appSplitPercentage = appSplitPercentage
        self.maxStakesPerUser = maxStakesPerUser
        self.maxStakesPerGoal = maxStakesPerGoal
        self.allowCompoundInterest = allowCompoundInterest
        self.allowEarlyWithdrawal = allowEarlyWithdrawal
        self.withdrawalPenalty = withdrawalPenalty
    }
}

// MARK: - Goals Configuration
struct GoalsConfig: Codable, Equatable {
    let enabled: Bool
    let maxGoalsPerUser: Int
    let maxGoalsPerGroup: Int
    let maxGoalsPerCorporateAccount: Int
    let minGoalDuration: TimeInterval
    let maxGoalDuration: TimeInterval
    let allowGoalModification: Bool
    let requireVerification: Bool
    let allowCollaboration: Bool
    let maxCollaborators: Int
    let allowAttachments: Bool
    let maxAttachmentSize: Int64
    let allowedAttachmentTypes: [String]
    
    init(
        enabled: Bool = true,
        maxGoalsPerUser: Int = 50,
        maxGoalsPerGroup: Int = 100,
        maxGoalsPerCorporateAccount: Int = 500,
        minGoalDuration: TimeInterval = 24 * 60 * 60, // 1 day
        maxGoalDuration: TimeInterval = 365 * 24 * 60 * 60, // 1 year
        allowGoalModification: Bool = true,
        requireVerification: Bool = true,
        allowCollaboration: Bool = true,
        maxCollaborators: Int = 10,
        allowAttachments: Bool = true,
        maxAttachmentSize: Int64 = 10 * 1024 * 1024, // 10MB
        allowedAttachmentTypes: [String] = ["image", "video", "document"]
    ) {
        self.enabled = enabled
        self.maxGoalsPerUser = maxGoalsPerUser
        self.maxGoalsPerGroup = maxGoalsPerGroup
        self.maxGoalsPerCorporateAccount = maxGoalsPerCorporateAccount
        self.minGoalDuration = minGoalDuration
        self.maxGoalDuration = maxGoalDuration
        self.allowGoalModification = allowGoalModification
        self.requireVerification = requireVerification
        self.allowCollaboration = allowCollaboration
        self.maxCollaborators = maxCollaborators
        self.allowAttachments = allowAttachments
        self.maxAttachmentSize = maxAttachmentSize
        self.allowedAttachmentTypes = allowedAttachmentTypes
    }
}

// MARK: - Groups Configuration
struct GroupsConfig: Codable, Equatable {
    let enabled: Bool
    let maxGroupsPerUser: Int
    let maxMembersPerGroup: Int
    let allowPublicGroups: Bool
    let allowPrivateGroups: Bool
    let requireApprovalToJoin: Bool
    let allowInvites: Bool
    let maxInvitesPerGroup: Int
    let allowGroupGoals: Bool
    let allowGroupStakes: Bool
    let maxGroupGoals: Int
    let maxGroupStakes: Int
    
    init(
        enabled: Bool = true,
        maxGroupsPerUser: Int = 20,
        maxMembersPerGroup: Int = 100,
        allowPublicGroups: Bool = true,
        allowPrivateGroups: Bool = true,
        requireApprovalToJoin: Bool = false,
        allowInvites: Bool = true,
        maxInvitesPerGroup: Int = 50,
        allowGroupGoals: Bool = true,
        allowGroupStakes: Bool = true,
        maxGroupGoals: Int = 50,
        maxGroupStakes: Int = 25
    ) {
        self.enabled = enabled
        self.maxGroupsPerUser = maxGroupsPerUser
        self.maxMembersPerGroup = maxMembersPerGroup
        self.allowPublicGroups = allowPublicGroups
        self.allowPrivateGroups = allowPrivateGroups
        self.requireApprovalToJoin = requireApprovalToJoin
        self.allowInvites = allowInvites
        self.maxInvitesPerGroup = maxInvitesPerGroup
        self.allowGroupGoals = allowGroupGoals
        self.allowGroupStakes = allowGroupStakes
        self.maxGroupGoals = maxGroupGoals
        self.maxGroupStakes = maxGroupStakes
    }
}

// MARK: - Corporate Configuration
struct CorporateConfig: Codable, Equatable {
    let enabled: Bool
    let maxCorporateAccountsPerUser: Int
    let maxEmployeesPerAccount: Int
    let allowEmployeeStakes: Bool
    let allowCorporateGoals: Bool
    let allowMatchingPolicies: Bool
    let maxMatchingPercentage: Decimal
    let maxMatchingAmount: Decimal
    let requireHRApproval: Bool
    let allowDepartmentGoals: Bool
    let maxDepartmentsPerAccount: Int
    
    init(
        enabled: Bool = true,
        maxCorporateAccountsPerUser: Int = 5,
        maxEmployeesPerAccount: Int = 1000,
        allowEmployeeStakes: Bool = true,
        allowCorporateGoals: Bool = true,
        allowMatchingPolicies: Bool = true,
        maxMatchingPercentage: Decimal = 1.0,
        maxMatchingAmount: Decimal = 10000.0,
        requireHRApproval: Bool = false,
        allowDepartmentGoals: Bool = true,
        maxDepartmentsPerAccount: Int = 50
    ) {
        self.enabled = enabled
        self.maxCorporateAccountsPerUser = maxCorporateAccountsPerUser
        self.maxEmployeesPerAccount = maxEmployeesPerAccount
        self.allowEmployeeStakes = allowEmployeeStakes
        self.allowCorporateGoals = allowCorporateGoals
        self.allowMatchingPolicies = allowMatchingPolicies
        self.maxMatchingPercentage = maxMatchingPercentage
        self.maxMatchingAmount = maxMatchingAmount
        self.requireHRApproval = requireHRApproval
        self.allowDepartmentGoals = allowDepartmentGoals
        self.maxDepartmentsPerAccount = maxDepartmentsPerAccount
    }
}

// MARK: - Privacy Configuration
struct PrivacyConfig: Codable, Equatable {
    let screenTimeTrackingEnabled: Bool
    let healthKitIntegrationEnabled: Bool
    let locationTrackingEnabled: Bool
    let analyticsDataRetentionDays: Int
    let userDataRetentionDays: Int
    let allowDataExport: Bool
    let allowDataDeletion: Bool
    let requireExplicitConsent: Bool
    let allowThirdPartyAnalytics: Bool
    let anonymizeUserData: Bool
    
    init(
        screenTimeTrackingEnabled: Bool = false,
        healthKitIntegrationEnabled: Bool = false,
        locationTrackingEnabled: Bool = false,
        analyticsDataRetentionDays: Int = 90,
        userDataRetentionDays: Int = 365,
        allowDataExport: Bool = true,
        allowDataDeletion: Bool = true,
        requireExplicitConsent: Bool = true,
        allowThirdPartyAnalytics: Bool = false,
        anonymizeUserData: Bool = true
    ) {
        self.screenTimeTrackingEnabled = screenTimeTrackingEnabled
        self.healthKitIntegrationEnabled = healthKitIntegrationEnabled
        self.locationTrackingEnabled = locationTrackingEnabled
        self.analyticsDataRetentionDays = analyticsDataRetentionDays
        self.userDataRetentionDays = userDataRetentionDays
        self.allowDataExport = allowDataExport
        self.allowDataDeletion = allowDataDeletion
        self.requireExplicitConsent = requireExplicitConsent
        self.allowThirdPartyAnalytics = allowThirdPartyAnalytics
        self.anonymizeUserData = anonymizeUserData
    }
}

// MARK: - Security Configuration
struct SecurityConfig: Codable, Equatable {
    let requireBiometricAuth: Bool
    let requirePasscode: Bool
    let sessionTimeout: TimeInterval
    let maxLoginAttempts: Int
    let lockoutDuration: TimeInterval
    let requireStrongPasswords: Bool
    let allowPasswordReset: Bool
    let requireEmailVerification: Bool
    let allowTwoFactorAuth: Bool
    let encryptLocalData: Bool
    let allowBiometricUnlock: Bool
    
    init(
        requireBiometricAuth: Bool = false,
        requirePasscode: Bool = true,
        sessionTimeout: TimeInterval = 24 * 60 * 60, // 24 hours
        maxLoginAttempts: Int = 5,
        lockoutDuration: TimeInterval = 15 * 60, // 15 minutes
        requireStrongPasswords: Bool = true,
        allowPasswordReset: Bool = true,
        requireEmailVerification: Bool = true,
        allowTwoFactorAuth: Bool = false,
        encryptLocalData: Bool = true,
        allowBiometricUnlock: Bool = true
    ) {
        self.requireBiometricAuth = requireBiometricAuth
        self.requirePasscode = requirePasscode
        self.sessionTimeout = sessionTimeout
        self.maxLoginAttempts = maxLoginAttempts
        self.lockoutDuration = lockoutDuration
        self.requireStrongPasswords = requireStrongPasswords
        self.allowPasswordReset = allowPasswordReset
        self.requireEmailVerification = requireEmailVerification
        self.allowTwoFactorAuth = allowTwoFactorAuth
        self.encryptLocalData = encryptLocalData
        self.allowBiometricUnlock = allowBiometricUnlock
    }
}

// MARK: - Performance Configuration
struct PerformanceConfig: Codable, Equatable {
    let enableCaching: Bool
    let cacheSizeLimit: Int64
    let enableImageOptimization: Bool
    let enableLazyLoading: Bool
    let enableBackgroundRefresh: Bool
    let backgroundRefreshInterval: TimeInterval
    let enableOfflineMode: Bool
    let maxOfflineDataSize: Int64
    let enableCompression: Bool
    let enableCDN: Bool
    
    init(
        enableCaching: Bool = true,
        cacheSizeLimit: Int64 = 100 * 1024 * 1024, // 100MB
        enableImageOptimization: Bool = true,
        enableLazyLoading: Bool = true,
        enableBackgroundRefresh: Bool = true,
        backgroundRefreshInterval: TimeInterval = 15 * 60, // 15 minutes
        enableOfflineMode: Bool = true,
        maxOfflineDataSize: Int64 = 50 * 1024 * 1024, // 50MB
        enableCompression: Bool = true,
        enableCDN: Bool = true
    ) {
        self.enableCaching = enableCaching
        self.cacheSizeLimit = cacheSizeLimit
        self.enableImageOptimization = enableImageOptimization
        self.enableLazyLoading = enableLazyLoading
        self.enableBackgroundRefresh = enableBackgroundRefresh
        self.backgroundRefreshInterval = backgroundRefreshInterval
        self.enableOfflineMode = enableOfflineMode
        self.maxOfflineDataSize = maxOfflineDataSize
        self.enableCompression = enableCompression
        self.enableCDN = enableCDN
    }
}

// MARK: - App Configuration Service
class AppConfigurationService: ObservableObject {
    static let shared = AppConfigurationService()
    
    @Published private(set) var config: AppConfig
    @Published private(set) var isLoading = false
    @Published private(set) var lastUpdateAttempt: Date?
    
    private let userDefaults = UserDefaults.standard
    private let configKey = "AppConfiguration"
    private let lastUpdateKey = "AppConfigurationLastUpdate"
    
    private init() {
        // Load default configuration
        self.config = AppConfig()
        loadLocalConfig()
    }
    
    // MARK: - Public Methods
    func loadConfiguration() async {
        await MainActor.run {
            isLoading = true
        }
        
        // Load local config first
        await loadLocalConfig()
        
        // Try to fetch remote config
        await fetchRemoteConfig()
        
        await MainActor.run {
            isLoading = false
            lastUpdateAttempt = Date()
        }
    }
    
    func updateConfiguration(_ newConfig: AppConfig) {
        config = newConfig
        saveLocalConfig()
    }
    
    func resetToDefaults() {
        config = AppConfig()
        saveLocalConfig()
    }
    
    // MARK: - Private Methods
    private func loadLocalConfig() async {
        if let data = userDefaults.data(forKey: configKey),
           let decodedConfig = try? JSONDecoder().decode(AppConfig.self, from: data) {
            await MainActor.run {
                config = decodedConfig
            }
        }
    }
    
    private func saveLocalConfig() {
        if let data = try? JSONEncoder().encode(config) {
            userDefaults.set(data, forKey: configKey)
            userDefaults.set(Date(), forKey: lastUpdateKey)
        }
    }
    
    private func fetchRemoteConfig() async {
        // TODO: Implement remote configuration fetching
        // This would typically involve:
        // 1. Making a network request to your configuration service
        // 2. Merging remote config with local defaults
        // 3. Handling conflicts (remote usually wins)
        // 4. Updating local storage
        
        logInfo("Remote configuration fetching not yet implemented", category: "AppConfig")
    }
}

// MARK: - App Configuration Extensions
extension AppConfig {
    var isProduction: Bool {
        return environment.isProduction
    }
    
    var isDevelopment: Bool {
        return environment.isDevelopment
    }
    
    var allowsDebugging: Bool {
        return environment.allowsDebugging
    }
    
    var allowsAnalytics: Bool {
        return environment.allowsAnalytics && analyticsEnabled
    }
    
    var allowsCrashReporting: Bool {
        return environment.allowsCrashReporting && crashReportingEnabled
    }
    
    var displayVersion: String {
        return "\(version) (\(buildNumber))"
    }
    
    var isStakingEnabled: Bool {
        return staking.enabled
    }
    
    var isGoalsEnabled: Bool {
        return goals.enabled
    }
    
    var isGroupsEnabled: Bool {
        return groups.enabled
    }
    
    var isCorporateEnabled: Bool {
        return corporate.enabled
    }
    
    var isScreenTimeTrackingEnabled: Bool {
        return privacy.screenTimeTrackingEnabled
    }
    
    var isHealthKitEnabled: Bool {
        return privacy.healthKitIntegrationEnabled
    }
    
    var isLocationTrackingEnabled: Bool {
        return privacy.locationTrackingEnabled
    }
}

// MARK: - Environment Extensions
extension EnvironmentValues {
    var appConfig: AppConfig {
        get { AppConfigurationService.shared.config }
        set { AppConfigurationService.shared.updateConfiguration(newValue) }
    }
}
