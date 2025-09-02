import SwiftUI

// MARK: - Groups View
struct GroupsView: View {
    @StateObject private var viewModel: GroupsViewModel
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Initialization
    init(
        groupRepository: GroupRepository,
        goalRepository: GoalRepository,
        userRepository: UserRepository,
        notificationRepository: NotificationRepository
    ) {
        self._viewModel = StateObject(wrappedValue: GroupsViewModel(
            groupRepository: groupRepository,
            goalRepository: goalRepository,
            userRepository: userRepository,
            notificationRepository: notificationRepository
        ))
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with search and filters
                headerView
                
                // Content
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.filteredGroups.isEmpty {
                    emptyStateView
                } else {
                    groupsListView
                }
            }
            .navigationTitle("Groups")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                toolbarContent
            }
            .refreshable {
                await viewModel.refreshGroups()
            }
            .task {
                await viewModel.loadGroups()
            }
            .sheet(isPresented: $viewModel.showCreateGroup) {
                CreateGroupView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showJoinGroup) {
                JoinGroupView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showGroupDetail) {
                if let group = viewModel.selectedGroup {
                    GroupDetailView(group: group, viewModel: viewModel)
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
            // Search bar
            searchBar
            
            // Filter chips
            filterChips
            
            // Sort options
            sortOptions
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search groups...", text: $viewModel.searchText)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !viewModel.searchText.isEmpty {
                Button("Clear") {
                    viewModel.searchText = ""
                }
                .foregroundColor(.accentColor)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    // MARK: - Filter Chips
    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // My Groups Only
                FilterChip(
                    title: "My Groups",
                    isSelected: viewModel.showMyGroupsOnly,
                    action: {
                        viewModel.showMyGroupsOnly.toggle()
                    }
                )
                
                // Privacy Filter
                if let privacy = viewModel.selectedPrivacy {
                    FilterChip(
                        title: privacy ? "Private" : "Public",
                        isSelected: true,
                        action: {
                            viewModel.selectedPrivacy = nil
                        }
                    )
                } else {
                    FilterChip(
                        title: "All Privacy",
                        isSelected: false,
                        action: {
                            // Show privacy picker
                        }
                    )
                }
                
                // Member Count Filter
                if let memberCount = viewModel.selectedMemberCount {
                    FilterChip(
                        title: "\(memberCount)+ Members",
                        isSelected: true,
                        action: {
                            viewModel.selectedMemberCount = nil
                        }
                    )
                } else {
                    FilterChip(
                        title: "Any Size",
                        isSelected: false,
                        action: {
                            // Show member count picker
                        }
                    )
                }
                
                // Clear Filters
                if viewModel.showMyGroupsOnly || viewModel.selectedPrivacy != nil || viewModel.selectedMemberCount != nil {
                    FilterChip(
                        title: "Clear All",
                        isSelected: false,
                        action: {
                            viewModel.clearFilters()
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Sort Options
    private var sortOptions: some View {
        HStack {
            Text("Sort by:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Picker("Sort", selection: $viewModel.sortOption) {
                ForEach(GroupSortOption.allCases, id: \.self) { option in
                    HStack {
                        Image(systemName: option.icon)
                        Text(option.rawValue)
                    }
                    .tag(option)
                }
            }
            .pickerStyle(MenuPickerStyle())
            
            Spacer()
        }
    }
    
    // MARK: - Groups List View
    private var groupsListView: some View {
        List {
            ForEach(viewModel.filteredGroups) { group in
                GroupRowView(group: group) {
                    viewModel.selectGroup(group)
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading groups...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No Groups Found")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Try adjusting your filters or create a new group to get started.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Create Group") {
                viewModel.showCreateGroup = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Toolbar Content
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button("Join") {
                viewModel.showJoinGroup = true
            }
            
            Button("Create") {
                viewModel.showCreateGroup = true
            }
        }
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

// MARK: - Group Row View
struct GroupRowView: View {
    let group: Group
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Group Avatar
                groupAvatar
                
                // Group Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(group.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if group.isPrivate {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if group.isUserMember {
                            Text("Member")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.accentColor.opacity(0.2))
                                .foregroundColor(.accentColor)
                                .cornerRadius(8)
                        }
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
                        
                        Text(group.updatedAt, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var groupAvatar: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor.opacity(0.2))
                .frame(width: 50, height: 50)
            
            Text(String(group.name.prefix(1)).uppercased())
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.accentColor)
        }
    }
}

// MARK: - Preview
struct GroupsView_Previews: PreviewProvider {
    static var previews: some View {
        GroupsView(
            groupRepository: MockGroupRepository(),
            goalRepository: MockGoalRepository(),
            userRepository: MockUserRepository(),
            notificationRepository: MockNotificationRepository()
        )
    }
}
