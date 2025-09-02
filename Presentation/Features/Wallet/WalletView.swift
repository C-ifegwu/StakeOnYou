import SwiftUI

// MARK: - Wallet View
struct WalletView: View {
    @StateObject private var viewModel: WalletViewModel
    @State private var selectedTab = 0
    
    private let userId: String
    
    init(
        userId: String,
        walletService: WalletService,
        paymentProvider: PaymentProvider,
        feeService: FeeService,
        charityRepository: CharityRepository,
        accountingService: AccountingService
    ) {
        self.userId = userId
        self._viewModel = StateObject(wrappedValue: WalletViewModel(
            walletService: walletService,
            paymentProvider: paymentProvider,
            feeService: feeService,
            charityRepository: charityRepository,
            accountingService: accountingService
        ))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with balance information
                balanceHeader
                
                // Tab picker
                tabPicker
                
                // Tab content
                TabView(selection: $selectedTab) {
                    // Overview tab
                    overviewTab
                        .tag(0)
                    
                    // Transactions tab
                    transactionsTab
                        .tag(1)
                    
                    // Settings tab
                    settingsTab
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Wallet")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        Task {
                            await viewModel.refreshWallet(for: userId)
                        }
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .refreshable {
                await viewModel.refreshWallet(for: userId)
            }
            .task {
                await viewModel.loadWallet(for: userId)
            }
            .sheet(isPresented: $viewModel.showDepositSheet) {
                DepositView(
                    viewModel: viewModel,
                    userId: userId
                )
            }
            .sheet(isPresented: $viewModel.showWithdrawSheet) {
                WithdrawView(
                    viewModel: viewModel,
                    userId: userId
                )
            }
            .sheet(isPresented: $viewModel.showTransactionDetail) {
                if let transaction = viewModel.selectedTransaction {
                    TransactionDetailView(transaction: transaction)
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }
    
    // MARK: - Balance Header
    private var balanceHeader: some View {
        VStack(spacing: 20) {
            // Total balance
            VStack(spacing: 8) {
                Text("Total Balance")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(viewModel.formattedTotalBalance)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            
            // Balance breakdown
            HStack(spacing: 40) {
                VStack(spacing: 4) {
                    Text("Available")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(viewModel.formattedAvailableBalance)
                        .font(.headline)
                        .foregroundColor(.green)
                }
                
                VStack(spacing: 4) {
                    Text("In Escrow")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(viewModel.formattedEscrowBalance)
                        .font(.headline)
                        .foregroundColor(.orange)
                }
            }
            
            // Action buttons
            HStack(spacing: 16) {
                Button(action: viewModel.showDeposit) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Deposit")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(!viewModel.canDeposit)
                
                Button(action: viewModel.showWithdraw) {
                    HStack {
                        Image(systemName: "minus.circle.fill")
                        Text("Withdraw")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(!viewModel.canWithdraw)
            }
            .padding(.horizontal, 20)
            
            // Status indicators
            HStack(spacing: 20) {
                Label(viewModel.kycStatusDisplay, systemImage: "person.circle")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Label(viewModel.walletStatusDisplay, systemImage: "creditcard")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Tab Picker
    private var tabPicker: some View {
        Picker("Wallet Tab", selection: $selectedTab) {
            Text("Overview").tag(0)
            Text("Transactions").tag(1)
            Text("Settings").tag(2)
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    // MARK: - Overview Tab
    private var overviewTab: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Quick actions
                quickActionsSection
                
                // Recent transactions
                if viewModel.hasTransactions {
                    recentTransactionsSection
                }
                
                // KYC status card
                kycStatusCard
                
                // Limits information
                limitsCard
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                QuickActionButton(
                    title: "Send Money",
                    icon: "arrow.up.circle.fill",
                    color: .blue
                ) {
                    // TODO: Implement send money
                }
                
                QuickActionButton(
                    title: "Request Money",
                    icon: "arrow.down.circle.fill",
                    color: .green
                ) {
                    // TODO: Implement request money
                }
                
                QuickActionButton(
                    title: "Charity",
                    icon: "heart.circle.fill",
                    color: .red
                ) {
                    // TODO: Navigate to charity selection
                }
                
                QuickActionButton(
                    title: "History",
                    icon: "clock.circle.fill",
                    color: .purple
                ) {
                    selectedTab = 1
                }
            }
        }
    }
    
    // MARK: - Recent Transactions Section
    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Transactions")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("View All") {
                    selectedTab = 1
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            LazyVStack(spacing: 8) {
                ForEach(viewModel.recentTransactions) { transaction in
                    TransactionRowView(transaction: transaction)
                        .onTapGesture {
                            viewModel.selectTransaction(transaction)
                        }
                }
            }
        }
    }
    
    // MARK: - KYC Status Card
    private var kycStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("KYC Status")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(viewModel.kycStatusDisplay)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if viewModel.kycStatus != .verified {
                    Button("Verify") {
                        // TODO: Navigate to KYC verification
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Limits Card
    private var limitsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Transaction Limits")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("$\(viewModel.wallet?.dailyLimit ?? 0)")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Monthly")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("$\(viewModel.wallet?.monthlyLimit ?? 0)")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Transactions Tab
    private var transactionsTab: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if viewModel.isLoading {
                    ProgressView("Loading transactions...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 100)
                } else if viewModel.transactions.isEmpty {
                    emptyTransactionsView
                } else {
                    ForEach(viewModel.transactions) { transaction in
                        TransactionRowView(transaction: transaction)
                            .onTapGesture {
                                viewModel.selectTransaction(transaction)
                            }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Empty Transactions View
    private var emptyTransactionsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "creditcard")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Transactions Yet")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Your transaction history will appear here once you make your first deposit or withdrawal.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    // MARK: - Settings Tab
    private var settingsTab: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Payment methods
                settingsSection(
                    title: "Payment Methods",
                    items: [
                        SettingsItem(title: "Credit Cards", icon: "creditcard", action: {}),
                        SettingsItem(title: "Bank Accounts", icon: "building.columns", action: {}),
                        SettingsItem(title: "Apple Pay", icon: "applelogo", action: {})
                    ]
                )
                
                // Security
                settingsSection(
                    title: "Security",
                    items: [
                        SettingsItem(title: "KYC Verification", icon: "person.circle", action: {}),
                        SettingsItem(title: "Two-Factor Auth", icon: "lock.shield", action: {}),
                        SettingsItem(title: "Transaction Limits", icon: "chart.bar", action: {})
                    ]
                )
                
                // Preferences
                settingsSection(
                    title: "Preferences",
                    items: [
                        SettingsItem(title: "Default Charity", icon: "heart", action: {}),
                        SettingsItem(title: "Notifications", icon: "bell", action: {}),
                        SettingsItem(title: "Currency", icon: "dollarsign.circle", action: {})
                    ]
                )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Settings Section
    private func settingsSection(title: String, items: [SettingsItem]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 1) {
                ForEach(items) { item in
                    Button(action: item.action) {
                        HStack {
                            Image(systemName: item.icon)
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            Text(item.title)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Color(.secondarySystemBackground))
                    }
                }
            }
            .cornerRadius(12)
        }
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
}

// MARK: - Settings Item
struct SettingsItem: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let action: () -> Void
}

// MARK: - Transaction Row View
struct TransactionRowView: View {
    let transaction: WalletTransaction
    
    var body: some View {
        HStack(spacing: 12) {
            // Transaction icon
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 40, height: 40)
                .background(iconColor.opacity(0.1))
                .cornerRadius(20)
            
            // Transaction details
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.description)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(transaction.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Amount
            VStack(alignment: .trailing, spacing: 4) {
                Text(formattedAmount)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(amountColor)
                
                Text(transaction.type.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var iconName: String {
        switch transaction.type {
        case .credit:
            return "arrow.down.circle.fill"
        case .debit:
            return "arrow.up.circle.fill"
        case .escrowHold:
            return "lock.circle.fill"
        case .escrowRelease:
            return "lock.open.circle.fill"
        case .fee:
            return "dollarsign.circle.fill"
        }
    }
    
    private var iconColor: Color {
        switch transaction.type {
        case .credit, .escrowRelease:
            return .green
        case .debit, .escrowHold:
            return .red
        case .fee:
            return .orange
        }
    }
    
    private var amountColor: Color {
        switch transaction.type {
        case .credit, .escrowRelease:
            return .green
        case .debit, .escrowHold:
            return .red
        case .fee:
            return .orange
        }
    }
    
    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSDecimalNumber(decimal: transaction.amount)) ?? "\(transaction.amount)"
    }
}

// MARK: - Transaction Detail View
struct TransactionDetailView: View {
    let transaction: WalletTransaction
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Transaction header
                    transactionHeader
                    
                    // Transaction details
                    transactionDetails
                    
                    // Balance impact
                    balanceImpact
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("Transaction Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var transactionHeader: some View {
        VStack(spacing: 16) {
            Image(systemName: iconName)
                .font(.system(size: 48))
                .foregroundColor(iconColor)
            
            Text(transaction.description)
                .font(.headline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            Text(formattedAmount)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(amountColor)
            
            Text(transaction.type.displayName)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
        }
        .padding(.top, 20)
    }
    
    private var transactionDetails: some View {
        VStack(spacing: 16) {
            Text("Transaction Details")
                .font(.headline)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                DetailRow(title: "Date", value: transaction.createdAt.formatted(date: .complete, time: .shortened))
                DetailRow(title: "Type", value: transaction.type.displayName)
                DetailRow(title: "Reference", value: transaction.reference)
                DetailRow(title: "Balance Before", value: formattedBalance(transaction.balanceBefore))
                DetailRow(title: "Balance After", value: formattedBalance(transaction.balanceAfter))
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var balanceImpact: some View {
        VStack(spacing: 16) {
            Text("Balance Impact")
                .font(.headline)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Before")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(formattedBalance(transaction.balanceBefore))
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .foregroundColor(.secondary)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("After")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(formattedBalance(transaction.balanceAfter))
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var iconName: String {
        switch transaction.type {
        case .credit:
            return "arrow.down.circle.fill"
        case .debit:
            return "arrow.up.circle.fill"
        case .escrowHold:
            return "lock.circle.fill"
        case .escrowRelease:
            return "lock.open.circle.fill"
        case .fee:
            return "dollarsign.circle.fill"
        }
    }
    
    private var iconColor: Color {
        switch transaction.type {
        case .credit, .escrowRelease:
            return .green
        case .debit, .escrowHold:
            return .red
        case .fee:
            return .orange
        }
    }
    
    private var amountColor: Color {
        switch transaction.type {
        case .credit, .escrowRelease:
            return .green
        case .debit, .escrowHold:
            return .red
        case .fee:
            return .orange
        }
    }
    
    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSDecimalNumber(decimal: transaction.amount)) ?? "\(transaction.amount)"
    }
    
    private func formattedBalance(_ balance: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSDecimalNumber(decimal: balance)) ?? "\(balance)"
    }
}

// MARK: - Detail Row
struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Preview
struct WalletView_Previews: PreviewProvider {
    static var previews: some View {
        WalletView(
            userId: "preview_user",
            walletService: MockWalletService(),
            paymentProvider: MockPaymentProvider(),
            feeService: MockFeeService(),
            charityRepository: MockCharityRepository(),
            accountingService: MockAccountingService(accountingRepository: MockAccountingRepository())
        )
    }
}
