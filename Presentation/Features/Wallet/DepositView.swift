import SwiftUI

// MARK: - Deposit View
struct DepositView: View {
    @ObservedObject var viewModel: WalletViewModel
    let userId: String
    
    @State private var amount: String = ""
    @State private var selectedPaymentMethod: PaymentMethod = .stripe
    @State private var description: String = ""
    @State private var showFeeCalculation = false
    @State private var feeCalculation: FeeCalculation?
    @State private var isCalculatingFees = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
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
            .navigationTitle("Deposit")
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
                Text("Your deposit has been processed successfully!")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {
                    // Error will be cleared automatically
                }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            
            Text("Add Money to Your Wallet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            Text("Choose an amount and payment method to add funds to your wallet.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
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
                ForEach([10, 25, 50, 100, 250, 500], id: \.self) { quickAmount in
                    Button(action: {
                        amount = "\(quickAmount)"
                    }) {
                        Text("$\(quickAmount)")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    // MARK: - Payment Method Section
    private var paymentMethodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Payment Method")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(PaymentMethod.allCases, id: \.self) { method in
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
            
            TextField("e.g., Monthly budget, Emergency fund", text: $description)
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
                    Text("Base Amount")
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
                
                // Total
                HStack {
                    Text("Total")
                        .fontWeight(.semibold)
                    Spacer()
                    Text(fees.formattedTotalAmount)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
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
                .disabled(amount.isEmpty || isCalculatingFees)
            }
            
            // Deposit button
            if showFeeCalculation {
                Button(action: processDeposit) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "plus.circle.fill")
                        }
                        Text("Process Deposit")
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
        guard let amountValue = Decimal(string: amount) else { return false }
        return amountValue > 0 && amountValue <= 10000 // Max deposit limit
    }
    
    private var amountValue: Decimal? {
        Decimal(string: amount)
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
                type: .deposit
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
    
    private func processDeposit() {
        guard let amountValue = amountValue else { return }
        
        Task {
            await viewModel.deposit(
                amount: amountValue,
                method: selectedPaymentMethod,
                description: description.isEmpty ? "Deposit via \(selectedPaymentMethod.displayName)" : description,
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
}

// MARK: - Payment Method Card
struct PaymentMethodCard: View {
    let method: PaymentMethod
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: method.iconName)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)
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
            .background(isSelected ? Color.blue : Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var methodDescription: String {
        switch method {
        case .stripe:
            return "Credit/Debit Card"
        case .applePay:
            return "Apple Pay"
        case .bankTransfer:
            return "Bank Transfer"
        case .internal:
            return "Internal Transfer"
        }
    }
}

// MARK: - Preview
struct DepositView_Previews: PreviewProvider {
    static var previews: some View {
        DepositView(
            viewModel: MockWalletViewModelFactory().createWalletViewModel(),
            userId: "preview_user"
        )
    }
}
