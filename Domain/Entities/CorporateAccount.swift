import Foundation

// MARK: - Corporate Account Entity
struct CorporateAccount: Identifiable, Codable, Equatable {
    let id: String
    let companyName: String
    let description: String
    let adminIds: [String]
    let policy: CorporatePolicy
    let settings: CorporateSettings
    let createdAt: Date
    let updatedAt: Date
    
    // Optional fields
    let logoURL: URL?
    let website: URL?
    let industry: Industry
    let size: CompanySize
    let region: String
    let taxId: String?
    let contactEmail: String?
    let contactPhone: String?
    let employeeCount: Int?
    let goals: [String] // Goal IDs
    let stakes: [String] // Stake IDs
    let employees: [Employee]
    let departments: [Department]
    
    init(
        id: String = UUID().uuidString,
        companyName: String,
        description: String,
        adminIds: [String],
        policy: CorporatePolicy = CorporatePolicy(),
        settings: CorporateSettings = CorporateSettings(),
        logoURL: URL? = nil,
        website: URL? = nil,
        industry: Industry = .technology,
        size: CompanySize = .medium,
        region: String = "United States",
        taxId: String? = nil,
        contactEmail: String? = nil,
        contactPhone: String? = nil,
        employeeCount: Int? = nil,
        goals: [String] = [],
        stakes: [String] = [],
        employees: [Employee] = [],
        departments: [Department] = []
    ) {
        self.id = id
        self.companyName = companyName
        self.description = description
        self.adminIds = adminIds
        self.policy = policy
        self.settings = settings
        self.createdAt = Date()
        self.updatedAt = Date()
        self.logoURL = logoURL
        self.website = website
        self.industry = industry
        self.size = size
        self.region = region
        self.taxId = taxId
        self.contactEmail = contactEmail
        self.contactPhone = contactPhone
        self.employeeCount = employeeCount
        self.goals = goals
        self.stakes = stakes
        self.employees = employees
        self.departments = departments
    }
}

// MARK: - Industry
enum Industry: String, Codable, CaseIterable {
    case technology = "technology"
    case healthcare = "healthcare"
    case finance = "finance"
    case education = "education"
    case retail = "retail"
    case manufacturing = "manufacturing"
    case consulting = "consulting"
    case nonprofit = "nonprofit"
    case government = "government"
    case media = "media"
    case realEstate = "real_estate"
    case hospitality = "hospitality"
    case transportation = "transportation"
    case energy = "energy"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .technology: return "Technology"
        case .healthcare: return "Healthcare"
        case .finance: return "Finance & Banking"
        case .education: return "Education"
        case .retail: return "Retail"
        case .manufacturing: return "Manufacturing"
        case .consulting: return "Consulting"
        case .nonprofit: return "Non-Profit"
        case .government: return "Government"
        case .media: return "Media & Entertainment"
        case .realEstate: return "Real Estate"
        case .hospitality: return "Hospitality & Tourism"
        case .transportation: return "Transportation"
        case .energy: return "Energy"
        case .other: return "Other"
        }
    }
    
    var iconName: String {
        switch self {
        case .technology: return "laptopcomputer"
        case .healthcare: return "cross.case.fill"
        case .finance: return "dollarsign.circle.fill"
        case .education: return "graduationcap.fill"
        case .retail: return "cart.fill"
        case .manufacturing: return "gearshape.fill"
        case .consulting: return "person.2.fill"
        case .nonprofit: return "heart.fill"
        case .government: return "building.columns.fill"
        case .media: return "play.fill"
        case .realEstate: return "house.fill"
        case .hospitality: return "bed.double.fill"
        case .transportation: return "car.fill"
        case .energy: return "bolt.fill"
        case .other: return "star.fill"
        }
    }
}

// MARK: - Company Size
enum CompanySize: String, Codable, CaseIterable {
    case startup = "startup"
    case small = "small"
    case medium = "medium"
    case large = "large"
    case enterprise = "enterprise"
    
    var displayName: String {
        switch self {
        case .startup: return "Startup (1-10)"
        case .small: return "Small (11-50)"
        case .medium: return "Medium (51-200)"
        case .large: return "Large (201-1000)"
        case .enterprise: return "Enterprise (1000+)"
        }
    }
    
    var employeeRange: String {
        switch self {
        case .startup: return "1-10"
        case .small: return "11-50"
        case .medium: return "51-200"
        case .large: return "201-1000"
        case .enterprise: return "1000+"
        }
    }
}

