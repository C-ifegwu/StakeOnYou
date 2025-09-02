import Foundation
import Combine

// MARK: - Wallet View Model
@MainActor
class WalletViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var wallet: Wallet?
    @Published var transactions: [WalletTransaction] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showDepositSheet = false
    @Published var showWithdrawSheet = false
    @Published var showTransactionDetail = false
    @Published var selectedTransaction: WalletTransaction?
    
    // MARK: - Private Properties
    private let walletService: WalletService
    private let paymentProvider: PaymentProvider
    private let feeService: FeeService
    private let charityRepository: CharityRepository
    private let accountingService: AccountingService
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var availableBalance: Decimal {
        wallet?.availableBalance ?? 0
    }
    
    var escrowBalance: Decimal {
        wallet?.escrowBalance ?? 0
    }
    
    var totalBalance: Decimal {
        wallet?.totalBalance ?? 0
    }
    
    var canDeposit: Bool {
        wallet?.canDeposit ?? false
    }
    
    var canWithdraw: Bool {
        wallet?.canWithdraw ?? false
    }
    
    var kycStatus: KYCStatus {
        wallet?.kycStatus ?? .unverified
    }
    
    var walletStatus: WalletStatus {
        wallet?.status ?? .active
    }
    
    // MARK: - Initialization
    init(
        walletService: WalletService,
        paymentProvider: PaymentProvider,
        feeService: FeeService,
        charityRepository: CharityRepository,
        accountingService: AccountingService
    ) {
        self.walletService = walletService
        self.paymentProvider = paymentProvider
        self.paymentProvider = paymentProvider
        self.feeService = feeService
        self.charityRepository = charityRepository
        self.accountingService = accountingService
    }
    
    // MARK: - Public Methods
    
    func loadWallet(for userId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let loadedWallet = try await walletService.getWallet(for: userId)
            wallet = loadedWallet
            
            // Load recent transactions
            await loadTransactionHistory(for: userId, limit: 10)
            
            isLoading = false
        } catch {
            await handleError(error)
        }
    }
    
    func refreshWallet(for userId: String) async {
        await loadWallet(for: userId)
    }
    
    func loadTransactionHistory(for userId: String, limit: Int? = nil) async {
        do {
            let history = try await walletService.getTransactionHistory(for: userId, limit: limit)
            transactions = history
        } catch {
            await handleError(error)
        }
    }
    
    func deposit(amount: Decimal, method: PaymentMethod, description: String, for userId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Calculate fees first
            let feeCalculation = try await feeService.calculateFees(
                for: amount,
                method: method,
                type: .deposit
            )
            
            // Process deposit
            let payment = try await walletService.deposit(
                amount: amount,
                to: userId,
                method: method
            )
            
            // Record in accounting
            try await accountingService.recordPayment(payment)
            
            // Refresh wallet and transactions
            await loadWallet(for: userId)
            await loadTransactionHistory(for: userId, limit: 10)
            
            isLoading = false
            
            // Show success message or navigate to success screen
            // This could be handled by the view layer
            
        } catch {
            await handleError(error)
        }
    }
    
    func withdraw(amount: Decimal, method: PaymentMethod, description: String, for userId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Calculate fees first
            let feeCalculation = try await feeService.calculateFees(
                for: amount,
                method: method,
                type: .withdrawal
            )
            
            // Process withdrawal
            let payment = try await walletService.withdraw(
                amount: amount,
                from: userId,
                method: method
            )
            
            // Record in accounting
            try await accountingService.recordPayment(payment)
            
            // Refresh wallet and transactions
            await loadWallet(for: userId)
            await loadTransactionHistory(for: userId, limit: 10)
            
            isLoading = false
            
            // Show success message or navigate to success screen
            
        } catch {
            await handleError(error)
        }
    }
    
    func holdEscrow(amount: Decimal, for userId: String, goalId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let payment = try await walletService.holdEscrow(
                amount: amount,
                for: userId,
                goalId: goalId
            )
            
            // Record in accounting
            let escrowRecord = EscrowRecord(
                userId: userId,
                goalId: goalId,
                amount: amount,
                status: .held
            )
            try await accountingService.recordEscrowHold(escrowRecord)
            
            // Refresh wallet
            await loadWallet(for: userId)
            
            isLoading = false
            
        } catch {
            await handleError(error)
        }
    }
    
    func releaseEscrow(amount: Decimal, for userId: String, goalId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let payment = try await walletService.releaseEscrow(
                amount: amount,
                for: userId,
                goalId: goalId
            )
            
            // Record in accounting
            let escrowRecord = EscrowRecord(
                userId: userId,
                goalId: goalId,
                amount: amount,
                status: .released
            )
            try await accountingService.recordEscrowRelease(escrowRecord)
            
            // Refresh wallet
            await loadWallet(for: userId)
            
            isLoading = false
            
        } catch {
            await handleError(error)
        }
    }
    
    func refundEscrow(amount: Decimal, for userId: String, goalId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let payment = try await walletService.refundEscrow(
                amount: amount,
                for: userId,
                goalId: goalId
            )
            
            // Refresh wallet
            await loadWallet(for: userId)
            
            isLoading = false
            
        } catch {
            await handleError(error)
        }
    }
    
    func calculateFees(for amount: Decimal, method: PaymentMethod, type: PaymentType) async -> FeeCalculation? {
        do {
            return try await feeService.calculateFees(
                for: amount,
                method: method,
                type: type
            )
        } catch {
            await handleError(error)
            return nil
        }
    }
    
    func validateTransaction(amount: Decimal, type: TransactionType, for userId: String) async -> ValidationResult? {
        do {
            return try await walletService.validateTransaction(
                amount: amount,
                type: type,
                for: userId
            )
        } catch {
            await handleError(error)
            return nil
        }
    }
    
    func selectTransaction(_ transaction: WalletTransaction) {
        selectedTransaction = transaction
        showTransactionDetail = true
    }
    
    func showDeposit() {
        showDepositSheet = true
    }
    
    func showWithdraw() {
        showWithdrawSheet = true
    }
    
    func dismissDeposit() {
        showDepositSheet = false
    }
    
    func dismissWithdraw() {
        showWithdrawSheet = false
    }
    
    func dismissTransactionDetail() {
        showTransactionDetail = false
        selectedTransaction = nil
    }
    
    // MARK: - Private Methods
    
    private func handleError(_ error: Error) async {
        isLoading = false
        
        if let walletError = error as? WalletServiceError {
            errorMessage = walletError.errorDescription
        } else if let paymentError = error as? PaymentProviderError {
            errorMessage = paymentError.errorDescription
        } else {
            errorMessage = error.localizedDescription
        }
        
        // Auto-dismiss error after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.errorMessage = nil
        }
    }
    
    private func clearError() {
        errorMessage = nil
    }
}

