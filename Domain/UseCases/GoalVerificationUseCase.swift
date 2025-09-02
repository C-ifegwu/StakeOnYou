import Foundation

public enum VerificationMethod: String, Codable, CaseIterable, Equatable { case manual, photo, peer }

public struct GoalVerification: Equatable {
    public let method: VerificationMethod
    public let isSuccessful: Bool
    public let notes: String?
}

public final class GoalVerificationUseCase {
    public init() {}

    public func verifyManual(evidence: String) async throws -> GoalVerification {
        GoalVerification(method: .manual, isSuccessful: !evidence.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, notes: nil)
    }

    public func verifyPhoto(urls: [URL]) async throws -> GoalVerification {
        GoalVerification(method: .photo, isSuccessful: !urls.isEmpty, notes: nil)
    }

    public func verifyPeer(votesFor: Int, votesAgainst: Int) async throws -> GoalVerification {
        GoalVerification(method: .peer, isSuccessful: votesFor > votesAgainst, notes: nil)
    }
}

import Foundation
import Combine

// MARK: - Goal Verification Use Case
struct GoalVerificationUseCase {
    private let goalRepository: GoalRepository
    private let stakeRepository: StakeRepository
    private let verificationRepository: GoalVerificationRepository
    private let screenTimeService: ScreenTimeService
    private let healthKitService: HealthKitService
    private let analyticsService: AnalyticsService
    
    init(
        goalRepository: GoalRepository,
        stakeRepository: StakeRepository,
        verificationRepository: GoalVerificationRepository,
        screenTimeService: ScreenTimeService,
        healthKitService: HealthKitService,
        analyticsService: AnalyticsService
    ) {
        self.goalRepository = goalRepository
        self.stakeRepository = stakeRepository
        self.verificationRepository = verificationRepository
        self.screenTimeService = screenTimeService
        self.healthKitService = healthKitService
        self.analyticsService = analyticsService
    }
    
    // MARK: - Execute Methods
    func execute(request: GoalVerificationRequest) async throws -> GoalVerificationResult {
        // Validate request
        let validationErrors = validateRequest(request)
        guard validationErrors.isEmpty else {
            throw GoalVerificationError.validationFailed(validationErrors)
        }
        
        // Get goal and stake
        let goal = try await goalRepository.getGoal(id: request.goalId)
        let stake = try await stakeRepository.getStake(forGoalId: request.goalId)
        
        // Perform verification based on method
        let verificationResult = try await performVerification(
            goal: goal,
            stake: stake,
            request: request
        )
        
        // Save verification result
        let savedVerification = try await verificationRepository.saveVerification(verificationResult)
        
        // Update goal status if verification is successful
        if verificationResult.isSuccessful {
            try await updateGoalStatus(goal: goal, verification: savedVerification)
        }
        
        // Track analytics
        analyticsService.track(
            .goalVerification(
                method: request.verificationMethod,
                success: verificationResult.isSuccessful,
                goalCategory: goal.category
            )
        )
        
        return GoalVerificationResult(
            verification: savedVerification,
            goal: goal,
            stake: stake
        )
    }
    
    // MARK: - Private Methods
    private func validateRequest(_ request: GoalVerificationRequest) -> [String] {
        var errors: [String] = []
        
        if request.goalId.isEmpty {
            errors.append("Goal ID is required")
        }
        
        if request.verificationMethod == .manual && request.evidence.isEmpty {
            errors.append("Evidence is required for manual verification")
        }
        
        if request.verificationMethod == .photo && request.evidence.isEmpty {
            errors.append("Photo evidence is required for photo verification")
        }
        
        return errors
    }
    
    private func performVerification(
        goal: Goal,
        stake: Stake?,
        request: GoalVerificationRequest
    ) async throws -> GoalVerification {
        let verificationDate = Date()
        
        switch request.verificationMethod {
        case .manual:
            return try await performManualVerification(
                goal: goal,
                evidence: request.evidence,
                date: verificationDate
            )
            
        case .photo:
            return try await performPhotoVerification(
                goal: goal,
                evidence: request.evidence,
                date: verificationDate
            )
            
        case .screenTime:
            return try await performScreenTimeVerification(
                goal: goal,
                date: verificationDate
            )
            
        case .healthKit:
            return try await performHealthKitVerification(
                goal: goal,
                date: verificationDate
            )
            
        case .peerReview:
            return try await performPeerReviewVerification(
                goal: goal,
                evidence: request.evidence,
                date: verificationDate
            )
            
        default:
            throw GoalVerificationError.unsupportedMethod(request.verificationMethod)
        }
    }
    
