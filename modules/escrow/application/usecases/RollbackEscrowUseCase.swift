import Foundation

public struct RollbackEscrowRequest: Equatable {
	public let escrowId: UUID
	public let reason: String
	public let idempotencyKey: String
	public init(escrowId: UUID, reason: String, idempotencyKey: String) {
		self.escrowId = escrowId
		self.reason = reason
		self.idempotencyKey = idempotencyKey
	}
}

public final class RollbackEscrowUseCase {
	private let escrowRepository: EscrowRepository
	private let escrowService: EscrowService
	
	public init(escrowRepository: EscrowRepository, escrowService: EscrowService) {
		self.escrowRepository = escrowRepository
		self.escrowService = escrowService
	}
	
	public func execute(_ request: RollbackEscrowRequest) async throws -> Escrow {
		var escrow = try await escrowRepository.getEscrow(request.escrowId.uuidString)
		guard escrow.status == .held || escrow.status == .pendingDistribution || escrow.status == .partial else {
			return escrow
		}
		_ = try await escrowService.refund(escrowId: escrow.id, idempotencyKey: request.idempotencyKey)
		escrow.status = .refunded
		escrow.updatedAt = Date()
		escrow = try await escrowRepository.updateEscrow(escrow)
		return escrow
	}
}
