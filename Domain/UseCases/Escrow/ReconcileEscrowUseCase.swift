import Foundation

final class ReconcileEscrowUseCase {
    private let escrowService: EscrowService
    
    init(escrowService: EscrowService) {
        self.escrowService = escrowService
    }
    
    func execute(escrowId: String) async throws -> Bool {
        return try await escrowService.reconcile(escrowId: escrowId)
    }
}
