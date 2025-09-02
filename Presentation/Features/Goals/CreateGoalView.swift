import SwiftUI

// MARK: - Create Goal View
struct CreateGoalView: View {
    @StateObject private var viewModel: CreateGoalViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.router) private var router
    
    init(viewModel: CreateGoalViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Goal Mode Selection
                    goalModeSection
                    
                    // Basic Information
                    basicInformationSection
                    
                    // Staking Configuration
                    if viewModel.createStake {
                        stakingSection
                    }
                    
                    // Additional Options
                    additionalOptionsSection
                    
                    // Create Button
                    createButtonSection
                }
                .padding()
            }
            .navigationTitle("Create Goal")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Reset") {
                        viewModel.resetForm()
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred")
            }
            .alert("Success", isPresented: $viewModel.showSuccess) {
                Button("Continue") {
                    if let goal = viewModel.createdGoal {
                        // Navigate to goal detail or dismiss
                        dismiss()
                    }
                }
            } message: {
                Text("Your goal has been created successfully!")
            }
            .overlay {
                if viewModel.isLoading {
                    LoadingOverlay()
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "target")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)
            
            Text("Create Your Goal")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Set a meaningful goal and optionally stake money on your success. Choose from individual, group, or corporate modes.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Goal Mode Section
    private var goalModeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Goal Mode", icon: "person.3")
            
            Picker("Goal Mode", selection: $viewModel.selectedMode) {
                ForEach([GoalMode.individual, .group, .corporate], id: \.self) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            
            // Mode-specific options
            if viewModel.selectedMode == .group {
                groupSelectionView
            } else if viewModel.selectedMode == .corporate {
                corporateSelectionView
            }
        }
    }
    
    private var groupSelectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Group")
                .font(.headline)
            
            // Placeholder for group selection
            Button(action: {
                // TODO: Show group picker
            }) {
                HStack {
                    Image(systemName: "person.3.fill")
                    Text(viewModel.selectedGroup?.name ?? "Select a group")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
    }
    
    private var corporateSelectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Corporate Account")
                .font(.headline)
            
            // Placeholder for corporate account selection
            Button(action: {
                // TODO: Show corporate account picker
            }) {
                HStack {
                    Image(systemName: "building.2.fill")
                    Text(viewModel.selectedCorporateAccount?.name ?? "Select corporate account")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Basic Information Section
    private var basicInformationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Basic Information", icon: "info.circle")
            
            // Title
            VStack(alignment: .leading, spacing: 8) {
                Text("Goal Title")
                    .font(.headline)
                
                TextField("Enter your goal title", text: $viewModel.title)
                    .textFieldStyle(.roundedBorder)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(viewModel.titleError.isEmpty ? Color.clear : Color.red, lineWidth: 1)
                    )
                
                if !viewModel.titleError.isEmpty {
                    Text(viewModel.titleError)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            // Description
            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.headline)
                
                TextEditor(text: $viewModel.description)
                    .frame(minHeight: 100)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(viewModel.descriptionError.isEmpty ? Color.clear : Color.red, lineWidth: 1)
                    )
                
                if !viewModel.descriptionError.isEmpty {
                    Text(viewModel.descriptionError)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            // Category
            VStack(alignment: .leading, spacing: 8) {
                Text("Category")
                    .font(.headline)
                
                Picker("Category", selection: $viewModel.selectedCategory) {
                    ForEach(GoalCategory.allCases, id: \.self) { category in
                        HStack {
                            Image(systemName: category.iconName)
                            Text(category.displayName)
                        }
                        .tag(category)
                    }
                }
                .pickerStyle(.menu)
            }
            
            // Dates
            VStack(alignment: .leading, spacing: 8) {
                Text("Timeline")
                    .font(.headline)
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Start Date")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        DatePicker("", selection: $viewModel.startDate, displayedComponents: .date)
                            .labelsHidden()
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("End Date")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        DatePicker("", selection: $viewModel.endDate, displayedComponents: .date)
                            .labelsHidden()
                    }
                }
                
                if !viewModel.dateError.isEmpty {
                    Text(viewModel.dateError)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            // Verification Method
            VStack(alignment: .leading, spacing: 8) {
                Text("Verification Method")
                    .font(.headline)
                
                Picker("Verification Method", selection: $viewModel.selectedVerificationMethod) {
                    ForEach(VerificationMethod.allCases, id: \.self) { method in
                        Text(method.displayName).tag(method)
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }
    
    // MARK: - Staking Section
    private var stakingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Staking Configuration", icon: "dollarsign.circle")
            
            // Stake Amount
            VStack(alignment: .leading, spacing: 8) {
                Text("Stake Amount")
                    .font(.headline)
                
                HStack {
                    TextField("0.00", text: $viewModel.stakeAmount)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)
                    
                    Picker("Currency", selection: $viewModel.selectedCurrency) {
                        ForEach(["USD", "EUR", "GBP"], id: \.self) { currency in
                            Text(currency).tag(currency)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                if !viewModel.stakeError.isEmpty {
                    Text(viewModel.stakeError)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            // APR Model
            VStack(alignment: .leading, spacing: 8) {
                Text("APR Model")
                    .font(.headline)
                
                Picker("APR Model", selection: $viewModel.selectedAPRModel) {
                    ForEach(APRModel.allCases, id: \.self) { model in
                        Text(model.displayName).tag(model)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            // Accrual Method
            VStack(alignment: .leading, spacing: 8) {
                Text("Accrual Method")
                    .font(.headline)
                
                Picker("Accrual Method", selection: $viewModel.selectedAccrualMethod) {
                    ForEach(AccrualMethod.allCases, id: \.self) { method in
                        Text(method.displayName).tag(method)
                    }
                }
                .pickerStyle(.menu)
            }
            
            // Early Completion Bonus
            VStack(alignment: .leading, spacing: 8) {
                Text("Early Completion Bonus (Optional)")
                    .font(.headline)
                
                TextField("0.00", text: $viewModel.earlyCompletionBonus)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
            }
            
            // Charity Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Charity (Optional)")
                    .font(.headline)
                
                Button(action: {
                    // TODO: Show charity picker
                }) {
                    HStack {
                        Image(systemName: "heart.fill")
                        Text(viewModel.selectedCharity?.name ?? "Select a charity")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
        }
    }
    
    // MARK: - Additional Options Section
    private var additionalOptionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Additional Options", icon: "plus.circle")
            
            // Staking Toggle
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Create a Stake", isOn: $viewModel.createStake)
                    .font(.headline)
                
                Text("Stake money on your goal to earn interest and stay motivated")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Tags
            VStack(alignment: .leading, spacing: 8) {
                Text("Tags")
                    .font(.headline)
                
                HStack {
                    TextField("Add a tag", text: $viewModel.newTag)
                        .textFieldStyle(.roundedBorder)
                    
                    Button("Add") {
                        viewModel.addTag()
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                if !viewModel.tags.isEmpty {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                        ForEach(viewModel.tags, id: \.self) { tag in
                            TagView(tag: tag) {
                                viewModel.removeTag(tag)
                            }
                        }
                    }
                }
            }
            
            // Milestones
            VStack(alignment: .leading, spacing: 8) {
                Text("Milestones")
                    .font(.headline)
                
                VStack(spacing: 12) {
                    HStack {
                        TextField("Milestone title", text: $viewModel.newMilestoneTitle)
                            .textFieldStyle(.roundedBorder)
                        
                        DatePicker("", selection: $viewModel.newMilestoneDate, displayedComponents: .date)
                            .labelsHidden()
                    }
                    
                    TextField("Description (optional)", text: $viewModel.newMilestoneDescription)
                        .textFieldStyle(.roundedBorder)
                    
                    Button("Add Milestone") {
                        viewModel.addMilestone()
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.newMilestoneTitle.isEmpty)
                }
                
                if !viewModel.milestones.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(viewModel.milestones) { milestone in
                            MilestoneRow(milestone: milestone) {
                                viewModel.removeMilestone(milestone)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Create Button Section
    private var createButtonSection: some View {
        VStack(spacing: 16) {
            Button(action: {
                Task {
                    await viewModel.createGoal()
                }
            }) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "plus.circle.fill")
                    }
                    
                    Text(viewModel.isLoading ? "Creating..." : "Create Goal")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.canCreateGoal ? Color.accentColor : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!viewModel.canCreateGoal || viewModel.isLoading)
            
            Text("By creating this goal, you agree to our terms and conditions")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Supporting Views
struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
            
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
            
            Spacer()
        }
    }
}

struct TagView: View {
    let tag: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.accentColor.opacity(0.2))
                .foregroundColor(.accentColor)
                .cornerRadius(12)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
}

struct MilestoneRow: View {
    let milestone: Milestone
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(milestone.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if !milestone.description.isEmpty {
                    Text(milestone.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(milestone.targetDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onRemove) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text("Creating your goal...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(24)
            .background(Color(.systemGray6).opacity(0.9))
            .cornerRadius(16)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Extensions
extension GoalMode {
    var displayName: String {
        switch self {
        case .individual: return "Individual"
        case .group: return "Group"
        case .corporate: return "Corporate"
        }
    }
}

// MARK: - Preview
struct CreateGoalView_Previews: PreviewProvider {
    static var previews: some View {
        CreateGoalView(viewModel: CreateGoalViewModel(
            createGoalUseCase: CreateGoalUseCase(
                goalRepository: MockGoalRepository(),
                stakeRepository: MockStakeRepository(),
                userRepository: MockUserRepository(),
                groupRepository: MockGroupRepository(),
                corporateRepository: MockCorporateRepository(),
                validationService: MockValidationService(),
                analyticsService: MockAnalyticsService()
            ),
            userRepository: MockUserRepository(),
            groupRepository: MockGroupRepository(),
            corporateRepository: MockCorporateRepository(),
            charityRepository: MockCharityRepository(),
            analyticsService: MockAnalyticsService()
        ))
    }
}

// MARK: - Mock Implementations for Preview
struct MockGoalRepository: GoalRepository {
    func createGoal(_ goal: Goal) async throws -> Goal { return goal }
    func getGoal(id: String) async throws -> Goal { throw GoalRepositoryError.goalNotFound }
    func updateGoal(_ goal: Goal) async throws -> Goal { return goal }
    func deleteGoal(id: String) async throws -> Bool { return true }
    func getGoals(forUserId: String) async throws -> [Goal] { return [] }
    func getGoals(forGroupId: String) async throws -> [Goal] { return [] }
    func getGoals(forCorporateAccountId: String) async throws -> [Goal] { return [] }
    func getGoals(byStatus: GoalStatus) async throws -> [Goal] { return [] }
    func getGoals(byCategory: GoalCategory) async throws -> [Goal] { return [] }
    func getGoals(byDateRange: DateInterval) async throws -> [Goal] { return [] }
    func searchGoals(query: String, userId: String?) async throws -> [Goal] { return [] }
    func getGoalsWithStakes(forUserId: String) async throws -> [GoalWithStake] { return [] }
    func getGoalStatistics(forUserId: String) async throws -> GoalStatistics { 
        return GoalStatistics(totalGoals: 0, activeGoals: 0, completedGoals: 0, failedGoals: 0, totalStakeAmount: 0, averageCompletionTime: 0, successRate: 0.0)
    }
    func getGoalCompletionRate(forUserId: String, timeRange: TimeRange) async throws -> Double { return 0.0 }
    func bulkUpdateGoals(_ goals: [Goal]) async throws -> [Goal] { return goals }
    func deleteExpiredGoals() async throws -> Int { return 0 }
}

struct MockStakeRepository: StakeRepository {
    func createStake(_ stake: Stake) async throws -> Stake { return stake }
    func getStake(id: String) async throws -> Stake { throw StakeRepositoryError.stakeNotFound }
    func getStake(forGoalId: String) async throws -> Stake? { return nil }
    func updateStake(_ stake: Stake) async throws -> Stake { return stake }
    func deleteStake(id: String) async throws -> Bool { return true }
    func getStakes(forUserId: String) async throws -> [Stake] { return [] }
    func getStakes(forGroupId: String) async throws -> [Stake] { return [] }
    func getStakes(forCorporateAccountId: String) async throws -> [Stake] { return [] }
    func getStakes(byStatus: StakeStatus) async throws -> [Stake] { return [] }
    func getStakes(byAPRModel: APRModel) async throws -> [Stake] { return [] }
    func getStakes(byAccrualMethod: AccrualMethod) async throws -> [Stake] { return [] }
    func getTotalStakeValue(forUserId: String) async throws -> Decimal { return 0 }
    func getTotalAccruedAmount(forUserId: String) async throws -> Decimal { return 0 }
    func getStakesByValueRange(min: Decimal, max: Decimal) async throws -> [Stake] { return [] }
    func updateAccruedAmount(forStakeId: String, newAmount: Decimal) async throws -> Stake { throw StakeRepositoryError.stakeNotFound }
    func processDailyAccrual() async throws -> [Stake] { return [] }
    func getStakesRequiringAccrual() async throws -> [Stake] { return [] }
    func getStakeStatistics(forUserId: String) async throws -> StakeStatistics { 
        return StakeStatistics(totalStakes: 0, activeStakes: 0, completedStakes: 0, failedStakes: 0, totalPrincipal: 0, totalAccrued: 0, averageAPR: 0, successRate: 0.0)
    }
    func getStakePerformance(forUserId: String, timeRange: TimeRange) async throws -> StakePerformance { 
        return StakePerformance(totalReturn: 0, returnRate: 0, duration: 0, riskScore: 0.0, volatility: 0.0)
    }
    func getTopPerformingStakes(forUserId: String, limit: Int) async throws -> [StakeWithPerformance] { return [] }
    func bulkUpdateStakes(_ stakes: [Stake]) async throws -> [Stake] { return stakes }
    func processBatchAccrual(stakeIds: [String]) async throws -> [Stake] { return [] }
}

struct MockUserRepository: UserRepository {
    func getCurrentUser() async throws -> User { 
        return User(id: "mock", email: "mock@example.com", fullName: "Mock User")
    }
}

struct MockGroupRepository: GroupRepository {
    func getGroup(id: String) async throws -> Group { 
        return Group(id: "mock", name: "Mock Group", description: "Mock", ownerId: "mock", members: ["mock"])
    }
}

struct MockCorporateRepository: CorporateAccountRepository {
    func getCorporateAccount(id: String) async throws -> CorporateAccount { 
        return CorporateAccount(id: "mock", name: "Mock Corp", description: "Mock", ownerId: "mock", employees: ["mock"])
    }
}

struct MockValidationService: ValidationService {
    func validateEmail(_ email: String) -> ValidationResult { return .success }
    func validatePassword(_ password: String) -> ValidationResult { return .success }
    func validateFullName(_ name: String) -> ValidationResult { return .success }
    func validateReferralCode(_ code: String?) -> ValidationResult { return .success }
    func calculatePasswordStrength(_ password: String) -> PasswordStrength { return .strong }
}

struct MockCharityRepository: CharityRepository {
    func getCharities() async throws -> [Charity] { return [] }
}

struct MockAnalyticsService: AnalyticsService {
    func track(_ event: AnalyticsEvent) { }
}
