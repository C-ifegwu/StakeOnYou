import Foundation
import Combine
import SwiftUI

// MARK: - Groups View Model
@MainActor
class GroupsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var groups: [Group] = []
    @Published var filteredGroups: [Group] = []
    @Published var selectedGroup: Group?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var showCreateGroup = false
    @Published var showEditGroup = false
    @Published var showGroupDetail = false
    @Published var showJoinGroup = false
    @Published var showInviteMembers = false
    
    // MARK: - Filter and Sort Properties
    @Published var selectedPrivacy: Bool? = nil
    @Published var selectedMemberCount: Int? = nil
    @Published var sortOption: GroupSortOption = .recentActivity
    @Published var searchText = ""
    @Published var showMyGroupsOnly = false
    
    // MARK: - Group Management Properties
    @Published var inviteCode = ""
    @Published var newMemberEmail = ""
    @Published var isJoiningGroup = false
    @Published var isCreatingGroup = false
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let groupRepository: GroupRepository
    private let goalRepository: GoalRepository
    private let userRepository: UserRepository
    private let notificationRepository: NotificationRepository
    
    // MARK: - Computed Properties
    var myGroups: [Group] {
        let userId = "current-user-id" // Get from auth service
        return groups.filter { group in
            group.members.contains { $0.userId == userId } || group.createdBy == userId
        }
    }
    
    var publicGroups: [Group] {
        groups.filter { !$0.isPrivate }
    }
    
    var groupsWithDeadlines: [Group] {
        groups.filter { group in
            // Check if any group goals have upcoming deadlines
            !group.goals.isEmpty
        }
    }
    
    var activeGroups: [Group] {
        groups.filter { group in
            group.members.contains { $0.isActive }
        }
    }
    
    // MARK: - Initialization
    init(
        groupRepository: GroupRepository,
        goalRepository: GoalRepository,
        userRepository: UserRepository,
        notificationRepository: NotificationRepository
    ) {
        self.groupRepository = groupRepository
        self.goalRepository = goalRepository
        self.userRepository = userRepository
        self.notificationRepository = notificationRepository
        
        setupBindings()
    }
    
    // MARK: - Public Methods
    func loadGroups() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let userId = "current-user-id" // Get from auth service
            let userGroups = try await groupRepository.getGroups(forUserId: userId)
            let publicGroups = try await groupRepository.getPublicGroups()
            
            // Combine user's groups with public groups, removing duplicates
            var allGroups = userGroups
            for publicGroup in publicGroups {
                if !allGroups.contains(where: { $0.id == publicGroup.id }) {
                    allGroups.append(publicGroup)
                }
            }
            
            await MainActor.run {
                self.groups = allGroups
                self.applyFiltersAndSort()
                self.isLoading = false
            }
        } catch {
            await handleError(error)
        }
    }
    
    func refreshGroups() async {
        await loadGroups()
    }
    
    func createGroup(_ group: Group) async {
        isCreatingGroup = true
        errorMessage = nil
        
        do {
            let createdGroup = try await groupRepository.createGroup(group)
            
            await MainActor.run {
                self.groups.append(createdGroup)
                self.applyFiltersAndSort()
                self.isCreatingGroup = false
                self.showCreateGroup = false
            }
        } catch {
            await handleError(error)
        }
    }
    
    func updateGroup(_ group: Group) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let updatedGroup = try await groupRepository.updateGroup(group)
            
            await MainActor.run {
                if let index = self.groups.firstIndex(where: { $0.id == updatedGroup.id }) {
                    self.groups[index] = updatedGroup
                }
                self.applyFiltersAndSort()
                self.isLoading = false
                self.showEditGroup = false
            }
        } catch {
            await handleError(error)
        }
    }
    
    func deleteGroup(_ group: Group) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let success = try await groupRepository.deleteGroup(id: group.id)
            
            if success {
                await MainActor.run {
                    self.groups.removeAll { $0.id == group.id }
                    self.applyFiltersAndSort()
                    self.isLoading = false
                }
            }
        } catch {
            await handleError(error)
        }
    }
    
    func joinGroup(withInviteCode: String) async {
        isJoiningGroup = true
        errorMessage = nil
        
        do {
            let userId = "current-user-id" // Get from auth service
            let joinedGroup = try await groupRepository.joinGroup(withInviteCode: withInviteCode, userId: userId)
            
            await MainActor.run {
                // Update existing group or add new one
                if let index = self.groups.firstIndex(where: { $0.id == joinedGroup.id }) {
                    self.groups[index] = joinedGroup
                } else {
                    self.groups.append(joinedGroup)
                }
                self.applyFiltersAndSort()
                self.isJoiningGroup = false
                self.showJoinGroup = false
                self.inviteCode = ""
            }
        } catch {
            await handleError(error)
        }
    }
    
    func leaveGroup(_ group: Group) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let userId = "current-user-id" // Get from auth service
            let updatedGroup = try await groupRepository.removeMember(fromGroupId: group.id, memberId: userId)
            
            await MainActor.run {
                if let index = self.groups.firstIndex(where: { $0.id == updatedGroup.id }) {
                    self.groups[index] = updatedGroup
                }
                self.applyFiltersAndSort()
                self.isLoading = false
            }
        } catch {
            await handleError(error)
        }
    }
    
    func inviteMember(toGroup group: Group, email: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // In a real app, this would send an invitation email
            // For now, we'll just log the action
            print("Inviting \(email) to group: \(group.name)")
            
            await MainActor.run {
                self.isLoading = false
                self.showInviteMembers = false
                self.newMemberEmail = ""
            }
        } catch {
            await handleError(error)
        }
    }
    
    func updateMemberRole(inGroupId: String, memberId: String, newRole: GroupMemberRole) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let updatedGroup = try await groupRepository.updateMemberRole(inGroupId: inGroupId, memberId: memberId, newRole: newRole)
            
            await MainActor.run {
                if let index = self.groups.firstIndex(where: { $0.id == updatedGroup.id }) {
                    self.groups[index] = updatedGroup
                }
                self.applyFiltersAndSort()
                self.isLoading = false
            }
        } catch {
            await handleError(error)
        }
    }
    
    func removeMember(fromGroupId: String, memberId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let updatedGroup = try await groupRepository.removeMember(fromGroupId: fromGroupId, memberId: memberId)
            
            await MainActor.run {
                if let index = self.groups.firstIndex(where: { $0.id == updatedGroup.id }) {
                    self.groups[index] = updatedGroup
                }
                self.applyFiltersAndSort()
                self.isLoading = false
            }
        } catch {
            await handleError(error)
        }
    }
    
    func selectGroup(_ group: Group) {
        selectedGroup = group
        showGroupDetail = true
    }
    
    func clearFilters() {
        selectedPrivacy = nil
        selectedMemberCount = nil
        searchText = ""
        showMyGroupsOnly = false
        applyFiltersAndSort()
    }
    
    func generateInviteCode(forGroup group: Group) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let newInviteCode = try await groupRepository.generateInviteCode(forGroupId: group.id)
            
            await MainActor.run {
                self.inviteCode = newInviteCode
                self.isLoading = false
            }
        } catch {
            await handleError(error)
        }
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
        // Combine publishers for reactive filtering
        Publishers.CombineLatest5($selectedPrivacy, $selectedMemberCount, $searchText, $showMyGroupsOnly, $sortOption)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _, _, _, _, _ in
                self?.applyFiltersAndSort()
            }
            .store(in: &cancellables)
    }
    
    private func applyFiltersAndSort() {
        var filtered = groups
        
        // Apply privacy filter
        if let privacy = selectedPrivacy {
            filtered = filtered.filter { $0.isPrivate == privacy }
        }
        
        // Apply member count filter
        if let memberCount = selectedMemberCount {
            filtered = filtered.filter { $0.members.count >= memberCount }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { group in
                group.name.localizedCaseInsensitiveContains(searchText) ||
                group.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply my groups filter
        if showMyGroupsOnly {
            filtered = filtered.filter { group in
                let userId = "current-user-id"
                return group.members.contains { $0.userId == userId } || group.createdBy == userId
            }
        }
        
        // Apply sorting
        filtered.sort { group1, group2 in
            switch sortOption {
            case .recentActivity:
                return group1.updatedAt > group2.updatedAt
            case .name:
                return group1.name.localizedCaseInsensitiveCompare(group2.name) == .orderedAscending
            case .memberCount:
                return group1.members.count > group2.members.count
            case .createdAt:
                return group1.createdAt > group2.createdAt
            case .alphabetical:
                return group1.name.localizedCaseInsensitiveCompare(group2.name) == .orderedAscending
            }
        }
        
        filteredGroups = filtered
    }
    
    private func handleError(_ error: Error) async {
        await MainActor.run {
            self.errorMessage = error.localizedDescription
            self.showError = true
            self.isLoading = false
            self.isJoiningGroup = false
            self.isCreatingGroup = false
        }
    }
}

// MARK: - Group Sort Options
enum GroupSortOption: String, CaseIterable {
    case recentActivity = "Recent Activity"
    case name = "Name"
    case memberCount = "Member Count"
    case createdAt = "Created Date"
    case alphabetical = "Alphabetical"
    
    var icon: String {
        switch self {
        case .recentActivity: return "clock.arrow.circlepath"
        case .name: return "textformat"
        case .memberCount: return "person.3.fill"
        case .createdAt: return "calendar"
        case .alphabetical: return "abc"
        }
    }
}

// MARK: - Group Extensions
extension Group {
    var memberCountText: String {
        let count = members.count
        if count == 1 {
            return "1 member"
        } else {
            return "\(count) members"
        }
    }
    
    var isUserMember: Bool {
        let userId = "current-user-id" // Get from auth service
        return members.contains { $0.userId == userId } || createdBy == userId
    }
    
    var isUserAdmin: Bool {
        let userId = "current-user-id" // Get from auth service
        return createdBy == userId || members.first { $0.userId == userId }?.role == .admin
    }
    
    var activeMemberCount: Int {
        members.filter { $0.isActive }.count
    }
    
    var progressPercentage: Double {
        // Calculate group progress based on member goals
        guard !goals.isEmpty else { return 0.0 }
        
        let completedGoals = goals.filter { $0.status == .completed }.count
        return Double(completedGoals) / Double(goals.count)
    }
}
