ADR: Distribution Idempotency

Context
All money-movement operations must be idempotent. External providers can time out or retry.

Decision
- Every distribution call carries an idempotency key
- We store external provider reference and local receipt refs
- On duplicate requests, we return prior result without re-executing

Consequences
- Simpler retry semantics
- Requires storage of request fingerprint and results
- Auditable via `AuditEvent.externalTxRef`


