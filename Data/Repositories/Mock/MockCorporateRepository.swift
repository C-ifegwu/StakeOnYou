import Foundation
import Combine

// MARK: - Mock Corporate Repository Implementation
class MockCorporateRepository: CorporateRepository {
    // MARK: - Properties
    private var corporateAccounts: [String: CorporateAccount] = [:]
    private let logger: Logger
    
    // MARK: - Initialization
    init(logger: Logger = ConsoleLogger()) {
        self.logger = logger
        setupMockData()
    }
    
    // MARK: - CRUD Operations
    func createCorporateAccount(_ account: CorporateAccount) async throws -> CorporateAccount {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        var newAccount = account
        if newAccount.id.isEmpty {
            newAccount = CorporateAccount(
                id: UUID().uuidString,
                companyName: account.companyName,
                industry: account.industry,
                size: account.size,
                adminUsers: account.adminUsers,
                employees: account.employees,
                policies: account.policies,
                matchPercentage: account.matchPercentage,
                verificationStrictness: account.verificationStrictness,
                isActive: account.isActive,
                createdAt: Date(),
                updatedAt: Date()
            )
        }
        
        corporateAccounts[newAccount.id] = newAccount
        logger.info("Mock: Created corporate account with ID: \(newAccount.id)")
        return newAccount
    }
    
    func getCorporateAccount(id: String) async throws -> CorporateAccount? {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let account = corporateAccounts[id]
        logger.info("Mock: Retrieved corporate account with ID: \(id), found: \(account != nil)")
        return account
    }
    
    func updateCorporateAccount(_ account: CorporateAccount) async throws -> CorporateAccount {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 600_000_000)
        
        guard corporateAccounts[account.id] != nil else {
            throw CorporateRepositoryError.accountNotFound
        }
        
        var updatedAccount = account
        updatedAccount.updatedAt = Date()
        corporateAccounts[account.id] = updatedAccount
        
