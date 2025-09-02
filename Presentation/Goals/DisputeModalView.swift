import SwiftUI

struct DisputeModalView: View {
	@ObservedObject var escrowViewModel: EscrowViewModel
	let goalId: String
	let userId: String
	
	@State private var reason: String = ""
	@State private var evidence: [String] = []
	@State private var isSubmitting = false
	
	var body: some View {
		NavigationView {
			Form {
				Section(header: Text("Reason")) {
					TextEditor(text: $reason)
						.frame(minHeight: 120)
				}
				Section(header: Text("Evidence (URLs)")) {
					ForEach(evidence.indices, id: \.self) { idx in
						TextField("Evidence URL", text: Binding(
							get: { evidence[idx] },
							set: { evidence[idx] = $0 }
						))
					}
					Button("Add Evidence") {
						guard evidence.count < 5 else { return }
						evidence.append("")
					}
				}
				Section {
					Button(action: submit) {
						HStack {
							if isSubmitting { ProgressView().scaleEffect(0.8) }
							Text("Submit Dispute")
						}
					}
					.disabled(!canSubmit || isSubmitting)
				}
			}
			.navigationTitle("File Dispute")
			.navigationBarTitleDisplayMode(.inline)
		}
	}
	
	private var canSubmit: Bool {
		!reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && reason.count <= 2000
	}
	
	private func submit() {
		guard canSubmit else { return }
		isSubmitting = true
		Task {
			await escrowViewModel.fileDispute(goalId: goalId, userId: userId, reason: reason, evidenceRefs: evidence.filter { !$0.isEmpty })
			await MainActor.run { isSubmitting = false }
		}
	}
}
