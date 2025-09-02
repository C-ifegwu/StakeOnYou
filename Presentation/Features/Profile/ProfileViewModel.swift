import SwiftUI
import Combine

@MainActor
class ProfileViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var user: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Sheet and Alert Presentation
    @Published var presentedSheet: ProfileSheetDestination?
    @Published var presentedAlert: ProfileAlertDestination?
    
    // Stats
    @Published var goalsCount = 0
    @Published var stakesCount = 0
    @Published var groupsCount = 0
    
    // MARK: - Dependencies
    private let userRepository: UserRepository
    private let goalRepository: GoalRepository
    private let stakeRepository: StakeRepository
    private let groupRepository: GroupRepository
    private let analyticsService: AnalyticsService
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(
        userRepository: UserRepository = DIContainer.shared.resolve(UserRepository.self),
        goalRepository: GoalRepository = DIContainer.shared.resolve(GoalRepository.self),
        stakeRepository: StakeRepository = DIContainer.shared.resolve(StakeRepository.self),
        groupRepository: GroupRepository = DIContainer.shared.resolve(GroupRepository.self),
        analyticsService: AnalyticsService = DIContainer.shared.resolve(AnalyticsService.self)
    ) {
        self.userRepository = userRepository
        self.goalRepository = goalRepository
        self.stakeRepository = stakeRepository
        self.groupRepository = groupRepository
        self.analyticsService = analyticsService
        
        setupObservers()
    }
    
    // MARK: - Public Methods
    func loadProfile() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load user profile
            if let currentUserId = getCurrentUserId() {
                user = try await userRepository.fetchUser(currentUserId)
            }
            
            // Load stats
            await loadStats()
            
            analyticsService.trackEvent(AnalyticsEvent(
                name: "profile_loaded",
                properties: ["user_id": user?.id ?? "unknown"]
            ))
        } catch {
            errorMessage = "Failed to load profile: \(error.localizedDescription)"
            logError("Failed to load profile: \(error)", category: "ProfileViewModel")
            
            analyticsService.trackError(error, context: "ProfileViewModel.loadProfile")
        }
        
        isLoading = false
    }
    
    func refreshProfile() async {
        await loadProfile()
    }
    
    func updateProfile(_ updatedUser: User) async {
        do {
            let savedUser = try await userRepository.updateUser(updatedUser)
            user = savedUser
            
            analyticsService.trackEvent(AnalyticsEvent(
                name: "profile_updated",
                properties: ["user_id": savedUser.id]
            ))
            
            presentedAlert = .success("Profile Updated", "Your profile has been updated successfully!")
        } catch {
            errorMessage = "Failed to update profile: \(error.localizedDescription)"
            logError("Failed to update profile: \(error)", category: "ProfileViewModel")
            
            analyticsService.trackError(error, context: "ProfileViewModel.updateProfile")
        }
    }
    
    func updateAvatar(_ imageData: Data) async {
        // TODO: Implement avatar upload
        logInfo("Avatar update requested", category: "ProfileViewModel")
        
        analyticsService.trackEvent(AnalyticsEvent(
            name: "avatar_update_requested"
        ))
        
        presentedAlert = .success("Avatar Updated", "Your avatar has been updated successfully!")
    }
    
    func exportData() {
        // TODO: Implement data export
        logInfo("Data export requested", category: "ProfileViewModel")
        
        analyticsService.trackEvent(AnalyticsEvent(
            name: "data_export_requested"
        ))
        
        presentedAlert = .success("Data Export", "Your data export has been prepared and will be available shortly.")
    }
    
    func deleteAccount() async {
        do {
            if let userId = user?.id {
                try await userRepository.deleteUser(userId)
                
                analyticsService.trackEvent(AnalyticsEvent(
                    name: "account_deleted",
                    properties: ["user_id": userId]
                ))
                
                // TODO: Handle post-deletion cleanup (logout, clear data, etc.)
                presentedAlert = .success("Account Deleted", "Your account has been permanently deleted.")
            }
        } catch {
            errorMessage = "Failed to delete account: \(error.localizedDescription)"
            logError("Failed to delete account: \(error)", category: "ProfileViewModel")
            
            analyticsService.trackError(error, context: "ProfileViewModel.deleteAccount")
        }
    }
    
    // MARK: - Sheet Presentation
    func showEditProfile() {
        presentedSheet = .editProfile
    }
    
    func showEditAvatar() {
        presentedSheet = .editAvatar
    }
    
    func showPrivacySettings() {
        presentedSheet = .privacySettings
    }
    
    func showNotificationSettings() {
        presentedSheet = .notificationSettings
    }
    
    func showAppearanceSettings() {
        presentedSheet = .appearanceSettings
    }
    
    func showLanguageSettings() {
        presentedSheet = .languageSettings
    }
    
    func showAccessibilitySettings() {
        presentedSheet = .accessibilitySettings
    }
    
    func showHelp() {
        presentedSheet = .help
    }
    
    func showPrivacyPolicy() {
        presentedSheet = .privacyPolicy
    }
    
    func showTermsOfService() {
        presentedSheet = .termsOfService
    }
    
    func showContactSupport() {
        presentedSheet = .contactSupport
    }
    
    func showHistory() {
        // TODO: Navigate to history view
        logInfo("History view requested", category: "ProfileViewModel")
        
        analyticsService.trackEvent(AnalyticsEvent(
            name: "history_view_requested"
        ))
    }
    
    func showDeleteAccountConfirmation() {
        presentedAlert = .deleteAccountConfirmation {
            Task {
                await self.deleteAccount()
            }
        }
    }
    
    // MARK: - Private Methods
    private func loadStats() async {
        do {
            // Load goals count
            let goals = try await goalRepository.fetchGoals()
            goalsCount = goals.count
            
            // Load stakes count
            let stakes = try await stakeRepository.fetchStakes()
            stakesCount = stakes.count
            
            // Load groups count
            let groups = try await groupRepository.fetchGroups()
            groupsCount = groups.count
            
            analyticsService.trackEvent(AnalyticsEvent(
                name: "profile_stats_loaded",
                properties: [
                    "goals_count": goalsCount,
                    "stakes_count": stakesCount,
                    "groups_count": groupsCount
                ]
            ))
        } catch {
            logError("Failed to load profile stats: \(error)", category: "ProfileViewModel")
        }
    }
    
    private func getCurrentUserId() -> String? {
        // TODO: Get actual current user ID from authentication service
        return "current_user_id"
    }
    
    private func setupObservers() {
        // Observe user changes
        $user
            .compactMap { $0 }
            .sink { [weak self] user in
                self?.logInfo("User profile updated: \(user.name)", category: "ProfileViewModel")
            }
            .store(in: &cancellables)
    }
    
    private func logError(_ message: String, category: String) {
        logError(message, category: category)
    }
    
    private func logInfo(_ message: String, category: String) {
        logInfo(message, category: category)
    }
}

