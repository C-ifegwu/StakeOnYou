import Foundation
import Combine

// MARK: - Create Goal Use Case
struct CreateGoalUseCase {
    private let goalRepository: GoalRepository
    private let stakeRepository: StakeRepository
    private let userRepository: UserRepository
    private let groupRepository: GroupRepository
    private let corporateRepository: CorporateAccountRepository
    private let validationService: ValidationService
    private let analyticsService: AnalyticsService
    
    init(
        goalRepository: GoalRepository,
        stakeRepository: StakeRepository,
        userRepository: UserRepository,
        groupRepository: GroupRepository,
        corporateRepository: CorporateAccountRepository,
        validationService: ValidationService,
        analyticsService: AnalyticsService
    ) {
        self.goalRepository = goalRepository
        self.stakeRepository = stakeRepository
        self.userRepository = userRepository
        self.groupRepository = groupRepository
        self.corporateRepository = corporateRepository
        self.validationService = validationService
        self.analyticsService = analyticsService
    }
    
    // MARK: - Execute Methods
    func execute(request: CreateGoalRequest) async throws -> CreateGoalResult {
        // Validate request
        let validationErrors = validateRequest(request)
        guard validationErrors.isEmpty else {
            throw GoalError.validationFailed(validationErrors)
        }
        
        // Validate user permissions
        try await validateUserPermissions(request)
        
        // Create goal
        let goal = try await createGoal(from: request)
        
        // Create stake if requested
        let stake: Stake?
        if request.createStake {
            stake = try await createStake(for: goal, with: request.stakeRequest)
        } else {
            stake = nil
        }
        
        // Track analytics
        analyticsService.track(
            .createGoal(
                mode: request.mode,
                category: request.category,
                hasStake: stake != nil
            )
        )
        
        return CreateGoalResult(goal: goal, stake: stake)
    }
    
    // MARK: - Private Methods
    private func validateRequest(_ request: CreateGoalRequest) -> [String] {
        var errors: [String] = []
        
        // Basic validation
        if request.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Goal title is required")
        }
        
        if request.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Goal description is required")
        }
        
        if request.startDate >= request.endDate {
            errors.append("Start date must be before end date")
        }
        
        if request.endDate < Date() {
            errors.append("End date cannot be in the past")
        }
        
        // Mode-specific validation
        switch request.mode {
        case .individual:
            if request.createStake && request.stakeRequest.principal <= 0 {
                errors.append("Stake amount must be greater than zero")
            }
            
        case .group:
            if request.groupId == nil {
                errors.append("Group ID is required for group goals")
            }
            
        case .corporate:
            if request.corporateAccountId == nil {
                errors.append("Corporate account ID is required for corporate goals")
            }
        }
        
        return errors
    }
    
    private func validateUserPermissions(_ request: CreateGoalRequest) async throws {
        let currentUser = try await userRepository.getCurrentUser()
        
        switch request.mode {
        case .individual:
            // Individual users can always create personal goals
            break
            
        case .group:
            guard let groupId = request.groupId else { return }
            let group = try await groupRepository.getGroup(id: groupId)
            
            guard group.members.contains(currentUser.id) else {
                throw GoalError.insufficientPermissions("You must be a member of the group to create group goals")
            }
            
        case .corporate:
            guard let corporateId = request.corporateAccountId else { return }
            let corporate = try await corporateRepository.getCorporateAccount(id: corporateId)
            
            guard corporate.employees.contains(currentUser.id) else {
                throw GoalError.insufficientPermissions("You must be an employee to create corporate goals")
            }
        }
    }
    
    private func createGoal(from request: CreateGoalRequest) async throws -> Goal {
        let goal = Goal(
            ownerId: request.ownerId,
            title: request.title,
            description: request.description,
            category: request.category,
            startDate: request.startDate,
            endDate: request.endDate,
            stakeAmount: request.stakeRequest?.principal ?? 0,
            stakeCurrency: request.stakeRequest?.currency ?? "USD",
            verificationMethod: request.verificationMethod,
            tags: request.tags,
            milestones: request.milestones,
            groupId: request.groupId,
            corporateAccountId: request.corporateAccountId
        )
        
        return try await goalRepository.createGoal(goal)
    }
    
    private func createStake(for goal: Goal, with request: StakeRequest) async throws -> Stake {
        let stake = Stake(
            goalId: goal.id,
            userId: goal.ownerId,
            principal: request.principal,
            aprModel: request.aprModel,
            accrualMethod: request.accrualMethod,
            feeRateOnStake: request.feeRateOnStake,
            feeRateOnWithdrawal: request.feeRateOnWithdrawal,
            earlyCompletionBonus: request.earlyCompletionBonus,
            charityId: request.charityId,
            groupId: goal.groupId,
            corporateAccountId: goal.corporateAccountId
        )
        
        return try await stakeRepository.createStake(stake)
    }
}

// MARK: - Request and Result Models
struct CreateGoalRequest {
    let mode: GoalMode
    let ownerId: String
    let title: String
    let description: String
    let category: GoalCategory
    let startDate: Date
    let endDate: Date
    let verificationMethod: VerificationMethod
    let tags: [String]
    let milestones: [Milestone]
    let createStake: Bool
    let stakeRequest: StakeRequest?
    let groupId: String?
    let corporateAccountId: String?
}

struct StakeRequest {
    let principal: Decimal
    let currency: String
    let aprModel: APRModel
    let accrualMethod: AccrualMethod
    let feeRateOnStake: Decimal
    let feeRateOnWithdrawal: Decimal
    let earlyCompletionBonus: Decimal?
    let charityId: String?
}

struct CreateGoalResult {
    let goal: Goal
    let stake: Stake?
}

enum GoalMode {
    case individual
    case group
    case corporate
}

// MARK: - Goal Error
enum GoalError: LocalizedError {
    case validationFailed([String])
    case insufficientPermissions(String)
    case goalNotFound
    case stakeCreationFailed
    case repositoryError(Error)
    
    var errorDescription: String? {
        switch self {
        case .validationFailed(let errors):
            return "Validation failed: \(errors.joined(separator: ", "))"
        case .insufficientPermissions(let message):
            return message
        case .goalNotFound:
            return "Goal not found"
        case .stakeCreationFailed:
            return "Failed to create stake"
        case .repositoryError(let error):
            return "Repository error: \(error.localizedDescription)"
        }
    }
}
