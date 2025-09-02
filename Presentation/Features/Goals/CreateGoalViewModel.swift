import Foundation
import SwiftUI
import Combine

// MARK: - Create Goal View Model
@MainActor
class CreateGoalViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var showSuccess = false
    @Published var createdGoal: Goal?
    
    // MARK: - Form Properties
    @Published var title = ""
    @Published var description = ""
    @Published var selectedCategory: GoalCategory = .fitness
    @Published var startDate = Date()
    @Published var endDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    @Published var selectedVerificationMethod: VerificationMethod = .manual
    
    // MARK: - Staking Properties
    @Published var createStake = false
    @Published var stakeAmount = ""
    @Published var selectedCurrency = "USD"
    @Published var selectedAPRModel: APRModel = .fixed
    @Published var selectedAccrualMethod: AccrualMethod = .daily
    @Published var earlyCompletionBonus = ""
    @Published var selectedCharity: Charity?
    
    // MARK: - Mode Properties
    @Published var selectedMode: GoalMode = .individual
    @Published var selectedGroup: Group?
    @Published var selectedCorporateAccount: CorporateAccount?
    
    // MARK: - Additional Properties
    @Published var tags: [String] = []
    @Published var newTag = ""
    @Published var milestones: [Milestone] = []
    @Published var newMilestoneTitle = ""
    @Published var newMilestoneDescription = ""
    @Published var newMilestoneDate = Date()
    
    // MARK: - Validation Properties
    @Published var titleError = ""
    @Published var descriptionError = ""
    @Published var dateError = ""
    @Published var stakeError = ""
    
    // MARK: - Dependencies
    private let createGoalUseCase: CreateGoalUseCase
    private let userRepository: UserRepository
    private let groupRepository: GroupRepository
    private let corporateRepository: CorporateAccountRepository
    private let charityRepository: CharityRepository
    private let analyticsService: AnalyticsService
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(
        createGoalUseCase: CreateGoalUseCase,
        userRepository: UserRepository,
        groupRepository: GroupRepository,
        corporateRepository: CorporateAccountRepository,
        charityRepository: CharityRepository,
        analyticsService: AnalyticsService
    ) {
        self.createGoalUseCase = createGoalUseCase
        self.userRepository = userRepository
        self.groupRepository = groupRepository
        self.corporateRepository = corporateRepository
        self.charityRepository = charityRepository
        self.analyticsService = analyticsService
        
        setupBindings()
    }
    
    // MARK: - Public Methods
    func createGoal() async {
        guard validateForm() else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let currentUser = try await userRepository.getCurrentUser()
            
            let stakeRequest: StakeRequest?
            if createStake {
                guard let amount = Decimal(string: stakeAmount), amount > 0 else {
                    stakeError = "Please enter a valid stake amount"
                    isLoading = false
                    return
                }
                
                stakeRequest = StakeRequest(
                    principal: amount,
                    currency: selectedCurrency,
                    aprModel: selectedAPRModel,
                    accrualMethod: selectedAccrualMethod,
                    feeRateOnStake: 0.05, // 5% default
                    feeRateOnWithdrawal: 0.02, // 2% default
                    earlyCompletionBonus: Decimal(string: earlyCompletionBonus),
                    charityId: selectedCharity?.id
                )
            } else {
                stakeRequest = nil
            }
            
            let request = CreateGoalRequest(
                mode: selectedMode,
                ownerId: currentUser.id,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                description: description.trimmingCharacters(in: .whitespacesAndNewlines),
                category: selectedCategory,
                startDate: startDate,
                endDate: endDate,
                verificationMethod: selectedVerificationMethod,
                tags: tags,
                milestones: milestones,
                createStake: createStake,
                stakeRequest: stakeRequest,
                groupId: selectedGroup?.id,
                corporateAccountId: selectedCorporateAccount?.id
            )
            
            let result = try await createGoalUseCase.execute(request: request)
            
            createdGoal = result.goal
            
            // Track analytics
            analyticsService.track(
                .createGoal(
                    mode: selectedMode,
                    category: selectedCategory,
                    hasStake: result.stake != nil
                )
            )
            
            showSuccess = true
            
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            
            // Track error analytics
            analyticsService.track(
                .createGoalError(
                    mode: selectedMode,
                    category: selectedCategory,
                    error: error.localizedDescription
                )
            )
        }
        
        isLoading = false
    }
    
    func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTag.isEmpty, !tags.contains(trimmedTag) else {
            newTag = ""
            return
        }
        
        tags.append(trimmedTag)
        newTag = ""
    }
    
    func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
    
    func addMilestone() {
        let trimmedTitle = newMilestoneTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = newMilestoneDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedTitle.isEmpty else { return }
        
        let milestone = Milestone(
            title: trimmedTitle,
            description: trimmedDescription,
            targetDate: newMilestoneDate
        )
        
        milestones.append(milestone)
        
        // Reset form
        newMilestoneTitle = ""
        newMilestoneDescription = ""
        newMilestoneDate = Date()
    }
    
    func removeMilestone(_ milestone: Milestone) {
        milestones.removeAll { $0.id == milestone.id }
    }
    
    func resetForm() {
        title = ""
        description = ""
        selectedCategory = .fitness
        startDate = Date()
        endDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
        selectedVerificationMethod = .manual
        createStake = false
        stakeAmount = ""
        selectedCurrency = "USD"
        selectedAPRModel = .fixed
        selectedAccrualMethod = .daily
        earlyCompletionBonus = ""
        selectedCharity = nil
        selectedMode = .individual
        selectedGroup = nil
        selectedCorporateAccount = nil
        tags = []
        milestones = []
        clearValidationErrors()
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
        // Auto-validate title
        $title
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] title in
                self?.validateTitle(title)
            }
            .store(in: &cancellables)
        
        // Auto-validate description
        $description
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] description in
                self?.validateDescription(description)
            }
            .store(in: &cancellables)
        
        // Auto-validate dates
        Publishers.CombineLatest($startDate, $endDate)
            .sink { [weak self] startDate, endDate in
                self?.validateDates(startDate: startDate, endDate: endDate)
            }
            .store(in: &cancellables)
        
        // Auto-validate stake amount
        $stakeAmount
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] amount in
                self?.validateStakeAmount(amount)
            }
            .store(in: &cancellables)
    }
    
    private func validateForm() -> Bool {
        let titleValid = validateTitle(title)
        let descriptionValid = validateDescription(description)
        let datesValid = validateDates(startDate: startDate, endDate: endDate)
        let stakeValid = createStake ? validateStakeAmount(stakeAmount) : true
        
        return titleValid && descriptionValid && datesValid && stakeValid
    }
    
    private func validateTitle(_ title: String) -> Bool {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            titleError = "Title is required"
            return false
        }
        
        if trimmed.count < 3 {
            titleError = "Title must be at least 3 characters"
            return false
        }
        
        if trimmed.count > 100 {
            titleError = "Title must be less than 100 characters"
            return false
        }
        
        titleError = ""
        return true
    }
    
    private func validateDescription(_ description: String) -> Bool {
        let trimmed = description.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            descriptionError = "Description is required"
            return false
        }
        
        if trimmed.count < 10 {
            descriptionError = "Description must be at least 10 characters"
            return false
        }
        
        if trimmed.count > 1000 {
            descriptionError = "Description must be less than 1000 characters"
            return false
        }
        
        descriptionError = ""
        return true
    }
    
    private func validateDates(startDate: Date, endDate: Date) -> Bool {
        if startDate >= endDate {
            dateError = "Start date must be before end date"
            return false
        }
        
        if endDate < Date() {
            dateError = "End date cannot be in the past"
            return false
        }
        
        let calendar = Calendar.current
        let daysDifference = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        
        if daysDifference < 1 {
            dateError = "Goal must be at least 1 day long"
            return false
        }
        
        if daysDifference > 365 {
            dateError = "Goal cannot be longer than 1 year"
            return false
        }
        
        dateError = ""
        return true
    }
    
    private func validateStakeAmount(_ amount: String) -> Bool {
        guard !amount.isEmpty else {
            stakeError = "Stake amount is required"
            return false
        }
        
        guard let decimalAmount = Decimal(string: amount), decimalAmount > 0 else {
            stakeError = "Please enter a valid stake amount"
            return false
        }
        
        if decimalAmount < 1 {
            stakeError = "Minimum stake amount is $1"
            return false
        }
        
        if decimalAmount > 10000 {
            stakeError = "Maximum stake amount is $10,000"
            return false
        }
        
        stakeError = ""
        return true
    }
    
    private func clearValidationErrors() {
        titleError = ""
        descriptionError = ""
        dateError = ""
        stakeError = ""
    }
}

