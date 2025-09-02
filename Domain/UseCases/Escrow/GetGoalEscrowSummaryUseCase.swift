import Foundation

final class GetGoalEscrowSummaryUseCase {
    private let escrowRepository: EscrowRepository
    
    init(escrowRepository: EscrowRepository) {
        self.escrowRepository = escrowRepository
    }
    
    func execute(goalId: String) async throws -> GoalEscrowSummary? {
        guard let escrow = try await escrowRepository.listEscrowsForGoal(goalId).first else { return nil }
        let transactions = try await escrowRepository.listTransactions(forEscrowId: escrow.id)
        let pending = escrow.status == .pendingDistribution
        let nextActionAt: Date? = pending ? Calendar.current.date(byAdding: .hour, value: 48, to: Date()) : nil
        return GoalEscrowSummary(goalId: goalId, escrowId: escrow.id, totalPrincipal: escrow.totalPrincipal, accruedAmount: escrow.accruedAmount, pendingDistribution: pending, nextActionAt: nextActionAt)
    }
}
