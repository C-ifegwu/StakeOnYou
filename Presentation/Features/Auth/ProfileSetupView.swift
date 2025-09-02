import SwiftUI

// MARK: - Profile Setup View
struct ProfileSetupView: View {
    @StateObject private var viewModel = ProfileSetupViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.router) private var router
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    // Header
                    headerSection
                    
                    // Profile Form
                    profileFormSection
                    
                    // Preferences Section
                    preferencesSection
                    
                    // Privacy Section
                    privacySection
                    
                    // Complete Setup Button
                    completeSetupButton
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.xl)
            }
            .navigationTitle("Complete Your Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") {
                        completeProfileSetup()
                    }
                    .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: AppSpacing.md) {
            // Success Icon
            ZStack {
                Circle()
                    .fill(AppColors.success.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(AppColors.success)
            }
            
            Text("Welcome to StakeOnYou!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.center)
            
            Text("Let's complete your profile to get started")
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Profile Form Section
    private var profileFormSection: some View {
        VStack(spacing: AppSpacing.lg) {
            SectionHeader(title: "Basic Information", icon: "person.circle")
            
            VStack(spacing: AppSpacing.md) {
                // Profile Picture
                VStack(spacing: AppSpacing.sm) {
                    Button(action: { viewModel.showImagePicker = true }) {
                        ZStack {
                            if let profileImage = viewModel.profileImage {
                                Image(uiImage: profileImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(AppColors.surface)
                                    .frame(width: 100, height: 100)
                                    .overlay(
                                        Circle()
                                            .stroke(AppColors.border, lineWidth: 2)
                                    )
                                
                                Image(systemName: "camera.fill")
                                    .font(.title2)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                    }
                    
                    Text("Tap to add photo")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                // Display Name
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Display Name")
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    TextField("Enter your display name", text: $viewModel.displayName)
                        .textFieldStyle(AppTextFieldStyle())
                        .textContentType(.name)
                        .autocapitalization(.words)
                }
                
                // Bio
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Bio (Optional)")
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    TextField("Tell us about yourself", text: $viewModel.bio, axis: .vertical)
                        .textFieldStyle(AppTextFieldStyle())
                        .lineLimit(3...6)
                }
                
                // Date of Birth
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Date of Birth")
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    DatePicker(
                        "Select your date of birth",
                        selection: $viewModel.dateOfBirth,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.sm)
                    .background(AppColors.surface)
                    .cornerRadius(AppCornerRadius.small)
                }
            }
        }
    }
    
    // MARK: - Preferences Section
    private var preferencesSection: some View {
        VStack(spacing: AppSpacing.lg) {
            SectionHeader(title: "Preferences", icon: "gearshape")
            
            VStack(spacing: AppSpacing.md) {
                // Notification Preferences
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Notifications")
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    VStack(spacing: AppSpacing.sm) {
                        Toggle("Push Notifications", isOn: $viewModel.pushNotificationsEnabled)
                            .font(.subheadline)
                        
                        Toggle("Email Updates", isOn: $viewModel.emailUpdatesEnabled)
                            .font(.subheadline)
                        
                        Toggle("Goal Reminders", isOn: $viewModel.goalRemindersEnabled)
                            .font(.subheadline)
                        
                        Toggle("Stake Alerts", isOn: $viewModel.stakeAlertsEnabled)
                            .font(.subheadline)
                    }
                }
                
                // App Preferences
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("App Settings")
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    VStack(spacing: AppSpacing.sm) {
                        Toggle("Dark Mode", isOn: $viewModel.darkModeEnabled)
                            .font(.subheadline)
                        
                        Toggle("Haptic Feedback", isOn: $viewModel.hapticFeedbackEnabled)
                            .font(.subheadline)
                        
                        Toggle("Sound Effects", isOn: $viewModel.soundEffectsEnabled)
                            .font(.subheadline)
                    }
                }
            }
        }
    }
    
    // MARK: - Privacy Section
    private var privacySection: some View {
        VStack(spacing: AppSpacing.lg) {
            SectionHeader(title: "Privacy & Security", icon: "lock.shield")
            
            VStack(spacing: AppSpacing.md) {
                // Privacy Settings
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Privacy")
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    VStack(spacing: AppSpacing.sm) {
                        Toggle("Public Profile", isOn: $viewModel.publicProfileEnabled)
                            .font(.subheadline)
                        
                        Toggle("Show Progress", isOn: $viewModel.showProgressEnabled)
                            .font(.subheadline)
                        
                        Toggle("Allow Friend Requests", isOn: $viewModel.allowFriendRequestsEnabled)
                            .font(.subheadline)
                    }
                }
                
                // Data Sharing
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Data Sharing")
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    VStack(spacing: AppSpacing.sm) {
                        Toggle("Analytics", isOn: $viewModel.analyticsEnabled)
                            .font(.subheadline)
                        
                        Toggle("Crash Reports", isOn: $viewModel.crashReportsEnabled)
                            .font(.subheadline)
                        
                        Toggle("Usage Statistics", isOn: $viewModel.usageStatisticsEnabled)
                            .font(.subheadline)
                    }
                }
            }
        }
    }
    
    // MARK: - Complete Setup Button
    private var completeSetupButton: some View {
        Button(action: {
            Task {
                await viewModel.completeProfileSetup()
                completeProfileSetup()
            }
        }) {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                }
                
                Text(viewModel.isLoading ? "Setting up..." : "Complete Setup")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(viewModel.canCompleteSetup ? AppColors.primary : AppColors.disabled)
            .cornerRadius(AppCornerRadius.medium)
        }
        .disabled(!viewModel.canCompleteSetup || viewModel.isLoading)
    }
    
    // MARK: - Private Methods
    private func completeProfileSetup() {
        // Navigate to main app
        router.navigateToRoot()
        dismiss()
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(AppColors.primary)
            
            Text(title)
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
            
            Spacer()
        }
        .padding(.horizontal, AppSpacing.sm)
    }
}

