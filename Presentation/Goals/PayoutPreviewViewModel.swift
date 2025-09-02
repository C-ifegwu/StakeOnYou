import Foundation
import Combine

@MainActor
final class PayoutPreviewViewModel: ObservableObject {
    @Published var summary: GoalEscrowSummary?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let getSummaryUseCase: GetGoalEscrowSummaryUseCase
    private let completeGoalUseCase: CompleteGoalUseCase
    private let distributionPlanProvider: (String) -> DistributionPlan

    init(
        getSummaryUseCase: GetGoalEscrowSummaryUseCase,
        completeGoalUseCase: CompleteGoalUseCase,
        distributionPlanProvider: @escaping (String) -> DistributionPlan
    ) {
        self.getSummaryUseCase = getSummaryUseCase
        self.completeGoalUseCase = completeGoalUseCase
        self.distributionPlanProvider = distributionPlanProvider
    }

    func load(goalId: String) async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        do {
            summary = try await getSummaryUseCase.execute(goalId: goalId)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    func confirm(goalId: String, success: Bool = true) async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        do {
            let plan = distributionPlanProvider(goalId)
            let result = try await completeGoalUseCase.execute(.init(
                goalId: goalId,
                success: success,
                distributionPlan: plan,
                idempotencyKey: UUID().uuidString
            ))
            isLoading = false
            let refs = result.distributionTxRefs.joined(separator: ", ")
            successMessage = refs.isEmpty ? "Distribution initiated" : "Distribution receipts: \(refs)"
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    var statusText: String {
        guard let escrowId = summary?.escrowId else { return "—" }
        // This method can be enhanced to reflect pending/partial states via repository if needed
        return "#\(escrowId.prefix(6))…"
    }
}

import Foundation
import Combine

@MainActor
final class PayoutPreviewViewModel: ObservableObject {
	@Published var summary: GoalEscrowSummary?
	@Published var isLoading = false
	@Published var errorMessage: String?
	@Published var successMessage: String?
	@Published var resultRefs: [String] = []
	
	private let getSummary: GetGoalEscrowSummaryUseCase
	private let initiateDistribution: InitiateDistributionUseCase
	
	init(getSummary: GetGoalEscrowSummaryUseCase, initiateDistribution: InitiateDistributionUseCase) {
		self.getSummary = getSummary
		self.initiateDistribution = initiateDistribution
	}
	
	func load(goalId: String) async {
		isLoading = true
		do {
			summary = try await getSummary.execute(goalId: goalId)
			isLoading = false
		} catch {
			isLoading = false
			errorMessage = error.localizedDescription
		}
	}
	
	func confirm(goalId: String) async {
		isLoading = true
		do {
			let result = try await initiateDistribution.execute(goalId: goalId)
			resultRefs = result.transactionRefs
			successMessage = result.partial ? "Partial distribution executed" : "Distribution executed"
			isLoading = false
		} catch {
			isLoading = false
			errorMessage = error.localizedDescription
		}
	}
}
