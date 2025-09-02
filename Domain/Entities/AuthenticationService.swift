import Foundation
import Combine

// MARK: - Authentication Service Protocol
protocol AuthenticationService {
    // MARK: - Authentication State
    var authenticationState: AnyPublisher<AuthenticationState, Never> { get }
    var currentUser: AuthUser? { get }
    
    // MARK: - Sign Up
    func signUp(
        email: String,
        password: String,
        fullName: String,
        referralCode: String?
    ) async throws -> AuthUser
    
    // MARK: - Sign In
    func signIn(
        email: String,
        password: String,
        rememberMe: Bool
    ) async throws -> AuthUser
    
    // MARK: - Social Sign In
    func signInWithApple() async throws -> AuthUser
    func signInWithGoogle() async throws -> AuthUser
    
    // MARK: - Biometric Authentication
    func authenticateWithBiometrics() async throws -> AuthUser
    func enableBiometrics() async throws
    func disableBiometrics() async throws
    var isBiometricsAvailable: Bool { get }
    var isBiometricsEnrolled: Bool { get }
    
    // MARK: - Password Management
    func resetPassword(email: String) async throws
    func changePassword(
        currentPassword: String,
        newPassword: String
    ) async throws
    
    // MARK: - Session Management
    func signOut() async throws
    func refreshSession() async throws
    func revokeAllSessions() async throws
    
    // MARK: - Account Management
    func updateProfile(_ user: AuthUser) async throws -> AuthUser
    func deleteAccount() async throws
    func verifyEmail() async throws
    
    // MARK: - Security
    func checkAccountLockout() -> Bool
    func incrementFailedAttempts()
    func resetFailedAttempts()
}

// MARK: - Authentication Repository Protocol
protocol AuthenticationRepository {
    func createUser(_ user: AuthUser) async throws -> AuthUser
    func getUser(by id: String) async throws -> AuthUser?
    func getUser(by email: String) async throws -> AuthUser?
    func updateUser(_ user: AuthUser) async throws -> AuthUser
    func deleteUser(_ id: String) async throws
    func checkEmailExists(_ email: String) async throws -> Bool
}

// MARK: - Biometric Service Protocol
protocol BiometricService {
    var isAvailable: Bool { get }
    var isEnrolled: Bool { get }
    var biometricType: BiometricType { get }
    
    func authenticate(reason: String) async throws
    func enableBiometrics() async throws
    func disableBiometrics() async throws
}

// MARK: - Biometric Type
enum BiometricType: String, CaseIterable {
    case none = "none"
    case touchID = "touchID"
    case faceID = "faceID"
    
    var displayName: String {
        switch self {
        case .none:
            return "None"
        case .touchID:
            return "Touch ID"
        case .faceID:
            return "Face ID"
        }
    }
    
    var iconName: String {
        switch self {
        case .none:
            return "lock"
        case .touchID:
            return "touchid"
        case .faceID:
            return "faceid"
        }
    }
}

// MARK: - Keychain Service Protocol
protocol KeychainService {
    func save(_ data: Data, for key: String) throws
    func load(for key: String) throws -> Data?
    func delete(for key: String) throws
    func exists(for key: String) -> Bool
}

// MARK: - Authentication Use Cases
struct SignUpUseCase {
    private let authService: AuthenticationService
    private let validationService: ValidationService
    
    init(
        authService: AuthenticationService,
        validationService: ValidationService
    ) {
        self.authService = authService
        self.validationService = validationService
    }
    
    func execute(
        email: String,
        password: String,
        fullName: String,
        referralCode: String?
    ) async throws -> AuthUser {
        // Validate inputs
        try validationService.validateEmail(email)
        try validationService.validatePassword(password)
        try validationService.validateFullName(fullName)
        
        // Check if email already exists
        // This would typically be done in the auth service
        
        // Create user
        return try await authService.signUp(
            email: email,
            password: password,
            fullName: fullName,
            referralCode: referralCode
        )
    }
}

struct SignInUseCase {
    private let authService: AuthenticationService
    
    init(authService: AuthenticationService) {
        self.authService = authService
    }
    
    func execute(
        email: String,
        password: String,
        rememberMe: Bool
    ) async throws -> AuthUser {
        return try await authService.signIn(
            email: email,
            password: password,
            rememberMe: rememberMe
        )
    }
}

// MARK: - Validation Service Protocol
protocol ValidationService {
    func validateEmail(_ email: String) throws
    func validatePassword(_ password: String) throws
    func validateFullName(_ fullName: String) throws
    func validateReferralCode(_ code: String?) throws
}
