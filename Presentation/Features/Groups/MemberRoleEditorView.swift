import SwiftUI

// MARK: - Member Role Editor View
struct MemberRoleEditorView: View {
    let member: GroupMember
    let group: Group
    @ObservedObject var viewModel: GroupsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedRole: GroupMemberRole
    @State private var showRemoveConfirmation = false
    @State private var hasChanges = false
    
    // MARK: - Initialization
    init(member: GroupMember, group: Group, viewModel: GroupsViewModel) {
        self.member = member
        self.group = group
        self.viewModel = viewModel
        
        // Initialize state with current role
        self._selectedRole = State(initialValue: member.role)
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            Form {
                // Member Info Section
                Section("Member Information") {
                    HStack(spacing: 12) {
                        // Member Avatar
                        ZStack {
                            Circle()
                                .fill(Color.accentColor.opacity(0.2))
                                .frame(width: 50, height: 50)
                            
                            Text(String(member.userId.prefix(1)).uppercased())
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.accentColor)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(member.userId) // In real app, get user name
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("Joined \(member.joinedAt.formatted(date: .complete, time: .omitted))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Text("Current Role:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(member.role.rawValue.capitalized)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(member.role == .admin ? Color.orange.opacity(0.2) : Color.blue.opacity(0.2))
                                    .foregroundColor(member.role == .admin ? .orange : .blue)
                                    .cornerRadius(6)
                            }
                        }
                    }
                }
                
                // Role Selection Section
                Section("Change Role") {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(GroupMemberRole.allCases, id: \.self) { role in
                            RoleOptionRow(
                                role: role,
                                isSelected: selectedRole == role,
                                isDisabled: isRoleDisabled(role),
                                onSelect: {
                                    selectedRole = role
                                    checkForChanges()
                                }
                            )
                        }
                    }
                }
                
                // Role Permissions Section
                Section("Role Permissions") {
                    permissionsForRole(selectedRole)
                }
                
                // Actions Section
                Section("Actions") {
                    Button("Save Changes") {
                        saveChanges()
                    }
                    .disabled(!hasChanges)
                    .opacity(hasChanges ? 1.0 : 0.5)
                    
                    if member.role != .admin && group.members.filter({ $0.role == .admin }).count > 1 {
                        Button("Remove Member", role: .destructive) {
                            showRemoveConfirmation = true
                        }
                    }
                }
            }
            .navigationTitle("Edit Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
            .alert("Remove Member", isPresented: $showRemoveConfirmation) {
                Button("Remove", role: .destructive) {
                    removeMember()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to remove this member from '\(group.name)'? They will need an invite code to rejoin.")
            }
        }
    }
    
    // MARK: - Role Option Row
    private func RoleOptionRow(
        role: GroupMemberRole,
        isSelected: Bool,
        isDisabled: Bool,
        onSelect: @escaping () -> Void
    ) -> some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Radio Button
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.accentColor : Color.secondary, lineWidth: 2)
                        .frame(width: 20, height: 20)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 12, height: 12)
                    }
                }
                
                // Role Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(role.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(isDisabled ? .secondary : .primary)
                        
                        if role == .admin {
                            Text("(Default)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    Text(role.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
            }
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1.0)
    }
    
    // MARK: - Role Permissions
    private func permissionsForRole(_ role: GroupMemberRole) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(role.permissions, id: \.self) { permission in
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    
                    Text(permission.displayName)
                        .font(.subheadline)
                    
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Role Validation
    private func isRoleDisabled(_ role: GroupMemberRole) -> Bool {
        // Prevent removing the last admin
        if member.role == .admin && role != .admin {
            let adminCount = group.members.filter { $0.role == .admin }.count
            if adminCount <= 1 {
                return true
            }
        }
        
        // Prevent promoting to admin if user is not admin
        if role == .admin && !group.isUserAdmin {
            return true
        }
        
        return false
    }
    
    // MARK: - Change Detection
    private func checkForChanges() {
        hasChanges = selectedRole != member.role
    }
    
    // MARK: - Toolbar Content
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarLeading) {
            Button("Cancel") {
                dismiss()
            }
        }
    }
    
    // MARK: - Actions
    private func saveChanges() {
        guard hasChanges else { return }
        
        Task {
            await viewModel.updateMemberRole(inGroupId: group.id, memberId: member.userId, newRole: selectedRole)
            dismiss()
        }
    }
    
    private func removeMember() {
        Task {
            await viewModel.removeMember(fromGroupId: group.id, memberId: member.userId)
            dismiss()
        }
    }
}

