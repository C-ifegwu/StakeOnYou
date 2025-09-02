import SwiftUI
import Combine

@MainActor
class GroupsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var groups: [Group] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Sheet and Alert Presentation
    @Published var presentedSheet: GroupsSheetDestination?
    @Published var presentedAlert: GroupsAlertDestination?
    
    // Filtering and Sorting
    @Published var selectedCategory: GroupCategory?
    @Published var searchText = ""
    @Published var sortOrder: GroupSortOrder = .createdDescending
    
    // MARK: - Computed Properties
    var filteredGroups: [Group] {
        var filtered = groups
        
        // Apply category filter
        if let selectedCategory = selectedCategory {
            filtered = filtered.filter { $0.category == selectedCategory }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { group in
                group.name.localizedCaseInsensitiveContains(searchText) ||
                group.description.localizedCaseInsensitiveContains(searchText) ||
                group.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Apply sorting
        filtered.sort { first, second in
            switch sortOrder {
            case .createdAscending:
                return first.createdAt < second.createdAt
            case .createdDescending:
                return first.createdAt > second.createdAt
            case .nameAscending:
                return first.name < second.name
            case .nameDescending:
                return first.name > second.name
            case .memberCountAscending:
                return first.memberIds.count < second.memberIds.count
            case .memberCountDescending:
                return first.memberIds.count > second.memberIds.count
            }
        }
        
        return filtered
    }
    
    var myGroups: [Group] {
        filteredGroups.filter { group in
            // TODO: Check if current user is owner or member
            group.ownerId == "current_user_id" || group.memberIds.contains("current_user_id")
        }
    }
    
    var publicGroups: [Group] {
        filteredGroups.filter { group in
            group.isPublic && !myGroups.contains(group)
        }
    }
    
    var invitedGroups: [Group] {
        // TODO: Implement actual invitation logic
        return []
    }
    
    var myGroupsCount: Int {
        myGroups.count
    }
    
    var activeChallengesCount: Int {
        myGroups.reduce(0) { count, group in
            count + (group.goals?.count ?? 0)
        }
    }
    
    var categories: [GroupCategory] {
        Array(Set(groups.map { $0.category })).sorted { $0.displayName < $1.displayName }
    }
    
    // MARK: - Dependencies
    private let groupRepository: GroupRepository
    private let userRepository: UserRepository
    private let analyticsService: AnalyticsService
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(
        groupRepository: GroupRepository = DIContainer.shared.resolve(GroupRepository.self),
        userRepository: UserRepository = DIContainer.shared.resolve(UserRepository.self),
        analyticsService: AnalyticsService = DIContainer.shared.resolve(AnalyticsService.self)
    ) {
        self.groupRepository = groupRepository
        self.userRepository = userRepository
        self.analyticsService = analyticsService
        
        setupObservers()
    }
    
    // MARK: - Public Methods
    func loadGroups() async {
        isLoading = true
        errorMessage = nil
        
        do {
            groups = try await groupRepository.fetchGroups()
            analyticsService.trackEvent(AnalyticsEvent(
                name: "groups_loaded",
                properties: ["count": groups.count]
            ))
        } catch {
            errorMessage = "Failed to load groups: \(error.localizedDescription)"
            logError("Failed to load groups: \(error)", category: "GroupsViewModel")
            
            analyticsService.trackError(error, context: "GroupsViewModel.loadGroups")
        }
        
        isLoading = false
    }
    
    func refreshGroups() async {
        await loadGroups()
    }
    
    func createGroup(_ group: Group) async {
        do {
            let createdGroup = try await groupRepository.createGroup(group)
            groups.append(createdGroup)
            
            analyticsService.trackEvent(AnalyticsEvent(
                name: "group_created",
                properties: [
                    "group_id": createdGroup.id,
                    "category": createdGroup.category.rawValue,
                    "is_public": createdGroup.isPublic
                ]
            ))
            
            presentedAlert = .success("Group Created", "Your group has been created successfully!")
        } catch {
            errorMessage = "Failed to create group: \(error.localizedDescription)"
            logError("Failed to create group: \(error)", category: "GroupsViewModel")
            
            analyticsService.trackError(error, context: "GroupsViewModel.createGroup")
        }
    }
    
    func updateGroup(_ group: Group) async {
        do {
            let updatedGroup = try await groupRepository.updateGroup(group)
            if let index = groups.firstIndex(where: { $0.id == updatedGroup.id }) {
                groups[index] = updatedGroup
            }
            
            analyticsService.trackEvent(AnalyticsEvent(
                name: "group_updated",
                properties: ["group_id": updatedGroup.id]
            ))
            
            presentedAlert = .success("Group Updated", "Your group has been updated successfully!")
        } catch {
            errorMessage = "Failed to update group: \(error.localizedDescription)"
            logError("Failed to update group: \(error)", category: "GroupsViewModel")
            
            analyticsService.trackError(error, context: "GroupsViewModel.updateGroup")
        }
    }
    
    func deleteGroup(_ group: Group) async {
        do {
            try await groupRepository.deleteGroup(group.id)
            groups.removeAll { $0.id == group.id }
            
            analyticsService.trackEvent(AnalyticsEvent(
                name: "group_deleted",
                properties: ["group_id": group.id]
            ))
            
            presentedAlert = .success("Group Deleted", "Your group has been deleted successfully!")
        } catch {
            errorMessage = "Failed to delete group: \(error.localizedDescription)"
            logError("Failed to delete group: \(error)", category: "GroupsViewModel")
            
            analyticsService.trackError(error, context: "GroupsViewModel.deleteGroup")
        }
    }
    
    func acceptGroupInvitation(_ groupId: String) async {
        // TODO: Implement actual invitation acceptance
        logInfo("Group invitation accepted for group: \(groupId)", category: "GroupsViewModel")
        
        analyticsService.trackEvent(AnalyticsEvent(
            name: "group_invitation_accepted",
            properties: ["group_id": groupId]
        ))
        
        presentedAlert = .groupInvitation(
            "Invitation Accepted",
            "You have successfully joined the group!"
        )
    }
    
    func declineGroupInvitation(_ groupId: String) async {
        // TODO: Implement actual invitation decline
        logInfo("Group invitation declined for group: \(groupId)", category: "GroupsViewModel")
        
        analyticsService.trackEvent(AnalyticsEvent(
            name: "group_invitation_declined",
            properties: ["group_id": groupId]
        ))
        
        presentedAlert = .groupInvitation(
            "Invitation Declined",
            "You have declined the group invitation."
        )
    }
    
    func showCreateGroup() {
        presentedSheet = .createGroup
    }
    
    func showEditGroup(_ group: Group) {
        presentedSheet = .editGroup(group.id)
    }
    
    func showJoinGroup() {
        presentedSheet = .joinGroup
    }
    
    func showGroupInvite(_ group: Group) {
        presentedSheet = .groupInvite(group.id)
    }
    
    func showGroupSettings(_ group: Group) {
        presentedSheet = .groupSettings(group.id)
    }
    
    // MARK: - Filtering and Sorting
    func applyCategoryFilter(_ category: GroupCategory?) {
        selectedCategory = category
        analyticsService.trackEvent(AnalyticsEvent(
            name: "groups_filtered",
            properties: ["filter_type": "category", "value": category?.rawValue ?? "none"]
        ))
    }
    
    func applySearchFilter(_ searchText: String) {
        self.searchText = searchText
        analyticsService.trackEvent(AnalyticsEvent(
            name: "groups_searched",
            properties: ["search_text": searchText]
        ))
    }
    
    func applySortOrder(_ sortOrder: GroupSortOrder) {
        self.sortOrder = sortOrder
        analyticsService.trackEvent(AnalyticsEvent(
            name: "groups_sorted",
            properties: ["sort_order": sortOrder.rawValue]
        ))
    }
    
    func clearFilters() {
        selectedCategory = nil
        searchText = ""
        sortOrder = .createdDescending
        
        analyticsService.trackEvent(AnalyticsEvent(
            name: "groups_filters_cleared"
        ))
    }
    
    // MARK: - Private Methods
    private func setupObservers() {
        // Observe search text changes for debounced search
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] searchText in
                self?.applySearchFilter(searchText)
            }
            .store(in: &cancellables)
        
        // Observe filter changes
        $selectedCategory
            .sink { [weak self] category in
                if let category = category {
                    self?.applyCategoryFilter(category)
                }
            }
            .store(in: &cancellables)
    }
    
    private func logError(_ message: String, category: String) {
        logError(message, category: category)
    }
}

