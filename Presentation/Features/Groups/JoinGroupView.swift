import SwiftUI

// MARK: - Join Group View
struct JoinGroupView: View {
    @ObservedObject var viewModel: GroupsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var inviteCode = ""
    @State private var searchQuery = ""
    @State private var selectedCategory: GroupCategory?
    @State private var showPublicGroups = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Content
                if showPublicGroups {
                    publicGroupsView
                } else {
                    joinWithCodeView
                }
            }
            .navigationTitle("Join Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
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
            // Toggle between join with code and discover public groups
            Picker("Join Method", selection: $showPublicGroups) {
                Text("Join with Code").tag(false)
                Text("Discover Groups").tag(true)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            if showPublicGroups {
                // Search bar for public groups
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search public groups...", text: $searchQuery)
                        .textFieldStyle(PlainTextFieldStyle())
                    
                    if !searchQuery.isEmpty {
                        Button("Clear") {
                            searchQuery = ""
                        }
                        .foregroundColor(.accentColor)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Category filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        FilterChip(
                            title: "All Categories",
                            isSelected: selectedCategory == nil,
                            action: {
                                selectedCategory = nil
                            }
                        )
                        
                        ForEach(GroupCategory.allCases.prefix(10), id: \.self) { category in
                            FilterChip(
                                title: category.displayName,
                                isSelected: selectedCategory == category,
                                action: {
                                    selectedCategory = selectedCategory == category ? nil : category
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.top, 8)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Join with Code View
    private var joinWithCodeView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon and Title
            VStack(spacing: 16) {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 60))
                    .foregroundColor(.accentColor)
                
                VStack(spacing: 8) {
                    Text("Join a Group")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Enter the invite code provided by the group creator")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Invite Code Input
            VStack(spacing: 16) {
                TextField("Enter invite code", text: $inviteCode)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.characters)
                    .onChange(of: inviteCode) { newValue in
                        inviteCode = newValue.uppercased()
                    }
                
                Button("Join Group") {
                    joinGroup()
                }
                .buttonStyle(.borderedProminent)
                .disabled(inviteCode.isEmpty)
                .opacity(inviteCode.isEmpty ? 0.5 : 1.0)
            }
            .padding(.horizontal, 32)
            
            // Help Text
            VStack(spacing: 8) {
                Text("Don't have an invite code?")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button("Browse Public Groups") {
                    showPublicGroups = true
                }
                .font(.subheadline)
                .foregroundColor(.accentColor)
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Public Groups View
    private var publicGroupsView: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading {
                loadingView
            } else if viewModel.publicGroups.isEmpty {
                emptyPublicGroupsView
            } else {
                publicGroupsList
            }
        }
    }
    
    // MARK: - Public Groups List
    private var publicGroupsList: some View {
        List {
            ForEach(filteredPublicGroups) { group in
                PublicGroupRowView(group: group) {
                    joinPublicGroup(group)
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    // MARK: - Filtered Public Groups
    private var filteredPublicGroups: [Group] {
        var filtered = viewModel.publicGroups
        
        // Apply search filter
        if !searchQuery.isEmpty {
            filtered = filtered.filter { group in
                group.name.localizedCaseInsensitiveContains(searchQuery) ||
                group.description.localizedCaseInsensitiveContains(searchQuery)
            }
        }
        
        // Apply category filter
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        return filtered
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Searching for groups...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty Public Groups View
    private var emptyPublicGroupsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No Public Groups Found")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Try adjusting your search or filters to find more groups.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Join with Code Instead") {
                showPublicGroups = false
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Toolbar Content
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarLeading) {
            Button("Cancel") {
                dismiss()
            }
        }
        
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            if showPublicGroups {
                Button("Refresh") {
                    Task {
                        await viewModel.refreshGroups()
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    private func joinGroup() {
        guard !inviteCode.isEmpty else { return }
        
        Task {
            await viewModel.joinGroup(withInviteCode: inviteCode)
        }
    }
    
    private func joinPublicGroup(_ group: Group) {
        // For public groups, we'll generate an invite code and join
        Task {
            await viewModel.generateInviteCode(forGroup: group)
            if !viewModel.inviteCode.isEmpty {
                await viewModel.joinGroup(withInviteCode: viewModel.inviteCode)
            }
        }
    }
}

// MARK: - Public Group Row View
struct PublicGroupRowView: View {
    let group: Group
    let onJoin: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
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
            
            // Group Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(group.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Label(group.category.displayName, systemImage: group.category.icon)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(group.category.color.opacity(0.2))
                        .foregroundColor(group.category.color)
                        .cornerRadius(6)
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
                    
                    Text(group.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Join Button
            Button("Join") {
                onJoin()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview
struct JoinGroupView_Previews: PreviewProvider {
    static var previews: some View {
        JoinGroupView(viewModel: GroupsViewModel(
            groupRepository: MockGroupRepository(),
            goalRepository: MockGoalRepository(),
            userRepository: MockUserRepository(),
            notificationRepository: MockNotificationRepository()
        ))
    }
}
