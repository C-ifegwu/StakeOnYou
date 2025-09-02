import SwiftUI

// MARK: - Create Group View
struct CreateGroupView: View {
    @ObservedObject var viewModel: GroupsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var groupName = ""
    @State private var groupDescription = ""
    @State private var isPrivate = false
    @State private var maxMembers = 50
    @State private var selectedCategory = GroupCategory.general
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    
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
            }
            .navigationTitle("Create Group")
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
                        
                        Text("0/\(maxMembers) members")
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
            Button("Create") {
                createGroup()
            }
            .disabled(!isFormValid)
            .opacity(isFormValid ? 1.0 : 0.5)
        }
    }
    
    // MARK: - Form Validation
    private var isFormValid: Bool {
        !groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !groupDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        groupName.count >= 3 &&
        groupName.count <= 50 &&
        groupDescription.count >= 10 &&
        groupDescription.count <= 500
    }
    
    // MARK: - Actions
    private func createGroup() {
        let newGroup = Group(
            id: "",
            name: groupName.trimmingCharacters(in: .whitespacesAndNewlines),
            description: groupDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            createdBy: "current-user-id", // Get from auth service
            members: [
                GroupMember(
                    userId: "current-user-id",
                    role: .admin,
                    joinedAt: Date(),
                    isActive: true
                )
            ],
            inviteCode: "",
            isPrivate: isPrivate,
            maxMembers: maxMembers,
            category: selectedCategory,
            goals: [],
            createdAt: Date(),
            updatedAt: Date()
        )
        
        Task {
            await viewModel.createGroup(newGroup)
        }
    }
}

// MARK: - Group Category Extensions
extension GroupCategory {
    var icon: String {
        switch self {
        case .general: return "person.3.fill"
        case .fitness: return "figure.run"
        case .education: return "book.fill"
        case .health: return "heart.fill"
        case .business: return "briefcase.fill"
        case .technology: return "laptopcomputer"
        case .creative: return "paintbrush.fill"
        case .social: return "message.fill"
        case .finance: return "dollarsign.circle.fill"
        case .travel: return "airplane"
        case .food: return "fork.knife"
        case .music: return "music.note"
        case .sports: return "sportscourt.fill"
        case .gaming: return "gamecontroller.fill"
        case .environment: return "leaf.fill"
        case .charity: return "hand.raised.fill"
        case .parenting: return "house.fill"
        case .pet: return "pawprint.fill"
        case .hobby: return "star.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .general: return .blue
        case .fitness: return .green
        case .education: return .orange
        case .health: return .red
        case .business: return .purple
        case .technology: return .indigo
        case .creative: return .pink
        case .social: return .teal
        case .finance: return .yellow
        case .travel: return .cyan
        case .food: return .brown
        case .music: return .mint
        case .sports: return .green
        case .gaming: return .purple
        case .environment: return .green
        case .charity: return .orange
        case .parenting: return .blue
        case .pet: return .brown
        case .hobby: return .pink
        case .other: return .gray
        }
    }
}

// MARK: - Preview
struct CreateGroupView_Previews: PreviewProvider {
    static var previews: some View {
        CreateGroupView(viewModel: GroupsViewModel(
            groupRepository: MockGroupRepository(),
            goalRepository: MockGoalRepository(),
            userRepository: MockUserRepository(),
            notificationRepository: MockNotificationRepository()
        ))
    }
}