        logger.info("Mock: Updated corporate account with ID: \(account.id)")
        return updatedAccount
    }
    
    func deleteCorporateAccount(id: String) async throws -> Bool {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 800_000_000)
        
        guard corporateAccounts[id] != nil else {
            throw CorporateRepositoryError.accountNotFound
        }
        
        corporateAccounts.removeValue(forKey: id)
        logger.info("Mock: Deleted corporate account with ID: \(id)")
        return true
    }
    
    // MARK: - Query Operations
    func getCorporateAccounts(forAdminUserId: String) async throws -> [CorporateAccount] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        let adminAccounts = corporateAccounts.values.filter { account in
            account.adminUsers.contains { $0.userId == forAdminUserId }
        }
        
        logger.info("Mock: Retrieved \(adminAccounts.count) corporate accounts for admin user: \(forAdminUserId)")
        return adminAccounts
    }
    
    func getCorporateAccounts(byIndustry: String) async throws -> [CorporateAccount] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let industryAccounts = corporateAccounts.values.filter { $0.industry == byIndustry }
        logger.info("Mock: Retrieved \(industryAccounts.count) corporate accounts in industry: \(byIndustry)")
        return industryAccounts
    }
    
    func getCorporateAccounts(bySize: CompanySize) async throws -> [CorporateAccount] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let sizeAccounts = corporateAccounts.values.filter { $0.size == bySize }
        logger.info("Mock: Retrieved \(sizeAccounts.count) corporate accounts with size: \(bySize)")
        return sizeAccounts
    }
    
    func getActiveCorporateAccounts() async throws -> [CorporateAccount] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let activeAccounts = corporateAccounts.values.filter { $0.isActive }
        logger.info("Mock: Retrieved \(activeAccounts.count) active corporate accounts")
        return activeAccounts
    }
    
    // MARK: - Employee Management
    func addEmployee(toAccountId: String, employee: CorporateEmployee) async throws -> CorporateAccount {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 600_000_000)
        
        guard var account = corporateAccounts[toAccountId] else {
            throw CorporateRepositoryError.accountNotFound
        }
        
        // Check if employee already exists
        if account.employees.contains(where: { $0.userId == employee.userId }) {
            throw CorporateRepositoryError.employeeAlreadyExists
        }
        
        account.employees.append(employee)
        account.updatedAt = Date()
        corporateAccounts[toAccountId] = account
        
        logger.info("Mock: Added employee \(employee.userId) to corporate account: \(toAccountId)")
        return account
    }
    
    func removeEmployee(fromAccountId: String, employeeId: String) async throws -> CorporateAccount {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        guard var account = corporateAccounts[fromAccountId] else {
            throw CorporateRepositoryError.accountNotFound
        }
        
        guard let employeeIndex = account.employees.firstIndex(where: { $0.userId == employeeId }) else {
            throw CorporateRepositoryError.employeeNotFound
        }
        
        account.employees.remove(at: employeeIndex)
        account.updatedAt = Date()
        corporateAccounts[fromAccountId] = account
        
        logger.info("Mock: Removed employee \(employeeId) from corporate account: \(fromAccountId)")
        return account
    }
    
    func updateEmployeeRole(inAccountId: String, employeeId: String, newRole: CorporateEmployeeRole) async throws -> CorporateAccount {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        guard var account = corporateAccounts[inAccountId] else {
            throw CorporateRepositoryError.accountNotFound
        }
        
        guard let employeeIndex = account.employees.firstIndex(where: { $0.userId == employeeId }) else {
            throw CorporateRepositoryError.employeeNotFound
        }
        
        account.employees[employeeIndex].role = newRole
        account.updatedAt = Date()
        corporateAccounts[inAccountId] = account
        
        logger.info("Mock: Updated employee \(employeeId) role to \(newRole) in account: \(inAccountId)")
        return account
    }
    
    func getEmployees(forAccountId: String) async throws -> [CorporateEmployee] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        guard let account = corporateAccounts[forAccountId] else {
            throw CorporateRepositoryError.accountNotFound
        }
        
        logger.info("Mock: Retrieved \(account.employees.count) employees for corporate account: \(forAccountId)")
        return account.employees
    }
    
    // MARK: - Admin Management
    func addAdminUser(toAccountId: String, adminUser: CorporateAdminUser) async throws -> CorporateAccount {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 600_000_000)
        
        guard var account = corporateAccounts[toAccountId] else {
            throw CorporateRepositoryError.accountNotFound
        }
        
        // Check if admin already exists
        if account.adminUsers.contains(where: { $0.userId == adminUser.userId }) {
            throw CorporateRepositoryError.adminAlreadyExists
        }
        
        account.adminUsers.append(adminUser)
        account.updatedAt = Date()
        corporateAccounts[toAccountId] = account
        
        logger.info("Mock: Added admin user \(adminUser.userId) to corporate account: \(toAccountId)")
        return account
    }
    
    func removeAdminUser(fromAccountId: String, adminId: String) async throws -> CorporateAccount {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        guard var account = corporateAccounts[fromAccountId] else {
            throw CorporateRepositoryError.accountNotFound
        }
        
        guard let adminIndex = account.adminUsers.firstIndex(where: { $0.userId == adminId }) else {
            throw CorporateRepositoryError.adminNotFound
        }
        
        // Prevent removing the last admin
        if account.adminUsers.count <= 1 {
            throw CorporateRepositoryError.cannotRemoveLastAdmin
        }
        
        account.adminUsers.remove(at: adminIndex)
        account.updatedAt = Date()
        corporateAccounts[fromAccountId] = account
        
        logger.info("Mock: Removed admin user \(adminId) from corporate account: \(fromAccountId)")
        return account
    }
    
    func updateAdminPermissions(inAccountId: String, adminId: String, permissions: [CorporatePermission]) async throws -> CorporateAccount {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        guard var account = corporateAccounts[inAccountId] else {
            throw CorporateRepositoryError.accountNotFound
        }
        
        guard let adminIndex = account.adminUsers.firstIndex(where: { $0.userId == adminId }) else {
            throw CorporateRepositoryError.adminNotFound
        }
        
        account.adminUsers[adminIndex].permissions = permissions
        account.updatedAt = Date()
        corporateAccounts[inAccountId] = account
        
        logger.info("Mock: Updated admin permissions for \(adminId) in account: \(inAccountId)")
        return account
    }
    
    // MARK: - Policy Management
    func updateCorporatePolicies(forAccountId: String, policies: CorporatePolicies) async throws -> CorporateAccount {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        guard var account = corporateAccounts[forAccountId] else {
            throw CorporateRepositoryError.accountNotFound
        }
        
        account.policies = policies
        account.updatedAt = Date()
        corporateAccounts[forAccountId] = account
        
        logger.info("Mock: Updated corporate policies for account: \(forAccountId)")
        return account
    }
    
    func getCorporatePolicies(forAccountId: String) async throws -> CorporatePolicies {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        guard let account = corporateAccounts[forAccountId] else {
            throw CorporateRepositoryError.accountNotFound
        }
        
        logger.info("Mock: Retrieved corporate policies for account: \(forAccountId)")
        return account.policies
    }
    
    // MARK: - Goal and Stake Management
    func getCorporateGoals(forAccountId: String) async throws -> [Goal] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        guard corporateAccounts[forAccountId] != nil else {
            throw CorporateRepositoryError.accountNotFound
        }
        
        // Mock corporate goals
        let corporateGoals = [
            Goal(
                id: "corp-goal-1",
                title: "Employee Wellness Challenge",
                description: "Quarterly wellness challenge for all employees",
                category: .health,
                difficulty: .medium,
                deadline: Date().addingTimeInterval(90 * 24 * 60 * 60), // 90 days from now
                userId: "corp-\(forAccountId)",
                isCorporate: true,
                corporateAccountId: forAccountId,
                milestones: [],
                attachments: [],
                notes: [],
                createdAt: Date().addingTimeInterval(-30 * 24 * 60 * 60),
                updatedAt: Date().addingTimeInterval(-7 * 24 * 60 * 60)
            ),
            Goal(
                id: "corp-goal-2",
                title: "Professional Development",
                description: "Complete at least one certification or course per quarter",
                category: .education,
                difficulty: .hard,
                deadline: Date().addingTimeInterval(120 * 24 * 60 * 60), // 120 days from now
                userId: "corp-\(forAccountId)",
                isCorporate: true,
                corporateAccountId: forAccountId,
                milestones: [],
                attachments: [],
                notes: [],
                createdAt: Date().addingTimeInterval(-45 * 24 * 60 * 60),
                updatedAt: Date().addingTimeInterval(-14 * 24 * 60 * 60)
            )
        ]
        
        logger.info("Mock: Retrieved \(corporateGoals.count) corporate goals for account: \(forAccountId)")
        return corporateGoals
    }
    
    func getCorporateStakes(forAccountId: String) async throws -> [Stake] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        guard corporateAccounts[forAccountId] != nil else {
            throw CorporateRepositoryError.accountNotFound
        }
        
        // Mock corporate stakes
        let corporateStakes = [
            Stake(
                id: "corp-stake-1",
                goalId: "corp-goal-1",
                userId: "corp-\(forAccountId)",
                amount: 1000.0,
                stakeType: .corporate,
                status: .active,
                apr: 0.05, // 5% APR
                startDate: Date().addingTimeInterval(-30 * 24 * 60 * 60),
                endDate: Date().addingTimeInterval(60 * 24 * 60 * 60),
                verificationMethod: .healthKit,
                isCorporate: true,
                corporateAccountId: forAccountId,
                createdAt: Date().addingTimeInterval(-30 * 24 * 60 * 60),
                updatedAt: Date().addingTimeInterval(-7 * 24 * 60 * 60)
            ),
            Stake(
                id: "corp-stake-2",
                goalId: "corp-goal-2",
                userId: "corp-\(forAccountId)",
                amount: 500.0,
                stakeType: .corporate,
                status: .active,
                apr: 0.06, // 6% APR
                startDate: Date().addingTimeInterval(-45 * 24 * 60 * 60),
                endDate: Date().addingTimeInterval(75 * 24 * 60 * 60),
                verificationMethod: .photoNote,
                isCorporate: true,
                corporateAccountId: forAccountId,
                createdAt: Date().addingTimeInterval(-45 * 24 * 60 * 60),
                updatedAt: Date().addingTimeInterval(-14 * 24 * 60 * 60)
            )
        ]
        
        logger.info("Mock: Retrieved \(corporateStakes.count) corporate stakes for account: \(forAccountId)")
        return corporateStakes
    }
    
    // MARK: - Analytics and Reporting
    func getCorporateOverview(forAccountId: String) async throws -> CorporateOverview {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        guard let account = corporateAccounts[forAccountId] else {
            throw CorporateRepositoryError.accountNotFound
        }
        
        let overview = CorporateOverview(
            totalEmployees: account.employees.count,
            activeEmployees: account.employees.filter { $0.isActive }.count,
            totalGoals: 2, // Mock value
            completedGoals: 1, // Mock value
            totalStakes: 1500.0, // Mock value
            totalAccrued: 75.0, // Mock value
            averageCompletionRate: 0.78, // Mock value
            topPerformingEmployees: Array(account.employees.prefix(3).map { $0.userId }),
            recentActivity: [
                CorporateActivity(
                    id: UUID().uuidString,
                    type: .goalCompleted,
                    description: "Employee completed wellness challenge",
                    employeeId: "emp-123",
                    timestamp: Date().addingTimeInterval(-24 * 60 * 60),
                    metadata: ["goalName": "Employee Wellness Challenge"]
                )
            ]
        )
        
        logger.info("Mock: Generated corporate overview for account: \(forAccountId)")
        return overview
    }
    
    func getEmployeePerformance(forAccountId: String, employeeId: String) async throws -> EmployeePerformance {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        guard corporateAccounts[forAccountId] != nil else {
            throw CorporateRepositoryError.accountNotFound
        }
        
        let performance = EmployeePerformance(
            employeeId: employeeId,
            goalsCompleted: 3,
            totalStakes: 500.0,
            totalAccrued: 25.0,
            completionRate: 0.85,
            averageGoalDuration: 45.0, // days
            lastActivity: Date().addingTimeInterval(-2 * 24 * 60 * 60),
            performanceScore: 0.78
        )
        
        logger.info("Mock: Generated employee performance for \(employeeId) in account: \(forAccountId)")
        return performance
    }
    
    func generateCorporateReport(forAccountId: String, reportType: CorporateReportType, dateRange: DateInterval) async throws -> CorporateReport {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 800_000_000)
        
        guard corporateAccounts[forAccountId] != nil else {
            throw CorporateRepositoryError.accountNotFound
        }
        
        let report = CorporateReport(
            id: UUID().uuidString,
            accountId: forAccountId,
            reportType: reportType,
            dateRange: dateRange,
            generatedAt: Date(),
            data: [
                "totalEmployees": "25",
                "activeGoals": "8",
                "completedGoals": "6",
                "totalStakes": "$2,500",
                "totalAccrued": "$125",
                "averageCompletionRate": "75%"
            ],
            summary: "Q4 2024 Corporate Performance Report"
        )
        
        logger.info("Mock: Generated corporate report for account: \(forAccountId)")
        return report
    }
    
    // MARK: - Search and Discovery
    func searchCorporateAccounts(query: String, filters: CorporateSearchFilters?) async throws -> [CorporateAccount] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        var searchResults = corporateAccounts.values
        
        // Apply text search
        if !query.isEmpty {
            searchResults = searchResults.filter { account in
                account.companyName.localizedCaseInsensitiveContains(query) ||
                account.industry.localizedCaseInsensitiveContains(query)
            }
        }
        
        // Apply filters
        if let filters = filters {
            if let industry = filters.industry {
                searchResults = searchResults.filter { $0.industry == industry }
            }
            
            if let size = filters.size {
                searchResults = searchResults.filter { $0.size == size }
            }
            
            if let isActive = filters.isActive {
                searchResults = searchResults.filter { $0.isActive == isActive }
            }
        }
        
        logger.info("Mock: Search returned \(searchResults.count) corporate accounts for query: \(query)")
        return searchResults
    }
    
    // MARK: - Private Helper Methods
    private func setupMockData() {
        // Create some mock corporate accounts for testing
        let mockAccounts = [
            CorporateAccount(
                id: "corp-1",
                companyName: "TechCorp Solutions",
                industry: "Technology",
                size: .medium,
                adminUsers: [
                    CorporateAdminUser(
                        userId: "admin-1",
                        role: .superAdmin,
                        permissions: [.manageEmployees, .managePolicies, .viewReports, .manageGoals],
                        isActive: true
                    ),
                    CorporateAdminUser(
                        userId: "admin-2",
                        role: .admin,
                        permissions: [.manageEmployees, .viewReports],
                        isActive: true
                    )
                ],
                employees: [
                    CorporateEmployee(
                        userId: "emp-1",
                        role: .employee,
                        department: "Engineering",
                        isActive: true,
                        joinedAt: Date().addingTimeInterval(-365 * 24 * 60 * 60)
                    ),
                    CorporateEmployee(
                        userId: "emp-2",
                        role: .employee,
                        department: "Marketing",
                        isActive: true,
                        joinedAt: Date().addingTimeInterval(-180 * 24 * 60 * 60)
                    ),
                    CorporateEmployee(
                        userId: "emp-3",
                        role: .employee,
                        department: "Sales",
                        isActive: false,
                        joinedAt: Date().addingTimeInterval(-90 * 24 * 60 * 60)
                    )
                ],
                policies: CorporatePolicies(
                    maxStakeAmount: 1000.0,
                    minStakeAmount: 50.0,
                    allowedCategories: [.health, .education, .fitness],
                    verificationMethods: [.healthKit, .photoNote, .screenTime],
                    matchPercentage: 0.25, // 25% match
                    maxGoalsPerEmployee: 3
                ),
                matchPercentage: 0.25,
                verificationStrictness: .moderate,
                isActive: true,
                createdAt: Date().addingTimeInterval(-365 * 24 * 60 * 60),
                updatedAt: Date().addingTimeInterval(-30 * 24 * 60 * 60)
            ),
            CorporateAccount(
                id: "corp-2",
                companyName: "HealthFirst Inc.",
                industry: "Healthcare",
                size: .large,
                adminUsers: [
                    CorporateAdminUser(
                        userId: "admin-3",
                        role: .superAdmin,
                        permissions: [.manageEmployees, .managePolicies, .viewReports, .manageGoals],
                        isActive: true
                    )
                ],
                employees: [
                    CorporateEmployee(
                        userId: "emp-4",
                        role: .employee,
                        department: "Nursing",
                        isActive: true,
                        joinedAt: Date().addingTimeInterval(-730 * 24 * 60 * 60)
                    ),
                    CorporateEmployee(
                        userId: "emp-5",
                        role: .employee,
                        department: "Administration",
                        isActive: true,
                        joinedAt: Date().addingTimeInterval(-365 * 24 * 60 * 60)
                    )
                ],
                policies: CorporatePolicies(
                    maxStakeAmount: 2000.0,
                    minStakeAmount: 100.0,
                    allowedCategories: [.health, .fitness, .wellness],
                    verificationMethods: [.healthKit, .photoNote],
                    matchPercentage: 0.50, // 50% match
                    maxGoalsPerEmployee: 5
                ),
                matchPercentage: 0.50,
                verificationStrictness: .strict,
                isActive: true,
                createdAt: Date().addingTimeInterval(-730 * 24 * 60 * 60),
                updatedAt: Date().addingTimeInterval(-60 * 24 * 60 * 60)
            ),
            CorporateAccount(
                id: "corp-3",
                companyName: "EduTech Academy",
                industry: "Education",
                size: .small,
                adminUsers: [
                    CorporateAdminUser(
                        userId: "admin-4",
                        role: .superAdmin,
                        permissions: [.manageEmployees, .managePolicies, .viewReports, .manageGoals],
                        isActive: true
                    )
                ],
                employees: [
                    CorporateEmployee(
                        userId: "emp-6",
                        role: .employee,
                        department: "Teaching",
                        isActive: true,
                        joinedAt: Date().addingTimeInterval(-180 * 24 * 60 * 60)
                    )
                ],
                policies: CorporatePolicies(
                    maxStakeAmount: 500.0,
                    minStakeAmount: 25.0,
                    allowedCategories: [.education, .personal],
                    verificationMethods: [.photoNote, .screenTime],
                    matchPercentage: 0.10, // 10% match
                    maxGoalsPerEmployee: 2
                ),
                matchPercentage: 0.10,
                verificationStrictness: .relaxed,
                isActive: true,
                createdAt: Date().addingTimeInterval(-180 * 24 * 60 * 60),
                updatedAt: Date().addingTimeInterval(-15 * 24 * 60 * 60)
            )
        ]
        
        for account in mockAccounts {
            corporateAccounts[account.id] = account
        }
        
        logger.info("Mock: Setup \(mockAccounts.count) mock corporate accounts")
    }
}
