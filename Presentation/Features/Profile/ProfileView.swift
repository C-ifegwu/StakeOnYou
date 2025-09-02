import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @Environment(\.router) private var router
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Profile Header
                    profileHeader
                    
                    // Stats Section
                    statsSection
                    
                    // Quick Actions
                    quickActionsSection
                    
                    // Settings Sections
                    settingsSections
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.bottom, AppSpacing.xl)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { router.navigateToSettings() }) {
                        Image(systemName: "gearshape")
                            .font(.title2)
                    }
                }
            }
            .refreshable {
                await viewModel.refreshProfile()
            }
            .sheet(item: $viewModel.presentedSheet) { sheet in
                sheetView(for: sheet)
            }
            .alert(item: $viewModel.presentedAlert) { alert in
                alertView(for: alert)
            }
        }
        .onAppear {
            Task {
                await viewModel.loadProfile()
            }
        }
    }
    
    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: AppSpacing.md) {
            // Avatar
            avatarSection
            
            // User Info
            VStack(spacing: AppSpacing.xs) {
                Text(viewModel.user?.name ?? "User")
                    .font(.appTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.appTextPrimary)
                
                if let email = viewModel.user?.email {
                    Text(email)
                        .font(.appBody)
                        .foregroundColor(.appTextSecondary)
                }
                
                // Profile Completeness
                if let user = viewModel.user {
                    ProfileCompletenessView(user: user)
                }
            }
            
            // Edit Profile Button
            Button(action: { viewModel.showEditProfile() }) {
                Text("Edit Profile")
                    .font(.appLabel)
                    .fontWeight(.medium)
                    .foregroundColor(.appPrimary)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.vertical, AppSpacing.sm)
                    .background(Color.appPrimary.opacity(0.1))
                    .cornerRadius(AppSpacing.sm)
            }
        }
        .padding(AppSpacing.lg)
        .background(Color.appSurface)
        .cornerRadius(AppSpacing.md)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var avatarSection: some View {
        ZStack {
            Circle()
                .fill(Color.appPrimary.opacity(0.1))
                .frame(width: 100, height: 100)
            
            if let avatarURL = viewModel.user?.avatarURL {
                AsyncImage(url: avatarURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                } placeholder: {
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.appPrimary)
                }
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.appPrimary)
            }
            
            // Edit Avatar Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { viewModel.showEditAvatar() }) {
                        Image(systemName: "camera.fill")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(AppSpacing.xs)
                            .background(Color.appPrimary)
                            .clipShape(Circle())
                    }
                }
            }
        }
    }
    
    // MARK: - Stats Section
    private var statsSection: some View {
        VStack(spacing: AppSpacing.md) {
            Text("Your Stats")
                .font(.appHeadline)
                .fontWeight(.semibold)
                .foregroundColor(.appTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AppSpacing.md) {
                StatCard(
                    title: "Goals",
                    value: "\(viewModel.goalsCount)",
                    icon: "target",
                    color: .appPrimary
                )
                
                StatCard(
                    title: "Stakes",
                    value: "\(viewModel.stakesCount)",
                    icon: "dollarsign.circle",
                    color: .appSecondary
                )
                
                StatCard(
                    title: "Groups",
                    value: "\(viewModel.groupsCount)",
                    icon: "person.3.fill",
                    color: .appSuccess
                )
            }
        }
    }
    
    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(spacing: AppSpacing.md) {
            Text("Quick Actions")
                .font(.appHeadline)
                .fontWeight(.semibold)
                .foregroundColor(.appTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AppSpacing.md) {
                QuickActionCard(
                    title: "Create Goal",
                    subtitle: "Set a new challenge",
                    icon: "plus.circle.fill",
                    color: .appPrimary,
                    action: { router.navigateToCreateGoal() }
                )
                
                QuickActionCard(
                    title: "Join Group",
                    subtitle: "Find accountability",
                    icon: "person.3.fill",
                    color: .appSecondary,
                    action: { router.navigateToJoinGroup() }
                )
                
                QuickActionCard(
                    title: "View History",
                    subtitle: "Track progress",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .appSuccess,
                    action: { viewModel.showHistory() }
                )
                
                QuickActionCard(
                    title: "Settings",
                    subtitle: "Customize app",
                    icon: "gearshape.fill",
                    color: .appInfo,
                    action: { router.navigateToSettings() }
                )
            }
        }
    }
    
    // MARK: - Settings Sections
    private var settingsSections: some View {
        VStack(spacing: AppSpacing.lg) {
            // Account Settings
            SettingsSection(
                title: "Account",
                items: [
                    SettingsItem(
                        title: "Personal Information",
                        subtitle: "Name, email, avatar",
                        icon: "person.fill",
                        color: .appPrimary
                    ) {
                        viewModel.showEditProfile()
                    },
                    SettingsItem(
                        title: "Privacy Settings",
                        subtitle: "Data sharing, visibility",
                        icon: "lock.fill",
                        color: .appWarning
                    ) {
                        viewModel.showPrivacySettings()
                    },
                    SettingsItem(
                        title: "Notifications",
                        subtitle: "Push, email preferences",
                        icon: "bell.fill",
                        color: .appInfo
                    ) {
                        viewModel.showNotificationSettings()
                    }
                ]
            )
            
            // App Settings
            SettingsSection(
                title: "App",
                items: [
                    SettingsItem(
                        title: "Appearance",
                        subtitle: "Theme, font size",
                        icon: "paintbrush.fill",
                        color: .appSecondary
                    ) {
                        viewModel.showAppearanceSettings()
                    },
                    SettingsItem(
                        title: "Language",
                        subtitle: "Localization",
                        icon: "globe",
                        color: .appSuccess
                    ) {
                        viewModel.showLanguageSettings()
                    },
                    SettingsItem(
                        title: "Accessibility",
                        subtitle: "VoiceOver, Dynamic Type",
                        icon: "accessibility",
                        color: .appPrimary
                    ) {
                        viewModel.showAccessibilitySettings()
                    }
                ]
            )
            
            // Support & Legal
            SettingsSection(
                title: "Support & Legal",
                items: [
                    SettingsItem(
                        title: "Help & FAQ",
                        subtitle: "Get assistance",
                        icon: "questionmark.circle.fill",
                        color: .appInfo
                    ) {
                        viewModel.showHelp()
                    },
                    SettingsItem(
                        title: "Privacy Policy",
                        subtitle: "Data handling",
                        icon: "doc.text.fill",
                        color: .appWarning
                    ) {
                        viewModel.showPrivacyPolicy()
                    },
                    SettingsItem(
                        title: "Terms of Service",
                        subtitle: "Usage agreement",
                        icon: "doc.plaintext.fill",
                        color: .appTextSecondary
                    ) {
                        viewModel.showTermsOfService()
                    },
                    SettingsItem(
                        title: "Contact Support",
                        subtitle: "Get in touch",
                        icon: "envelope.fill",
                        color: .appPrimary
                    ) {
                        viewModel.showContactSupport()
                    }
                ]
            )
            
            // Danger Zone
            SettingsSection(
                title: "Danger Zone",
                items: [
                    SettingsItem(
                        title: "Export Data",
                        subtitle: "Download your data",
                        icon: "square.and.arrow.down.fill",
                        color: .appInfo
                    ) {
                        viewModel.exportData()
                    },
                    SettingsItem(
                        title: "Delete Account",
                        subtitle: "Permanently remove",
                        icon: "trash.fill",
                        color: .appError
                    ) {
                        viewModel.showDeleteAccountConfirmation()
                    }
                ]
            )
        }
    }
    
    // MARK: - Sheet Views
    @ViewBuilder
    private func sheetView(for sheet: ProfileSheetDestination) -> some View {
        switch sheet {
        case .editProfile:
            EditProfileView(user: viewModel.user)
        case .editAvatar:
            EditAvatarView()
        case .privacySettings:
            PrivacySettingsView()
        case .notificationSettings:
            NotificationSettingsView()
        case .appearanceSettings:
            AppearanceSettingsView()
        case .languageSettings:
            LanguageSettingsView()
        case .accessibilitySettings:
            AccessibilitySettingsView()
        case .help:
            HelpView()
        case .privacyPolicy:
            PrivacyPolicyView()
        case .termsOfService:
            TermsOfServiceView()
        case .contactSupport:
            ContactSupportView()
        }
    }
    
    // MARK: - Alert Views
    @ViewBuilder
    private func alertView(for alert: ProfileAlertDestination) -> some View {
        switch alert {
        case .error(let title, let message):
            Alert(
                title: Text(title),
                message: message.map { Text($0) },
                dismissButton: .default(Text("OK"))
            )
        case .confirmation(let title, let message, let action):
            Alert(
                title: Text(title),
                message: message.map { Text($0) },
                primaryButton: .default(Text("Confirm"), action: action),
                secondaryButton: .cancel()
            )
        case .deleteAccountConfirmation(let action):
            Alert(
                title: Text("Delete Account"),
                message: Text("This action cannot be undone. All your data will be permanently deleted."),
                primaryButton: .destructive(Text("Delete"), action: action),
                secondaryButton: .cancel()
            )
        }
    }
}

