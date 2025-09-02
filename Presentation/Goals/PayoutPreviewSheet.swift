import SwiftUI

struct PayoutPreviewSheet: View {
	@ObservedObject var viewModel: PayoutPreviewViewModel
	let goalId: String
	let goalTitle: String
	
	var body: some View {
		NavigationView {
			VStack(spacing: 16) {
				headers
				content
				footer
			}
			.padding(16)
			.navigationTitle("Payout Preview")
			.navigationBarTitleDisplayMode(.inline)
		}
		.task {
			await viewModel.load(goalId: goalId)
		}
	}
	
	private var headers: some View {
		VStack(alignment: .leading, spacing: 8) {
			Text(goalTitle)
				.font(.headline)
			Text("Escrow: \(viewModel.statusText)")
				.font(.subheadline)
				.foregroundColor(.secondary)
		}
	}
	
	private var content: some View {
		VStack(spacing: 12) {
			row("Principal", amount: viewModel.summary?.totalPrincipal ?? 0)
			row("Accrued", amount: viewModel.summary?.accruedAmount ?? 0, color: .green)
			Divider()
			row("Estimated Fees", amount: 0) // Placeholder
			row("Charity Share", amount: 0)
			row("App Share", amount: 0)
			row("Winners Share", amount: 0)
			Divider()
			row("Estimated Net", amount: (viewModel.summary?.totalPrincipal ?? 0) + (viewModel.summary?.accruedAmount ?? 0))
		}
		.padding(12)
		.background(Color(.secondarySystemBackground))
		.cornerRadius(12)
	}
	
	private var footer: some View {
		VStack(spacing: 8) {
			if let success = viewModel.successMessage {
				Text(success)
					.font(.subheadline)
					.foregroundColor(.green)
			}
			if let error = viewModel.errorMessage {
				Text(error)
					.font(.subheadline)
					.foregroundColor(.red)
			}
			Button(action: {
				Task { await viewModel.confirm(goalId: goalId) }
			}) {
				HStack {
					if viewModel.isLoading { ProgressView().scaleEffect(0.8) }
					Text("Confirm Distribute")
				}
				.frame(maxWidth: .infinity)
				.padding(.vertical, 14)
				.background(Color.blue)
				.foregroundColor(.white)
				.cornerRadius(12)
			}
			.disabled(viewModel.isLoading)
		}
	}
	
	private func row(_ title: String, amount: Decimal, color: Color = .primary) -> some View {
		HStack {
			Text(title)
				.foregroundColor(.secondary)
			Spacer()
			Text(format(amount))
				.foregroundColor(color)
		}
	}
	
	private var statusText: String {
		switch viewModel.summary?.pendingDistribution ?? false {
		case true: return "Pending"
		case false: return "Ready"
		}
	}
	
	private func format(_ amount: Decimal) -> String {
		let f = NumberFormatter()
		f.numberStyle = .currency
		f.currencyCode = "USD"
		return f.string(from: NSDecimalNumber(decimal: amount)) ?? "\(amount)"
	}
}
