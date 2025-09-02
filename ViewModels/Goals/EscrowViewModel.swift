import Foundation
import Combine

@MainActor
final class EscrowViewModel: ObservableObject {
    @Published var summary: GoalEscrowSummary?
    @Published var escrow: Escrow?
    @Published var transactions: [EscrowTransaction] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let escrowRepository: EscrowRepository
    private let accrueUseCase: AccrueEscrowUseCase
    private let getSummaryUseCase: GetGoalEscrowSummaryUseCase
    private let fileDisputeUseCase: FileDisputeUseCase
    
    init(escrowRepository: EscrowRepository,
         accrueUseCase: AccrueEscrowUseCase,
         getSummaryUseCase: GetGoalEscrowSummaryUseCase,
         fileDisputeUseCase: FileDisputeUseCase) {
        self.escrowRepository = escrowRepository
        self.accrueUseCase = accrueUseCase
        self.getSummaryUseCase = getSummaryUseCase
        self.fileDisputeUseCase = fileDisputeUseCase
    }
    
    func load(goalId: String) async {
        isLoading = true
        do {
            summary = try await getSummaryUseCase.execute(goalId: goalId)
            if let escrowId = summary?.escrowId {
                escrow = try await escrowRepository.getEscrow(escrowId)
                transactions = try await escrowRepository.listTransactions(forEscrowId: escrowId)
            }
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }
    
    func accrueNow(escrowId: String) async {
        isLoading = true
        do {
            let updated = try await accrueUseCase.execute(escrowId: escrowId)
            escrow = updated
            summary = GoalEscrowSummary(goalId: updated.goalId, escrowId: updated.id, totalPrincipal: updated.totalPrincipal, accruedAmount: updated.accruedAmount, pendingDistribution: updated.status == .pendingDistribution, nextActionAt: summary?.nextActionAt)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }
    
    func fileDispute(goalId: String, userId: String, reason: String, evidenceRefs: [String]) async {
        isLoading = true
        do {
            _ = try await fileDisputeUseCase.execute(.init(goalId: goalId, userId: userId, reason: reason, evidenceRefs: evidenceRefs))
            await load(goalId: goalId)
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }
}
