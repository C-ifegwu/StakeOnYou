import SwiftUI

// MARK: - Authentication View
struct AuthView: View {
    @StateObject private var viewModel = AuthViewModel()
    @Environment(\.router) private var router
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppSpacing.xl) {
                        // Header
                        headerSection
                        
                        // Authentication Form
                        if viewModel.isSignUpMode {
                            signUpForm
                        } else {
                            signInForm
                        }
                        
                        // Social Sign In
                        socialSignInSection
                        
                        // Mode Switch
                        modeSwitchSection
                        
                        // Forgot Password
                        if !viewModel.isSignUpMode {
                            forgotPasswordSection
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.vertical, AppSpacing.xl)
                }
                
                // Loading Overlay
                if viewModel.isLoading {
                    loadingOverlay
                }
            }
            .navigationBarHidden(true)
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .sheet(isPresented: $viewModel.showBiometricPrompt) {
            BiometricPromptView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showProfileSetup) {
            ProfileSetupView()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: AppSpacing.lg) {
            // App Logo
            Image(systemName: "target")
                .font(.system(size: 60, weight: .bold))
                .foregroundColor(AppColors.primary)
            
            // App Title
            Text("StakeOnYou")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(AppColors.textPrimary)
            
            // Subtitle
            Text(viewModel.isSignUpMode ? "Create your account" : "Welcome back")
                .font(.title2)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Sign Up Form
    private var signUpForm: some View {
        VStack(spacing: AppSpacing.lg) {
            // Full Name
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Full Name")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                TextField("Enter your full name", text: $viewModel.fullName)
                    .textFieldStyle(AppTextFieldStyle())
                    .textContentType(.name)
                    .autocapitalization(.words)
                
                if let error = viewModel.fullNameError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(AppColors.error)
                }
            }
            
            // Email
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Email")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                TextField("Enter your email", text: $viewModel.email)
                    .textFieldStyle(AppTextFieldStyle())
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                
                if let error = viewModel.emailError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(AppColors.error)
                }
            }
            
            // Password
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Password")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                HStack {
                    if viewModel.showPassword {
                        TextField("Enter your password", text: $viewModel.password)
                            .textFieldStyle(AppTextFieldStyle())
                            .textContentType(.newPassword)
                    } else {
                        SecureField("Enter your password", text: $viewModel.password)
                            .textFieldStyle(AppTextFieldStyle())
                            .textContentType(.newPassword)
                    }
                    
                    Button(action: { viewModel.showPassword.toggle() }) {
                        Image(systemName: viewModel.showPassword ? "eye.slash" : "eye")
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                
                if let error = viewModel.passwordError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(AppColors.error)
                }
                
                // Password Strength Indicator
                PasswordStrengthView(strength: viewModel.passwordStrength)
            }
            
            // Confirm Password
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Confirm Password")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                HStack {
                    if viewModel.showConfirmPassword {
                        TextField("Confirm your password", text: $viewModel.confirmPassword)
                            .textFieldStyle(AppTextFieldStyle())
                            .textContentType(.newPassword)
                    } else {
                        SecureField("Confirm your password", text: $viewModel.confirmPassword)
                            .textFieldStyle(AppTextFieldStyle())
                            .textContentType(.newPassword)
                    }
                    
                    Button(action: { viewModel.showConfirmPassword.toggle() }) {
                        Image(systemName: viewModel.showConfirmPassword ? "eye.slash" : "eye")
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                
                if let error = viewModel.confirmPasswordError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(AppColors.error)
                }
            }
            
            // Referral Code (Optional)
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Referral Code (Optional)")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                TextField("Enter referral code", text: $viewModel.referralCode)
                    .textFieldStyle(AppTextFieldStyle())
                    .autocapitalization(.none)
                
                if let error = viewModel.referralCodeError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(AppColors.error)
                }
            }
            
            // Sign Up Button
            Button(action: {
                Task {
                    await viewModel.signUp()
                }
            }) {
                Text("Create Account")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(viewModel.canSubmitSignUp ? AppColors.primary : AppColors.disabled)
                    .cornerRadius(AppCornerRadius.medium)
            }
            .disabled(!viewModel.canSubmitSignUp || viewModel.isLoading)
        }
    }
    
    // MARK: - Sign In Form
    private var signInForm: some View {
        VStack(spacing: AppSpacing.lg) {
            // Email
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Email")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                TextField("Enter your email", text: $viewModel.email)
                    .textFieldStyle(AppTextFieldStyle())
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                
                if let error = viewModel.emailError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(AppColors.error)
                }
            }
            
            // Password
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Password")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                HStack {
                    if viewModel.showPassword {
                        TextField("Enter your password", text: $viewModel.password)
                            .textFieldStyle(AppTextFieldStyle())
                            .textContentType(.password)
                    } else {
                        SecureField("Enter your password", text: $viewModel.password)
                            .textFieldStyle(AppTextFieldStyle())
                            .textContentType(.password)
                    }
                    
                    Button(action: { viewModel.showPassword.toggle() }) {
                        Image(systemName: viewModel.showPassword ? "eye.slash" : "eye")
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                
                if let error = viewModel.passwordError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(AppColors.error)
                }
            }
            
            // Remember Me
            HStack {
                Toggle("Remember Me", isOn: $viewModel.rememberMe)
                    .font(.subheadline)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
            }
            
            // Sign In Button
            Button(action: {
                Task {
                    await viewModel.signIn()
                }
            }) {
                Text("Sign In")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(viewModel.canSubmitSignIn ? AppColors.primary : AppColors.disabled)
                    .cornerRadius(AppCornerRadius.medium)
            }
            .disabled(!viewModel.canSubmitSignIn || viewModel.isLoading)
        }
    }
    
    // MARK: - Social Sign In Section
    private var socialSignInSection: some View {
        VStack(spacing: AppSpacing.md) {
            // Divider
            HStack {
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(AppColors.border)
                
                Text("or")
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.horizontal, AppSpacing.md)
                
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(AppColors.border)
            }
            
            // Social Buttons
            VStack(spacing: AppSpacing.md) {
                // Sign in with Apple
                Button(action: {
                    Task {
                        await viewModel.signInWithApple()
                    }
                }) {
                    HStack {
                        Image(systemName: "applelogo")
                            .font(.title2)
                        Text("Sign in with Apple")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.black)
                    .cornerRadius(AppCornerRadius.medium)
                }
                
                // Sign in with Google
                Button(action: {
                    Task {
                        await viewModel.signInWithGoogle()
                    }
                }) {
                    HStack {
                        Image(systemName: "globe")
                            .font(.title2)
                        Text("Sign in with Google")
                            .font(.headline)
                    }
                    .foregroundColor(AppColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(AppColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                            .stroke(AppColors.border, lineWidth: 1)
                    )
                }
            }
        }
    }
    
    // MARK: - Mode Switch Section
    private var modeSwitchSection: some View {
        HStack {
            Text(viewModel.isSignUpMode ? "Already have an account?" : "Don't have an account?")
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
            
            Button(action: {
                if viewModel.isSignUpMode {
                    viewModel.switchToSignIn()
                } else {
                    viewModel.switchToSignUp()
                }
            }) {
                Text(viewModel.isSignUpMode ? "Sign In" : "Sign Up")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.primary)
            }
        }
    }
    
    // MARK: - Forgot Password Section
    private var forgotPasswordSection: some View {
        Button(action: {
            // Show forgot password alert
            viewModel.errorMessage = "Password reset functionality will be implemented with Firebase/Supabase integration."
        }) {
            Text("Forgot Password?")
                .font(.subheadline)
                .foregroundColor(AppColors.primary)
        }
    }
    
    // MARK: - Loading Overlay
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: AppSpacing.md) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                
                Text("Please wait...")
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - Password Strength View
struct PasswordStrengthView: View {
    let strength: PasswordStrength
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack {
                Text("Password Strength:")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                
                Spacer()
                
                Text(strength.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(strengthColor)
            }
            
            // Strength Bar
            HStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { index in
                    Rectangle()
                        .frame(height: 4)
                        .foregroundColor(index < strengthIndex ? strengthColor : AppColors.border)
                        .cornerRadius(2)
                }
            }
        }
    }
    
    private var strengthIndex: Int {
        switch strength {
        case .weak: return 1
        case .fair: return 2
        case .good: return 3
        case .strong: return 4
        case .veryStrong: return 5
        }
    }
    
    private var strengthColor: Color {
        switch strength {
        case .weak: return AppColors.error
        case .fair: return AppColors.warning
        case .good: return AppColors.success
        case .strong: return AppColors.success
        case .veryStrong: return AppColors.primary
        }
    }
}

// MARK: - App Text Field Style
struct AppTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(AppSpacing.md)
            .background(AppColors.surface)
            .cornerRadius(AppCornerRadius.small)
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.small)
                    .stroke(AppColors.border, lineWidth: 1)
            )
    }
}

// MARK: - Preview
#Preview {
    AuthView()
        .environment(\.router, AppRouter())
}
