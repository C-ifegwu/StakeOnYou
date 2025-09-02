import Foundation

// MARK: - Corporate Overview
struct CorporateOverview: Identifiable, Codable, Equatable {
    let id: String
    let corporateId: String
    let corporateName: String
    let totalEmployees: Int
    let activeEmployees: Int
    let totalGoals: Int
    let activeGoals: Int
    let completedGoals: Int
    let totalStakeValue: Decimal
    let totalAccruedAmount: Decimal
    let averageSuccessRate: Double
    let topPerformingDepartments: [DepartmentPerformance]
    let recentActivity: [CorporateActivityItem]
    let complianceMetrics: ComplianceMetrics
    let lastUpdated: Date
    
    init(
        id: String = UUID().uuidString,
        corporateId: String,
        corporateName: String,
        totalEmployees: Int = 0,
        activeEmployees: Int = 0,
        totalGoals: Int = 0,
        activeGoals: Int = 0,
        completedGoals: Int = 0,
        totalStakeValue: Decimal = 0,
        totalAccruedAmount: Decimal = 0,
        averageSuccessRate: Double = 0.0,
        topPerformingDepartments: [DepartmentPerformance] = [],
        recentActivity: [CorporateActivityItem] = [],
        complianceMetrics: ComplianceMetrics = ComplianceMetrics(),
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.corporateId = corporateId
        self.corporateName = corporateName
        self.totalEmployees = totalEmployees
        self.activeEmployees = activeEmployees
        self.totalGoals = totalGoals
        self.activeGoals = activeGoals
        self.completedGoals = completedGoals
        self.totalStakeValue = totalStakeValue
        self.totalAccruedAmount = totalAccruedAmount
        self.averageSuccessRate = averageSuccessRate
        self.topPerformingDepartments = topPerformingDepartments
        self.recentActivity = recentActivity
        self.complianceMetrics = complianceMetrics
        self.lastUpdated = lastUpdated
    }
}

// MARK: - Department Performance
struct DepartmentPerformance: Identifiable, Codable, Equatable {
    let id: String
    let departmentName: String
    let employeeCount: Int
    let activeGoals: Int
    let completedGoals: Int
    let successRate: Double
    let averageStakeValue: Decimal
    let totalAccruedAmount: Decimal
    let rank: Int
    
    init(
        id: String = UUID().uuidString,
        departmentName: String,
        employeeCount: Int,
        activeGoals: Int = 0,
        completedGoals: Int = 0,
        successRate: Double = 0.0,
        averageStakeValue: Decimal = 0,
        totalAccruedAmount: Decimal = 0,
        rank: Int = 0
    ) {
        self.id = id
        self.departmentName = departmentName
        self.employeeCount = employeeCount
        self.activeGoals = activeGoals
        self.completedGoals = completedGoals
        self.successRate = successRate
        self.averageStakeValue = averageStakeValue
        self.totalAccruedAmount = totalAccruedAmount
        self.rank = rank
    }
}

// MARK: - Corporate Activity Item
struct CorporateActivityItem: Identifiable, Codable, Equatable {
    let id: String
    let type: CorporateActivityType
    let title: String
    let description: String
    let timestamp: Date
    let departmentId: String?
    let employeeId: String?
    let goalId: String?
    let metadata: [String: String]
    
    init(
        id: String = UUID().uuidString,
        type: CorporateActivityType,
        title: String,
        description: String,
        timestamp: Date = Date(),
        departmentId: String? = nil,
        employeeId: String? = nil,
        goalId: String? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.description = description
        self.timestamp = timestamp
        self.departmentId = departmentId
        self.employeeId = employeeId
        self.goalId = goalId
        self.metadata = metadata
    }
}

enum CorporateActivityType: String, Codable, CaseIterable {
    case employeeJoined = "employee_joined"
    case employeeLeft = "employee_left"
    case goalCreated = "goal_created"
    case goalCompleted = "goal_completed"
    case goalFailed = "goal_failed"
    case departmentCreated = "department_created"
    case departmentUpdated = "department_updated"
    case policyChanged = "policy_changed"
    case complianceAlert = "compliance_alert"
    case milestoneReached = "milestone_reached"
    case achievementUnlocked = "achievement_unlocked"
    
    var displayName: String {
        switch self {
        case .employeeJoined: return "Employee Joined"
        case .employeeLeft: return "Employee Left"
        case .goalCreated: return "Goal Created"
        case .goalCompleted: return "Goal Completed"
        case .goalFailed: return "Goal Failed"
        case .departmentCreated: return "Department Created"
        case .departmentUpdated: return "Department Updated"
        case .policyChanged: return "Policy Changed"
        case .complianceAlert: return "Compliance Alert"
        case .milestoneReached: return "Milestone Reached"
        case .achievementUnlocked: return "Achievement Unlocked"
        }
    }
    
