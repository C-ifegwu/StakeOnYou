import Foundation

// MARK: - Audit Event Entity
struct AuditEvent: Identifiable, Codable, Equatable {
    let id: String
    let type: AuditEventType
    let actorId: String
    let actorType: ActorType
    let targetId: String?
    let targetType: TargetType?
    let action: String
    let metadata: [String: String]
    let timestamp: Date
    let ipAddress: String?
    let userAgent: String?
    let sessionId: String?
    
    // Optional fields
    let description: String?
    let severity: AuditSeverity
    let category: AuditCategory
    let tags: [String]
    let relatedEvents: [String] // Other audit event IDs
    
    init(
        id: String = UUID().uuidString,
        type: AuditEventType,
        actorId: String,
        actorType: ActorType,
        targetId: String? = nil,
        targetType: TargetType? = nil,
        action: String,
        metadata: [String: String] = [:],
        timestamp: Date = Date(),
        ipAddress: String? = nil,
        userAgent: String? = nil,
        sessionId: String? = nil,
        description: String? = nil,
        severity: AuditSeverity = .info,
        category: AuditCategory = .general,
        tags: [String] = [],
        relatedEvents: [String] = []
    ) {
        self.id = id
        self.type = type
        self.actorId = actorId
        self.actorType = actorType
        self.targetId = targetId
        self.targetType = targetType
        self.action = action
        self.metadata = metadata
        self.timestamp = timestamp
        self.ipAddress = ipAddress
        self.userAgent = userAgent
        self.sessionId = sessionId
        self.description = description
        self.severity = severity
        self.category = category
        self.tags = tags
        self.relatedEvents = relatedEvents
    }
}

// MARK: - Audit Event Type
enum AuditEventType: String, Codable, CaseIterable {
    case userLogin = "user_login"
    case userLogout = "user_logout"
    case userRegistration = "user_registration"
    case userProfileUpdate = "user_profile_update"
    case userDeletion = "user_deletion"
    
    case goalCreation = "goal_creation"
    case goalUpdate = "goal_update"
    case goalDeletion = "goal_deletion"
    case goalCompletion = "goal_completion"
    case goalFailure = "goal_failure"
    
    case stakeCreation = "stake_creation"
    case stakeUpdate = "stake_update"
    case stakeDeletion = "stake_deletion"
    case stakeCompletion = "stake_completion"
    case stakeForfeiture = "stake_forfeiture"
    
    case groupCreation = "group_creation"
    case groupUpdate = "group_update"
    case groupDeletion = "group_deletion"
    case groupMemberJoin = "group_member_join"
    case groupMemberLeave = "group_member_leave"
    
    case corporateAccountCreation = "corporate_account_creation"
    case corporateAccountUpdate = "corporate_account_update"
    case corporateAccountDeletion = "corporate_account_deletion"
    case employeeEnrollment = "employee_enrollment"
    case employeeRemoval = "employee_removal"
    
    case charityDonation = "charity_donation"
    case charityVerification = "charity_verification"
    
    case transactionCreation = "transaction_creation"
    case transactionUpdate = "transaction_update"
    case transactionCancellation = "transaction_cancellation"
    case transactionReversal = "transaction_reversal"
    
    case permissionRequest = "permission_request"
    case permissionGranted = "permission_granted"
    case permissionDenied = "permission_denied"
    
    case dataExport = "data_export"
    case dataDeletion = "data_deletion"
    case dataAccess = "data_access"
    
    case systemMaintenance = "system_maintenance"
    case featureFlagChange = "feature_flag_change"
    case configurationChange = "configuration_change"
    
    case securityIncident = "security_incident"
    case fraudDetection = "fraud_detection"
    case complianceViolation = "compliance_violation"
    
    case apiCall = "api_call"
    case webhookDelivery = "webhook_delivery"
    case integrationEvent = "integration_event"
    
