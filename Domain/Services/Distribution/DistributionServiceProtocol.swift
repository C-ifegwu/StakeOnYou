import Foundation

public struct DistributionResult: Equatable {
	public let goalId: String
	public let escrowId: String
	public let status: EscrowStatus
	public let transactionRefs: [String]
	public let partial: Bool
	public let message: String?
}

public protocol DistributionServiceProtocol: AnyObject {
	func distribute(goalId: UUID) async throws -> DistributionResult
}
