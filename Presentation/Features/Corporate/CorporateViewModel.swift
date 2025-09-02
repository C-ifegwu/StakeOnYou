import SwiftUI
import Combine

@MainActor
class CorporateViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var corporateAccounts: [CorporateAccount] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Sheet and Alert Presentation
    @Published var presentedSheet: CorporateSheetDestination?
    @Published var presentedAlert: CorporateAlertDestination?
    
    // Filtering and Sorting
    @Published var selectedIndustry: Industry?
    @Published var selectedSize: CompanySize?
    @Published var searchText = ""
    @Published var sortOrder: CorporateSortOrder = .createdDescending
    
    // MARK: - Computed Properties
    var filteredCorporateAccounts: [CorporateAccount] {
        var filtered = corporateAccounts
        
        // Apply industry filter
        if let selectedIndustry = selectedIndustry {
            filtered = filtered.filter { $0.industry == selectedIndustry }
        }
        
        // Apply size filter
        if let selectedSize = selectedSize {
            filtered = filtered.filter { $0.size == selectedSize }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { corporate in
                corporate.companyName.localizedCaseInsensitiveContains(searchText) ||
                corporate.description.localizedCaseInsensitiveContains(searchText) ||
                corporate.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Apply sorting
        filtered.sort { first, second in
            switch sortOrder {
            case .createdAscending:
                return first.createdAt < second.createdAt
            case .createdDescending:
                return first.createdAt > second.createdAt
            case .nameAscending:
                return first.companyName < second.companyName
            case .nameDescending:
                return first.companyName > second.companyName
            case .employeeCountAscending:
                return (first.employeeCount ?? 0) < (second.employeeCount ?? 0)
            case .employeeCountDescending:
                return (first.employeeCount ?? 0) > (second.employeeCount ?? 0)
            case .industryAscending:
                return first.industry.rawValue < second.industry.rawValue
            case .industryDescending:
                return first.industry.rawValue > second.industry.rawValue
            }
        }
        
        return filtered
    }
    
    var myCompanies: [CorporateAccount] {
        filteredCorporateAccounts.filter { corporate in
            // TODO: Check if current user is admin
            corporate.adminIds.contains("current_user_id")
        }
    }
    
    var employeeCompanies: [CorporateAccount] {
        filteredCorporateAccounts.filter { corporate in
            // TODO: Check if current user is employee
            corporate.employees.contains { $0.userId == "current_user_id" }
        }
    }
    
    var invitedCompanies: [CorporateAccount] {
        // TODO: Implement actual invitation logic
        return []
    }
    
    var corporateAccountsCount: Int {
        myCompanies.count + employeeCompanies.count
    }
    
    var totalEmployeesCount: Int {
        corporateAccounts.reduce(0) { count, corporate in
            count + (corporate.employeeCount ?? 0)
        }
    }
    
    var industries: [Industry] {
        Array(Set(corporateAccounts.map { $0.industry })).sorted { $0.displayName < $1.displayName }
    }
    
    var companySizes: [CompanySize] {
        Array(Set(corporateAccounts.compactMap { $0.size })).sorted { $0.displayName < $1.displayName }
    }
    
    // MARK: - Dependencies
    private let corporateRepository: CorporateRepository
    private let userRepository: UserRepository
    private let analyticsService: AnalyticsService
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(
        corporateRepository: CorporateRepository = DIContainer.shared.resolve(CorporateRepository.self),
        userRepository: UserRepository = DIContainer.shared.resolve(UserRepository.self),
        analyticsService: AnalyticsService = DIContainer.shared.resolve(AnalyticsService.self)
    ) {
        self.corporateRepository = corporateRepository
        self.userRepository = userRepository
        self.analyticsService = analyticsService
        
        setupObservers()
    }
    
    // MARK: - Public Methods
    func loadCorporateAccounts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            corporateAccounts = try await corporateRepository.fetchCorporateAccounts()
            analyticsService.trackEvent(AnalyticsEvent(
                name: "corporate_accounts_loaded",
                properties: ["count": corporateAccounts.count]
            ))
        } catch {
            errorMessage = "Failed to load corporate accounts: \(error.localizedDescription)"
            logError("Failed to load corporate accounts: \(error)", category: "CorporateViewModel")
            
            analyticsService.trackError(error, context: "CorporateViewModel.loadCorporateAccounts")
        }
        
        isLoading = false
    }
    
    func refreshCorporateAccounts() async {
        await loadCorporateAccounts()
    }
    
    func createCorporateAccount(_ corporate: CorporateAccount) async {
        do {
            let createdCorporate = try await corporateRepository.createCorporateAccount(corporate)
            corporateAccounts.append(createdCorporate)
            
            analyticsService.trackEvent(AnalyticsEvent(
                name: "corporate_account_created",
                properties: [
                    "corporate_id": createdCorporate.id,
                    "industry": createdCorporate.industry.rawValue,
                    "size": createdCorporate.size?.rawValue ?? "unknown"
                ]
            ))
            
            presentedAlert = .success("Company Created", "Your company has been created successfully!")
        } catch {
            errorMessage = "Failed to create company: \(error.localizedDescription)"
            logError("Failed to create company: \(error)", category: "CorporateViewModel")
            
            analyticsService.trackError(error, context: "CorporateViewModel.createCorporateAccount")
        }
    }
    
    func updateCorporateAccount(_ corporate: CorporateAccount) async {
        do {
            let updatedCorporate = try await corporateRepository.updateCorporateAccount(corporate)
            if let index = corporateAccounts.firstIndex(where: { $0.id == updatedCorporate.id }) {
                corporateAccounts[index] = updatedCorporate
            }
            
            analyticsService.trackEvent(AnalyticsEvent(
                name: "corporate_account_updated",
                properties: ["corporate_id": updatedCorporate.id]
            ))
            
            presentedAlert = .success("Company Updated", "Your company has been updated successfully!")
        } catch {
            errorMessage = "Failed to update company: \(error.localizedDescription)"
            logError("Failed to update company: \(error)", category: "CorporateViewModel")
            
            analyticsService.trackError(error, context: "CorporateViewModel.updateCorporateAccount")
        }
    }
    
    func deleteCorporateAccount(_ corporate: CorporateAccount) async {
        do {
            try await corporateRepository.deleteCorporateAccount(corporate.id)
            corporateAccounts.removeAll { $0.id == corporate.id }
            
            analyticsService.trackEvent(AnalyticsEvent(
                name: "corporate_account_deleted",
                properties: ["corporate_id": corporate.id]
            ))
            
            presentedAlert = .success("Company Deleted", "Your company has been deleted successfully!")
        } catch {
            errorMessage = "Failed to delete company: \(error.localizedDescription)"
            logError("Failed to delete company: \(error)", category: "CorporateViewModel")
            
            analyticsService.trackError(error, context: "CorporateViewModel.deleteCorporateAccount")
        }
    }
    
    func acceptCorporateInvitation(_ corporateId: String) async {
        // TODO: Implement actual invitation acceptance
        logInfo("Corporate invitation accepted for company: \(corporateId)", category: "CorporateViewModel")
        
        analyticsService.trackEvent(AnalyticsEvent(
            name: "corporate_invitation_accepted",
            properties: ["corporate_id": corporateId]
        ))
        
        presentedAlert = .corporateInvitation(
            "Invitation Accepted",
            "You have successfully joined the company!"
        )
    }
    
    func declineCorporateInvitation(_ corporateId: String) async {
        // TODO: Implement actual invitation decline
        logInfo("Corporate invitation declined for company: \(corporateId)", category: "CorporateViewModel")
        
        analyticsService.trackEvent(AnalyticsEvent(
            name: "corporate_invitation_declined",
            properties: ["corporate_id": corporateId]
        ))
        
        presentedAlert = .corporateInvitation(
            "Invitation Declined",
            "You have declined the company invitation."
        )
    }
    
    func showCreateCorporate() {
        presentedSheet = .createCorporate
    }
    
    func showEditCorporate(_ corporate: CorporateAccount) {
        presentedSheet = .editCorporate(corporate.id)
    }
    
    func showJoinCorporate() {
        presentedSheet = .joinCorporate
    }
    
    func showCorporateInvite(_ corporate: CorporateAccount) {
        presentedSheet = .corporateInvite(corporate.id)
    }
    
    func showCorporateSettings(_ corporate: CorporateAccount) {
        presentedSheet = .corporateSettings(corporate.id)
    }
    
    // MARK: - Filtering and Sorting
    func applyIndustryFilter(_ industry: Industry?) {
        selectedIndustry = industry
        analyticsService.trackEvent(AnalyticsEvent(
            name: "corporate_filtered",
            properties: ["filter_type": "industry", "value": industry?.rawValue ?? "none"]
        ))
    }
    
    func applySizeFilter(_ size: CompanySize?) {
        selectedSize = size
        analyticsService.trackEvent(AnalyticsEvent(
            name: "corporate_filtered",
            properties: ["filter_type": "size", "value": size?.rawValue ?? "none"]
        ))
    }
    
    func applySearchFilter(_ searchText: String) {
        self.searchText = searchText
        analyticsService.trackEvent(AnalyticsEvent(
            name: "corporate_searched",
            properties: ["search_text": searchText]
        ))
    }
    
    func applySortOrder(_ sortOrder: CorporateSortOrder) {
        self.sortOrder = sortOrder
        analyticsService.trackEvent(AnalyticsEvent(
            name: "corporate_sorted",
            properties: ["sort_order": sortOrder.rawValue]
        ))
    }
    
    func clearFilters() {
        selectedIndustry = nil
        selectedSize = nil
        searchText = ""
        sortOrder = .createdDescending
        
        analyticsService.trackEvent(AnalyticsEvent(
            name: "corporate_filters_cleared"
        ))
    }
    
    // MARK: - Private Methods
    private func setupObservers() {
        // Observe search text changes for debounced search
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] searchText in
                self?.applySearchFilter(searchText)
            }
            .store(in: &cancellables)
        
        // Observe filter changes
        $selectedIndustry
            .sink { [weak self] industry in
                if let industry = industry {
                    self?.applyIndustryFilter(industry)
                }
            }
            .store(in: &cancellables)
        
        $selectedSize
            .sink { [weak self] size in
                if let size = size {
                    self?.applySizeFilter(size)
                }
            }
            .store(in: &cancellables)
    }
    
    private func logError(_ message: String, category: String) {
        logError(message, category: category)
    }
}