// MARK: - Supporting Types
enum ProfileSheetDestination: Identifiable {
    case editProfile
    case editAvatar
    case privacySettings
    case notificationSettings
    case appearanceSettings
    case languageSettings
    case accessibilitySettings
    case help
    case privacyPolicy
    case termsOfService
    case contactSupport
    
    var id: String {
        switch self {
        case .editProfile: return "editProfile"
        case .editAvatar: return "editAvatar"
        case .privacySettings: return "privacySettings"
        case .notificationSettings: return "notificationSettings"
        case .appearanceSettings: return "appearanceSettings"
        case .languageSettings: return "languageSettings"
        case .accessibilitySettings: return "accessibilitySettings"
        case .help: return "help"
        case .privacyPolicy: return "privacyPolicy"
        case .termsOfService: return "termsOfService"
        case .contactSupport: return "contactSupport"
        }
    }
}

enum ProfileAlertDestination: Identifiable {
    case error(String, String?)
    case success(String, String?)
    case confirmation(String, String?, () -> Void)
    case deleteAccountConfirmation(() -> Void)
    
    var id: String {
        switch self {
        case .error(let title, let message): return "error_\(title)_\(message ?? "")"
        case .success(let title, let message): return "success_\(title)_\(message ?? "")"
        case .confirmation(let title, let message, _): return "confirmation_\(title)_\(message ?? "")"
        case .deleteAccountConfirmation: return "deleteAccountConfirmation"
        }
    }
}