    var iconName: String {
        switch self {
        case .employeeJoined: return "person.badge.plus"
        case .employeeLeft: return "person.badge.minus"
        case .goalCreated: return "target"
        case .goalCompleted: return "checkmark.circle"
        case .goalFailed: return "xmark.circle"
        case .departmentCreated: return "building.2"
        case .departmentUpdated: return "building.2.fill"
        case .policyChanged: return "doc.text"
        case .complianceAlert: return "exclamationmark.triangle"
        case .milestoneReached: return "flag"
        case .achievementUnlocked: return "trophy"
        }
    }
}

// MARK: - Compliance Metrics
struct ComplianceMetrics: Codable, Equatable {
    let totalPolicies: Int
    let compliantPolicies: Int
    let complianceRate: Double
    let lastAuditDate: Date?
    let nextAuditDate: Date?
    let riskLevel: ComplianceRiskLevel
    let alerts: [ComplianceAlert]
    
    init(
        totalPolicies: Int = 0,
        compliantPolicies: Int = 0,
        complianceRate: Double = 0.0,
        lastAuditDate: Date? = nil,
        nextAuditDate: Date? = nil,
        riskLevel: ComplianceRiskLevel = .low,
        alerts: [ComplianceAlert] = []
    ) {
        self.totalPolicies = totalPolicies
        self.compliantPolicies = compliantPolicies
        self.complianceRate = complianceRate
        self.lastAuditDate = lastAuditDate
        self.nextAuditDate = nextAuditDate
        self.riskLevel = riskLevel
        self.alerts = alerts
    }
}

enum ComplianceRiskLevel: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    var displayName: String {
        switch self {
        case .low: return "Low Risk"
        case .medium: return "Medium Risk"
        case .high: return "High Risk"
        case .critical: return "Critical Risk"
        }
    }
    
    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "yellow"
        case .high: return "orange"
        case .critical: return "red"
        }
    }
    
    var iconName: String {
        switch self {
        case .low: return "checkmark.shield"
        case .medium: return "exclamationmark.triangle"
        case .high: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.shield.fill"
        }
    }
}

// MARK: - Compliance Alert
struct ComplianceAlert: Identifiable, Codable, Equatable {
    let id: String
    let type: ComplianceAlertType
    let title: String
    let description: String
    let severity: ComplianceRiskLevel
    let createdAt: Date
    let isResolved: Bool
    let resolvedAt: Date?
    let assignedTo: String?
    let metadata: [String: String]
    
    init(
        id: String = UUID().uuidString,
        type: ComplianceAlertType,
        title: String,
        description: String,
        severity: ComplianceRiskLevel,
        createdAt: Date = Date(),
        isResolved: Bool = false,
        resolvedAt: Date? = nil,
        assignedTo: String? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.description = description
        self.severity = severity
        self.createdAt = createdAt
        self.isResolved = isResolved
        self.resolvedAt = resolvedAt
        self.assignedTo = assignedTo
        self.metadata = metadata
    }
}

enum ComplianceAlertType: String, Codable, CaseIterable {
    case policyViolation = "policy_violation"
    case deadlineMissed = "deadline_missed"
    case dataBreach = "data_breach"
    case auditFinding = "audit_finding"
    case regulatoryChange = "regulatory_change"
    case systemFailure = "system_failure"
    
    var displayName: String {
        switch self {
        case .policyViolation: return "Policy Violation"
        case .deadlineMissed: return "Deadline Missed"
        case .dataBreach: return "Data Breach"
        case .auditFinding: return "Audit Finding"
        case .regulatoryChange: return "Regulatory Change"
        case .systemFailure: return "System Failure"
        }
    }
    
    var iconName: String {
        switch self {
        case .policyViolation: return "exclamationmark.triangle"
        case .deadlineMissed: return "clock.badge.exclamationmark"
        case .dataBreach: return "lock.shield"
        case .auditFinding: return "doc.text.magnifyingglass"
        case .regulatoryChange: return "building.columns"
        case .systemFailure: return "exclamationmark.octagon"
        }
    }
}

