import SwiftUI

// MARK: - Biometric Prompt View
struct BiometricPromptView: View {
    @ObservedObject var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: AppSpacing.xl) {
                // Header
                headerSection
                
                // Biometric Icon
                biometricIconSection
                
                // Description
                descriptionSection
                
                // Benefits
                benefitsSection
                
                // Action Buttons
                actionButtonsSection
                
                Spacer()
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.xl)
            .navigationTitle("Enable \(viewModel.biometricTypeDisplayName)")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") {
                        viewModel.skipBiometricSetup()
                        dismiss()
                    }
                    .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: AppSpacing.md) {
            Text("Quick & Secure Access")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.center)
            
            Text("Use \(viewModel.biometricTypeDisplayName) to sign in without entering your password")
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Biometric Icon Section
    private var biometricIconSection: some View {
        VStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(AppColors.primary.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: viewModel.biometricIconName)
                    .font(.system(size: 50, weight: .medium))
                    .foregroundColor(AppColors.primary)
            }
            
            Text(viewModel.biometricTypeDisplayName)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary)
        }
    }
    
    // MARK: - Description Section
    private var descriptionSection: some View {
        VStack(spacing: AppSpacing.md) {
            Text("How it works:")
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
            
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                BenefitRow(
                    icon: "1.circle.fill",
                    title: "Authenticate",
                    description: "Use \(viewModel.biometricTypeDisplayName.lowercased()) to verify your identity"
                )
                
                BenefitRow(
                    icon: "2.circle.fill",
                    title: "Instant Access",
                    description: "Sign in quickly without typing passwords"
                )
                
                BenefitRow(
                    icon: "3.circle.fill",
                    title: "Secure",
                    description: "Your biometric data stays on your device"
                )
            }
        }
    }
    
    // MARK: - Benefits Section
    private var benefitsSection: some View {
        VStack(spacing: AppSpacing.md) {
            Text("Benefits:")
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
            
            VStack(spacing: AppSpacing.sm) {
                BenefitItem(
                    icon: "bolt.fill",
                    title: "Faster Sign In",
                    description: "No more typing passwords"
                )
                
                BenefitItem(
                    icon: "lock.shield.fill",
                    title: "Enhanced Security",
                    description: "Biometric verification is more secure than passwords"
                )
                
                BenefitItem(
                    icon: "hand.raised.fill",
                    title: "Privacy First",
                    description: "Your biometric data never leaves your device"
                )
            }
        }
    }
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        VStack(spacing: AppSpacing.md) {
            // Enable Button
            Button(action: {
                Task {
                    await viewModel.enableBiometrics()
                    dismiss()
                }
            }) {
                HStack {
                    Image(systemName: viewModel.biometricIconName)
                        .font(.title3)
                    Text("Enable \(viewModel.biometricTypeDisplayName)")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(AppColors.primary)
                .cornerRadius(AppCornerRadius.medium)
            }
            
            // Skip Button
            Button(action: {
                viewModel.skipBiometricSetup()
                dismiss()
            }) {
                Text("Maybe Later")
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }
}

// MARK: - Benefit Row
struct BenefitRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(AppColors.primary)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Benefit Item
struct BenefitItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(AppColors.success)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.small)
    }
}

// MARK: - Biometric Authentication View
struct BiometricAuthenticationView: View {
    @ObservedObject var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: AppSpacing.xl) {
                // Header
                VStack(spacing: AppSpacing.md) {
                    Text("Welcome Back!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Use \(viewModel.biometricTypeDisplayName) to sign in")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                // Biometric Icon
                ZStack {
                    Circle()
                        .fill(AppColors.primary.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: viewModel.biometricIconName)
                        .font(.system(size: 50, weight: .medium))
                        .foregroundColor(AppColors.primary)
                }
                
                // Action Button
                Button(action: {
                    Task {
                        await viewModel.authenticateWithBiometrics()
                        dismiss()
                    }
                }) {
                    HStack {
                        Image(systemName: viewModel.biometricIconName)
                            .font(.title3)
                        Text("Sign in with \(viewModel.biometricTypeDisplayName)")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(AppColors.primary)
                    .cornerRadius(AppCornerRadius.medium)
                }
                
                // Alternative Options
                VStack(spacing: AppSpacing.md) {
                    Text("Or")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Button("Use Password Instead") {
                        // Switch to password authentication
                        dismiss()
                    }
                    .font(.subheadline)
                    .foregroundColor(AppColors.primary)
                }
                
                Spacer()
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.xl)
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Preview
#Preview {
    BiometricPromptView(viewModel: AuthViewModel())
}
