import Foundation

public enum APRType: String, Codable, Equatable {
	case simple
	case compound
}

public struct AccrueEscrowRequest: Equatable {
	public let escrowId: UUID
	public let period: TimeInterval
	public let aprType: APRType
	public let feeRate: Decimal // optional platform fee on accrual (0..1)
	public init(escrowId: UUID, period: TimeInterval, aprType: APRType = .simple, feeRate: Decimal = 0) {
		self.escrowId = escrowId
		self.period = period
		self.aprType = aprType
		self.feeRate = feeRate
	}
}

public final class AccrueEscrowUseCase {
	private let escrowRepository: EscrowRepository
	private let accrualService: AccrualServiceProtocol
	
	public init(escrowRepository: EscrowRepository, accrualService: AccrualServiceProtocol) {
		self.escrowRepository = escrowRepository
		self.accrualService = accrualService
	}
	
	public func execute(_ request: AccrueEscrowRequest) async throws -> Escrow {
		// Load current escrow
		var escrow = try await escrowRepository.getEscrow(request.escrowId.uuidString)
		guard escrow.status == .held || escrow.status == .pendingDistribution || escrow.status == .partial else {
			return escrow // No accrual when already finalized
		}
		
		// Perform base accrual via service (simple APR on principal or principal+accrued handled by service impl)
		var updated = try await accrualService.accrue(escrowId: request.escrowId, period: request.period)
		
		// Apply fee on newly accrued if any
		if request.feeRate > 0 {
			let previousAccrued = escrow.accruedAmount
			let increment = max(0, updated.accruedAmount - previousAccrued)
			if increment > 0 {
				let fee = increment * request.feeRate
				updated.accruedAmount -= fee
				updated.updatedAt = Date()
				updated = try await escrowRepository.updateEscrow(updated)
			}
		}
		return updated
	}
}