// MARK: - Corporate Policy
struct CorporatePolicy: Codable, Equatable {
    var goalCreationPolicy: CorporateGoalPolicy
    var stakePolicy: CorporateStakePolicy
    var matchingPolicy: MatchingPolicy
    var verificationPolicy: CorporateVerificationPolicy
    var disputeResolution: CorporateDisputeResolution
    var forfeitureDistribution: CorporateForfeitDistribution
    var employeePermissions: EmployeePermissions
    
    init(
        goalCreationPolicy: CorporateGoalPolicy = .adminOnly,
        stakePolicy: CorporateStakePolicy = .allEmployees,
        matchingPolicy: MatchingPolicy = MatchingPolicy(),
        verificationPolicy: CorporateVerificationPolicy = .managerApproval,
        disputeResolution: CorporateDisputeResolution = .hrDecision,
        forfeitureDistribution: CorporateForfeitDistribution = .charityAndApp,
        employeePermissions: EmployeePermissions = EmployeePermissions()
    ) {
        self.goalCreationPolicy = goalCreationPolicy
        self.stakePolicy = stakePolicy
        self.matchingPolicy = matchingPolicy
        self.verificationPolicy = verificationPolicy
        self.disputeResolution = disputeResolution
        self.forfeitureDistribution = forfeitureDistribution
        self.employeePermissions = employeePermissions
    }
}

enum CorporateGoalPolicy: String, Codable, CaseIterable {
    case adminOnly = "admin_only"
    case managersOnly = "managers_only"
    case allEmployees = "all_employees"
    case approvedEmployees = "approved_employees"
    
    var displayName: String {
        switch self {
        case .adminOnly: return "Admins Only"
        case .managersOnly: return "Managers Only"
        case .allEmployees: return "All Employees"
        case .approvedEmployees: return "Approved Employees"
        }
    }
}

enum CorporateStakePolicy: String, Codable, CaseIterable {
    case none = "none"
    case employeesOnly = "employees_only"
    case managersOnly = "managers_only"
    case allEmployees = "all_employees"
    
    var displayName: String {
        switch self {
        case .none: return "No Staking"
        case .employeesOnly: return "Employees Only"
        case .managersOnly: return "Managers Only"
        case .allEmployees: return "All Employees"
        }
    }
}

struct MatchingPolicy: Codable, Equatable {
    var enabled: Bool
    var matchPercentage: Decimal
    var maxMatchAmount: Decimal
    var matchOnSuccess: Bool
    var matchOnFailure: Bool
    var annualCap: Decimal?
    
    init(
        enabled: Bool = false,
        matchPercentage: Decimal = 0.5,
        maxMatchAmount: Decimal = 1000,
        matchOnSuccess: Bool = true,
        matchOnFailure: Bool = false,
        annualCap: Decimal? = nil
    ) {
        self.enabled = enabled
        self.matchPercentage = matchPercentage
        self.maxMatchAmount = maxMatchAmount
        self.matchOnSuccess = matchOnSuccess
        self.matchOnFailure = matchOnFailure
        self.annualCap = annualCap
    }
}

enum CorporateVerificationPolicy: String, Codable, CaseIterable {
    case selfVerification = "self_verification"
    case peerVerification = "peer_verification"
    case managerApproval = "manager_approval"
    case hrApproval = "hr_approval"
    case thirdParty = "third_party"
    
    var displayName: String {
        switch self {
        case .selfVerification: return "Self Verification"
        case .peerVerification: return "Peer Verification"
        case .managerApproval: return "Manager Approval"
        case .hrApproval: return "HR Approval"
        case .thirdParty: return "Third Party"
        }
    }
}

enum CorporateDisputeResolution: String, Codable, CaseIterable {
    case managerDecision = "manager_decision"
    case hrDecision = "hr_decision"
    case adminDecision = "admin_decision"
    case peerReview = "peer_review"
    case thirdParty = "third_party"
    
    var displayName: String {
        switch self {
        case .managerDecision: return "Manager Decision"
        case .hrDecision: return "HR Decision"
        case .adminDecision: return "Admin Decision"
        case .peerReview: return "Peer Review"
        case .thirdParty: return "Third Party"
        }
    }
}

enum CorporateForfeitDistribution: String, Codable, CaseIterable {
    case charityOnly = "charity_only"
    case charityAndApp = "charity_and_app"
    case charityAndCompany = "charity_and_company"
    case companyOnly = "company_only"
    
    var displayName: String {
        switch self {
        case .charityOnly: return "Charity Only"
        case .charityAndApp: return "Charity & App"
        case .charityAndCompany: return "Charity & Company"
        case .companyOnly: return "Company Only"
        }
    }
}

