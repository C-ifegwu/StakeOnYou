import Foundation

final class AccrueEscrowUseCase {
    private let escrowService: EscrowService
    
    init(escrowService: EscrowService) {
        self.escrowService = escrowService
    }
    
    func execute(escrowId: String, asOf: Date = Date()) async throws -> Escrow {
        return try await escrowService.accrue(escrowId: escrowId, asOf: asOf)
    }
}
