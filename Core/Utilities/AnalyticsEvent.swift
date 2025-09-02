import Foundation

// MARK: - Analytics Event
struct AnalyticsEvent {
    let name: String
    let properties: [String: Any]
    let timestamp: Date
    let sessionId: String?
    
    init(
        name: String,
        properties: [String: Any] = [:],
        timestamp: Date = Date(),
        sessionId: String? = nil
    ) {
        self.name = name
        self.properties = properties
        self.timestamp = timestamp
        self.sessionId = sessionId
    }
}

// MARK: - Analytics Service Protocol
protocol AnalyticsService {
    func trackEvent(_ event: AnalyticsEvent)
    func trackError(_ error: Error, context: String)
    func trackScreen(_ screenName: String, properties: [String: Any]?)
    func setUserProperty(_ key: String, value: String)
    func setUserId(_ userId: String)
    func configure()
}

// MARK: - Default Analytics Service
class DefaultAnalyticsService: AnalyticsService {
    static let shared = DefaultAnalyticsService()
    
    private var isConfigured = false
    private var userId: String?
    private var userProperties: [String: String] = [:]
    
    private init() {}
    
    func trackEvent(_ event: AnalyticsEvent) {
        guard isConfigured else {
            logWarning("Analytics not configured, event not tracked: \(event.name)", category: "Analytics")
            return
        }
        
        // Log the event
        logInfo("Analytics Event: \(event.name)", category: "Analytics")
        
        // TODO: Implement actual analytics tracking
        // This would typically send data to Firebase Analytics, Mixpanel, Amplitude, etc.
        
        // For now, just log the event details
        if !event.properties.isEmpty {
            logInfo("Event Properties: \(event.properties)", category: "Analytics")
        }
    }
    
    func trackError(_ error: Error, context: String) {
        guard isConfigured else {
            logWarning("Analytics not configured, error not tracked", category: "Analytics")
            return
        }
        
        let event = AnalyticsEvent(
            name: "error_occurred",
            properties: [
                "error_description": error.localizedDescription,
                "error_domain": (error as NSError).domain,
                "error_code": (error as NSError).code,
                "context": context,
                "timestamp": Date().timeIntervalSince1970
            ]
        )
        
        trackEvent(event)
        
        // Log error for debugging
        logError("Analytics Error Tracked: \(error.localizedDescription) in \(context)", category: "Analytics")
    }
    
    func trackScreen(_ screenName: String, properties: [String: Any]? = nil) {
        guard isConfigured else {
            logWarning("Analytics not configured, screen not tracked: \(screenName)", category: "Analytics")
            return
        }
        
        let event = AnalyticsEvent(
            name: "screen_view",
            properties: [
                "screen_name": screenName,
                "timestamp": Date().timeIntervalSince1970
            ].merging(properties ?? [:]) { current, _ in current }
        )
        
        trackEvent(event)
        
        logInfo("Screen Tracked: \(screenName)", category: "Analytics")
    }
    
    func setUserProperty(_ key: String, value: String) {
        userProperties[key] = value
        
        logInfo("User Property Set: \(key) = \(value)", category: "Analytics")
        
        // TODO: Send to analytics service
    }
    
    func setUserId(_ userId: String) {
        self.userId = userId
        
        logInfo("User ID Set: \(userId)", category: "Analytics")
        
        // TODO: Send to analytics service
    }
    
    func configure() {
        guard !isConfigured else { return }
        
        // TODO: Initialize analytics service with configuration
        // This would typically include API keys, configuration options, etc.
        
        isConfigured = true
        
        logInfo("Analytics service configured", category: "Analytics")
        
        // Track app launch
        let launchEvent = AnalyticsEvent(
            name: "app_launch",
            properties: [
                "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
                "build_number": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown",
                "device_model": UIDevice.current.model,
                "os_version": UIDevice.current.systemVersion
            ]
        )
        
        trackEvent(launchEvent)
    }
}