// MARK: - Supporting Types
enum GroupSortOrder: String, CaseIterable {
    case createdAscending = "created_asc"
    case createdDescending = "created_desc"
    case nameAscending = "name_asc"
    case nameDescending = "name_desc"
    case memberCountAscending = "members_asc"
    case memberCountDescending = "members_desc"
    
    var displayName: String {
        switch self {
        case .createdAscending: return "Created (Oldest)"
        case .createdDescending: return "Created (Newest)"
        case .nameAscending: return "Name (A-Z)"
        case .nameDescending: return "Name (Z-A)"
        case .memberCountAscending: return "Members (Fewest)"
        case .memberCountDescending: return "Members (Most)"
        }
    }
}

enum GroupsSheetDestination: Identifiable {
    case createGroup
    case editGroup(String)
    case joinGroup
    case groupInvite(String)
    case groupSettings(String)
    
    var id: String {
        switch self {
        case .createGroup: return "createGroup"
        case .editGroup(let id): return "editGroup_\(id)"
        case .joinGroup: return "joinGroup"
        case .groupInvite(let groupId): return "groupInvite_\(groupId)"
        case .groupSettings(let groupId): return "groupSettings_\(groupId)"
        }
    }
}

enum GroupsAlertDestination: Identifiable {
    case error(String, String?)
    case success(String, String?)
    case confirmation(String, String?, () -> Void)
    case groupInvitation(String, String?)
    
    var id: String {
        switch self {
        case .error(let title, let message): return "error_\(title)_\(message ?? "")"
        case .success(let title, let message): return "success_\(title)_\(message ?? "")"
        case .confirmation(let title, let message, _): return "confirmation_\(title)_\(message ?? "")"
        case .groupInvitation(let title, let message): return "groupInvitation_\(title)_\(message ?? "")"
        }
    }
}

// MARK: - Extensions
extension GroupCategory {
    var color: Color {
        switch self {
        case .fitness: return .appSuccess
        case .health: return .appPrimary
        case .education: return .appInfo
        case .career: return .appWarning
        case .finance: return .appSecondary
        case .personal: return .appTextSecondary
        case .social: return .appPrimary
        case .creative: return .appSecondary
        case .travel: return .appInfo
        case .other: return .appTextSecondary
        }
    }
    
    var displayName: String {
        switch self {
        case .fitness: return "Fitness"
        case .health: return "Health"
        case .education: return "Education"
        case .career: return "Career"
        case .finance: return "Finance"
        case .personal: return "Personal"
        case .social: return "Social"
        case .creative: return "Creative"
        case .travel: return "Travel"
        case .other: return "Other"
        }
    }
}
