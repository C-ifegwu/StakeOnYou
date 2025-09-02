import Foundation

final class MockEscrowService: EscrowService {
    private let escrowRepository: EscrowRepository
    private let disputeRepository: DisputeRepository
    private let accountingService: AccountingService
    private let walletService: WalletService
    
    // Simple idempotency store in-memory
    private var idempotencyLedger: Set<String> = []
    
    init(
        escrowRepository: EscrowRepository,
        disputeRepository: DisputeRepository,
        accountingService: AccountingService,
        walletService: WalletService
    ) {
        self.escrowRepository = escrowRepository
        self.disputeRepository = disputeRepository
        self.accountingService = accountingService
        self.walletService = walletService
    }
    
    func hold(goalId: String, stakeholders: [EscrowStakeholder], currency: String, idempotencyKey: String) async throws -> Escrow {
        if idempotencyLedger.contains(idempotencyKey) {
            // Return existing escrow by querying goal
            if let existing = try await escrowRepository.listEscrowsForGoal(goalId).first {
                return existing
            }
        }
        idempotencyLedger.insert(idempotencyKey)
        
        // Aggregate hold across stakeholders (mock: ensure balances sufficient)
        for stakeholder in stakeholders {
            _ = try await walletService.holdEscrow(amount: stakeholder.principal, for: stakeholder.userId, goalId: goalId)
        }
        
        let escrow = try await escrowRepository.createEscrow(goalId: goalId, stakeholders: stakeholders, currency: currency, holdRef: idempotencyKey)
        
        // Append accounting entries (simplified)
        let entry = LedgerEntry(
            transactionId: escrow.id,
            accountId: "escrow_account_\(goalId)",
            accountType: .escrowAccount,
            entryType: .credit,
            amount: escrow.totalPrincipal,
            description: "Escrow hold",
            reference: idempotencyKey
        )
        _ = try await (accountingService as? MockAccountingService)?.accountingRepository.saveLedgerEntry(entry)
        
        // Record tx
        let tx = EscrowTransaction(escrowId: escrow.id, type: .hold, amount: escrow.totalPrincipal, relatedTxRef: idempotencyKey)
        _ = try await escrowRepository.appendTransaction(tx)
        
        return escrow
    }
    
    func accrue(escrowId: String, asOf: Date) async throws -> Escrow {
        var escrow = try await escrowRepository.getEscrow(escrowId)
        // Simple daily accrual mock: 5% APR simple interest
        // accrued = principal * rate * days/365
        let days = Decimal(Calendar.current.dateComponents([.day], from: escrow.updatedAt, to: asOf).day ?? 0)
        if days > 0 {
            let apr: Decimal = 0.05
            let dailyRate = apr / 365
            let accrual = escrow.totalPrincipal * dailyRate * days
            escrow.accruedAmount += accrual
            escrow.updatedAt = asOf
            escrow = try await escrowRepository.updateEscrow(escrow)
        }
        return escrow
    }
    
    func release(escrowId: String, distributionPlan: DistributionPlan, idempotencyKey: String) async throws -> [String] {
        if idempotencyLedger.contains(idempotencyKey) { return [] }
        idempotencyLedger.insert(idempotencyKey)
        
        var escrow = try await escrowRepository.getEscrow(escrowId)
        guard escrow.status == .held || escrow.status == .pendingDistribution || escrow.status == .partial else {
            throw EscrowServiceError.invalidState
        }
        
        // Check for active dispute
        let disputes = try await disputeRepository.listDisputes(goalId: escrow.goalId)
        if disputes.contains(where: { $0.status == .open }) {
            throw EscrowServiceError.distributionPausedDueToDispute
        }
        
        let totalPool = escrow.totalPrincipal + escrow.accruedAmount
        var txRefs: [String] = []
        
        switch distributionPlan.type {
        case .individual, .corporate:
            // Refund to original stakeholders minus fees (mock: no fees applied here)
            for s in escrow.stakeholders {
                let share = (s.principal / escrow.totalPrincipal) * totalPool
                // Release to user wallet
                _ = try await walletService.releaseEscrow(amount: share, for: s.userId, goalId: escrow.goalId)
            }
        case .group:
            // Distribute by winners list
            for winner in distributionPlan.winners {
                let share = (winner.sharePercent / 100) * totalPool
                _ = try await walletService.releaseEscrow(amount: share, for: winner.userId, goalId: escrow.goalId)
            }
        }
        
        // Update status and record tx
        escrow.status = .released
        escrow.updatedAt = Date()
        escrow = try await escrowRepository.updateEscrow(escrow)
        
        let tx = EscrowTransaction(escrowId: escrow.id, type: .release, amount: totalPool, relatedTxRef: idempotencyKey)
        let saved = try await escrowRepository.appendTransaction(tx)
        txRefs.append(saved.id)
        
        return txRefs
    }
    
