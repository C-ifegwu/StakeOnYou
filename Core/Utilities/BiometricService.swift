import Foundation
import LocalAuthentication

// MARK: - Biometric Service Implementation
class BiometricServiceImpl: BiometricService {
    
    // MARK: - Properties
    private let context = LAContext()
    private var error: NSError?
    
    var isAvailable: Bool {
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    var isEnrolled: Bool {
        guard isAvailable else { return false }
        return context.biometryType != .none
    }
    
    var biometricType: BiometricType {
        guard isAvailable else { return .none }
        
        switch context.biometryType {
        case .none:
            return .none
        case .touchID:
            return .touchID
        case .faceID:
            return .faceID
        @unknown default:
            return .none
        }
    }
    
    // MARK: - Authentication
    func authenticate(reason: String) async throws {
        guard isAvailable else {
            throw BiometricError.notAvailable
        }
        
        guard isEnrolled else {
            throw BiometricError.notEnrolled
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            ) { success, error in
                if success {
                    continuation.resume()
                } else if let error = error {
                    let biometricError = BiometricError.fromLAError(error)
                    continuation.resume(throwing: biometricError)
                } else {
                    continuation.resume(throwing: BiometricError.unknown)
                }
            }
        }
    }
    
    // MARK: - Biometric Management
    func enableBiometrics() async throws {
        // This would typically involve:
        // 1. Authenticating with biometrics to confirm user identity
        // 2. Storing biometric preference in secure storage
        // 3. Updating user preferences
        
        try await authenticate(reason: "Enable biometric authentication")
        
        // Store preference in keychain or secure storage
        // This is a placeholder - actual implementation would depend on your storage solution
        logInfo("Biometric authentication enabled", category: "BiometricService")
    }
    
    func disableBiometrics() async throws {
        // This would typically involve:
        // 1. Authenticating with biometrics to confirm user identity
        // 2. Removing biometric preference from secure storage
        // 3. Updating user preferences
        
        try await authenticate(reason: "Disable biometric authentication")
        
        // Remove preference from keychain or secure storage
        // This is a placeholder - actual implementation would depend on your storage solution
        logInfo("Biometric authentication disabled", category: "BiometricService")
    }
    
    // MARK: - Helper Methods
    func checkBiometricStatus() -> BiometricStatus {
        guard isAvailable else {
            return .notAvailable
        }
        
        guard isEnrolled else {
            return .notEnrolled
        }
        
        return .available
    }
    
    func getBiometricTypeDescription() -> String {
        switch biometricType {
        case .none:
            return "Biometric authentication not available"
        case .touchID:
            return "Touch ID is available"
        case .faceID:
            return "Face ID is available"
        }
    }
}

// MARK: - Biometric Status
enum BiometricStatus {
    case available
    case notAvailable
    case notEnrolled
    case lockedOut
    case notInteractive
}

// MARK: - Biometric Errors
enum BiometricError: LocalizedError, Equatable {
    case notAvailable
    case notEnrolled
    case lockedOut
    case notInteractive
    case userCancelled
    case userFallback
    case systemCancel
    case passcodeNotSet
    case biometryNotAvailable
    case biometryNotEnrolled
    case biometryLockout
    case appCancel
    case invalidContext
    case notInteractive
    case watchNotAvailable
    case unknown
    