// MARK: - Wallet View Model Factory
protocol WalletViewModelFactory {
    func createWalletViewModel() -> WalletViewModel
}

// MARK: - Mock Wallet View Model Factory
class MockWalletViewModelFactory: WalletViewModelFactory {
    func createWalletViewModel() -> WalletViewModel {
        let walletService = MockWalletService()
        let paymentProvider = MockPaymentProvider()
        let feeService = MockFeeService()
        let charityRepository = MockCharityRepository()
        let accountingService = MockAccountingService(accountingRepository: MockAccountingRepository())
        
        return WalletViewModel(
            walletService: walletService,
            paymentProvider: paymentProvider,
            feeService: feeService,
            charityRepository: charityRepository,
            accountingService: accountingService
        )
    }
}

// MARK: - Wallet View Model Extensions
extension WalletViewModel {
    var formattedAvailableBalance: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = wallet?.currency ?? "USD"
        return formatter.string(from: NSDecimalNumber(decimal: availableBalance)) ?? "\(availableBalance)"
    }
    
    var formattedEscrowBalance: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = wallet?.currency ?? "USD"
        return formatter.string(from: NSDecimalNumber(decimal: escrowBalance)) ?? "\(escrowBalance)"
    }
    
    var formattedTotalBalance: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = wallet?.currency ?? "USD"
        return formatter.string(from: NSDecimalNumber(decimal: totalBalance)) ?? "\(totalBalance)"
    }
    
    var kycStatusDisplay: String {
        switch kycStatus {
        case .unverified:
            return "Unverified - Limited transactions"
        case .limited:
            return "Limited - Some restrictions apply"
        case .verified:
            return "Verified - Full access"
        case .blocked:
            return "Blocked - Contact support"
        }
    }
    
    var walletStatusDisplay: String {
        switch walletStatus {
        case .active:
            return "Active"
        case .suspended:
            return "Suspended - Contact support"
        case .frozen:
            return "Frozen - Contact support"
        case .closed:
            return "Closed"
        }
    }
    
    var hasTransactions: Bool {
        !transactions.isEmpty
    }
    
    var recentTransactions: [WalletTransaction] {
        Array(transactions.prefix(5))
    }
    
    var transactionCount: Int {
        transactions.count
    }
}