// MARK: - Employee Permissions
struct EmployeePermissions: Codable, Equatable {
    var canCreateGoals: Bool
    var canCreateStakes: Bool
    var canVerifyGoals: Bool
    var canViewAnalytics: Bool
    var canInviteColleagues: Bool
    var canViewCompanyGoals: Bool
    var canParticipateInChallenges: Bool
    
    init(
        canCreateGoals: Bool = true,
        canCreateStakes: Bool = true,
        canVerifyGoals: Bool = true,
        canViewAnalytics: Bool = true,
        canInviteColleagues: Bool = true,
        canViewCompanyGoals: Bool = true,
        canParticipateInChallenges: Bool = true
    ) {
        self.canCreateGoals = canCreateGoals
        self.canCreateStakes = canCreateStakes
        self.canVerifyGoals = canVerifyGoals
        self.canViewAnalytics = canViewAnalytics
        self.canInviteColleagues = canInviteColleagues
        self.canViewCompanyGoals = canViewCompanyGoals
        self.canParticipateInChallenges = canParticipateInChallenges
    }
}

// MARK: - Corporate Settings
struct CorporateSettings: Codable, Equatable {
    var notifications: CorporateNotificationSettings
    var privacy: CorporatePrivacySettings
    var analytics: CorporateAnalyticsSettings
    var integration: CorporateIntegrationSettings
    
    init(
        notifications: CorporateNotificationSettings = CorporateNotificationSettings(),
        privacy: CorporatePrivacySettings = CorporatePrivacySettings(),
        analytics: CorporateAnalyticsSettings = CorporateAnalyticsSettings(),
        integration: CorporateIntegrationSettings = CorporateIntegrationSettings()
    ) {
        self.notifications = notifications
        self.privacy = privacy
        self.analytics = analytics
        self.integration = integration
    }
}

struct CorporateNotificationSettings: Codable, Equatable {
    var newEmployeeJoined: Bool
    var goalCreated: Bool
    var goalCompleted: Bool
    var goalFailed: Bool
    var stakeCreated: Bool
    var disputeRaised: Bool
    var weeklyReport: Bool
    var monthlyReport: Bool
    
    init(
        newEmployeeJoined: Bool = true,
        goalCreated: Bool = true,
        goalCompleted: Bool = true,
        goalFailed: Bool = true,
        stakeCreated: Bool = true,
        disputeRaised: Bool = true,
        weeklyReport: Bool = false,
        monthlyReport: Bool = true
    ) {
        self.newEmployeeJoined = newEmployeeJoined
        self.goalCreated = goalCreated
        self.goalCompleted = goalCompleted
        self.goalFailed = goalFailed
        self.stakeCreated = stakeCreated
        self.disputeRaised = disputeRaised
        self.weeklyReport = weeklyReport
        self.monthlyReport = monthlyReport
    }
}

struct CorporatePrivacySettings: Codable, Equatable {
    var showEmployeeNames: Bool
    var showGoalProgress: Bool
    var showStakeAmounts: Bool
    var showDepartmentGoals: Bool
    var allowExternalInvites: Bool
    var requireApprovalToJoin: Bool
    
    init(
        showEmployeeNames: Bool = true,
        showGoalProgress: Bool = true,
        showStakeAmounts: Bool = false,
        showDepartmentGoals: Bool = true,
        allowExternalInvites: Bool = false,
        requireApprovalToJoin: Bool = true
    ) {
        self.showEmployeeNames = showEmployeeNames
        self.showGoalProgress = showGoalProgress
        self.showStakeAmounts = showStakeAmounts
        self.showDepartmentGoals = showDepartmentGoals
        self.allowExternalInvites = allowExternalInvites
        self.requireApprovalToJoin = requireApprovalToJoin
    }
}

struct CorporateAnalyticsSettings: Codable, Equatable {
    var trackEmployeeActivity: Bool
    var trackGoalProgress: Bool
    var trackStakePerformance: Bool
    var generateWeeklyReports: Bool
    var generateMonthlyReports: Bool
    var shareAnalyticsWithEmployees: Bool
    var shareAnalyticsWithManagers: Bool
    
    init(
        trackEmployeeActivity: Bool = true,
        trackGoalProgress: Bool = true,
        trackStakePerformance: Bool = true,
        generateWeeklyReports: Bool = false,
        generateMonthlyReports: Bool = true,
        shareAnalyticsWithEmployees: Bool = true,
        shareAnalyticsWithManagers: Bool = true
    ) {
        self.trackEmployeeActivity = trackEmployeeActivity
        self.trackGoalProgress = trackGoalProgress
        self.trackStakePerformance = trackStakePerformance
        self.generateWeeklyReports = generateWeeklyReports
        self.generateMonthlyReports = generateMonthlyReports
        self.shareAnalyticsWithEmployees = shareAnalyticsWithEmployees
        self.shareAnalyticsWithManagers = shareAnalyticsWithManagers
    }
}