// MARK: - Supporting Types
enum CorporateSortOrder: String, CaseIterable {
    case createdAscending = "created_asc"
    case createdDescending = "created_desc"
    case nameAscending = "name_asc"
    case nameDescending = "name_desc"
    case employeeCountAscending = "employees_asc"
    case employeeCountDescending = "employees_desc"
    case industryAscending = "industry_asc"
    case industryDescending = "industry_desc"
    
    var displayName: String {
        switch self {
        case .createdAscending: return "Created (Oldest)"
        case .createdDescending: return "Created (Newest)"
        case .nameAscending: return "Name (A-Z)"
        case .nameDescending: return "Name (Z-A)"
        case .employeeCountAscending: return "Employees (Fewest)"
        case .employeeCountDescending: return "Employees (Most)"
        case .industryAscending: return "Industry (A-Z)"
        case .industryDescending: return "Industry (Z-A)"
        }
    }
}

enum CorporateSheetDestination: Identifiable {
    case createCorporate
    case editCorporate(String)
    case joinCorporate
    case corporateInvite(String)
    case corporateSettings(String)
    
    var id: String {
        switch self {
        case .createCorporate: return "createCorporate"
        case .editCorporate(let id): return "editCorporate_\(id)"
        case .joinCorporate: return "joinCorporate"
        case .corporateInvite(let corporateId): return "corporateInvite_\(corporateId)"
        case .corporateSettings(let corporateId): return "corporateSettings_\(corporateId)"
        }
    }
}

enum CorporateAlertDestination: Identifiable {
    case error(String, String?)
    case success(String, String?)
    case confirmation(String, String?, () -> Void)
    case corporateInvitation(String, String?)
    
    var id: String {
        switch self {
        case .error(let title, let message): return "error_\(title)_\(message ?? "")"
        case .success(let title, let message): return "success_\(title)_\(message ?? "")"
        case .confirmation(let title, let message, _): return "confirmation_\(title)_\(message ?? "")"
        case .corporateInvitation(let title, let message): return "corporateInvitation_\(title)_\(message ?? "")"
        }
    }
}
