import SwiftUI
import Combine

// MARK: - Authentication View Model
@MainActor
class AuthViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var authenticationState: AuthenticationState = .unauthenticated
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showBiometricPrompt = false
    @Published var showProfileSetup = false
    
    // Form States
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var fullName = ""
    @Published var referralCode = ""
    @Published var rememberMe = false
    
    // Validation States
    @Published var emailError: String?
    @Published var passwordError: String?
    @Published var confirmPasswordError: String?
    @Published var fullNameError: String?
    @Published var referralCodeError: String?
    
    // UI States
    @Published var isSignUpMode = false
    @Published var showPassword = false
    @Published var showConfirmPassword = false
    @Published var passwordStrength: PasswordStrength = .weak
    
    // MARK: - Dependencies
    private let authService: AuthenticationService
    private let validationService: ValidationService
    private let biometricService: BiometricService
    private let keychainService: KeychainService
    private let analyticsService: AnalyticsService
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(
        authService: AuthenticationService = DIContainer.shared.resolve(AuthenticationService.self),
        validationService: ValidationService = DIContainer.shared.resolve(ValidationService.self),
        biometricService: BiometricService = DIContainer.shared.resolve(BiometricService.self),
        keychainService: KeychainService = DIContainer.shared.resolve(KeychainService.self),
        analyticsService: AnalyticsService = DIContainer.shared.resolve(AnalyticsService.self)
    ) {
        self.authService = authService
        self.validationService = validationService
        self.biometricService = biometricService
        self.keychainService = keychainService
        self.analyticsService = analyticsService
        
        setupObservers()
        checkBiometricStatus()
        loadSavedCredentials()
    }
    
    // MARK: - Setup
    private func setupObservers() {
        // Monitor authentication state changes
        authService.authenticationState
            .receive(on: DispatchQueue.main)
            .assign(to: \.authenticationState, on: self)
            .store(in: &cancellables)
        
        // Monitor password changes for strength calculation
        $password
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] password in
                self?.updatePasswordStrength(password)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    // MARK: - Sign Up
    func signUp() async {
        guard validateSignUpForm() else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await authService.signUp(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password,
                fullName: fullName.trimmingCharacters(in: .whitespacesAndNewlines),
                referralCode: referralCode.isEmpty ? nil : referralCode.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            
            // Save credentials if remember me is enabled
            if rememberMe {
                try saveCredentials()
            }
            
            // Track successful sign up
            trackAnalyticsEvent("sign_up_success", properties: [
                "has_referral_code": !referralCode.isEmpty,
                "password_strength": passwordStrength.rawValue
            ])
            
            // Show biometric prompt if available
            if biometricService.isAvailable && biometricService.isEnrolled {
                showBiometricPrompt = true
            } else {
                showProfileSetup = true
            }
            
        } catch {
            handleAuthenticationError(error)
        }
        
        isLoading = false
    }
    
    // MARK: - Sign In
    func signIn() async {
        guard validateSignInForm() else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await authService.signIn(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password,
                rememberMe: rememberMe
            )
            
            // Save credentials if remember me is enabled
            if rememberMe {
                try saveCredentials()
            }
            
            // Track successful sign in
            trackAnalyticsEvent("sign_in_success", properties: [
                "remember_me": rememberMe,
                "method": "email_password"
            ])
            
            // Show biometric prompt if available and not enabled
            if biometricService.isAvailable && biometricService.isEnrolled && !user.preferences.enableBiometrics {
                showBiometricPrompt = true
            } else {
                showProfileSetup = true
            }
            
        } catch {
            handleAuthenticationError(error)
        }
        
        isLoading = false
    }
    
    // MARK: - Social Sign In
    func signInWithApple() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await authService.signInWithApple()
            
            trackAnalyticsEvent("sign_in_success", properties: [
                "method": "apple",
                "remember_me": false
            ])
            
            showProfileSetup = true
            
        } catch {
            handleAuthenticationError(error)
        }
        
        isLoading = false
    }
    
    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await authService.signInWithGoogle()
            
            trackAnalyticsEvent("sign_in_success", properties: [
                "method": "google",
                "remember_me": false
            ])
            
            showProfileSetup = true
            
        } catch {
            handleAuthenticationError(error) {
                // Google sign in might not be available
                self.errorMessage = "Google Sign-In is not available. Please use email/password or Sign in with Apple."
            }
        }
        
        isLoading = false
    }
    
    // MARK: - Biometric Authentication
    func authenticateWithBiometrics() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await authService.authenticateWithBiometrics()
            
            trackAnalyticsEvent("sign_in_success", properties: [
                "method": "biometric",
                "biometric_type": biometricService.biometricType.rawValue
            ])
            
            showProfileSetup = true
            
        } catch {
            handleAuthenticationError(error)
        }
        
        isLoading = false
    }
    
    func enableBiometrics() async {
        do {
            try await authService.enableBiometrics()
            
            trackAnalyticsEvent("biometric_enabled", properties: [
                "biometric_type": biometricService.biometricType.rawValue
            ])
            
            showProfileSetup = true
            
        } catch {
            handleAuthenticationError(error)
        }
    }
    
    func skipBiometricSetup() {
        showProfileSetup = true
    }
    
    // MARK: - Password Reset
    func resetPassword() async {
        guard validateEmail() else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.resetPassword(email: email.trimmingCharacters(in: .whitespacesAndNewlines))
            
            trackAnalyticsEvent("password_reset_requested", properties: [
                "email": email.trimmingCharacters(in: .whitespacesAndNewlines)
            ])
            
            // Show success message
            errorMessage = "Password reset email sent. Please check your inbox."
            
        } catch {
            handleAuthenticationError(error)
        }
        
        isLoading = false
    }
    
    // MARK: - Form Validation
    private func validateSignUpForm() -> Bool {
        var isValid = true
        
        // Clear previous errors
        clearValidationErrors()
        
        // Validate email
        if !validateEmail() {
            isValid = false
        }
        
        // Validate password
        if !validatePassword() {
            isValid = false
        }
        
        // Validate confirm password
        if !validateConfirmPassword() {
            isValid = false
        }
        
        // Validate full name
        if !validateFullName() {
            isValid = false
        }
        
        // Validate referral code (optional)
        if !referralCode.isEmpty && !validateReferralCode() {
            isValid = false
        }
        
        return isValid
    }
    
    private func validateSignInForm() -> Bool {
        var isValid = true
        
        // Clear previous errors
        clearValidationErrors()
        
        // Validate email
        if !validateEmail() {
            isValid = false
        }
        
        // Validate password
        if !validatePassword() {
            isValid = false
        }
        
        return isValid
    }
    
    private func validateEmail() -> Bool {
        do {
            try validationService.validateEmail(email)
            emailError = nil
            return true
        } catch {
            emailError = error.localizedDescription
            return false
        }
    }
    
    private func validatePassword() -> Bool {
        do {
            try validationService.validatePassword(password)
            passwordError = nil
            return true
        } catch {
            passwordError = error.localizedDescription
            return false
        }
    }
    
    private func validateConfirmPassword() -> Bool {
        guard !confirmPassword.isEmpty else {
            confirmPasswordError = "Please confirm your password"
            return false
        }
        
        guard password == confirmPassword else {
            confirmPasswordError = "Passwords do not match"
            return false
        }
        
        confirmPasswordError = nil
        return true
    }
    
    private func validateFullName() -> Bool {
        do {
            try validationService.validateFullName(fullName)
            fullNameError = nil
            return true
        } catch {
            fullNameError = error.localizedDescription
            return false
        }
    }
    
    private func validateReferralCode() -> Bool {
        do {
            try validationService.validateReferralCode(referralCode)
            referralCodeError = nil
            return true
        } catch {
            referralCodeError = error.localizedDescription
            return false
        }
    }
    
    private func clearValidationErrors() {
        emailError = nil
        passwordError = nil
        confirmPasswordError = nil
        fullNameError = nil
        referralCodeError = nil
    }
    
    // MARK: - Form Management
    func switchToSignUp() {
        isSignUpMode = true
        clearForm()
        clearValidationErrors()
        trackAnalyticsEvent("auth_mode_changed", properties: ["mode": "signup"])
    }
    
    func switchToSignIn() {
        isSignUpMode = false
        clearForm()
        clearValidationErrors()
        trackAnalyticsEvent("auth_mode_changed", properties: ["mode": "signin"])
    }
    
    func clearForm() {
        email = ""
        password = ""
        confirmPassword = ""
        fullName = ""
        referralCode = ""
        rememberMe = false
        showPassword = false
        showConfirmPassword = false
        passwordStrength = .weak
    }
    
    // MARK: - Private Methods
    private func updatePasswordStrength(_ password: String) {
        if let validationService = validationService as? ValidationServiceImpl {
            passwordStrength = validationService.calculatePasswordStrength(password)
        }
    }
    
    private func checkBiometricStatus() {
        // Check if biometrics are available and enrolled
        if biometricService.isAvailable && biometricService.isEnrolled {
            // Check if user has previously enabled biometrics
            if let biometricEnabled = try? keychainService.loadBool(for: KeychainConstants.biometricEnabledKey),
               biometricEnabled {
                // User has biometrics enabled, offer biometric login
                showBiometricPrompt = true
            }
        }
    }
    
    private func loadSavedCredentials() {
        // Load saved email if remember me was enabled
        if let savedEmail = try? keychainService.loadString(for: "saved_email") {
            email = savedEmail
        }
        
        // Load remember me preference
        if let savedRememberMe = try? keychainService.loadBool(for: KeychainConstants.rememberMeKey) {
            rememberMe = savedRememberMe
        }
    }
    
    private func saveCredentials() throws {
        if rememberMe {
            try keychainService.saveString(email, for: "saved_email")
            try keychainService.saveBool(true, for: KeychainConstants.rememberMeKey)
        } else {
            try? keychainService.delete(for: "saved_email")
            try? keychainService.delete(for: KeychainConstants.rememberMeKey)
        }
    }
    
    private func handleAuthenticationError(_ error: Error, customHandler: (() -> Void)? = nil) {
        if let customHandler = customHandler {
            customHandler()
        } else {
            if let authError = error as? AuthenticationError {
                errorMessage = authError.localizedDescription
            } else {
                errorMessage = error.localizedDescription
            }
        }
        
        trackAnalyticsEvent("auth_error", properties: [
            "error": error.localizedDescription,
            "mode": isSignUpMode ? "signup" : "signin"
        ])
    }
    
    // MARK: - Computed Properties
    var canSubmitSignUp: Bool {
        !email.isEmpty && !password.isEmpty && !confirmPassword.isEmpty && !fullName.isEmpty
    }
    
    var canSubmitSignIn: Bool {
        !email.isEmpty && !password.isEmpty
    }
    
    var canSubmitPasswordReset: Bool {
        !email.isEmpty
    }
    
    var biometricTypeDisplayName: String {
        biometricService.biometricType.displayName
    }
    
    var biometricIconName: String {
        biometricService.biometricType.iconName
    }
    
    var isBiometricAvailable: Bool {
        biometricService.isAvailable
    }
    
    var isBiometricEnrolled: Bool {
        biometricService.isEnrolled
    }
}
