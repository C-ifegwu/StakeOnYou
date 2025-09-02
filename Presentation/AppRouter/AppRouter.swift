import SwiftUI
import Combine

// MARK: - App Router
class AppRouter: ObservableObject {
    @Published var navigationPath = NavigationPath()
    @Published var presentedSheet: SheetDestination?
    @Published var presentedFullScreenCover: FullScreenDestination?
    @Published var presentedAlert: AlertDestination?
    
    // Deep linking
    @Published var pendingDeepLink: DeepLink?
    
    // Tab selection
    @Published var selectedTab: Int = 0
    
    // Navigation state
    @Published var isNavigating = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupObservers()
    }
    
    // MARK: - Navigation Methods
    func navigate(to destination: NavigationDestination) {
        isNavigating = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.navigationPath.append(destination)
            self.isNavigating = false
        }
    }
    
    func navigateBack() {
        guard !navigationPath.isEmpty else { return }
        
        isNavigating = true
        navigationPath.removeLast()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.isNavigating = false
        }
    }
    
    func navigateToRoot() {
        isNavigating = true
        navigationPath.removeLast(navigationPath.count)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.isNavigating = false
        }
    }
    
    // MARK: - Sheet Presentation
    func presentSheet(_ destination: SheetDestination) {
        presentedSheet = destination
    }
    
    func dismissSheet() {
        presentedSheet = nil
    }
    
    // MARK: - Full Screen Cover Presentation
    func presentFullScreenCover(_ destination: FullScreenDestination) {
        presentedFullScreenCover = destination
    }
    
    func dismissFullScreenCover() {
        presentedFullScreenCover = nil
    }
    
    // MARK: - Alert Presentation
    func presentAlert(_ destination: AlertDestination) {
        presentedAlert = destination
    }
    
    func dismissAlert() {
        presentedAlert = nil
    }
    
    // MARK: - Tab Navigation
    func switchToTab(_ tab: Int) {
        selectedTab = tab
    }
    
    // MARK: - Deep Linking
    func handleDeepLink(_ deepLink: DeepLink) {
        pendingDeepLink = deepLink
        processDeepLink(deepLink)
    }
    
    private func processDeepLink(_ deepLink: DeepLink) {
        switch deepLink {
        case .goal(let goalId):
            navigateToGoal(goalId)
        case .stake(let stakeId):
            navigateToStake(stakeId)
        case .group(let groupId):
            navigateToGroup(groupId)
        case .corporate(let corporateId):
            navigateToCorporate(corporateId)
        case .charity(let charityId):
            navigateToCharity(charityId)
        case .profile:
            switchToTab(4) // Profile tab
        case .goals:
            switchToTab(1) // Goals tab
        case .groups:
            switchToTab(2) // Groups tab
        case .corporate:
            switchToTab(3) // Corporate tab
        }
        
        // Clear pending deep link after processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.pendingDeepLink = nil
        }
    }
    
    // MARK: - Specific Navigation Methods
    func navigateToGoal(_ goalId: String) {
        switchToTab(1) // Goals tab
        navigate(to: .goalDetail(goalId))
    }
    
    func navigateToStake(_ stakeId: String) {
        navigate(to: .stakeDetail(stakeId))
    }
    
    func navigateToGroup(_ groupId: String) {
        switchToTab(2) // Groups tab
        navigate(to: .groupDetail(groupId))
    }
    
    func navigateToCorporate(_ corporateId: String) {
        switchToTab(3) // Corporate tab
        navigate(to: .corporateDetail(corporateId))
    }
    
    func navigateToCharity(_ charityId: String) {
        navigate(to: .charityDetail(charityId))
    }
    
    func navigateToCreateGoal() {
        presentSheet(.createGoal)
    }
    
    func navigateToStartStake(goalId: String) {
        presentSheet(.startStake(goalId))
    }
    
    func navigateToJoinGroup() {
        presentSheet(.joinGroup)
    }
    
    func navigateToSettings() {
        presentSheet(.settings)
    }
    
    // MARK: - Private Methods
    private func setupObservers() {
        // Observe navigation state changes
        $isNavigating
            .sink { [weak self] isNavigating in
                if isNavigating {
                    logInfo("Navigation started", category: "Router")
                } else {
                    logInfo("Navigation completed", category: "Router")
                }
            }
            .store(in: &cancellables)
        
        // Observe deep link changes
        $pendingDeepLink
            .compactMap { $0 }
            .sink { [weak self] deepLink in
                logInfo("Processing deep link: \(deepLink)", category: "Router")
            }
            .store(in: &cancellables)
    }
}

