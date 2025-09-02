import Foundation
import Combine

// MARK: - Corporate Repository Protocol
protocol CorporateRepository {
    // MARK: - CRUD Operations
    func createCorporateAccount(_ account: CorporateAccount) async throws -> CorporateAccount
    func getCorporateAccount(id: String) async throws -> CorporateAccount?
    func updateCorporateAccount(_ account: CorporateAccount) async throws -> CorporateAccount
    func deleteCorporateAccount(id: String) async throws -> Bool
    
    // MARK: - Query Operations
    func getCorporateAccountsForUser(userId: String) async throws -> [CorporateAccount]
    func getCorporateAccounts(byIndustry: String) async throws -> [CorporateAccount]
    func getCorporateAccounts(byDateRange: DateInterval) async throws -> [CorporateAccount]
    func getVerifiedCorporateAccounts() async throws -> [CorporateAccount]
    
    // MARK: - Admin Operations
    func addAdminToCorporate(corporateId: String, userId: String) async throws -> CorporateAccount
    func removeAdminFromCorporate(corporateId: String, userId: String) async throws -> CorporateAccount
    func isUserAdminOfCorporate(userId: String, corporateId: String) async throws -> Bool
    func getCorporateAdmins(corporateId: String) async throws -> [User]
    
    // MARK: - Employee Operations
    func addEmployeeToCorporate(corporateId: String, userId: String) async throws -> CorporateAccount
    func removeEmployeeFromCorporate(corporateId: String, userId: String) async throws -> CorporateAccount
    func getCorporateEmployees(corporateId: String) async throws -> [User]
    func isUserEmployeeOfCorporate(userId: String, corporateId: String) async throws -> Bool
    
    // MARK: - Policy Management
    func updateCorporatePolicy(corporateId: String, policy: CorporatePolicy) async throws -> CorporateAccount
    func getCorporatePolicy(corporateId: String) async throws -> CorporatePolicy?
    func updateVerificationStrictness(corporateId: String, strictness: VerificationStrictness) async throws -> CorporateAccount
    
    // MARK: - Analytics Operations
    func getCorporateStatistics(corporateId: String) async throws -> CorporateStatistics
    func getCorporatePerformance(corporateId: String, timeRange: TimeRange) async throws -> CorporatePerformance
    func getTopCorporateAccounts(limit: Int) async throws -> [CorporateAccountWithStats]
    
    // MARK: - Reporting Operations
    func generateCorporateReport(corporateId: String, reportType: CorporateReportType, dateRange: DateInterval) async throws -> CorporateReport
    func exportCorporateData(corporateId: String, format: ExportFormat) async throws -> Data
    
    // MARK: - Bulk Operations
    func bulkUpdateCorporateAccounts(_ accounts: [CorporateAccount]) async throws -> [CorporateAccount]
    func deleteInactiveCorporateAccounts(olderThan date: Date) async throws -> Int
}

// MARK: - Supporting Models
enum VerificationStrictness: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case strict = "strict"
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .strict: return "Strict"
        }
    }
    
    var requiredEvidenceTypes: [String] {
        switch self {
        case .low: return ["manual"]
        case .medium: return ["manual", "photo"]
        case .high: return ["manual", "photo", "screen_time"]
        case .strict: return ["manual", "photo", "screen_time", "health_kit", "peer_review"]
        }
    }
}

struct CorporateStatistics {
    let totalEmployees: Int
    let activeEmployees: Int
    let totalGoals: Int
    let completedGoals: Int
    let totalStakeAmount: Decimal
    let totalMatchAmount: Decimal
    let averageGoalCompletionRate: Double
    let employeeRetentionRate: Double
}

struct CorporatePerformance {
    let totalReturn: Decimal
    let returnRate: Decimal
    let employeeEngagementScore: Double
    let goalSuccessRate: Double
    let averageGoalDuration: TimeInterval
    let costPerEmployee: Decimal
}

struct CorporateAccountWithStats {
    let account: CorporateAccount
    let statistics: CorporateStatistics
    let recentActivity: [CorporateActivityItem]
}

struct CorporateActivityItem {
    let type: CorporateActivityType
    let userId: String
    let userName: String
    let timestamp: Date
    let details: String
    let impact: CorporateActivityImpact
}

enum CorporateActivityType: String, CaseIterable {
    case employeeJoined = "employee_joined"
    case employeeLeft = "employee_left"
    case goalCreated = "goal_created"
    case goalCompleted = "goal_completed"
    case stakePlaced = "stake_placed"
    case stakeWon = "stake_won"
    case stakeLost = "stake_lost"
    case policyUpdated = "policy_updated"
    case adminAdded = "admin_added"
    case adminRemoved = "admin_removed"
    