// MARK: - Group Member Role Extensions
extension GroupMemberRole {
    var displayName: String {
        switch self {
        case .admin: return "Admin"
        case .moderator: return "Moderator"
        case .member: return "Member"
        }
    }
    
    var description: String {
        switch self {
        case .admin:
            return "Full control over group settings, members, and content. Can delete the group."
        case .moderator:
            return "Can manage members, moderate content, and help with group administration."
        case .member:
            return "Can participate in group activities, invite new members, and contribute to goals."
        }
    }
    
    var permissions: [GroupPermission] {
        switch self {
        case .admin:
            return [
                .manageGroupSettings,
                .manageMembers,
                .moderateContent,
                .deleteGroup,
                .inviteMembers,
                .createGoals,
                .editGoals,
                .deleteGoals,
                .viewAnalytics,
                .exportData
            ]
        case .moderator:
            return [
                .manageMembers,
                .moderateContent,
                .inviteMembers,
                .createGoals,
                .editGoals,
                .viewAnalytics
            ]
        case .member:
            return [
                .inviteMembers,
                .createGoals,
                .editOwnGoals,
                .viewGroupContent
            ]
        }
    }
}

// MARK: - Group Permission Extensions
extension GroupPermission {
    var displayName: String {
        switch self {
        case .manageGroupSettings: return "Manage Group Settings"
        case .manageMembers: return "Manage Members"
        case .moderateContent: return "Moderate Content"
        case .deleteGroup: return "Delete Group"
        case .inviteMembers: return "Invite Members"
        case .createGoals: return "Create Goals"
        case .editGoals: return "Edit Goals"
        case .editOwnGoals: return "Edit Own Goals"
        case .deleteGoals: return "Delete Goals"
        case .viewAnalytics: return "View Analytics"
        case .exportData: return "Export Data"
        case .viewGroupContent: return "View Group Content"
        }
    }
}

// MARK: - Preview
struct MemberRoleEditorView_Previews: PreviewProvider {
    static var previews: some View {
        let mockMember = GroupMember(
            userId: "user-2",
            role: .moderator,
            joinedAt: Date().addingTimeInterval(-25 * 24 * 60 * 60),
            isActive: true
        )
        
        let mockGroup = Group(
            id: "group-1",
            name: "Fitness Warriors",
            description: "A group dedicated to achieving fitness goals together.",
            createdBy: "user-1",
            members: [
                GroupMember(userId: "user-1", role: .admin, joinedAt: Date().addingTimeInterval(-30 * 24 * 60 * 60), isActive: true),
                mockMember,
                GroupMember(userId: "user-3", role: .member, joinedAt: Date().addingTimeInterval(-20 * 24 * 60 * 60), isActive: true)
            ],
            inviteCode: "FITNESS123",
            isPrivate: false,
            maxMembers: 50,
            category: .fitness,
            goals: [],
            createdAt: Date().addingTimeInterval(-30 * 24 * 60 * 60),
            updatedAt: Date().addingTimeInterval(-5 * 24 * 60 * 60)
        )
        
        MemberRoleEditorView(
            member: mockMember,
            group: mockGroup,
            viewModel: GroupsViewModel(
                groupRepository: MockGroupRepository(),
                goalRepository: MockGoalRepository(),
                userRepository: MockUserRepository(),
                notificationRepository: MockNotificationRepository()
            )
        )
    }
}