// MARK: - Navigation Destinations
enum NavigationDestination: Hashable {
    case goalDetail(String)
    case stakeDetail(String)
    case groupDetail(String)
    case corporateDetail(String)
    case charityDetail(String)
    case userProfile(String)
    case goalEdit(String)
    case stakeEdit(String)
    case groupEdit(String)
    case corporateEdit(String)
    case charityEdit(String)
    case goalVerification(String)
    case stakeCompletion(String)
    case groupInvite(String)
    case corporateInvite(String)
    case charityDonation(String)
    case transactionHistory
    case auditLog
    case analytics
    case reports
    case help
    case about
    case privacy
    case terms
    case support
}

// MARK: - Sheet Destinations
enum SheetDestination: Identifiable {
    case createGoal
    case editGoal(String)
    case startStake(String)
    case editStake(String)
    case createGroup
    case editGroup(String)
    case joinGroup
    case createCorporate
    case editCorporate(String)
    case createCharity
    case editCharity(String)
    case goalVerification(String)
    case stakeCompletion(String)
    case groupInvite(String)
    case corporateInvite(String)
    case charityDonation(String)
    case settings
    case profile
    case notifications
    case privacy
    case help
    case about
    case support
    
    var id: String {
        switch self {
        case .createGoal: return "createGoal"
        case .editGoal(let id): return "editGoal_\(id)"
        case .startStake(let goalId): return "startStake_\(goalId)"
        case .editStake(let id): return "editStake_\(id)"
        case .createGroup: return "createGroup"
        case .editGroup(let id): return "editGroup_\(id)"
        case .joinGroup: return "joinGroup"
        case .createCorporate: return "createCorporate"
        case .editCorporate(let id): return "editCorporate_\(id)"
        case .createCharity: return "createCharity"
        case .editCharity(let id): return "editCharity_\(id)"
        case .goalVerification(let id): return "goalVerification_\(id)"
        case .stakeCompletion(let id): return "stakeCompletion_\(id)"
        case .groupInvite(let id): return "groupInvite_\(id)"
        case .corporateInvite(let id): return "corporateInvite_\(id)"
        case .charityDonation(let id): return "charityDonation_\(id)"
        case .settings: return "settings"
        case .profile: return "profile"
        case .notifications: return "notifications"
        case .privacy: return "privacy"
        case .help: return "help"
        case .about: return "about"
        case .support: return "support"
        }
    }
}

// MARK: - Full Screen Destinations
enum FullScreenDestination: Identifiable {
    case auth
    case camera
    case photoLibrary
    case documentPicker
    case webView(URL)
    case videoPlayer(URL)
    case audioPlayer(URL)
    case map
    case calendar
    case contacts
    case healthKit
    case screenTime
    
    var id: String {
        switch self {
        case .auth: return "auth"
        case .camera: return "camera"
        case .photoLibrary: return "photoLibrary"
        case .documentPicker: return "documentPicker"
        case .webView(let url): return "webView_\(url.absoluteString)"
        case .videoPlayer(let url): return "videoPlayer_\(url.absoluteString)"
        case .audioPlayer(let url): return "audioPlayer_\(url.absoluteString)"
        case .map: return "map"
        case .calendar: return "calendar"
        case .contacts: return "contacts"
        case .healthKit: return "healthKit"
        case .screenTime: return "screenTime"
        }
    }
}

// MARK: - Alert Destinations
enum AlertDestination: Identifiable {
    case error(String, String?)
    case confirmation(String, String?, () -> Void)
    case warning(String, String?)
    case success(String, String?)
    case permissionRequest(PermissionType, String, String?)
    case goalCompletion(String, String?)
    case stakeForfeiture(String, String?)
    case groupInvitation(String, String?)
    case corporateInvitation(String, String?)
    case charityDonation(String, String?)
    
    var id: String {
        switch self {
        case .error(let title, let message): return "error_\(title)_\(message ?? "")"
        case .confirmation(let title, let message, _): return "confirmation_\(title)_\(message ?? "")"
        case .warning(let title, let message): return "warning_\(title)_\(message ?? "")"
        case .success(let title, let message): return "success_\(title)_\(message ?? "")"
        case .permissionRequest(let type, let title, let message): return "permission_\(type.rawValue)_\(title)_\(message ?? "")"
        case .goalCompletion(let title, let message): return "goalCompletion_\(title)_\(message ?? "")"
        case .stakeForfeiture(let title, let message): return "stakeForfeiture_\(title)_\(message ?? "")"
        case .groupInvitation(let title, let message): return "groupInvitation_\(title)_\(message ?? "")"
        case .corporateInvitation(let title, let message): return "corporateInvitation_\(title)_\(message ?? "")"
        case .charityDonation(let title, let message): return "charityDonation_\(title)_\(message ?? "")"
        }
    }
}