    func forfeit(escrowId: String, distributionPlan: DistributionPlan, idempotencyKey: String) async throws -> [String] {
        if idempotencyLedger.contains(idempotencyKey) { return [] }
        idempotencyLedger.insert(idempotencyKey)
        
        var escrow = try await escrowRepository.getEscrow(escrowId)
        guard escrow.status == .held || escrow.status == .pendingDistribution || escrow.status == .partial else {
            throw EscrowServiceError.invalidState
        }
        
        let totalPool = escrow.totalPrincipal + escrow.accruedAmount
        var txRefs: [String] = []
        
        switch distributionPlan.type {
        case .individual, .corporate:
            let charityPercent = distributionPlan.rules.charityPercent / 100
            let appPercent = distributionPlan.rules.appPercent / 100
            let charityAmount = totalPool * charityPercent
            let appAmount = totalPool * appPercent
            // Mock: just record accounting; real implementation would transfer
            let charityEntry = LedgerEntry(
                transactionId: UUID().uuidString,
                accountId: "charity_account_\(distributionPlan.charityId ?? "default")",
                accountType: .charityAccount,
                entryType: .credit,
                amount: charityAmount,
                description: "Escrow forfeiture to charity",
                reference: escrow.id
            )
            _ = try await (accountingService as? MockAccountingService)?.accountingRepository.saveLedgerEntry(charityEntry)
            let appEntry = LedgerEntry(
                transactionId: UUID().uuidString,
                accountId: "platform_revenue",
                accountType: .feeAccount,
                entryType: .credit,
                amount: appAmount,
                description: "Escrow forfeiture to app",
                reference: escrow.id
            )
            _ = try await (accountingService as? MockAccountingService)?.accountingRepository.saveLedgerEntry(appEntry)
        case .group:
            for winner in distributionPlan.winners {
                let share = (winner.sharePercent / 100) * totalPool
                _ = try await walletService.releaseEscrow(amount: share, for: winner.userId, goalId: escrow.goalId)
            }
        }
        
        escrow.status = .forfeited
        escrow.updatedAt = Date()
        escrow = try await escrowRepository.updateEscrow(escrow)
        let tx = EscrowTransaction(escrowId: escrow.id, type: .forfeit, amount: totalPool, relatedTxRef: idempotencyKey)
        let saved = try await escrowRepository.appendTransaction(tx)
        txRefs.append(saved.id)
        return txRefs
    }
    
    func refund(escrowId: String, idempotencyKey: String) async throws -> [String] {
        if idempotencyLedger.contains(idempotencyKey) { return [] }
        idempotencyLedger.insert(idempotencyKey)
        
        var escrow = try await escrowRepository.getEscrow(escrowId)
        guard escrow.status == .held || escrow.status == .pendingDistribution || escrow.status == .partial else {
            throw EscrowServiceError.invalidState
        }
        
        var txRefs: [String] = []
        for s in escrow.stakeholders {
            _ = try await walletService.refundEscrow(amount: s.principal, for: s.userId, goalId: escrow.goalId)
        }
        escrow.status = .refunded
        escrow.updatedAt = Date()
        escrow = try await escrowRepository.updateEscrow(escrow)
        let tx = EscrowTransaction(escrowId: escrow.id, type: .refund, amount: escrow.totalPrincipal, relatedTxRef: idempotencyKey)
        let saved = try await escrowRepository.appendTransaction(tx)
        txRefs.append(saved.id)
        return txRefs
    }
    
    func reconcile(escrowId: String) async throws -> Bool {
        // In mock, always true
        return true
    }
}
