import SwiftUI

// MARK: - Invite Members View
struct InviteMembersView: View {
    let group: Group
    @ObservedObject var viewModel: GroupsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var inviteMethod: InviteMethod = .email
    @State private var emailAddresses: [String] = [""]
    @State private var customMessage = ""
    @State private var isInviting = false
    @State private var showInviteCode = false
    @State private var inviteCode = ""
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Content
                if inviteMethod == .email {
                    emailInviteView
                } else {
                    inviteCodeView
                }
            }
            .navigationTitle("Invite Members")
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
            
            // Invite Method Toggle
            Picker("Invite Method", selection: $inviteMethod) {
                Text("Email").tag(InviteMethod.email)
                Text("Invite Code").tag(InviteMethod.inviteCode)
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - Email Invite View
    private var emailInviteView: some View {
        Form {
            // Email Addresses Section
            Section("Email Addresses") {
                ForEach(emailAddresses.indices, id: \.self) { index in
                    HStack {
                        TextField("Enter email address", text: $emailAddresses[index])
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                        if emailAddresses.count > 1 {
                            Button(action: {
                                removeEmail(at: index)
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                
                Button("Add Another Email") {
                    addEmail()
                }
                .foregroundColor(.accentColor)
            }
            
            // Custom Message Section
            Section("Custom Message (Optional)") {
                TextField("Add a personal message to your invitation", text: $customMessage, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(3...6)
                
                Text("This message will be included in the invitation email")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Invitation Preview Section
            Section("Invitation Preview") {
                invitationPreview
            }
        }
    }
    
    // MARK: - Invite Code View
    private var inviteCodeView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon and Title
            VStack(spacing: 16) {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 60))
                    .foregroundColor(.accentColor)
                
                VStack(spacing: 8) {
                    Text("Share Invite Code")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Share this code with people you want to invite to '\(group.name)'")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Invite Code Display
            VStack(spacing: 16) {
                if showInviteCode {
                    Text(inviteCode)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.accentColor)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .textSelection(.enabled)
                } else {
                    Button("Generate Invite Code") {
                        generateInviteCode()
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                if showInviteCode {
                    VStack(spacing: 8) {
                        Text("Share this code with friends")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 16) {
                            Button("Copy") {
                                copyInviteCode()
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Share") {
                                shareInviteCode()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
            }
            .padding(.horizontal, 32)
            
            // Help Text
            VStack(spacing: 8) {
                Text("Anyone with this code can join your group")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("The code will expire in 7 days")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Invitation Preview
    private var invitationPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Invitation Preview")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Subject: You're invited to join '\(group.name)'")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Hi there!")
                    .font(.subheadline)
                
                Text("You've been invited to join '\(group.name)' on StakeOnYou.")
                    .font(.subheadline)
                
                if !customMessage.isEmpty {
                    Text(customMessage)
                        .font(.subheadline)
                        .italic()
                }
                
                Text("Click the link below to accept the invitation and start achieving your goals together!")
                    .font(.subheadline)
                
                Text("Best regards,\nThe \(group.name) team")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Toolbar Content
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarLeading) {
            Button("Cancel") {
                dismiss()
            }
        }
        
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            if inviteMethod == .email {
                Button("Send Invites") {
                    sendInvites()
                }
                .disabled(!canSendInvites)
                .opacity(canSendInvites ? 1.0 : 0.5)
            }
        }
    }
    
    // MARK: - Computed Properties
    private var canSendInvites: Bool {
        let validEmails = emailAddresses.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return !validEmails.isEmpty && validEmails.allSatisfy { isValidEmail($0) }
    }
    
    // MARK: - Helper Methods
    private func addEmail() {
        emailAddresses.append("")
    }
    
    private func removeEmail(at index: Int) {
        emailAddresses.remove(at: index)
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func generateInviteCode() {
        Task {
            await viewModel.generateInviteCode(forGroup: group)
            await MainActor.run {
                inviteCode = viewModel.inviteCode
                showInviteCode = true
            }
        }
    }
    
    private func copyInviteCode() {
        UIPasteboard.general.string = inviteCode
        // Show success feedback
    }
    
    private func shareInviteCode() {
        let shareText = "Join my group '\(group.name)' on StakeOnYou! Use invite code: \(inviteCode)"
        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
    
    // MARK: - Actions
    private func sendInvites() {
        let validEmails = emailAddresses.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        isInviting = true
        
        Task {
            for email in validEmails {
                await viewModel.inviteMember(toGroup: group, email: email.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            
            await MainActor.run {
                isInviting = false
                dismiss()
            }
        }
    }
}

// MARK: - Invite Method Enum
enum InviteMethod: String, CaseIterable {
    case email = "Email"
    case inviteCode = "Invite Code"
}

// MARK: - Preview
struct InviteMembersView_Previews: PreviewProvider {
    static var previews: some View {
        let mockGroup = Group(
            id: "group-1",
            name: "Fitness Warriors",
            description: "A group dedicated to achieving fitness goals together.",
            createdBy: "user-1",
            members: [
                GroupMember(userId: "user-1", role: .admin, joinedAt: Date().addingTimeInterval(-30 * 24 * 60 * 60), isActive: true)
            ],
            inviteCode: "FITNESS123",
            isPrivate: false,
            maxMembers: 50,
            category: .fitness,
            goals: [],
            createdAt: Date().addingTimeInterval(-30 * 24 * 60 * 60),
            updatedAt: Date().addingTimeInterval(-5 * 24 * 60 * 60)
        )
        
        InviteMembersView(
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
