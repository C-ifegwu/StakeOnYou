import Foundation

final class CoreDataDisputeRepository: DisputeRepository {
    private let backing = MockDisputeRepository()

    func createDispute(goalId: String, filedBy: String, reason: String, evidenceRefs: [String]) async throws -> Dispute {
        try await backing.createDispute(goalId: goalId, filedBy: filedBy, reason: reason, evidenceRefs: evidenceRefs)
    }

    func getDispute(_ disputeId: String) async throws -> Dispute {
        try await backing.getDispute(disputeId)
    }

    func listDisputes(goalId: String?) async throws -> [Dispute] {
        try await backing.listDisputes(goalId: goalId)
    }

    func setDecision(disputeId: String, status: DisputeStatus, notes: String?, actorId: String) async throws -> Dispute {
        try await backing.setDecision(disputeId: disputeId, status: status, notes: notes, actorId: actorId)
    }
}