// MARK: - Profile Completeness View
struct ProfileCompletenessView: View {
    let user: User
    
    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            HStack {
                Text("Profile Complete")
                    .font(.caption)
                    .foregroundColor(.appTextSecondary)
                
                Spacer()
                
                Text("\(user.profileCompleteness)%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.appPrimary)
            }
            
            ProgressView(value: Double(user.profileCompleteness) / 100.0)
                .progressViewStyle(LinearProgressViewStyle(tint: .appPrimary))
                .scaleEffect(x: 1, y: 0.5, anchor: .center)
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.appTitle)
                .fontWeight(.bold)
                .foregroundColor(.appTextPrimary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.appTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(AppSpacing.md)
        .background(Color.appSurface)
        .cornerRadius(AppSpacing.sm)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Quick Action Card
struct QuickActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: AppSpacing.sm) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                VStack(spacing: AppSpacing.xxs) {
                    Text(title)
                        .font(.appLabel)
                        .fontWeight(.semibold)
                        .foregroundColor(.appTextPrimary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.appTextSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(AppSpacing.md)
            .frame(maxWidth: .infinity)
            .background(Color.appSurface)
            .cornerRadius(AppSpacing.sm)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Settings Section
struct SettingsSection: View {
    let title: String
    let items: [SettingsItem]
    
    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Text(title)
                .font(.appHeadline)
                .fontWeight(.semibold)
                .foregroundColor(.appTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    SettingsItemRow(item: item)
                    
                    if index < items.count - 1 {
                        Divider()
                            .padding(.leading, AppSpacing.xl)
                    }
                }
            }
            .background(Color.appSurface)
            .cornerRadius(AppSpacing.sm)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
}

// MARK: - Settings Item
struct SettingsItem {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
}

// MARK: - Settings Item Row
struct SettingsItemRow: View {
    let item: SettingsItem
    
    var body: some View {
        Button(action: item.action) {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: item.icon)
                    .font(.title3)
                    .foregroundColor(item.color)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(item.title)
                        .font(.appLabel)
                        .fontWeight(.medium)
                        .foregroundColor(.appTextPrimary)
                    
                    Text(item.subtitle)
                        .font(.caption)
                        .foregroundColor(.appTextSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.appTextSecondary)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environment(\.router, AppRouter())
    }
}