    private func performManualVerification(
        goal: Goal,
        evidence: [VerificationEvidence],
        date: Date
    ) async throws -> GoalVerification {
        // For manual verification, we trust the user's evidence
        let verification = GoalVerification(
            goalId: goal.id,
            method: .manual,
            evidence: evidence,
            verifiedAt: date,
            verifiedBy: goal.ownerId,
            isSuccessful: true,
            notes: "Manual verification completed by user"
        )
        
        return verification
    }
    
    private func performPhotoVerification(
        goal: Goal,
        evidence: [VerificationEvidence],
        date: Date
    ) async throws -> GoalVerification {
        // Validate photo evidence
        let photoEvidence = evidence.filter { $0.type == .photo }
        guard !photoEvidence.isEmpty else {
            throw GoalVerificationError.insufficientEvidence("Photo evidence is required")
        }
        
        // For now, we'll accept photo evidence as valid
        // In a real app, you might want to analyze the photos or have them reviewed
        let verification = GoalVerification(
            goalId: goal.id,
            method: .photo,
            evidence: evidence,
            verifiedAt: date,
            verifiedBy: goal.ownerId,
            isSuccessful: true,
            notes: "Photo verification completed"
        )
        
        return verification
    }
    
    private func performScreenTimeVerification(
        goal: Goal,
        date: Date
    ) async throws -> GoalVerification {
        // Get Screen Time data for the goal period
        let screenTimeData = try await screenTimeService.getScreenTimeData(
            from: goal.startDate,
            to: date,
            categories: getScreenTimeCategories(for: goal.category)
        )
        
        // Analyze Screen Time data to determine if goal was met
        let isSuccessful = analyzeScreenTimeForGoal(goal: goal, data: screenTimeData)
        
        let verification = GoalVerification(
            goalId: goal.id,
            method: .screenTime,
            evidence: [],
            verifiedAt: date,
            verifiedBy: "system",
            isSuccessful: isSuccessful,
            notes: "Screen Time verification completed automatically"
        )
        
        return verification
    }
    
    private func performHealthKitVerification(
        goal: Goal,
        date: Date
    ) async throws -> GoalVerification {
        // Get HealthKit data for the goal period
        let healthData = try await healthKitService.getHealthData(
            from: goal.startDate,
            to: date,
            types: getHealthKitTypes(for: goal.category)
        )
        
        // Analyze HealthKit data to determine if goal was met
        let isSuccessful = analyzeHealthKitForGoal(goal: goal, data: healthData)
        
        let verification = GoalVerification(
            goalId: goal.id,
            method: .healthKit,
            evidence: [],
            verifiedAt: date,
            verifiedBy: "system",
            isSuccessful: isSuccessful,
            notes: "HealthKit verification completed automatically"
        )
        
        return verification
    }
    
    private func performPeerReviewVerification(
        goal: Goal,
        evidence: [VerificationEvidence],
        date: Date
    ) async throws -> GoalVerification {
        // For peer review, we need to get the group members' votes
        guard let groupId = goal.groupId else {
            throw GoalVerificationError.insufficientPermissions("Peer review requires a group goal")
        }
        
        // Get group members and their votes
        let votes = try await getPeerReviewVotes(groupId: groupId, goalId: goal.id)
        let isSuccessful = calculatePeerReviewResult(votes: votes)
        
        let verification = GoalVerification(
            goalId: goal.id,
            method: .peerReview,
            evidence: evidence,
            verifiedAt: date,
            verifiedBy: "peer_review",
            isSuccessful: isSuccessful,
            notes: "Peer review completed with \(votes.count) votes"
        )
        
        return verification
    }
    
