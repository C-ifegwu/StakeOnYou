import Foundation

final class RollbackEscrowUseCase {
    private let escrowService: EscrowService
    
    init(escrowService: EscrowService) {
        self.escrowService = escrowService
    }
    
    func execute(escrowId: String, idempotencyKey: String) async throws -> [String] {
        return try await escrowService.refund(escrowId: escrowId, idempotencyKey: idempotencyKey)
    }
}
