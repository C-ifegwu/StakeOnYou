import Foundation

final class MockDisputeRepository: DisputeRepository {
    private var disputes: [String: Dispute] = [:]
    private var goalToDisputeIds: [String: [String]] = [:]
    
    func createDispute(goalId: String, filedBy: String, reason: String, evidenceRefs: [String]) async throws -> Dispute {
        let dispute = Dispute(
            id: UUID().uuidString,
            goalId: goalId,
            filedBy: filedBy,
            reason: reason,
            evidenceRefs: evidenceRefs,
            status: .open,
            createdAt: Date(),
            resolvedAt: nil,
            decisionBy: nil
        )
        disputes[dispute.id] = dispute
        goalToDisputeIds[goalId, default: []].append(dispute.id)
        return dispute
    }
    
    func getDispute(_ disputeId: String) async throws -> Dispute {
        guard let d = disputes[disputeId] else { throw EscrowServiceError.escrowNotFound }
        return d
    }
    
    func listDisputes(goalId: String?) async throws -> [Dispute] {
        if let goalId = goalId {
            let ids = goalToDisputeIds[goalId] ?? []
            return ids.compactMap { disputes[$0] }.sorted { $0.createdAt > $1.createdAt }
        }
        return disputes.values.sorted { $0.createdAt > $1.createdAt }
    }
    
    func setDecision(disputeId: String, status: DisputeStatus, notes: String?, actorId: String) async throws -> Dispute {
        guard var d = disputes[disputeId] else { throw EscrowServiceError.escrowNotFound }
        d.status = status
        d.resolvedAt = Date()
        d.decisionBy = actorId
        disputes[disputeId] = d
        return d
    }
}
