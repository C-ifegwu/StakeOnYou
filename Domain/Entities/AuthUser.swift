import Foundation

// MARK: - Auth User Entity
struct AuthUser: Identifiable, Codable, Equatable {
    let id: String
    let email: String
    let fullName: String
    let avatarURL: URL?
    let referralCode: String?
    let isEmailVerified: Bool
    let createdAt: Date
    let updatedAt: Date
    let lastLoginAt: Date?
    let preferences: AuthUserPreferences
    let security: AuthUserSecurity
    
    init(
        id: String,
        email: String,
        fullName: String,
        avatarURL: URL? = nil,
        referralCode: String? = nil,
        isEmailVerified: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        lastLoginAt: Date? = nil,
        preferences: AuthUserPreferences = AuthUserPreferences(),
        security: AuthUserSecurity = AuthUserSecurity()
    ) {
        self.id = id
        self.email = email
        self.fullName = fullName
        self.avatarURL = avatarURL
        self.referralCode = referralCode
        self.isEmailVerified = isEmailVerified
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastLoginAt = lastLoginAt
        self.preferences = preferences
        self.security = security
    }
}

// MARK: - Auth User Preferences
struct AuthUserPreferences: Codable, Equatable {
    let enableBiometrics: Bool
    let enableNotifications: Bool
    let enableEmailUpdates: Bool
    let language: String
    let timezone: String
    let rememberMe: Bool
    
    init(
        enableBiometrics: Bool = false,
        enableNotifications: Bool = true,
        enableEmailUpdates: Bool = true,
        language: String = "en",
        timezone: String = TimeZone.current.identifier,
        rememberMe: Bool = false
    ) {
        self.enableBiometrics = enableBiometrics
        self.enableNotifications = enableNotifications
        self.enableEmailUpdates = enableEmailUpdates
        self.language = language
        self.timezone = timezone
        self.rememberMe = rememberMe
    }
}

// MARK: - Auth User Security
struct AuthUserSecurity: Codable, Equatable {
    let hasBiometricEnabled: Bool
    let lastPasswordChange: Date?
    let failedLoginAttempts: Int
    let isAccountLocked: Bool
    let lockoutUntil: Date?
    let sessionTokens: [String]
    
    init(
        hasBiometricEnabled: Bool = false,
        lastPasswordChange: Date? = nil,
        failedLoginAttempts: Int = 0,
        isAccountLocked: Bool = false,
        lockoutUntil: Date? = nil,
        sessionTokens: [String] = []
    ) {
        self.hasBiometricEnabled = hasBiometricEnabled
        self.lastPasswordChange = lastPasswordChange
        self.failedLoginAttempts = failedLoginAttempts
        self.isAccountLocked = isAccountLocked
        self.lockoutUntil = lockoutUntil
        self.sessionTokens = sessionTokens
    }
}

// MARK: - Authentication State
enum AuthenticationState: Equatable {
    case unauthenticated
    case authenticating
    case authenticated(AuthUser)
    case error(AuthenticationError)
}

// MARK: - Authentication Error
enum AuthenticationError: LocalizedError, Equatable {
    case invalidCredentials
    case emailAlreadyInUse
    case weakPassword
    case networkError
    case tooManyAttempts
    case accountLocked
    case biometricNotAvailable
    case biometricNotEnrolled
    case userCancelled
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password. Please try again."
        case .emailAlreadyInUse:
            return "An account with this email already exists."
        case .weakPassword:
            return "Password must be at least 8 characters with 1 uppercase letter and 1 number."
        case .networkError:
            return "Network error. Please check your connection and try again."
        case .tooManyAttempts:
            return "Too many failed attempts. Please try again later."
        case .accountLocked:
            return "Account temporarily locked due to security concerns."
        case .biometricNotAvailable:
            return "Biometric authentication is not available on this device."
        case .biometricNotEnrolled:
            return "Please set up Face ID or Touch ID in Settings."
        case .userCancelled:
            return "Authentication was cancelled."
        case .unknown(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }
}