    var displayName: String {
        switch self {
        case .userLogin: return "User Login"
        case .userLogout: return "User Logout"
        case .userRegistration: return "User Registration"
        case .userProfileUpdate: return "User Profile Update"
        case .userDeletion: return "User Deletion"
        case .goalCreation: return "Goal Creation"
        case .goalUpdate: return "Goal Update"
        case .goalDeletion: return "Goal Deletion"
        case .goalCompletion: return "Goal Completion"
        case .goalFailure: return "Goal Failure"
        case .stakeCreation: return "Stake Creation"
        case .stakeUpdate: return "Stake Update"
        case .stakeDeletion: return "Stake Deletion"
        case .stakeCompletion: return "Stake Completion"
        case .stakeForfeiture: return "Stake Forfeiture"
        case .groupCreation: return "Group Creation"
        case .groupUpdate: return "Group Update"
        case .groupDeletion: return "Group Deletion"
        case .groupMemberJoin: return "Group Member Join"
        case .groupMemberLeave: return "Group Member Leave"
        case .corporateAccountCreation: return "Corporate Account Creation"
        case .corporateAccountUpdate: return "Corporate Account Update"
        case .corporateAccountDeletion: return "Corporate Account Deletion"
        case .employeeEnrollment: return "Employee Enrollment"
        case .employeeRemoval: return "Employee Removal"
        case .charityDonation: return "Charity Donation"
        case .charityVerification: return "Charity Verification"
        case .transactionCreation: return "Transaction Creation"
        case .transactionUpdate: return "Transaction Update"
        case .transactionCancellation: return "Transaction Cancellation"
        case .transactionReversal: return "Transaction Reversal"
        case .permissionRequest: return "Permission Request"
        case .permissionGranted: return "Permission Granted"
        case .permissionDenied: return "Permission Denied"
        case .dataExport: return "Data Export"
        case .dataDeletion: return "Data Deletion"
        case .dataAccess: return "Data Access"
        case .systemMaintenance: return "System Maintenance"
        case .featureFlagChange: return "Feature Flag Change"
        case .configurationChange: return "Configuration Change"
        case .securityIncident: return "Security Incident"
        case .fraudDetection: return "Fraud Detection"
        case .complianceViolation: return "Compliance Violation"
        case .apiCall: return "API Call"
        case .webhookDelivery: return "Webhook Delivery"
        case .integrationEvent: return "Integration Event"
        }
    }
    
    var requiresImmediateAttention: Bool {
        switch self {
        case .securityIncident, .fraudDetection, .complianceViolation:
            return true
        default:
            return false
        }
    }
    
    var isUserAction: Bool {
        switch self {
        case .userLogin, .userLogout, .userRegistration, .userProfileUpdate, .userDeletion,
             .goalCreation, .goalUpdate, .goalDeletion, .goalCompletion, .goalFailure,
             .stakeCreation, .stakeUpdate, .stakeDeletion, .stakeCompletion, .stakeForfeiture,
             .groupCreation, .groupUpdate, .groupDeletion, .groupMemberJoin, .groupMemberLeave,
             .corporateAccountCreation, .corporateAccountUpdate, .corporateAccountDeletion,
             .employeeEnrollment, .employeeRemoval, .charityDonation, .permissionRequest:
            return true
        default:
            return false
        }
    }
    
    var isSystemAction: Bool {
        return !isUserAction
    }
}

// MARK: - Actor Type
enum ActorType: String, Codable, CaseIterable {
    case user = "user"
    case system = "system"
    case admin = "admin"
    case api = "api"
    case webhook = "webhook"
    case integration = "integration"
    
    var displayName: String {
        switch self {
        case .user: return "User"
        case .system: return "System"
        case .admin: return "Administrator"
        case .api: return "API"
        case .webhook: return "Webhook"
        case .integration: return "Integration"
        }
    }
}

// MARK: - Target Type
enum TargetType: String, Codable, CaseIterable {
    case user = "user"
    case goal = "goal"
    case stake = "stake"
    case group = "group"
    case corporateAccount = "corporate_account"
    case charity = "charity"
    case transaction = "transaction"
    case system = "system"
    case feature = "feature"
    case configuration = "configuration"
    
    var displayName: String {
        switch self {
        case .user: return "User"
        case .goal: return "Goal"
        case .stake: return "Stake"
        case .group: return "Group"
        case .corporateAccount: return "Corporate Account"
        case .charity: return "Charity"
        case .transaction: return "Transaction"
        case .system: return "System"
        case .feature: return "Feature"
        case .configuration: return "Configuration"
        }
    }
}

// MARK: - Audit Severity
enum AuditSeverity: String, Codable, CaseIterable {
    case debug = "debug"
    case info = "info"
    case warning = "warning"
    case error = "error"
    case critical = "critical"
    
    var displayName: String {
        switch self {
        case .debug: return "Debug"
        case .info: return "Info"
        case .warning: return "Warning"
        case .error: return "Error"
        case .critical: return "Critical"
        }
    }
    
    var level: Int {
        switch self {
        case .debug: return 0
        case .info: return 1
        case .warning: return 2
        case .error: return 3
        case .critical: return 4
        }
    }
    
    var color: String {
        switch self {
        case .debug: return "secondary"
        case .info: return "info"
        case .warning: return "warning"
        case .error: return "error"
        case .critical: return "critical"
        }
    }
}

// MARK: - Audit Category
enum AuditCategory: String, Codable, CaseIterable {
    case authentication = "authentication"
    case authorization = "authorization"
    case dataAccess = "data_access"
    case dataModification = "data_modification"
    case financial = "financial"
    case security = "security"
    case compliance = "compliance"
    case system = "system"
    case user = "user"
    case business = "business"
    case general = "general"
    
