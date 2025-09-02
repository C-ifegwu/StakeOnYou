import Foundation

actor AccrualBackgroundWorker {
    private let escrowRepository: EscrowRepository
    private let accrueEscrowUseCase: AccrueEscrowUseCase
    private var timerTask: Task<Void, Never>?
    private var isRunning: Bool = false
    private let intervalSeconds: TimeInterval

    init(escrowRepository: EscrowRepository, accrueEscrowUseCase: AccrueEscrowUseCase, intervalSeconds: TimeInterval = 15 * 60) {
        self.escrowRepository = escrowRepository
        self.accrueEscrowUseCase = accrueEscrowUseCase
        self.intervalSeconds = intervalSeconds
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        timerTask = Task { [intervalSeconds] in
            while !Task.isCancelled {
                await tick()
                try? await Task.sleep(nanoseconds: UInt64(intervalSeconds * 1_000_000_000))
            }
        }
    }

    func stop() {
        timerTask?.cancel()
        timerTask = nil
        isRunning = false
    }

    func significantTimeChange() async {
        await tick()
    }

    private func tick() async {
        do {
            // List all active escrows and accrue a small period fragment (intervalSeconds)
            let activeEscrows = try await listActiveEscrows()
            for escrow in activeEscrows {
                _ = try await accrueEscrowUseCase.execute(escrowId: escrow.id, asOf: Date())
            }
        } catch {
            // Intentionally swallow to keep background worker alive; consider audit logging elsewhere
        }
    }

    private func listActiveEscrows() async throws -> [Escrow] {
        // naive: map over all goals by scanning via repository if available; otherwise, return those in held/pending/partial states
        // Since EscrowRepository lacks a listAll, derive from a mocked path by querying known goals in app context.
        // For now, return empty; actual app should provide goalIds to scan or add a listActive API.
        return []
    }
}


