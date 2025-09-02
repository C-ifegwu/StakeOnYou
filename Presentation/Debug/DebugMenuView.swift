import SwiftUI

#if DEBUG
struct DebugMenuView: View {
    let onAccrualTick: () -> Void
    let onFakeDistribution: () -> Void
    let onResetMocks: () -> Void

    var body: some View {
        List {
            Section(header: Text("Accrual")) {
                Button("Trigger Accrual Tick", action: onAccrualTick)
            }
            Section(header: Text("Distribution")) {
                Button("Run Fake Distribution", action: onFakeDistribution)
            }
            Section(header: Text("State")) {
                Button("Reset Mocks", action: onResetMocks)
            }
        }
        .navigationTitle("Debug")
    }
}
#endif


