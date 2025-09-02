import SwiftUI

// MARK: - Withdraw View
struct WithdrawView: View {
    @ObservedObject var viewModel: WalletViewModel
    let userId: String
    
    @State private var amount: String = ""
    @State private var selectedPaymentMethod: PaymentMethod = .bankTransfer
    @State private var description: String = ""
    @State private var showFeeCalculation = false
    @State private var feeCalculation: FeeCalculation?
    @State private var isCalculatingFees = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showConfirmation = false
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Available balance
                    availableBalanceSection
                    
                    // Amount input
                    amountSection
                    
                    // Payment method selection
                    paymentMethodSection
                    
                    // Description input
                    descriptionSection
                    
                    // Fee calculation
                    if showFeeCalculation, let fees = feeCalculation {
                        feeCalculationSection(fees)
                    }
                    
                    // Action buttons
                    actionButtonsSection
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationTitle("Withdraw")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onChange(of: amount) { newAmount in
                calculateFeesIfNeeded()
            }
            .onChange(of: selectedPaymentMethod) { _ in
                calculateFeesIfNeeded()
            }
            .alert("Success", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your withdrawal has been processed successfully!")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {
                    // Error will be cleared automatically
                }
            } message: {
                Text(errorMessage)
            }
            .alert("Confirm Withdrawal", isPresented: $showConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Withdraw", role: .destructive) {
                    processWithdrawal()
                }
            } message: {
                Text("Are you sure you want to withdraw \(formattedAmount)? This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "minus.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)
            
            Text("Withdraw from Your Wallet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            Text("Choose an amount and payment method to withdraw funds from your wallet.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Available Balance Section
    private var availableBalanceSection: some View {
        VStack(spacing: 12) {
            Text("Available Balance")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(viewModel.formattedAvailableBalance)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.green)
            
            if viewModel.kycStatus != .verified {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("KYC verification required for withdrawals")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(20)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Amount Section
    private var amountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Amount")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack {
                Text("$")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                TextField("0.00", text: $amount)
                    .font(.title2)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onChange(of: amount) { newValue in
                        // Filter to only allow valid decimal input
                        let filtered = newValue.filter { "0123456789.".contains($0) }
                        if filtered != newValue {
                            amount = filtered
                        }
                        
                        // Ensure only one decimal point
                        let components = filtered.components(separatedBy: ".")
                        if components.count > 2 {
                            amount = components[0] + "." + components[1]
                        }
                    }
                
                Spacer()
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            
            // Quick amount buttons
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                ForEach(quickAmounts, id: \.self) { quickAmount in
                    Button(action: {
                        amount = "\(quickAmount)"
                    }) {
                        Text("$\(quickAmount)")
                            .font(.subheadline)
                            .foregroundColor(.green)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .disabled(quickAmount > viewModel.availableBalance)
                }
            }
            
            // Max amount button
            if viewModel.availableBalance > 0 {
                Button(action: {
                    amount = "\(viewModel.availableBalance)"
                }) {
                    Text("Withdraw All ($\(viewModel.availableBalance))")
                        .font(.subheadline)
                        .foregroundColor(.green)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
    }
    
    // MARK: - Payment Method Section
    private var paymentMethodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Withdrawal Method")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(withdrawalMethods, id: \.self) { method in
                    PaymentMethodCard(
                        method: method,
                        isSelected: selectedPaymentMethod == method,
                        action: {
                            selectedPaymentMethod = method
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Description Section
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Description (Optional)")
                .font(.headline)
                .foregroundColor(.primary)
            
            TextField("e.g., Emergency funds, Monthly expenses", text: $description)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.subheadline)
        }
    }
    
    // MARK: - Fee Calculation Section
    private func feeCalculationSection(_ fees: FeeCalculation) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Fee Breakdown")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                // Base amount
                HStack {
                    Text("Withdrawal Amount")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(fees.formattedBaseAmount)
                        .fontWeight(.medium)
                }
                
                // Fees
                ForEach(fees.feeBreakdown, id: \.description) { fee in
                    HStack {
                        Text(fee.description)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(fee.formattedAmount)
                            .foregroundColor(.orange)
                    }
                }
                
                Divider()
                
                // Net amount
                HStack {
                    Text("You'll Receive")
                        .fontWeight(.semibold)
                    Spacer()
                    Text(formattedNetAmount(fees))
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                
                // Fee percentage
                HStack {
                    Text("Total Fees")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(fees.formattedFeePercentage)
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            // Calculate fees button
            if !showFeeCalculation {
                Button(action: calculateFees) {
                    HStack {
                        if isCalculatingFees {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "calculator")
                        }
                        Text("Calculate Fees")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(amount.isEmpty || isCalculatingFees || !canWithdraw)
            }
            
            // Withdraw button
            if showFeeCalculation {
                Button(action: {
                    showConfirmation = true
                }) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "minus.circle.fill")
                        }
                        Text("Process Withdrawal")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(viewModel.isLoading || !isFormValid)
            }
            
            // Terms and conditions
            Text("By proceeding, you agree to our terms and conditions and privacy policy.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Computed Properties
    private var isFormValid: Bool {
        guard let amountValue = amountValue else { return false }
        return amountValue > 0 && amountValue <= viewModel.availableBalance
    }
    
    private var amountValue: Decimal? {
        Decimal(string: amount)
    }
    
    private var canWithdraw: Bool {
        viewModel.canWithdraw && viewModel.kycStatus == .verified
    }
    
    private var quickAmounts: [Decimal] {
        let available = viewModel.availableBalance
        let amounts: [Decimal] = [10, 25, 50, 100, 250, 500]
        return amounts.filter { $0 <= available }
    }
    
    private var withdrawalMethods: [PaymentMethod] {
        [.bankTransfer, .stripe] // Only allow bank transfers and Stripe for withdrawals
    }
    
    private var formattedAmount: String {
        guard let amountValue = amountValue else { return "0.00" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSDecimalNumber(decimal: amountValue)) ?? "\(amountValue)"
    }
    
    // MARK: - Private Methods
    private func calculateFeesIfNeeded() {
        guard let amountValue = amountValue, amountValue > 0 else {
            showFeeCalculation = false
            return
        }
        
        // Debounce fee calculation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if amount == self.amount && selectedPaymentMethod == self.selectedPaymentMethod {
                calculateFees()
            }
        }
    }
    
    private func calculateFees() {
        guard let amountValue = amountValue, amountValue > 0 else { return }
        
        isCalculatingFees = true
        
        Task {
            let fees = await viewModel.calculateFees(
                for: amountValue,
                method: selectedPaymentMethod,
                type: .withdrawal
            )
            
            await MainActor.run {
                isCalculatingFees = false
                if let fees = fees {
                    feeCalculation = fees
                    showFeeCalculation = true
                }
            }
        }
    }
    
    private func processWithdrawal() {
        guard let amountValue = amountValue else { return }
        
        Task {
            await viewModel.withdraw(
                amount: amountValue,
                method: selectedPaymentMethod,
                description: description.isEmpty ? "Withdrawal via \(selectedPaymentMethod.displayName)" : description,
                for: userId
            )
            
            await MainActor.run {
                if viewModel.errorMessage == nil {
                    showSuccess = true
                } else {
                    errorMessage = viewModel.errorMessage ?? "An error occurred"
                    showError = true
                }
            }
        }
    }
    
    private func formattedNetAmount(_ fees: FeeCalculation) -> String {
        let netAmount = fees.baseAmount - fees.feeAmount
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSDecimalNumber(decimal: netAmount)) ?? "\(netAmount)"
    }
}

// MARK: - Payment Method Card
struct WithdrawPaymentMethodCard: View {
    let method: PaymentMethod
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: method.iconName)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .green)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(method.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(methodDescription)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.title3)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(isSelected ? Color.green : Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var methodDescription: String {
        switch method {
        case .stripe:
            return "Credit/Debit Card"
        case .bankTransfer:
            return "Bank Transfer (2-3 days)"
        default:
            return "Withdrawal Method"
        }
    }
}

// MARK: - Preview
struct WithdrawView_Previews: PreviewProvider {
    static var previews: some View {
        WithdrawView(
            viewModel: MockWalletViewModelFactory().createWalletViewModel(),
            userId: "preview_user"
        )
    }
}
