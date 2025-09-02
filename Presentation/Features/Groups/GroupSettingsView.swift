import SwiftUI

// MARK: - Group Settings View
struct GroupSettingsView: View {
    let group: Group
    @ObservedObject var viewModel: GroupsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTab = 0
    @State private var showMemberRoleEditor = false
    @State private var selectedMember: GroupMember?
    @State private var showNotificationSettings = false
    @State private var showPrivacySettings = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Tab Content
                TabView(selection: $selectedTab) {
                    generalSettingsTab
                        .tag(0)
                    
                    memberManagementTab
                        .tag(1)
                    
                    notificationSettingsTab
                        .tag(2)
                    
                    privacySecurityTab
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Group Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
            .sheet(isPresented: $showMemberRoleEditor) {
                if let member = selectedMember {
                    MemberRoleEditorView(member: member, group: group, viewModel: viewModel)
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred")
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 16) {
            // Group Info
            HStack(spacing: 12) {
                // Group Avatar
                ZStack {
                    Circle()
                        .fill(group.category.color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Text(String(group.name.prefix(1)).uppercased())
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(group.category.color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("\(group.members.count)/\(group.maxMembers) members")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Tab Picker
            Picker("Settings Tab", selection: $selectedTab) {
                Text("General").tag(0)
                Text("Members").tag(1)
                Text("Notifications").tag(2)
                Text("Privacy").tag(3)
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - General Settings Tab
    private var generalSettingsTab: some View {
        Form {
            // Group Information Section
            Section("Group Information") {
                InfoRow(title: "Name", value: group.name)
                InfoRow(title: "Description", value: group.description)
                InfoRow(title: "Category", value: group.category.displayName)
                InfoRow(title: "Created", value: group.createdAt.formatted(date: .complete, time: .omitted))
                InfoRow(title: "Last Updated", value: group.updatedAt.formatted(date: .complete, time: .omitted))
            }
            
            // Group Statistics Section
            Section("Group Statistics") {
                InfoRow(title: "Total Members", value: "\(group.members.count)")
                InfoRow(title: "Active Members", value: "\(group.activeMemberCount)")
                InfoRow(title: "Total Goals", value: "\(group.goals.count)")
                InfoRow(title: "Completion Rate", value: "\(Int(group.progressPercentage * 100))%")
            }
            
            // Quick Actions Section
            Section("Quick Actions") {
                Button("Edit Group") {
                    // Navigate to edit group
                }
                
                Button("Generate New Invite Code") {
                    Task {
                        await viewModel.generateInviteCode(forGroup: group)
                    }
                }
                
                Button("Export Group Data") {
                    // Export functionality
                }
            }
        }
    }
    
    // MARK: - Member Management Tab
    private var memberManagementTab: some View {
        Form {
            // Member List Section
            Section("Members (\(group.members.count))") {
                ForEach(group.members) { member in
                    MemberSettingsRow(member: member, group: group) {
                        selectedMember = member
                        showMemberRoleEditor = true
                    }
                }
            }
            
            // Member Actions Section
            Section("Member Actions") {
                Button("Invite New Members") {
                    // Navigate to invite members
                }
                
                Button("Remove Inactive Members") {
                    // Remove inactive members
                }
                .foregroundColor(.orange)
                
                Button("Export Member List") {
                    // Export member list
                }
            }
            
            // Role Management Section
            Section("Role Management") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Admin")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("Can edit group settings, manage members, and delete the group")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Moderator")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("Can manage members and moderate group content")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Member")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("Can participate in group activities and invite new members")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Notification Settings Tab
    private var notificationSettingsTab: some View {
        Form {
            // Group Notifications Section
            Section("Group Notifications") {
                Toggle("New Member Joins", isOn: .constant(true))
                Toggle("Goal Updates", isOn: .constant(true))
                Toggle("Milestone Achievements", isOn: .constant(true))
                Toggle("Group Announcements", isOn: .constant(true))
                Toggle("Weekly Progress Reports", isOn: .constant(false))
            }
            
            // Notification Frequency Section
            Section("Notification Frequency") {
                Picker("Default Frequency", selection: .constant(NotificationFrequency.immediate)) {
                    ForEach(NotificationFrequency.allCases, id: \.self) { frequency in
                        Text(frequency.displayName).tag(frequency)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            // Quiet Hours Section
            Section("Quiet Hours") {
                Toggle("Enable Quiet Hours", isOn: .constant(false))
                
                HStack {
                    Text("Start Time")
                    Spacer()
                    Text("9:00 PM")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("End Time")
                    Spacer()
                    Text("8:00 AM")
                        .foregroundColor(.secondary)
                }
            }
            
            // Notification Channels Section
            Section("Notification Channels") {
                Toggle("Push Notifications", isOn: .constant(true))
                Toggle("Email Notifications", isOn: .constant(false))
                Toggle("In-App Notifications", isOn: .constant(true))
            }
        }
    }
    
    // MARK: - Privacy Security Tab
    private var privacySecurityTab: some View {
        Form {
            // Privacy Settings Section
            Section("Privacy Settings") {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Group Visibility")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(group.isPrivate ? "Private - Only members can see this group" : "Public - Anyone can see this group")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Change") {
                        showPrivacySettings = true
                    }
                    .foregroundColor(.accentColor)
                }
                
                Toggle("Show Member List to Non-Members", isOn: .constant(false))
                Toggle("Allow Member Invitations", isOn: .constant(true))
                Toggle("Show Group Goals to Non-Members", isOn: .constant(false))
            }
            
            // Security Settings Section
            Section("Security Settings") {
                Toggle("Require Admin Approval for New Members", isOn: .constant(false))
                Toggle("Two-Factor Authentication for Admins", isOn: .constant(false))
                Toggle("Audit Log for Member Actions", isOn: .constant(true))
            }
            
            // Content Moderation Section
            Section("Content Moderation") {
                Toggle("Auto-Moderate Content", isOn: .constant(true))
                Toggle("Require Admin Review for Goals", isOn: .constant(false))
                Toggle("Filter Inappropriate Language", isOn: .constant(true))
            }
            
            // Data Retention Section
            Section("Data Retention") {
                Picker("Message Retention", selection: .constant(DataRetention.oneYear)) {
                    ForEach(DataRetention.allCases, id: \.self) { retention in
                        Text(retention.displayName).tag(retention)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                
                Picker("Goal History Retention", selection: .constant(DataRetention.forever)) {
                    ForEach(DataRetention.allCases, id: \.self) { retention in
                        Text(retention.displayName).tag(retention)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
        }
    }
    
    // MARK: - Toolbar Content
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarLeading) {
            Button("Done") {
                dismiss()
            }
        }
        
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button("Save") {
                // Save settings
                dismiss()
            }
        }
    }
}

// MARK: - Supporting Views
struct MemberSettingsRow: View {
    let member: GroupMember
    let group: Group
    let onEditRole: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Member Avatar
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Text(String(member.userId.prefix(1)).uppercased())
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.accentColor)
            }
            
            // Member Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(member.userId) // In real app, get user name
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text(member.role.rawValue.capitalized)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(member.role == .admin ? Color.orange.opacity(0.2) : Color.blue.opacity(0.2))
                        .foregroundColor(member.role == .admin ? .orange : .blue)
                        .cornerRadius(6)
                }
                
                HStack {
                    Text("Joined \(member.joinedAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if member.isActive {
                        Text("Active")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Text("Inactive")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Edit Button
            if group.isUserAdmin && member.userId != "current-user-id" {
                Button("Edit") {
                    onEditRole()
                }
                .font(.caption)
                .foregroundColor(.accentColor)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Enums
enum NotificationFrequency: String, CaseIterable {
    case immediate = "immediate"
    case hourly = "hourly"
    case daily = "daily"
    case weekly = "weekly"
    
    var displayName: String {
        switch self {
        case .immediate: return "Immediate"
        case .hourly: return "Hourly"
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        }
    }
}

enum DataRetention: String, CaseIterable {
    case oneWeek = "oneWeek"
    case oneMonth = "oneMonth"
    case threeMonths = "threeMonths"
    case sixMonths = "sixMonths"
    case oneYear = "oneYear"
    case forever = "forever"
    
    var displayName: String {
        switch self {
        case .oneWeek: return "1 Week"
        case .oneMonth: return "1 Month"
        case .threeMonths: return "3 Months"
        case .sixMonths: return "6 Months"
        case .oneYear: return "1 Year"
        case .forever: return "Forever"
        }
    }
}

// MARK: - Preview
struct GroupSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        let mockGroup = Group(
            id: "group-1",
            name: "Fitness Warriors",
            description: "A group dedicated to achieving fitness goals together.",
            createdBy: "user-1",
            members: [
                GroupMember(userId: "user-1", role: .admin, joinedAt: Date().addingTimeInterval(-30 * 24 * 60 * 60), isActive: true),
                GroupMember(userId: "user-2", role: .moderator, joinedAt: Date().addingTimeInterval(-25 * 24 * 60 * 60), isActive: true),
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
        
        GroupSettingsView(
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