    var displayName: String {
        switch self {
        case .authentication: return "Authentication"
        case .authorization: return "Authorization"
        case .dataAccess: return "Data Access"
        case .dataModification: return "Data Modification"
        case .financial: return "Financial"
        case .security: return "Security"
        case .compliance: return "Compliance"
        case .system: return "System"
        case .user: return "User"
        case .business: return "Business"
        case .general: return "General"
        }
    }
}

// MARK: - Audit Event Extensions
extension AuditEvent {
    var isHighPriority: Bool {
        return severity == .critical || severity == .error || type.requiresImmediateAttention
    }
    
    var isUserGenerated: Bool {
        return actorType == .user
    }
    
    var isSystemGenerated: Bool {
        return actorType == .system
    }
    
    var isAdminAction: Bool {
        return actorType == .admin
    }
    
    var hasTarget: Bool {
        return targetId != nil && targetType != nil
    }
    
    var isFinancialEvent: Bool {
        return category == .financial
    }
    
    var isSecurityEvent: Bool {
        return category == .security
    }
    
    var isComplianceEvent: Bool {
        return category == .compliance
    }
    
    var isDataEvent: Bool {
        return category == .dataAccess || category == .dataModification
    }
    
    var displayDescription: String {
        if let description = description, !description.isEmpty {
            return description
        }
        return "\(action) by \(actorType.displayName)"
    }
    
    var shortDescription: String {
        return "\(type.displayName): \(action)"
    }
    
    var age: TimeInterval {
        return Date().timeIntervalSince(timestamp)
    }
    
    var isRecent: Bool {
        return age < 24 * 60 * 60 // Less than 24 hours
    }
    
    var isOld: Bool {
        return age > 30 * 24 * 60 * 60 // More than 30 days
    }
}

// MARK: - Audit Event Validation
extension AuditEvent {
    var validationErrors: [String] {
        var errors: [String] = []
        
        if actorId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Actor ID is required")
        }
        
        if action.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Action is required")
        }
        
        if targetId != nil && targetType == nil {
            errors.append("Target type is required when target ID is provided")
        }
        
        if targetType != nil && targetId == nil {
            errors.append("Target ID is required when target type is provided")
        }
        
        return errors
    }
    
    var isValid: Bool {
        return validationErrors.isEmpty
    }
}

// MARK: - Audit Event Filtering
extension AuditEvent {
    func matchesType(_ type: AuditEventType?) -> Bool {
        guard let type = type else { return true }
        return self.type == type
    }
    
    func matchesSeverity(_ severity: AuditSeverity?) -> Bool {
        guard let severity = severity else { return true }
        return self.severity == severity
    }
    
    func matchesCategory(_ category: AuditCategory?) -> Bool {
        guard let category = category else { return true }
        return self.category == category
    }
    
    func matchesActor(_ actorId: String?) -> Bool {
        guard let actorId = actorId else { return true }
        return self.actorId == actorId
    }
    
    func matchesActorType(_ actorType: ActorType?) -> Bool {
        guard let actorType = actorType else { return true }
        return self.actorType == actorType
    }
    
    func matchesTarget(_ targetId: String?) -> Bool {
        guard let targetId = targetId else { return true }
        return self.targetId == targetId
    }
    
    func matchesTargetType(_ targetType: TargetType?) -> Bool {
        guard let targetType = targetType else { return true }
        return self.targetType == targetType
    }
    
    func matchesDateRange(_ startDate: Date?, _ endDate: Date?) -> Bool {
        if let startDate = startDate, timestamp < startDate {
            return false
        }
        if let endDate = endDate, timestamp > endDate {
            return false
        }
        return true
    }
    
    func matchesSeverityLevel(_ minSeverity: AuditSeverity?) -> Bool {
        guard let minSeverity = minSeverity else { return true }
        return self.severity.level >= minSeverity.level
    }
}

// MARK: - Audit Event Analytics
extension AuditEvent {
    var isAnomalous: Bool {
        // Simple anomaly detection based on severity and type
        return severity == .critical || 
               severity == .error || 
               type.requiresImmediateAttention ||
               category == .security ||
               category == .compliance
    }
    
    var riskScore: Int {
        var score = 0
        
        // Base score from severity
        score += severity.level * 10
        
        // Additional points for high-risk categories
        if category == .security { score += 20 }
        if category == .compliance { score += 15 }
        if category == .financial { score += 10 }
        if category == .dataAccess { score += 5 }
        
        // Additional points for high-risk types
        if type.requiresImmediateAttention { score += 25 }
        
        // Additional points for admin actions
        if actorType == .admin { score += 5 }
        
        return min(score, 100) // Cap at 100
    }
    
    var isHighRisk: Bool {
        return riskScore >= 50
    }
    
    var isMediumRisk: Bool {
        return riskScore >= 25 && riskScore < 50
    }
    
    var isLowRisk: Bool {
        return riskScore < 25
    }
}