    var displayName: String {
        switch self {
        case .employeeJoined: return "Employee Joined"
        case .employeeLeft: return "Employee Left"
        case .goalCreated: return "Goal Created"
        case .goalCompleted: return "Goal Completed"
        case .stakePlaced: return "Stake Placed"
        case .stakeWon: return "Stake Won"
        case .stakeLost: return "Stake Lost"
        case .policyUpdated: return "Policy Updated"
        case .adminAdded: return "Admin Added"
        case .adminRemoved: return "Admin Removed"
        }
    }
}

enum CorporateActivityImpact: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }
}

enum CorporateReportType: String, CaseIterable {
    case employeePerformance = "employee_performance"
    case goalCompletion = "goal_completion"
    case financialSummary = "financial_summary"
    case complianceReport = "compliance_report"
    case engagementMetrics = "engagement_metrics"
    
    var displayName: String {
        switch self {
        case .employeePerformance: return "Employee Performance"
        case .goalCompletion: return "Goal Completion"
        case .financialSummary: return "Financial Summary"
        case .complianceReport: return "Compliance Report"
        case .engagementMetrics: return "Engagement Metrics"
        }
    }
}

enum ExportFormat: String, CaseIterable {
    case csv = "csv"
    case pdf = "pdf"
    case json = "json"
    case excel = "excel"
    
    var displayName: String {
        switch self {
        case .csv: return "CSV"
        case .pdf: return "PDF"
        case .json: return "JSON"
        case .excel: return "Excel"
        }
    }
    
    var fileExtension: String {
        return rawValue
    }
}

struct CorporateReport {
    let id: String
    let corporateId: String
    let reportType: CorporateReportType
    let dateRange: DateInterval
    let generatedAt: Date
    let data: [String: Any]
    let summary: CorporateReportSummary
}

struct CorporateReportSummary {
    let totalRecords: Int
    let keyMetrics: [String: Any]
    let recommendations: [String]
    let riskFactors: [String]
}

// MARK: - Corporate Repository Extensions
extension CorporateRepository {
    // MARK: - Convenience Methods
    func getActiveCorporateAccounts(forUserId: String) async throws -> [CorporateAccount] {
        let accounts = try await getCorporateAccountsForUser(userId: userId)
        return accounts.filter { account in
            // Consider an account active if it has recent activity or active employees
            // This is a simplified check - in practice, you'd want more sophisticated logic
            return true
        }
    }
    
    func getCorporateAccountsBySize(minEmployees: Int, maxEmployees: Int? = nil) async throws -> [CorporateAccount] {
        let accounts = try await getVerifiedCorporateAccounts()
        // This would need to be implemented with actual employee count data
        // For now, return all accounts
        return accounts
    }
    
    func getCorporateAccountsByIndustry(industry: String) async throws -> [CorporateAccount] {
        return try await getCorporateAccounts(byIndustry: industry)
    }
    
    func getCorporateAccountsWithHighMatchPercentage(minPercentage: Decimal) async throws -> [CorporateAccount] {
        let accounts = try await getVerifiedCorporateAccounts()
        return accounts.filter { $0.matchPercentage >= minPercentage }
    }
    
    func getCorporateAccountsByVerificationStrictness(strictness: VerificationStrictness) async throws -> [CorporateAccount] {
        let accounts = try await getVerifiedCorporateAccounts()
        return accounts.filter { $0.verificationStrictness == strictness.rawValue }
    }
}

// MARK: - Corporate Repository Error
enum CorporateRepositoryError: LocalizedError {
    case corporateAccountNotFound
    case invalidCorporateAccountData
    case userNotEmployee
    case userNotAdmin
    case userAlreadyEmployee
    case userAlreadyAdmin
    case insufficientPermissions
    case invalidPolicy
    case databaseError(Error)
    case networkError(Error)
    case permissionDenied
    case quotaExceeded
    
    var errorDescription: String? {
        switch self {
        case .corporateAccountNotFound:
            return "Corporate account not found"
        case .invalidCorporateAccountData:
            return "Invalid corporate account data"
        case .userNotEmployee:
            return "User is not an employee of this corporate account"
        case .userNotAdmin:
            return "User is not an admin of this corporate account"
        case .userAlreadyEmployee:
            return "User is already an employee of this corporate account"
        case .userAlreadyAdmin:
            return "User is already an admin of this corporate account"
        case .insufficientPermissions:
            return "Insufficient permissions for this operation"
        case .invalidPolicy:
            return "Invalid corporate policy"
        case .databaseError(let error):
            return "Database error: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .permissionDenied:
            return "Permission denied"
        case .quotaExceeded:
            return "Quota exceeded"
        }
    }
}