    static func fromLAError(_ error: Error) -> BiometricError {
        let laError = error as? LAError ?? LAError(.unknown)
        
        switch laError.code {
        case .biometryNotAvailable:
            return .biometryNotAvailable
        case .biometryNotEnrolled:
            return .biometryNotEnrolled
        case .biometryLockout:
            return .biometryLockout
        case .userCancel:
            return .userCancelled
        case .userFallback:
            return .userFallback
        case .systemCancel:
            return .systemCancel
        case .passcodeNotSet:
            return .passcodeNotSet
        case .appCancel:
            return .appCancel
        case .invalidContext:
            return .invalidContext
        case .notInteractive:
            return .notInteractive
        case .watchNotAvailable:
            return .watchNotAvailable
        case .unknown:
            return .unknown
        @unknown default:
            return .unknown
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Biometric authentication is not available on this device"
        case .notEnrolled:
            return "Please set up Face ID or Touch ID in Settings"
        case .lockedOut:
            return "Biometric authentication is temporarily locked. Please try again later"
        case .notInteractive:
            return "Biometric authentication is not interactive"
        case .userCancelled:
            return "Authentication was cancelled"
        case .userFallback:
            return "User chose to use passcode instead"
        case .systemCancel:
            return "Authentication was cancelled by the system"
        case .passcodeNotSet:
            return "Please set a passcode in Settings to use biometric authentication"
        case .biometryNotAvailable:
            return "Biometric authentication is not available"
        case .biometryNotEnrolled:
            return "Biometric authentication is not set up"
        case .biometryLockout:
            return "Biometric authentication is locked due to too many failed attempts"
        case .appCancel:
            return "Authentication was cancelled by the app"
        case .invalidContext:
            return "Invalid authentication context"
        case .watchNotAvailable:
            return "Apple Watch authentication is not available"
        case .unknown:
            return "An unknown error occurred"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .notAvailable, .biometryNotAvailable:
            return "This device does not support biometric authentication"
        case .notEnrolled, .biometryNotEnrolled:
            return "Go to Settings > Face ID & Passcode (or Touch ID & Passcode) to set up biometric authentication"
        case .lockedOut, .biometryLockout:
            return "Wait a few minutes and try again, or use your passcode"
        case .passcodeNotSet:
            return "Go to Settings > Face ID & Passcode (or Touch ID & Passcode) to set a passcode"
        case .userCancelled, .userFallback, .systemCancel, .appCancel:
            return "Try authenticating again"
        case .notInteractive, .invalidContext, .watchNotAvailable, .unknown:
            return "Please try again or contact support if the problem persists"
        }
    }
}

// MARK: - Biometric Configuration
struct BiometricConfiguration {
    let allowFallbackToPasscode: Bool
    let allowFallbackToPassword: Bool
    let requireUserConfirmation: Bool
    let requireUserPresence: Bool
    
    static let `default` = BiometricConfiguration(
        allowFallbackToPasscode: true,
        allowFallbackToPassword: false,
        requireUserConfirmation: false,
        requireUserPresence: true
    )
    
    static let strict = BiometricConfiguration(
        allowFallbackToPasscode: false,
        allowFallbackToPassword: false,
        requireUserConfirmation: true,
        requireUserPresence: true
    )
}

// MARK: - Biometric Analytics
extension BiometricServiceImpl {
    func trackBiometricEvent(_ event: BiometricAnalyticsEvent) {
        trackAnalyticsEvent(event.name, properties: event.properties)
    }
}

enum BiometricAnalyticsEvent {
    case enabled
    case disabled
    case authenticationSuccess
    case authenticationFailure(BiometricError)
    case userCancelled
    case fallbackUsed
    
    var name: String {
        switch self {
        case .enabled:
            return "biometric_enabled"
        case .disabled:
            return "biometric_disabled"
        case .authenticationSuccess:
            return "biometric_auth_success"
        case .authenticationFailure:
            return "biometric_auth_failure"
        case .userCancelled:
            return "biometric_auth_cancelled"
        case .fallbackUsed:
            return "biometric_fallback_used"
        }
    }
    
    var properties: [String: Any] {
        switch self {
        case .enabled, .disabled:
            return [
                "biometric_type": BiometricServiceImpl().biometricType.rawValue,
                "timestamp": Date().timeIntervalSince1970
            ]
        case .authenticationSuccess:
            return [
                "biometric_type": BiometricServiceImpl().biometricType.rawValue,
                "timestamp": Date().timeIntervalSince1970
            ]
        case .authenticationFailure(let error):
            return [
                "biometric_type": BiometricServiceImpl().biometricType.rawValue,
                "error_code": error.localizedDescription,
                "timestamp": Date().timeIntervalSince1970
            ]
        case .userCancelled:
            return [
                "biometric_type": BiometricServiceImpl().biometricType.rawValue,
                "timestamp": Date().timeIntervalSince1970
            ]
        case .fallbackUsed:
            return [
                "biometric_type": BiometricServiceImpl().biometricType.rawValue,
                "fallback_method": "passcode",
                "timestamp": Date().timeIntervalSince1970
            ]
        }
    }
}
