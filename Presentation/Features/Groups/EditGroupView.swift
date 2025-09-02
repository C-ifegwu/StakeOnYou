import SwiftUI

// MARK: - Edit Group View
struct EditGroupView: View {
    let group: Group
    @ObservedObject var viewModel: GroupsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var groupName: String
    @State private var groupDescription: String
    @State private var isPrivate: Bool
    @State private var maxMembers: Int
    @State private var selectedCategory: GroupCategory
    @State private var hasChanges = false
    
    // MARK: - Initialization
    init(group: Group, viewModel: GroupsViewModel) {
        self.group = group
        self.viewModel = viewModel
        
        // Initialize state with current values
        self._groupName = State(initialValue: group.name)
        self._groupDescription = State(initialValue: group.description)
        self._isPrivate = State(initialValue: group.isPrivate)
        self._maxMembers = State(initialValue: group.maxMembers)
        self._selectedCategory = State(initialValue: group.category)
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            Form {
                // Basic Information Section
                Section("Basic Information") {
                    // Group Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Group Name")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("Enter group name", text: $groupName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: groupName) { _ in
                                checkForChanges()
                            }
                        
                        Text("Choose a descriptive name that reflects your group's purpose")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Group Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("Describe your group's purpose and goals", text: $groupDescription, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(3...6)
                            .onChange(of: groupDescription) { _ in
                                checkForChanges()
                            }
                        
                        Text("Explain what members can expect and what the group focuses on")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Category
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Picker("Category", selection: $selectedCategory) {
                            ForEach(GroupCategory.allCases, id: \.self) { category in
                                HStack {
                                    Image(systemName: category.icon)
                                    Text(category.displayName)
                                }
                                .tag(category)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .onChange(of: selectedCategory) { _ in
                            checkForChanges()
                        }
                        
                        Text("Select the category that best describes your group")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Settings Section
                Section("Group Settings") {
                    // Privacy Toggle
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Private Group")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("Private groups are only visible to members and require an invite code to join")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $isPrivate)
                            .onChange(of: isPrivate) { _ in
                                checkForChanges()
                            }
                    }
                    
                    // Max Members
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Maximum Members")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack {
                            Slider(value: Binding(
                                get: { Double(maxMembers) },
                                set: { maxMembers = Int($0) }
                            ), in: 5...200, step: 5)
                            .onChange(of: maxMembers) { _ in
                                checkForChanges()
                            }
                            
                            Text("\(maxMembers)")
                                .font(.headline)
                                .foregroundColor(.accentColor)
                                .frame(minWidth: 40)
                        }
                        
                        Text("Set the maximum number of members allowed in your group")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Preview Section
                Section("Preview") {
                    groupPreview
                }
                
                // Danger Zone Section
                Section {
                    Button("Delete Group") {
                        // This will be handled by the parent view
                        dismiss()
                    }
                    .foregroundColor(.red)
                } header: {
                    Text("Danger Zone")
                } footer: {
                    Text("Deleting a group will remove all members and cannot be undone.")
                }
            }
            .navigationTitle("Edit Group")
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
    
    // MARK: - Group Preview
    private var groupPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Group Avatar
                ZStack {
                    Circle()
                        .fill(selectedCategory.color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Text(String(groupName.prefix(1)).uppercased())
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(selectedCategory.color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(groupName.isEmpty ? "Group Name" : groupName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Image(systemName: isPrivate ? "lock.fill" : "globe")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(isPrivate ? "Private" : "Public")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(group.members.count)/\(maxMembers) members")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if !groupDescription.isEmpty {
                Text(groupDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            } else {
                Text("Group description will appear here")
                    .font(.subheadline)
                    .foregroundColor(.secondary.opacity(0.6))
                    .italic()
            }
            
            HStack {
                Label(selectedCategory.displayName, systemImage: selectedCategory.icon)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(selectedCategory.color.opacity(0.2))
                    .foregroundColor(selectedCategory.color)
                    .cornerRadius(8)
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Toolbar Content
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarLeading) {
            Button("Cancel") {
                dismiss()
            }
        }
        
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button("Save") {
                saveChanges()
            }
            .disabled(!hasChanges || !isFormValid)
            .opacity((hasChanges && isFormValid) ? 1.0 : 0.5)
        }
    }
    
    // MARK: - Form Validation
    private var isFormValid: Bool {
        !groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !groupDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        groupName.count >= 3 &&
        groupName.count <= 50 &&
        groupDescription.count >= 10 &&
        groupDescription.count <= 500 &&
        maxMembers >= group.members.count
    }
    
    // MARK: - Change Detection
    private func checkForChanges() {
        hasChanges = groupName != group.name ||
                    groupDescription != group.description ||
                    isPrivate != group.isPrivate ||
                    maxMembers != group.maxMembers ||
                    selectedCategory != group.category
    }
    
    // MARK: - Actions
    private func saveChanges() {
        let updatedGroup = Group(
            id: group.id,
            name: groupName.trimmingCharacters(in: .whitespacesAndNewlines),
            description: groupDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            createdBy: group.createdBy,
            members: group.members,
            inviteCode: group.inviteCode,
            isPrivate: isPrivate,
            maxMembers: maxMembers,
            category: selectedCategory,
            goals: group.goals,
            createdAt: group.createdAt,
            updatedAt: Date()
        )
        
        Task {
            await viewModel.updateGroup(updatedGroup)
            dismiss()
        }
    }
}

// MARK: - Preview
struct EditGroupView_Previews: PreviewProvider {
    static var previews: some View {
        let mockGroup = Group(
            id: "group-1",
            name: "Fitness Warriors",
            description: "A group dedicated to achieving fitness goals together. We support each other in our health and wellness journey.",
            createdBy: "user-1",
            members: [
                GroupMember(userId: "user-1", role: .admin, joinedAt: Date().addingTimeInterval(-30 * 24 * 60 * 60), isActive: true),
                GroupMember(userId: "user-2", role: .moderator, joinedAt: Date().addingTimeInterval(-25 * 24 * 60 * 60), isActive: true)
            ],
            inviteCode: "FITNESS123",
            isPrivate: false,
            maxMembers: 50,
            category: .fitness,
            goals: [],
            createdAt: Date().addingTimeInterval(-30 * 24 * 60 * 60),
            updatedAt: Date().addingTimeInterval(-5 * 24 * 60 * 60)
        )
        
        EditGroupView(
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