struct CorporateIntegrationSettings: Codable, Equatable {
    var slackIntegration: Bool
    var teamsIntegration: Bool
    var emailIntegration: Bool
    var calendarIntegration: Bool
    var hrSystemIntegration: Bool
    
    init(
        slackIntegration: Bool = false,
        teamsIntegration: Bool = false,
        emailIntegration: Bool = true,
        calendarIntegration: Bool = false,
        hrSystemIntegration: Bool = false
    ) {
        self.slackIntegration = slackIntegration
        self.teamsIntegration = teamsIntegration
        self.emailIntegration = emailIntegration
        self.calendarIntegration = calendarIntegration
        self.hrSystemIntegration = hrSystemIntegration
    }
}

// MARK: - Employee
struct Employee: Identifiable, Codable, Equatable {
    let id: String
    let userId: String
    let employeeId: String
    let firstName: String
    let lastName: String
    let email: String
    let department: String
    let position: String
    let managerId: String?
    let hireDate: Date
    let status: EmployeeStatus
    let permissions: EmployeePermissions
    
    init(
        id: String = UUID().uuidString,
        userId: String,
        employeeId: String,
        firstName: String,
        lastName: String,
        email: String,
        department: String,
        position: String,
        managerId: String? = nil,
        hireDate: Date = Date(),
        status: EmployeeStatus = .active,
        permissions: EmployeePermissions = EmployeePermissions()
    ) {
        self.id = id
        self.userId = userId
        self.employeeId = employeeId
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.department = department
        self.position = position
        self.managerId = managerId
        self.hireDate = hireDate
        self.status = status
        self.permissions = permissions
    }
}

enum EmployeeStatus: String, Codable, CaseIterable {
    case active = "active"
    case inactive = "inactive"
    case terminated = "terminated"
    case onLeave = "on_leave"
    
    var displayName: String {
        switch self {
        case .active: return "Active"
        case .inactive: return "Inactive"
        case .terminated: return "Terminated"
        case .onLeave: return "On Leave"
        }
    }
}

// MARK: - Department
struct Department: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let description: String
    let managerId: String?
    let employeeCount: Int
    let goals: [String] // Goal IDs
    let budget: Decimal?
    
    init(
        id: String = UUID().uuidString,
        name: String,
        description: String,
        managerId: String? = nil,
        employeeCount: Int = 0,
        goals: [String] = [],
        budget: Decimal? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.managerId = managerId
        self.employeeCount = employeeCount
        self.goals = goals
        self.budget = budget
    }
}

// MARK: - Corporate Account Extensions
extension CorporateAccount {
    var displayName: String {
        return companyName
    }
    
    var adminCount: Int {
        return adminIds.count
    }
    
    var activeEmployeeCount: Int {
        return employees.filter { $0.status == .active }.count
    }
    
    var activeGoalsCount: Int {
        return goals.count
    }
    
    var activeStakesCount: Int {
        return stakes.count
    }
    
    var hasLogo: Bool {
        return logoURL != nil
    }
    
    var hasWebsite: Bool {
        return website != nil
    }
    
    var hasContactInfo: Bool {
        return contactEmail != nil || contactPhone != nil
    }
    
    var isLargeCompany: Bool {
        return size == .large || size == .enterprise
    }
    
    var canCreateGoals: Bool {
        return policy.goalCreationPolicy != .adminOnly
    }
    
    var canCreateStakes: Bool {
        return policy.stakePolicy != .none
    }
    
    var hasMatchingPolicy: Bool {
        return policy.matchingPolicy.enabled
    }
}

// MARK: - Corporate Account Validation
extension CorporateAccount {
    var validationErrors: [String] {
        var errors: [String] = []
        
        if companyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Company name is required")
        }
        
        if description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Company description is required")
        }
        
        if adminIds.isEmpty {
            errors.append("At least one admin is required")
        }
        
        if let email = contactEmail, !isValidEmail(email) {
            errors.append("Invalid contact email format")
        }
        
        if let employeeCount = employeeCount, employeeCount < 1 {
            errors.append("Employee count must be at least 1")
        }
        
        return errors
    }
    
    var isValid: Bool {
        return validationErrors.isEmpty
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}
