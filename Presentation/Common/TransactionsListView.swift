import SwiftUI

struct TransactionsListView: View {
	let transactions: [EscrowTransaction]
	let onTap: (EscrowTransaction) -> Void
	
	var body: some View {
		List(transactions, id: \.id) { tx in
			HStack(spacing: 12) {
				Image(systemName: icon(tx))
					.foregroundColor(color(tx))
				VStack(alignment: .leading, spacing: 2) {
					Text(title(tx))
						.font(.subheadline)
					Text(tx.createdAt, style: .date)
						.font(.caption)
						.foregroundColor(.secondary)
				}
				Spacer()
				Text(format(tx.amount))
					.font(.subheadline)
			}
			.contentShape(Rectangle())
			.onTapGesture { onTap(tx) }
		}
	}
	
	private func title(_ tx: EscrowTransaction) -> String {
		switch tx.type {
		case .hold: return "Hold"
		case .release: return "Release"
		case .forfeit: return "Forfeit"
		case .refund: return "Refund"
		case .fee: return "Fee"
		}
	}
	
	private func icon(_ tx: EscrowTransaction) -> String {
		switch tx.type {
		case .hold: return "lock.circle"
		case .release: return "lock.open.circle"
		case .forfeit: return "xmark.octagon"
		case .refund: return "arrow.uturn.backward.circle"
		case .fee: return "dollarsign.circle"
		}
	}
	
	private func color(_ tx: EscrowTransaction) -> Color {
		switch tx.type {
		case .hold: return .orange
		case .release: return .green
		case .forfeit: return .red
		case .refund: return .blue
		case .fee: return .purple
		}
	}
	
	private func format(_ amount: Decimal) -> String {
		let f = NumberFormatter()
		f.numberStyle = .currency
		f.currencyCode = "USD"
		return f.string(from: NSDecimalNumber(decimal: amount)) ?? "\(amount)"
	}
}