// MARK: - Deep Links
enum DeepLink: Hashable {
    case goal(String)
    case stake(String)
    case group(String)
    case corporate(String)
    case charity(String)
    case profile
    case goals
    case groups
    case corporate
    case settings
    case help
    case about
    
    var url: URL? {
        let baseURL = "stakeonyou://"
        
        switch self {
        case .goal(let id):
            return URL(string: "\(baseURL)goal/\(id)")
        case .stake(let id):
            return URL(string: "\(baseURL)stake/\(id)")
        case .group(let id):
            return URL(string: "\(baseURL)group/\(id)")
        case .corporate(let id):
            return URL(string: "\(baseURL)corporate/\(id)")
        case .charity(let id):
            return URL(string: "\(baseURL)charity/\(id)")
        case .profile:
            return URL(string: "\(baseURL)profile")
        case .goals:
            return URL(string: "\(baseURL)goals")
        case .groups:
            return URL(string: "\(baseURL)groups")
        case .corporate:
            return URL(string: "\(baseURL)corporate")
        case .settings:
            return URL(string: "\(baseURL)settings")
        case .help:
            return URL(string: "\(baseURL)help")
        case .about:
            return URL(string: "\(baseURL)about")
        }
    }
    
    init?(url: URL) {
        guard url.scheme == "stakeonyou" else { return nil }
        
        let components = url.pathComponents.filter { $0 != "/" }
        
        switch components.first {
        case "goal":
            if components.count > 1 {
                self = .goal(components[1])
            } else {
                return nil
            }
        case "stake":
            if components.count > 1 {
                self = .stake(components[1])
            } else {
                return nil
            }
        case "group":
            if components.count > 1 {
                self = .group(components[1])
            } else {
                return nil
            }
        case "corporate":
            if components.count > 1 {
                self = .corporate(components[1])
            } else {
                return nil
            }
        case "charity":
            if components.count > 1 {
                self = .charity(components[1])
            } else {
                return nil
            }
        case "profile":
            self = .profile
        case "goals":
            self = .goals
        case "groups":
            self = .groups
        case "corporate":
            self = .corporate
        case "settings":
            self = .settings
        case "help":
            self = .help
        case "about":
            self = .about
        default:
            return nil
        }
    }
}

// MARK: - Router Extensions
extension AppRouter {
    func showError(_ title: String, message: String? = nil) {
        presentAlert(.error(title, message))
    }
    
    func showConfirmation(_ title: String, message: String? = nil, action: @escaping () -> Void) {
        presentAlert(.confirmation(title, message, action))
    }
    
    func showWarning(_ title: String, message: String? = nil) {
        presentAlert(.warning(title, message))
    }
    
    func showSuccess(_ title: String, message: String? = nil) {
        presentAlert(.success(title, message))
    }
    
    func showPermissionRequest(_ type: PermissionType, title: String, message: String? = nil) {
        presentAlert(.permissionRequest(type, title, message))
    }
    
    func showGoalCompletion(_ title: String, message: String? = nil) {
        presentAlert(.goalCompletion(title, message))
    }
    
    func showStakeForfeiture(_ title: String, message: String? = nil) {
        presentAlert(.stakeForfeiture(title, message))
    }
    
    func showGroupInvitation(_ title: String, message: String? = nil) {
        presentAlert(.groupInvitation(title, message))
    }
    
    func showCorporateInvitation(_ title: String, message: String? = nil) {
        presentAlert(.corporateInvitation(title, message))
    }
    
    func showCharityDonation(_ title: String, message: String? = nil) {
        presentAlert(.charityDonation(title, message))
    }
}

// MARK: - Router Analytics
extension AppRouter {
    func trackNavigation(_ destination: NavigationDestination) {
        let eventName = "navigation"
        let properties: [String: Any] = [
            "destination": String(describing: destination),
            "timestamp": Date().timeIntervalSince1970
        ]
        
        AnalyticsService.shared.trackEvent(AnalyticsEvent(name: eventName, properties: properties))
    }
    
    func trackSheetPresentation(_ destination: SheetDestination) {
        let eventName = "sheet_presentation"
        let properties: [String: Any] = [
            "destination": destination.id,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        AnalyticsService.shared.trackEvent(AnalyticsEvent(name: eventName, properties: properties))
    }
    
    func trackDeepLink(_ deepLink: DeepLink) {
        let eventName = "deep_link"
        let properties: [String: Any] = [
            "type": String(describing: deepLink),
            "timestamp": Date().timeIntervalSince1970
        ]
        
        AnalyticsService.shared.trackEvent(AnalyticsEvent(name: eventName, properties: properties))
    }
}

// MARK: - Environment Extensions
extension EnvironmentValues {
    var router: AppRouter {
        get { AppRouter() }
        set { /* Read-only */ }
    }
}
