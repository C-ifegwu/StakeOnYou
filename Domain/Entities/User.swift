import Foundation

// MARK: - User Entity
struct User: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let email: String
    let avatarURL: URL?
    let createdAt: Date
    let updatedAt: Date
    let preferences: UserPreferences
    let profile: UserProfile
    let privacySettings: PrivacySettings
    
    init(
        id: String = UUID().uuidString,
        name: String,
        email: String,
        avatarURL: URL? = nil,
        preferences: UserPreferences = UserPreferences(),
        profile: UserProfile = UserProfile(),
        privacySettings: PrivacySettings = PrivacySettings()
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.avatarURL = avatarURL
        self.createdAt = Date()
        self.updatedAt = Date()
        self.preferences = preferences
        self.profile = profile
        self.privacySettings = privacySettings
    }
}

// MARK: - User Preferences
struct UserPreferences: Codable, Equatable {
    var notifications: NotificationPreferences
    var appearance: AppearancePreferences
    var privacy: PrivacyPreferences
    var staking: StakingPreferences
    
    init(
        notifications: NotificationPreferences = NotificationPreferences(),
        appearance: AppearancePreferences = AppearancePreferences(),
        privacy: PrivacyPreferences = PrivacyPreferences(),
        staking: StakingPreferences = StakingPreferences()
    ) {
        self.notifications = notifications
        self.appearance = appearance
        self.privacy = privacy
        self.staking = staking
    }
}

struct NotificationPreferences: Codable, Equatable {
    var goalReminders: Bool = true
    var stakeUpdates: Bool = true
    var groupActivities: Bool = true
    var weeklyReports: Bool = false
    var marketingEmails: Bool = false
    var pushNotifications: Bool = true
    var emailNotifications: Bool = true
}

struct AppearancePreferences: Codable, Equatable {
    var theme: AppTheme = .system
    var useDynamicType: Bool = true
    var useHapticFeedback: Bool = true
    var useReducedMotion: Bool = false
    var accentColor: String = "primary"
}

struct PrivacyPreferences: Codable, Equatable {
    var shareProfilePublicly: Bool = false
    var shareGoalsWithFriends: Bool = true
    var allowAnalytics: Bool = true
    var allowCrashReporting: Bool = true
    var dataRetentionDays: Int = 365
}

struct StakingPreferences: Codable, Equatable {
    var defaultStakeAmount: Decimal = 10.0
    var defaultCurrency: String = "USD"
    var autoReinvest: Bool = false
    var preferredCharityId: String?
    var riskTolerance: RiskTolerance = .moderate
}

// MARK: - User Profile
struct UserProfile: Codable, Equatable {
    var bio: String = ""
    var location: String = ""
    var website: URL?
    var socialLinks: [SocialLink] = []
    var interests: [String] = []
    var achievements: [Achievement] = []
    var stats: UserStats = UserStats()
}

struct SocialLink: Codable, Equatable {
    let platform: SocialPlatform
    let url: URL
    let username: String
}

enum SocialPlatform: String, Codable, CaseIterable {
    case twitter = "twitter"
    case instagram = "instagram"
    case linkedin = "linkedin"
    case facebook = "facebook"
    case github = "github"
    case website = "website"
}

struct Achievement: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let description: String
    let iconName: String
    let unlockedAt: Date
    let category: AchievementCategory
    
    init(
        id: String = UUID().uuidString,
        title: String,
        description: String,
        iconName: String,
        unlockedAt: Date = Date(),
        category: AchievementCategory
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.iconName = iconName
        self.unlockedAt = unlockedAt
        self.category = category
    }
}

enum AchievementCategory: String, Codable, CaseIterable {
    case goals = "goals"
    case staking = "staking"
    case social = "social"
    case streak = "streak"
    case charity = "charity"
}

struct UserStats: Codable, Equatable {
    var totalGoals: Int = 0
    var completedGoals: Int = 0
    var totalStaked: Decimal = 0
    var totalEarned: Decimal = 0
    var totalDonated: Decimal = 0
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var joinDate: Date = Date()
}

// MARK: - Privacy Settings
struct PrivacySettings: Codable, Equatable {
    var screenTimeTracking: PermissionStatus = .notRequested
    var healthKitAccess: PermissionStatus = .notRequested
    var locationAccess: PermissionStatus = .notRequested
    var cameraAccess: PermissionStatus = .notRequested
    var photoLibraryAccess: PermissionStatus = .notRequested
    var microphoneAccess: PermissionStatus = .notRequested
    var contactsAccess: PermissionStatus = .notRequested
    var calendarAccess: PermissionStatus = .notRequested
}

enum PermissionStatus: String, Codable, CaseIterable {
    case notRequested = "not_requested"
    case denied = "denied"
    case restricted = "restricted"
    case authorized = "authorized"
    case provisional = "provisional"
    case ephemeral = "ephemeral"
}

// MARK: - Enums
enum AppTheme: String, Codable, CaseIterable {
    case light = "light"
    case dark = "dark"
    case system = "system"
}

enum RiskTolerance: String, Codable, CaseIterable {
    case conservative = "conservative"
    case moderate = "moderate"
    case aggressive = "aggressive"
}

// MARK: - User Extensions
extension User {
    var displayName: String {
        return name.isEmpty ? "User" : name
    }
    
    var isProfileComplete: Bool {
        return !name.isEmpty && !email.isEmpty
    }
    
    var hasCompletedGoals: Bool {
        return profile.stats.completedGoals > 0
    }
    
    var hasActiveStakes: Bool {
        return profile.stats.totalStaked > 0
    }
    
    var completionRate: Double {
        guard profile.stats.totalGoals > 0 else { return 0.0 }
        return Double(profile.stats.completedGoals) / Double(profile.stats.totalGoals)
    }
}

// MARK: - Privacy Extensions
extension User {
    var canTrackScreenTime: Bool {
        return privacySettings.screenTimeTracking == .authorized
    }
    
    var canAccessHealthKit: Bool {
        return privacySettings.healthKitAccess == .authorized
    }
    
    var hasLocationPermission: Bool {
        return privacySettings.locationAccess == .authorized
    }
    
    var privacyScore: Int {
        var score = 0
        if privacySettings.screenTimeTracking == .authorized { score += 1 }
        if privacySettings.healthKitAccess == .authorized { score += 1 }
        if privacySettings.locationAccess == .authorized { score += 1 }
        return score
    }
}
