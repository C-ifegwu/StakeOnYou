Escrow Reconciliation Runbook

Purpose
Detect and correct mismatches between Wallet balances, Escrow state, and Transaction ledger.

Signals
- Negative balances or orphan transactions
- Escrow `partial` status older than 24h
- Missing receipt refs for `released/forfeited/refunded`

Procedure
1. Identify target `escrowId`
2. Fetch escrow, wallet balances, transactions
3. Compute expected vs actual
4. If discrepancy:
   - Mark `partial` and enqueue compensation or rollback
   - Record `AuditEvent` with correlationId
5. Re-run until clean

Safety
- Idempotency keys per compensation
- Read-modify-write with last-write-wins
- Do not block UI thread; use background context


