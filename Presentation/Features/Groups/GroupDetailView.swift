import SwiftUI

// MARK: - Group Detail View
struct GroupDetailView: View {
    let group: Group
    @ObservedObject var viewModel: GroupsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTab = 0
    @State private var showEditGroup = false
    @State private var showInviteMembers = false
    @State private var showGroupSettings = false
    @State private var showLeaveConfirmation = false
    @State private var showDeleteConfirmation = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Tab Content
                TabView(selection: $selectedTab) {
                    overviewTab
                        .tag(0)
                    
                    membersTab
                        .tag(1)
                    
                    goalsTab
                        .tag(2)
                    
                    activityTab
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle(group.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
            .sheet(isPresented: $showEditGroup) {
                EditGroupView(group: group, viewModel: viewModel)
            }
            .sheet(isPresented: $showInviteMembers) {
                InviteMembersView(group: group, viewModel: viewModel)
            }
            .sheet(isPresented: $showGroupSettings) {
                GroupSettingsView(group: group, viewModel: viewModel)
            }
            .alert("Leave Group", isPresented: $showLeaveConfirmation) {
                Button("Leave", role: .destructive) {
                    leaveGroup()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to leave '\(group.name)'? You'll need an invite code to rejoin.")
            }
            .alert("Delete Group", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    deleteGroup()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete '\(group.name)'? This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 16) {
            // Group Avatar and Info
            HStack(spacing: 16) {
                // Group Avatar
                ZStack {
                    Circle()
                        .fill(group.category.color.opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    Text(String(group.name.prefix(1)).uppercased())
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(group.category.color)
                }
                
                // Group Info
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(group.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if group.isPrivate {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    Text(group.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    HStack(spacing: 16) {
                        Label(group.memberCountText, systemImage: "person.3.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if !group.goals.isEmpty {
                            Label("\(group.goals.count) goals", systemImage: "target")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
            }
            
            // Category Badge
            HStack {
                Label(group.category.displayName, systemImage: group.category.icon)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(group.category.color.opacity(0.2))
                    .foregroundColor(group.category.color)
                    .cornerRadius(8)
                
                Spacer()
                
                // Progress Indicator
                if !group.goals.isEmpty {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(Int(group.progressPercentage * 100))%")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.accentColor)
                        
                        Text("Complete")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Tab Picker
            Picker("Tab", selection: $selectedTab) {
                Text("Overview").tag(0)
                Text("Members").tag(1)
                Text("Goals").tag(2)
                Text("Activity").tag(3)
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - Overview Tab
    private var overviewTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Quick Stats
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    StatCard(
                        title: "Members",
                        value: "\(group.members.count)",
                        icon: "person.3.fill",
                        color: .blue
                    )
                    
                    StatCard(
                        title: "Goals",
                        value: "\(group.goals.count)",
                        icon: "target",
                        color: .green
                    )
                    
                    StatCard(
                        title: "Active",
                        value: "\(group.activeMemberCount)",
                        icon: "checkmark.circle.fill",
                        color: .orange
                    )
                    
                    StatCard(
                        title: "Created",
                        value: group.createdAt.formatted(date: .abbreviated, time: .omitted),
                        icon: "calendar",
                        color: .purple
                    )
                }
                
                // Recent Activity
                if !group.goals.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Activity")
                            .font(.headline)
                        
                        ForEach(group.goals.prefix(3)) { goal in
                            GoalActivityRow(goal: goal)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                // Group Rules/Info
                VStack(alignment: .leading, spacing: 12) {
                    Text("Group Information")
                        .font(.headline)
                    
                    InfoRow(title: "Privacy", value: group.isPrivate ? "Private" : "Public")
                    InfoRow(title: "Max Members", value: "\(group.maxMembers)")
                    InfoRow(title: "Created", value: group.createdAt.formatted(date: .complete, time: .omitted))
                    InfoRow(title: "Last Updated", value: group.updatedAt.formatted(date: .complete, time: .omitted))
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding()
        }
    }
    
    // MARK: - Members Tab
    private var membersTab: some View {
        List {
            ForEach(group.members) { member in
                MemberRow(member: member, group: group)
            }
        }
        .listStyle(PlainListStyle())
    }
    
    // MARK: - Goals Tab
    private var goalsTab: some View {
        if group.goals.isEmpty {
            VStack(spacing: 20) {
                Image(systemName: "target")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)
                
                VStack(spacing: 8) {
                    Text("No Goals Yet")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("This group hasn't created any goals yet.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                if group.isUserAdmin {
                    Button("Create Goal") {
                        // Navigate to create goal
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                ForEach(group.goals) { goal in
                    GoalRow(goal: goal)
                }
            }
            .listStyle(PlainListStyle())
        }
    }
    
    // MARK: - Activity Tab
    private var activityTab: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("Activity Feed")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Group activity and progress updates will appear here.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Toolbar Content
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarLeading) {
            Button("Done") {
                dismiss()
            }
        }
        
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Menu {
                if group.isUserAdmin {
                    Button("Edit Group") {
                        showEditGroup = true
                    }
                    
                    Button("Invite Members") {
                        showInviteMembers = true
                    }
                    
                    Button("Group Settings") {
                        showGroupSettings = true
                    }
                    
                    Divider()
                    
                    Button("Delete Group", role: .destructive) {
                        showDeleteConfirmation = true
                    }
                } else {
                    Button("Invite Members") {
                        showInviteMembers = true
                    }
                    
                    Divider()
                    
                    Button("Leave Group", role: .destructive) {
                        showLeaveConfirmation = true
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }
    
    // MARK: - Actions
    private func leaveGroup() {
        Task {
            await viewModel.leaveGroup(group)
            dismiss()
        }
    }
    
    private func deleteGroup() {
        Task {
            await viewModel.deleteGroup(group)
            dismiss()
        }
    }
}

// MARK: - Supporting Views
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

struct GoalActivityRow: View {
    let goal: Goal
    
    var body: some View {
        HStack {
            Image(systemName: "target")
                .font(.caption)
                .foregroundColor(.accentColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(goal.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(Int(goal.progress * 100))% complete")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct MemberRow: View {
    let member: GroupMember
    let group: Group
    
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
        }
        .padding(.vertical, 4)
    }
}

struct GoalRow: View {
    let goal: Goal
    
    var body: some View {
        HStack(spacing: 12) {
            // Goal Icon
            ZStack {
                Circle()
                    .fill(goal.category.color.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: goal.category.icon)
                    .font(.subheadline)
                    .foregroundColor(goal.category.color)
            }
            
            // Goal Info
            VStack(alignment: .leading, spacing: 4) {
                Text(goal.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(goal.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Text("\(Int(goal.progress * 100))% complete")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                    
                    Spacer()
                    
                    Text(goal.deadline, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
struct GroupDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let mockGroup = Group(
            id: "group-1",
            name: "Fitness Warriors",
            description: "A group dedicated to achieving fitness goals together. We support each other in our health and wellness journey.",
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
            goals: [
                Goal(
                    id: "goal-1",
                    title: "Run 5K",
                    description: "Complete a 5K run",
                    category: .fitness,
                    difficulty: .medium,
                    deadline: Date().addingTimeInterval(30 * 24 * 60 * 60),
                    userId: "user-1",
                    isCorporate: false,
                    corporateAccountId: nil,
                    milestones: [],
                    attachments: [],
                    notes: [],
                    createdAt: Date().addingTimeInterval(-10 * 24 * 60 * 60),
                    updatedAt: Date().addingTimeInterval(-5 * 24 * 60 * 60)
                )
            ],
            createdAt: Date().addingTimeInterval(-30 * 24 * 60 * 60),
            updatedAt: Date().addingTimeInterval(-5 * 24 * 60 * 60)
        )
        
        GroupDetailView(
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
