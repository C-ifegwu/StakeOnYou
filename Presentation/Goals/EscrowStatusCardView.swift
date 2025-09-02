import SwiftUI

struct EscrowStatusCardView: View {
    @ObservedObject var viewModel: EscrowViewModel
    let goalId: String
    let onPayoutPreview: () -> Void
    let onViewTransactions: () -> Void
    let onFileDispute: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Escrow Status")
                    .font(.headline)
                Spacer()
                Text(statusBadge)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(badgeColor.opacity(0.15))
                    .foregroundColor(badgeColor)
                    .cornerRadius(8)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Principal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatted(viewModel.summary?.totalPrincipal ?? 0))
                        .font(.headline)
                }
                Spacer()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Accrued")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatted(viewModel.summary?.accruedAmount ?? 0))
                        .font(.headline)
                        .foregroundColor(.green)
                }
            }
            
            if let next = viewModel.summary?.nextActionAt {
                Text("Next action: \(next.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 8) {
                Button("Payout Preview", action: onPayoutPreview)
                    .buttonStyle(.borderedProminent)
                Button("Transactions", action: onViewTransactions)
                    .buttonStyle(.bordered)
                if viewModel.summary?.pendingDistribution == true {
                    Button("File Dispute", action: onFileDispute)
                        .buttonStyle(.bordered)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .task {
            await viewModel.load(goalId: goalId)
        }
    }
    
    private var statusBadge: String {
        guard let escrow = viewModel.escrow else { return "—" }
        switch escrow.status {
        case .held: return "HELD"
        case .released: return "RELEASED"
        case .forfeited: return "FORFEITED"
        case .refunded: return "REFUNDED"
        case .pendingDistribution: return "PENDING"
        case .partial: return "PARTIAL"
        }
    }
    
    private var badgeColor: Color {
        guard let escrow = viewModel.escrow else { return .gray }
        switch escrow.status {
        case .held: return .orange
        case .released: return .green
        case .forfeited: return .red
        case .refunded: return .blue
        case .pendingDistribution: return .yellow
        case .partial: return .purple
        }
    }
    
    private func formatted(_ amount: Decimal) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        return f.string(from: NSDecimalNumber(decimal: amount)) ?? "\(amount)"
    }
}