    private func updateGoalStatus(
        goal: Goal,
        verification: GoalVerification
    ) async throws {
        if verification.isSuccessful {
            // Mark goal as completed
            let updatedGoal = Goal(
                id: goal.id,
                ownerId: goal.ownerId,
                title: goal.title,
                description: goal.description,
                category: goal.category,
                startDate: goal.startDate,
                endDate: goal.endDate,
                stakeAmount: goal.stakeAmount,
                stakeCurrency: goal.stakeCurrency,
                verificationMethod: goal.verificationMethod,
                status: .completed,
                tags: goal.tags,
                milestones: goal.milestones,
                attachments: goal.attachments,
                notes: goal.notes,
                collaborators: goal.collaborators,
                groupId: goal.groupId,
                corporateAccountId: goal.corporateAccountId
            )
            
            try await goalRepository.updateGoal(updatedGoal)
        }
    }
    
    // MARK: - Helper Methods
    private func getScreenTimeCategories(for category: GoalCategory) -> [String] {
        switch category {
        case .fitness:
            return ["fitness", "health", "sports"]
        case .learning:
            return ["education", "productivity", "reading"]
        case .career:
            return ["productivity", "business", "professional"]
        case .health:
            return ["health", "fitness", "wellness"]
        case .finance:
            return ["finance", "banking", "investment"]
        case .social:
            return ["social", "communication", "entertainment"]
        case .creative:
            return ["creativity", "art", "design"]
        case .travel:
            return ["travel", "navigation", "maps"]
        case .home:
            return ["home", "family", "lifestyle"]
        case .spiritual:
            return ["spiritual", "meditation", "mindfulness"]
        case .environmental:
            return ["environment", "nature", "outdoors"]
        case .other:
            return []
        }
    }
    
    private func getHealthKitTypes(for category: GoalCategory) -> [HealthKitDataType] {
        switch category {
        case .fitness:
            return [.steps, .workouts, .activeEnergy, .distance]
        case .health:
            return [.steps, .heartRate, .sleep, .weight]
        case .learning:
            return [.mindfulMinutes, .sleep]
        case .career:
            return [.mindfulMinutes, .sleep]
        case .social:
            return [.mindfulMinutes, .sleep]
        case .creative:
            return [.mindfulMinutes, .sleep]
        case .spiritual:
            return [.mindfulMinutes, .sleep]
        default:
            return []
        }
    }
    
    private func analyzeScreenTimeForGoal(goal: Goal, data: ScreenTimeData) -> Bool {
        // Implement logic to analyze Screen Time data
        // This is a simplified example
        let totalScreenTime = data.categories.values.reduce(0, +)
        let targetScreenTime = getTargetScreenTime(for: goal.category)
        
        return totalScreenTime <= targetScreenTime
    }
    
    private func analyzeHealthKitForGoal(goal: Goal, data: HealthKitData) -> Bool {
        // Implement logic to analyze HealthKit data
        // This is a simplified example
        switch goal.category {
        case .fitness:
            let totalSteps = data.steps.reduce(0, +)
            let targetSteps = getTargetSteps(for: goal)
            return totalSteps >= targetSteps
            
        case .health:
            let totalWorkouts = data.workouts.count
            let targetWorkouts = getTargetWorkouts(for: goal)
            return totalWorkouts >= targetWorkouts
            
        default:
            return false
        }
    }
    
    private func getPeerReviewVotes(groupId: String, goalId: String) async throws -> [PeerReviewVote] {
        // This would typically fetch from a repository
        // For now, return empty array
        return []
    }
    
    private func calculatePeerReviewResult(votes: [PeerReviewVote]) -> Bool {
        let totalVotes = votes.count
        let positiveVotes = votes.filter { $0.isApproved }.count
        
        return Double(positiveVotes) / Double(totalVotes) >= 0.7 // 70% approval required
    }
    
    private func getTargetScreenTime(for category: GoalCategory) -> TimeInterval {
        // Return target screen time in seconds
        switch category {
        case .fitness, .health:
            return 2 * 60 * 60 // 2 hours
        case .learning, .career:
            return 4 * 60 * 60 // 4 hours
        default:
            return 6 * 60 * 60 // 6 hours
        }
    }
    