// MARK: - Analytics Event Names
extension AnalyticsEvent {
    // App Events
    static let appLaunch = "app_launch"
    static let appOpen = "app_open"
    static let appBackground = "app_background"
    static let appForeground = "app_foreground"
    
    // User Events
    static let userSignUp = "user_sign_up"
    static let userSignIn = "user_sign_in"
    static let userSignOut = "user_sign_out"
    static let userProfileUpdate = "user_profile_update"
    
    // Goal Events
    static let goalCreated = "goal_created"
    static let goalUpdated = "goal_updated"
    static let goalDeleted = "goal_deleted"
    static let goalCompleted = "goal_completed"
    static let goalFailed = "goal_failed"
    
    // Stake Events
    static let stakeCreated = "stake_created"
    static let stakeUpdated = "stake_updated"
    static let stakeCompleted = "stake_completed"
    static let stakeForfeited = "stake_forfeited"
    static let stakePaused = "stake_paused"
    
    // Group Events
    static let groupCreated = "group_created"
    static let groupJoined = "group_joined"
    static let groupLeft = "group_left"
    static let groupInvitationSent = "group_invitation_sent"
    static let groupInvitationAccepted = "group_invitation_accepted"
    static let groupInvitationDeclined = "group_invitation_declined"
    
    // Corporate Events
    static let corporateAccountCreated = "corporate_account_created"
    static let corporateAccountJoined = "corporate_account_joined"
    static let employeeInvited = "employee_invited"
    static let employeeJoined = "employee_joined"
    
    // Navigation Events
    static let screenView = "screen_view"
    static let tabChanged = "tab_changed"
    static let deepLinkOpened = "deep_link_opened"
    
    // Feature Events
    static let featureEnabled = "feature_enabled"
    static let featureDisabled = "feature_disabled"
    static let permissionRequested = "permission_requested"
    static let permissionGranted = "permission_granted"
    static let permissionDenied = "permission_denied"
    
    // Error Events
    static let errorOccurred = "error_occurred"
    static let networkError = "network_error"
    static let validationError = "validation_error"
    static let persistenceError = "persistence_error"
}

// MARK: - Analytics Properties
extension AnalyticsEvent {
    // Common Properties
    static let timestamp = "timestamp"
    static let userId = "user_id"
    static let sessionId = "session_id"
    static let deviceModel = "device_model"
    static let osVersion = "os_version"
    static let appVersion = "app_version"
    static let buildNumber = "build_number"
    
    // Goal Properties
    static let goalId = "goal_id"
    static let goalCategory = "goal_category"
    static let goalStakeAmount = "goal_stake_amount"
    static let goalDeadline = "goal_deadline"
    static let goalStatus = "goal_status"
    
    // Stake Properties
    static let stakeId = "stake_id"
    static let stakeAmount = "stake_amount"
    static let stakeApr = "stake_apr"
    static let stakeDuration = "stake_duration"
    
    // Group Properties
    static let groupId = "group_id"
    static let groupCategory = "group_category"
    static let groupMemberCount = "group_member_count"
    static let groupIsPublic = "group_is_public"
    
    // Corporate Properties
    static let corporateId = "corporate_id"
    static let corporateIndustry = "corporate_industry"
    static let corporateSize = "corporate_size"
    static let employeeCount = "employee_count"
    
    // User Properties
    static let userAge = "user_age"
    static let userGender = "user_gender"
    static let userLocation = "user_location"
    static let userRiskTolerance = "user_risk_tolerance"
    static let userGoalCount = "user_goal_count"
    static let userStakeCount = "user_stake_count"
}

// MARK: - Analytics Helper Functions
func trackAnalyticsEvent(_ name: String, properties: [String: Any] = [:]) {
    let event = AnalyticsEvent(name: name, properties: properties)
    DefaultAnalyticsService.shared.trackEvent(event)
}

func trackAnalyticsScreen(_ screenName: String, properties: [String: Any]? = nil) {
    DefaultAnalyticsService.shared.trackScreen(screenName, properties: properties)
}

func trackAnalyticsError(_ error: Error, context: String) {
    DefaultAnalyticsService.shared.trackError(error, context: context)
}