// MARK: - Employee Goal Summary
struct EmployeeGoalSummary: Identifiable, Codable, Equatable {
    let id: String
    let employeeId: String
    let employeeName: String
    let departmentName: String
    let avatarURL: String?
    let totalGoals: Int
    let activeGoals: Int
    let completedGoals: Int
    let successRate: Double
    let totalStakeValue: Decimal
    let totalAccruedAmount: Decimal
    let averageGoalDuration: TimeInterval
    let lastGoalCreated: Date?
    let lastGoalCompleted: Date?
    let performanceScore: Double
    let rank: Int
    
    init(
        id: String = UUID().uuidString,
        employeeId: String,
        employeeName: String,
        departmentName: String,
        avatarURL: String? = nil,
        totalGoals: Int = 0,
        activeGoals: Int = 0,
        completedGoals: Int = 0,
        successRate: Double = 0.0,
        totalStakeValue: Decimal = 0,
        totalAccruedAmount: Decimal = 0,
        averageGoalDuration: TimeInterval = 0,
        lastGoalCreated: Date? = nil,
        lastGoalCompleted: Date? = nil,
        performanceScore: Double = 0.0,
        rank: Int = 0
    ) {
        self.id = id
        self.employeeId = employeeId
        self.employeeName = employeeName
        self.departmentName = departmentName
        self.avatarURL = avatarURL
        self.totalGoals = totalGoals
        self.activeGoals = activeGoals
        self.completedGoals = completedGoals
        self.successRate = successRate
        self.totalStakeValue = totalStakeValue
        self.totalAccruedAmount = totalAccruedAmount
        self.averageGoalDuration = averageGoalDuration
        self.lastGoalCreated = lastGoalCreated
        self.lastGoalCompleted = lastGoalCompleted
        self.performanceScore = performanceScore
        self.rank = rank
    }
}

// MARK: - Corporate Report Request
struct CorporateReportRequest: Codable, Equatable {
    let corporateId: String
    let reportType: CorporateReportType
    let dateRange: DateRange
    let departments: [String]?
    let employees: [String]?
    let includeDetails: Bool
    let format: ReportFormat
    
    init(
        corporateId: String,
        reportType: CorporateReportType,
        dateRange: DateRange,
        departments: [String]? = nil,
        employees: [String]? = nil,
        includeDetails: Bool = false,
        format: ReportFormat = .csv
    ) {
        self.corporateId = corporateId
        self.reportType = reportType
        self.dateRange = dateRange
        self.departments = departments
        self.employees = employees
        self.includeDetails = includeDetails
        self.format = format
    }
}

enum CorporateReportType: String, Codable, CaseIterable {
    case employeePerformance = "employee_performance"
    case departmentOverview = "department_overview"
    case goalAnalytics = "goal_analytics"
    case complianceReport = "compliance_report"
    case financialSummary = "financial_summary"
    case activityLog = "activity_log"
    
    var displayName: String {
        switch self {
        case .employeePerformance: return "Employee Performance"
        case .departmentOverview: return "Department Overview"
        case .goalAnalytics: return "Goal Analytics"
        case .complianceReport: return "Compliance Report"
        case .financialSummary: return "Financial Summary"
        case .activityLog: return "Activity Log"
        }
    }
    
    var description: String {
        switch self {
        case .employeePerformance: return "Individual employee performance metrics and rankings"
        case .departmentOverview: return "Department-level performance and comparison data"
        case .goalAnalytics: return "Goal creation, completion, and success rate analysis"
        case .complianceReport: return "Policy compliance and risk assessment"
        case .financialSummary: return "Stake values, accruals, and financial metrics"
        case .activityLog: return "Detailed activity and event log"
        }
    }
}

enum ReportFormat: String, Codable, CaseIterable {
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
        switch self {
        case .csv: return "csv"
        case .pdf: return "pdf"
        case .json: return "json"
        case .excel: return "xlsx"
        }
    }
}

// MARK: - Date Range
struct DateRange: Codable, Equatable {
    let startDate: Date
    let endDate: Date
    
    init(startDate: Date, endDate: Date) {
        self.startDate = startDate
        self.endDate = endDate
    }
    
    var duration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }
    
    var days: Int {
        Int(duration / (24 * 60 * 60))
    }
    
    static var lastWeek: DateRange {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate)!
        return DateRange(startDate: startDate, endDate: endDate)
    }
    
    static var lastMonth: DateRange {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .month, value: -1, to: endDate)!
        return DateRange(startDate: startDate, endDate: endDate)
    }
    
    static var lastQuarter: DateRange {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .month, value: -3, to: endDate)!
        return DateRange(startDate: startDate, endDate: endDate)
    }
    
    static var lastYear: DateRange {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .year, value: -1, to: endDate)!
        return DateRange(startDate: startDate, endDate: endDate)
    }
}