    private func getTargetSteps(for goal: Goal) -> Int {
        // This could be configurable per goal
        return 10000
    }
    
    private func getTargetWorkouts(for goal: Goal) -> Int {
        // This could be configurable per goal
        return 3
    }
}

// MARK: - Request and Result Models
struct GoalVerificationRequest {
    let goalId: String
    let verificationMethod: VerificationMethod
    let evidence: [VerificationEvidence]
    let notes: String?
}

struct GoalVerificationResult {
    let verification: GoalVerification
    let goal: Goal
    let stake: Stake?
}

// MARK: - Supporting Structures
struct GoalVerification: Identifiable, Codable, Equatable {
    let id: String
    let goalId: String
    let method: VerificationMethod
    let evidence: [VerificationEvidence]
    let verifiedAt: Date
    let verifiedBy: String
    let isSuccessful: Bool
    let notes: String?
    let createdAt: Date
    
    init(
        id: String = UUID().uuidString,
        goalId: String,
        method: VerificationMethod,
        evidence: [VerificationEvidence],
        verifiedAt: Date,
        verifiedBy: String,
        isSuccessful: Bool,
        notes: String?
    ) {
        self.id = id
        self.goalId = goalId
        self.method = method
        self.evidence = evidence
        self.verifiedAt = verifiedAt
        self.verifiedBy = verifiedBy
        self.isSuccessful = isSuccessful
        self.notes = notes
        self.createdAt = Date()
    }
}

struct VerificationEvidence: Identifiable, Codable, Equatable {
    let id: String
    let type: EvidenceType
    let url: URL?
    let description: String
    let submittedAt: Date
    
    init(
        id: String = UUID().uuidString,
        type: EvidenceType,
        url: URL? = nil,
        description: String,
        submittedAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.url = url
        self.description = description
        self.submittedAt = submittedAt
    }
}

struct PeerReviewVote: Identifiable, Codable, Equatable {
    let id: String
    let userId: String
    let goalId: String
    let isApproved: Bool
    let notes: String?
    let votedAt: Date
}

// MARK: - Service Protocols
protocol ScreenTimeService {
    func getScreenTimeData(
        from: Date,
        to: Date,
        categories: [String]
    ) async throws -> ScreenTimeData
}

protocol HealthKitService {
    func getHealthData(
        from: Date,
        to: Date,
        types: [HealthKitDataType]
    ) async throws -> HealthKitData
}

protocol GoalVerificationRepository {
    func saveVerification(_ verification: GoalVerification) async throws -> GoalVerification
    func getVerifications(forGoalId: String) async throws -> [GoalVerification]
}

// MARK: - Data Models
struct ScreenTimeData {
    let categories: [String: TimeInterval]
    let totalTime: TimeInterval
    let dateRange: DateInterval
}

struct HealthKitData {
    let steps: [Int]
    let workouts: [WorkoutData]
    let heartRate: [HeartRateData]
    let sleep: [SleepData]
    let weight: [WeightData]
}

enum HealthKitDataType {
    case steps, workouts, heartRate, sleep, weight, activeEnergy, distance, mindfulMinutes
}

struct WorkoutData {
    let type: String
    let duration: TimeInterval
    let calories: Double
    let date: Date
}

struct HeartRateData {
    let value: Double
    let date: Date
}

struct SleepData {
    let hours: Double
    let date: Date
}

struct WeightData {
    let value: Double
    let date: Date
}

// MARK: - Errors
enum GoalVerificationError: LocalizedError {
    case validationFailed([String])
    case insufficientEvidence(String)
    case insufficientPermissions(String)
    case unsupportedMethod(VerificationMethod)
    case verificationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .validationFailed(let errors):
            return "Validation failed: \(errors.joined(separator: ", "))"
        case .insufficientEvidence(let message):
            return message
        case .insufficientPermissions(let message):
            return message
        case .unsupportedMethod(let method):
            return "Verification method \(method.displayName) is not supported"
        case .verificationFailed(let message):
            return "Verification failed: \(message)"
        }
    }
}