// MARK: - Profile Setup View Model
@MainActor
class ProfileSetupViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var profileImage: UIImage?
    @Published var displayName = ""
    @Published var bio = ""
    @Published var dateOfBirth = Date()
    
    // Notification Preferences
    @Published var pushNotificationsEnabled = true
    @Published var emailUpdatesEnabled = true
    @Published var goalRemindersEnabled = true
    @Published var stakeAlertsEnabled = true
    
    // App Preferences
    @Published var darkModeEnabled = false
    @Published var hapticFeedbackEnabled = true
    @Published var soundEffectsEnabled = true
    
    // Privacy Settings
    @Published var publicProfileEnabled = false
    @Published var showProgressEnabled = true
    @Published var allowFriendRequestsEnabled = true
    
    // Data Sharing
    @Published var analyticsEnabled = true
    @Published var crashReportsEnabled = true
    @Published var usageStatisticsEnabled = false
    
    // UI State
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showImagePicker = false
    
    // MARK: - Computed Properties
    var canCompleteSetup: Bool {
        !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Public Methods
    func completeProfileSetup() async {
        guard canCompleteSetup else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Save profile data
            try await saveProfileData()
            
            // Update user preferences
            try await updateUserPreferences()
            
            // Track completion
            trackAnalyticsEvent("profile_setup_completed", properties: [
                "has_profile_image": profileImage != nil,
                "has_bio": !bio.isEmpty,
                "notifications_enabled": pushNotificationsEnabled,
                "privacy_level": publicProfileEnabled ? "public" : "private"
            ])
            
        } catch {
            errorMessage = "Failed to save profile: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Private Methods
    private func saveProfileData() async throws {
        // This would typically save to your backend/database
        // For now, we'll just simulate a delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        logInfo("Profile data saved successfully", category: "ProfileSetup")
    }
    
    private func updateUserPreferences() async throws {
        // This would typically update user preferences in your backend/database
        // For now, we'll just simulate a delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        logInfo("User preferences updated successfully", category: "ProfileSetup")
    }
}

// MARK: - Preview
#Preview {
    ProfileSetupView()
        .environment(\.router, AppRouter())
}
