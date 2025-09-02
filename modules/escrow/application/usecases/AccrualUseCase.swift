import Foundation

// MARK: - Accrual Service Protocol
public protocol AccrualServiceProtocol: AnyObject {
	/// Accrues value on an escrow for a given period.
	/// - Parameters:
	///   - escrowId: The escrow identifier (UUID). Internally bridged to String IDs.
	///   - period: The period of time over which to accrue (in seconds).
	/// - Returns: Updated Escrow with new accrued amount persisted.
	func accrue(escrowId: UUID, period: TimeInterval) async throws -> Escrow
}

// MARK: - Default Accrual Service
public final class DefaultAccrualService: AccrualServiceProtocol {
	private let escrowRepository: EscrowRepository
	private let annualInterestRate: Decimal
	private let accruesOnPrincipalOnly: Bool
	
	/// - Parameters:
	///   - escrowRepository: Repository to load and persist escrow records.
	///   - annualInterestRate: APR as a decimal (e.g., 0.05 for 5%). Defaults to 5%.
	///   - accruesOnPrincipalOnly: If true, accrual is simple interest on principal; if false, accrual compounds on (principal + accrued).
	public init(
		escrowRepository: EscrowRepository,
		annualInterestRate: Decimal = 0.05,
		accruesOnPrincipalOnly: Bool = true
	) {
		self.escrowRepository = escrowRepository
		self.annualInterestRate = annualInterestRate
		self.accruesOnPrincipalOnly = accruesOnPrincipalOnly
	}
	
	public func accrue(escrowId: UUID, period: TimeInterval) async throws -> Escrow {
		// Bridge UUID to String-based repository IDs
		let id = escrowId.uuidString
		var escrow = try await escrowRepository.getEscrow(id)
		
		// Convert period seconds to year fraction
		let secondsPerYear: Decimal = 365 * 24 * 60 * 60
		let periodSeconds = Decimal(period)
		guard periodSeconds > 0 else { return escrow }
		let yearFraction = periodSeconds / secondsPerYear
		
		// Determine base for accrual
		let base: Decimal
		if accruesOnPrincipalOnly {
			base = escrow.totalPrincipal
		} else {
			base = escrow.totalPrincipal + escrow.accruedAmount
		}
		
		// Simple APR accrual for the period
		let increment = (base * annualInterestRate) * yearFraction
		if increment > 0 {
			escrow.accruedAmount += increment
			escrow.updatedAt = Date()
			escrow = try await escrowRepository.updateEscrow(escrow)
		}
		return escrow
	}
}

// MARK: - Mock Accrual Service (for tests)
public final class MockAccrualService: AccrualServiceProtocol {
	private let escrowRepository: EscrowRepository
	public var fixedIncrementPerCall: Decimal
	
	public init(escrowRepository: EscrowRepository, fixedIncrementPerCall: Decimal = 1.0) {
		self.escrowRepository = escrowRepository
		self.fixedIncrementPerCall = fixedIncrementPerCall
	}
	
	public func accrue(escrowId: UUID, period: TimeInterval) async throws -> Escrow {
		let id = escrowId.uuidString
		var escrow = try await escrowRepository.getEscrow(id)
		escrow.accruedAmount += fixedIncrementPerCall
		escrow.updatedAt = Date()
		return try await escrowRepository.updateEscrow(escrow)
	}
}

// MARK: - Basic Test Stub (for reference)
#if DEBUG
public enum AccrualUseCaseTests {
	public static func testDailyAccrual() async throws {
		// Minimal in-file mock repo to avoid cross-target dependencies
		final class LocalMockRepo: EscrowRepository {
			var store: [String: Escrow] = [:]
			var txs: [String: [EscrowTransaction]] = [:]
			func createEscrow(goalId: String, stakeholders: [EscrowStakeholder], currency: String, holdRef: String) async throws -> Escrow {
				let e = Escrow(goalId: goalId, stakeholders: stakeholders, holdRef: holdRef, currency: currency)
				store[e.id] = e
				txs[e.id] = []
				return e
			}
			func getEscrow(_ escrowId: String) async throws -> Escrow { guard let e = store[escrowId] else { throw EscrowServiceError.escrowNotFound }; return e }
			func updateEscrow(_ escrow: Escrow) async throws -> Escrow { store[escrow.id] = escrow; return escrow }
			func listEscrowsForGoal(_ goalId: String) async throws -> [Escrow] { store.values.filter { $0.goalId == goalId } }
			func setEscrowStatus(_ escrowId: String, status: EscrowStatus) async throws -> Escrow { var e = try await getEscrow(escrowId); e.status = status; store[escrowId] = e; return e }
			func appendTransaction(_ tx: EscrowTransaction) async throws -> EscrowTransaction { txs[tx.escrowId, default: []].append(tx); return tx }
			func listTransactions(forEscrowId escrowId: String) async throws -> [EscrowTransaction] { txs[escrowId] ?? [] }
		}
		
		let repo = LocalMockRepo()
		let stakeholders = [EscrowStakeholder(userId: "u1", stakeId: "s1", principal: 100)]
		let escrow = try await repo.createEscrow(goalId: "g1", stakeholders: stakeholders, currency: "USD", holdRef: "hold_1")
		let service = DefaultAccrualService(escrowRepository: repo, annualInterestRate: 0.365) // ~0.1% per day
		let updated = try await service.accrue(escrowId: UUID(uuidString: escrow.id) ?? UUID(), period: 24 * 60 * 60)
		assert(updated.accruedAmount > 0, "Accrued amount should increase for one day period")
	}
}
#endif