// MARK: - Supporting Protocols
protocol UserRepository {
    func getCurrentUser() async throws -> User
}

protocol GroupRepository {
    func getGroup(id: String) async throws -> Group
}

protocol CorporateAccountRepository {
    func getCorporateAccount(id: String) async throws -> CorporateAccount
}

protocol CharityRepository {
    func getCharities() async throws -> [Charity]
}

// MARK: - Analytics Extensions
extension AnalyticsService {
    func track(_ event: CreateGoalAnalyticsEvent) {
        // Implementation would track the specific event
    }
}

enum CreateGoalAnalyticsEvent {
    case createGoal(mode: GoalMode, category: GoalCategory, hasStake: Bool)
    case createGoalError(mode: GoalMode, category: GoalCategory, error: String)
}

// MARK: - View Model Extensions
extension CreateGoalViewModel {
    var canCreateGoal: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        startDate < endDate &&
        endDate > Date() &&
        (!createStake || !stakeAmount.isEmpty)
    }
    
    var formIsValid: Bool {
        titleError.isEmpty &&
        descriptionError.isEmpty &&
        dateError.isEmpty &&
        (createStake ? stakeError.isEmpty : true)
    }
    
    var stakeAmountDecimal: Decimal? {
        return Decimal(string: stakeAmount)
    }
    
    var earlyCompletionBonusDecimal: Decimal? {
        return Decimal(string: earlyCompletionBonus)
    }
}
