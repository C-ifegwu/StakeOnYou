import Foundation
import Combine

// MARK: - Get Corporate Overview Use Case
struct GetCorporateOverviewUseCase {
    private let corporateRepository: CorporateRepository
    private let goalRepository: GoalRepository
    private let stakeRepository: StakeRepository
    private let userRepository: UserRepository
    private let analyticsService: AnalyticsService
    
    init(
        corporateRepository: CorporateRepository,
        goalRepository: GoalRepository,
        stakeRepository: StakeRepository,
        userRepository: UserRepository,
        analyticsService: AnalyticsService
    ) {
        self.corporateRepository = corporateRepository
        self.goalRepository = goalRepository
        self.stakeRepository = stakeRepository
        self.userRepository = userRepository
        self.analyticsService = analyticsService
    }
    
    func execute(corporateId: String) async throws -> CorporateOverview {
        // Track analytics
        analyticsService.track(event: .corporateDashboardViewed(corporateId: corporateId))
        
        // Fetch corporate data concurrently
        async let corporateTask = corporateRepository.getCorporateAccount(id: corporateId)
        async let employeesTask = corporateRepository.getEmployees(corporateId: corporateId)
        async let goalsTask = goalRepository.getGoals(corporateId: corporateId)
        async let stakesTask = stakeRepository.getStakes(corporateId: corporateId)
        async let departmentsTask = corporateRepository.getDepartments(corporateId: corporateId)
        
        // Wait for all tasks to complete
        let (corporate, employees, goals, stakes, departments) = try await (
            corporateTask,
            employeesTask,
            goalsTask,
            stakesTask,
            departmentsTask
        )
        
        // Calculate corporate metrics
        let metrics = calculateCorporateMetrics(
            employees: employees,
            goals: goals,
            stakes: stakes,
            departments: departments
        )
        
        // Create corporate overview
        let overview = CorporateOverview(
            corporateId: corporateId,
            corporateName: corporate?.name ?? "Unknown Corporate",
            totalEmployees: employees.count,
            activeEmployees: employees.filter { $0.isActive }.count,
            totalGoals: goals.count,
            activeGoals: goals.filter { $0.status == .active }.count,
            completedGoals: goals.filter { $0.status == .completed }.count,
            totalStakeValue: stakes.reduce(0) { $0 + $1.amount },
            totalAccruedAmount: stakes.reduce(0) { $0 + $1.accruedAmount },
            averageSuccessRate: metrics.averageSuccessRate,
            topPerformingDepartments: metrics.topPerformingDepartments,
            recentActivity: metrics.recentActivity,
            complianceMetrics: metrics.complianceMetrics
        )
        
        return overview
    }
    
    func getEmployeePerformance(
        corporateId: String,
        departmentId: String? = nil,
        limit: Int = 50
    ) async throws -> [EmployeeGoalSummary] {
        let employees = try await corporateRepository.getEmployees(corporateId: corporateId)
        let goals = try await goalRepository.getGoals(corporateId: corporateId)
        let stakes = try await stakeRepository.getStakes(corporateId: corporateId)
        
        let employeeSummaries = try await buildEmployeeSummaries(
            employees: employees,
            goals: goals,
            stakes: stakes,
            departmentId: departmentId
        )
        
        // Sort by performance score and limit results
        let sortedSummaries = employeeSummaries
            .sorted { $0.performanceScore > $1.performanceScore }
            .prefix(limit)
            .enumerated()
            .map { index, summary in
                var updatedSummary = summary
                updatedSummary.rank = index + 1
                return updatedSummary
            }
        
        return Array(sortedSummaries)
    }
    
    func getDepartmentPerformance(corporateId: String) async throws -> [DepartmentPerformance] {
        let departments = try await corporateRepository.getDepartments(corporateId: corporateId)
        let employees = try await corporateRepository.getEmployees(corporateId: corporateId)
        let goals = try await goalRepository.getGoals(corporateId: corporateId)
        let stakes = try await stakeRepository.getStakes(corporateId: corporateId)
        
        let departmentPerformances = try await buildDepartmentPerformances(
            departments: departments,
            employees: employees,
            goals: goals,
            stakes: stakes
        )
        
        // Sort by success rate and add ranking
        let sortedPerformances = departmentPerformances
            .sorted { $0.successRate > $1.successRate }
            .enumerated()
            .map { index, performance in
                var updatedPerformance = performance
                updatedPerformance.rank = index + 1
                return updatedPerformance
            }
        
        return Array(sortedPerformances)
    }
    
    func getComplianceMetrics(corporateId: String) async throws -> ComplianceMetrics {
        let corporate = try await corporateRepository.getCorporateAccount(id: corporateId)
        let policies = try await corporateRepository.getPolicies(corporateId: corporateId)
        let alerts = try await corporateRepository.getComplianceAlerts(corporateId: corporateId)
        
        let compliantPolicies = policies.filter { $0.isCompliant }.count
        let complianceRate = policies.isEmpty ? 0.0 : Double(compliantPolicies) / Double(policies.count) * 100
        
        let riskLevel = determineRiskLevel(alerts: alerts, complianceRate: complianceRate)
        
        let metrics = ComplianceMetrics(
            totalPolicies: policies.count,
            compliantPolicies: compliantPolicies,
            complianceRate: complianceRate,
            lastAuditDate: corporate?.lastAuditDate,
            nextAuditDate: corporate?.nextAuditDate,
            riskLevel: riskLevel,
            alerts: alerts
        )
        
        return metrics
    }
    
    // MARK: - Private Methods
    
    private func calculateCorporateMetrics(
        employees: [User],
        goals: [Goal],
        stakes: [Stake],
        departments: [Department]
    ) -> CorporateMetrics {
        let activeGoals = goals.filter { $0.status == .active }
        let completedGoals = goals.filter { $0.status == .completed }
        let totalGoals = goals.count
        
        let averageSuccessRate = totalGoals > 0 ? Double(completedGoals.count) / Double(totalGoals) * 100 : 0.0
        
        let topPerformingDepartments = buildTopPerformingDepartments(
            departments: departments,
            employees: employees,
            goals: goals,
            stakes: stakes
        )
        
        let recentActivity = buildRecentActivity(goals: goals, employees: employees)
        
        let complianceMetrics = buildComplianceMetrics(employees: employees, goals: goals)
        
        return CorporateMetrics(
            averageSuccessRate: averageSuccessRate,
            topPerformingDepartments: topPerformingDepartments,
            recentActivity: recentActivity,
            complianceMetrics: complianceMetrics
        )
    }
    
    private func buildTopPerformingDepartments(
        departments: [Department],
        employees: [User],
        goals: [Goal],
        stakes: [Stake]
    ) -> [DepartmentPerformance] {
        return departments.map { department in
            let departmentEmployees = employees.filter { $0.departmentId == department.id }
            let departmentGoals = goals.filter { goal in
                departmentEmployees.contains { $0.id == goal.userId }
            }
            let departmentStakes = stakes.filter { stake in
                departmentEmployees.contains { $0.id == stake.userId }
            }
            
            let activeGoals = departmentGoals.filter { $0.status == .active }
            let completedGoals = departmentGoals.filter { $0.status == .completed }
            let successRate = departmentGoals.isEmpty ? 0.0 : Double(completedGoals.count) / Double(departmentGoals.count) * 100
            let averageStakeValue = departmentStakes.isEmpty ? 0 : departmentStakes.reduce(0) { $0 + $1.amount } / Decimal(departmentStakes.count)
            let totalAccruedAmount = departmentStakes.reduce(0) { $0 + $1.accruedAmount }
            
            return DepartmentPerformance(
                departmentName: department.name,
                employeeCount: departmentEmployees.count,
                activeGoals: activeGoals.count,
                completedGoals: completedGoals.count,
                successRate: successRate,
                averageStakeValue: averageStakeValue,
                totalAccruedAmount: totalAccruedAmount
            )
        }
        .sorted { $0.successRate > $1.successRate }
        .prefix(5)
        .map { $0 }
    }
    
    private func buildRecentActivity(goals: [Goal], employees: [User]) -> [CorporateActivityItem] {
        let recentGoals = goals
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(10)
        
        return recentGoals.map { goal in
            let employee = employees.first { $0.id == goal.userId }
            let activityType: CorporateActivityType
            
            switch goal.status {
            case .active:
                activityType = .goalCreated
            case .completed:
                activityType = .goalCompleted
            case .failed:
                activityType = .goalFailed
            default:
                activityType = .goalCreated
            }
            
            return CorporateActivityItem(
                type: activityType,
                title: "Goal: \(goal.title)",
                description: "\(employee?.fullName ?? "Unknown") - \(goal.category.displayName)",
                departmentId: employee?.departmentId,
                employeeId: goal.userId,
                goalId: goal.id
            )
        }
    }
    
    private func buildComplianceMetrics(employees: [User], goals: [Goal]) -> ComplianceMetrics {
        // Simplified compliance metrics
        // In a real implementation, this would check against actual compliance policies
        let totalPolicies = 10 // Placeholder
        let compliantPolicies = 8 // Placeholder
        let complianceRate = Double(compliantPolicies) / Double(totalPolicies) * 100
        
        let alerts: [ComplianceAlert] = [] // Placeholder for actual alerts
        
        return ComplianceMetrics(
            totalPolicies: totalPolicies,
            compliantPolicies: compliantPolicies,
            complianceRate: complianceRate,
            riskLevel: .low
        )
    }
    
    private func buildEmployeeSummaries(
        employees: [User],
        goals: [Goal],
        stakes: [Stake],
        departmentId: String?
    ) async throws -> [EmployeeGoalSummary] {
        let filteredEmployees = departmentId != nil ? employees.filter { $0.departmentId == departmentId } : employees
        
        return filteredEmployees.map { employee in
            let employeeGoals = goals.filter { $0.userId == employee.id }
            let employeeStakes = stakes.filter { $0.userId == employee.id }
            
            let totalGoals = employeeGoals.count
            let activeGoals = employeeGoals.filter { $0.status == .active }.count
            let completedGoals = employeeGoals.filter { $0.status == .completed }.count
            let successRate = totalGoals > 0 ? Double(completedGoals.count) / Double(totalGoals) * 100 : 0.0
            
            let totalStakeValue = employeeStakes.reduce(0) { $0 + $1.amount }
            let totalAccruedAmount = employeeStakes.reduce(0) { $0 + $1.accruedAmount }
            
            let averageGoalDuration = employeeGoals.isEmpty ? 0 : employeeGoals.reduce(0) { $0 + $0.duration }
            let lastGoalCreated = employeeGoals.max { $0.createdAt < $1.createdAt }?.createdAt
            let lastGoalCompleted = employeeGoals.filter { $0.status == .completed }.max { $0.completedAt ?? Date.distantPast < $1.completedAt ?? Date.distantPast }?.completedAt
            
            let performanceScore = calculatePerformanceScore(
                successRate: successRate,
                totalGoals: totalGoals,
                totalStakeValue: totalStakeValue,
                totalAccruedAmount: totalAccruedAmount
            )
            
            return EmployeeGoalSummary(
                employeeId: employee.id,
                employeeName: employee.fullName,
                departmentName: employee.departmentName ?? "Unknown",
                avatarURL: employee.avatarURL,
                totalGoals: totalGoals,
                activeGoals: activeGoals,
                completedGoals: completedGoals,
                successRate: successRate,
                totalStakeValue: totalStakeValue,
                totalAccruedAmount: totalAccruedAmount,
                averageGoalDuration: averageGoalDuration,
                lastGoalCreated: lastGoalCreated,
                lastGoalCompleted: lastGoalCompleted,
                performanceScore: performanceScore
            )
        }
    }
    
    private func buildDepartmentPerformances(
        departments: [Department],
        employees: [User],
        goals: [Goal],
        stakes: [Stake]
    ) async throws -> [DepartmentPerformance] {
        return departments.map { department in
            let departmentEmployees = employees.filter { $0.departmentId == department.id }
            let departmentGoals = goals.filter { goal in
                departmentEmployees.contains { $0.id == goal.userId }
            }
            let departmentStakes = stakes.filter { stake in
                departmentEmployees.contains { $0.id == stake.userId }
            }
            
            let activeGoals = departmentGoals.filter { $0.status == .active }
            let completedGoals = departmentGoals.filter { $0.status == .completed }
            let successRate = departmentGoals.isEmpty ? 0.0 : Double(completedGoals.count) / Double(departmentGoals.count) * 100
            let averageStakeValue = departmentStakes.isEmpty ? 0 : departmentStakes.reduce(0) { $0 + $1.amount } / Decimal(departmentStakes.count)
            let totalAccruedAmount = departmentStakes.reduce(0) { $0 + $1.accruedAmount }
            
            return DepartmentPerformance(
                departmentName: department.name,
                employeeCount: departmentEmployees.count,
                activeGoals: activeGoals.count,
                completedGoals: completedGoals.count,
                successRate: successRate,
                averageStakeValue: averageStakeValue,
                totalAccruedAmount: totalAccruedAmount
            )
        }
    }
    
    private func calculatePerformanceScore(
        successRate: Double,
        totalGoals: Int,
        totalStakeValue: Decimal,
        totalAccruedAmount: Decimal
    ) -> Double {
        let goalWeight = 0.4
        let successWeight = 0.3
        let stakeWeight = 0.2
        let accrualWeight = 0.1
        
        let goalScore = min(Double(totalGoals) / 10.0, 1.0) * 100 // Normalize to 0-100
        let successScore = successRate
        let stakeScore = min(Double(truncating: totalStakeValue as NSDecimalNumber) / 1000.0, 1.0) * 100 // Normalize to 0-100
        let accrualScore = min(Double(truncating: totalAccruedAmount as NSDecimalNumber) / 500.0, 1.0) * 100 // Normalize to 0-100
        
        return goalScore * goalWeight + successScore * successWeight + stakeScore * stakeWeight + accrualScore * accrualWeight
    }
    
    private func determineRiskLevel(alerts: [ComplianceAlert], complianceRate: Double) -> ComplianceRiskLevel {
        let criticalAlerts = alerts.filter { $0.severity == .critical }.count
        let highAlerts = alerts.filter { $0.severity == .high }.count
        
        if criticalAlerts > 0 || complianceRate < 70 {
            return .critical
        } else if highAlerts > 2 || complianceRate < 85 {
            return .high
        } else if highAlerts > 0 || complianceRate < 95 {
            return .medium
        } else {
            return .low
        }
    }
}

// MARK: - Supporting Structures
struct CorporateMetrics {
    let averageSuccessRate: Double
    let topPerformingDepartments: [DepartmentPerformance]
    let recentActivity: [CorporateActivityItem]
    let complianceMetrics: ComplianceMetrics
}

struct Department: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let corporateId: String
    let managerId: String?
    let createdAt: Date
    
    init(
        id: String = UUID().uuidString,
        name: String,
        corporateId: String,
        managerId: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.corporateId = corporateId
        self.managerId = managerId
        self.createdAt = createdAt
    }
}

// MARK: - Corporate Repository Protocol
protocol CorporateRepository {
    func getCorporateAccount(id: String) async throws -> CorporateAccount?
    func getEmployees(corporateId: String) async throws -> [User]
    func getDepartments(corporateId: String) async throws -> [Department]
    func getPolicies(corporateId: String) async throws -> [CorporatePolicy]
    func getComplianceAlerts(corporateId: String) async throws -> [ComplianceAlert]
}

struct CorporatePolicy: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let description: String
    let isCompliant: Bool
    let lastChecked: Date
    let nextCheck: Date
    
    init(
        id: String = UUID().uuidString,
        name: String,
        description: String,
        isCompliant: Bool = true,
        lastChecked: Date = Date(),
        nextCheck: Date = Date().addingTimeInterval(30 * 24 * 60 * 60) // 30 days
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.isCompliant = isCompliant
        self.lastChecked = lastChecked
        self.nextCheck = nextCheck
    }
}

// MARK: - Analytics Events
extension AnalyticsEvent {
    static func corporateDashboardViewed(corporateId: String) -> AnalyticsEvent {
        AnalyticsEvent(
            name: "corporate_dashboard_viewed",
            properties: [
                "corporate_id": corporateId,
                "timestamp": Date().timeIntervalSince1970
            ]
        )
    }
    
    static func employeePerformanceViewed(corporateId: String, departmentId: String?) -> AnalyticsEvent {
        var properties: [String: Any] = [
            "corporate_id": corporateId,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if let departmentId = departmentId {
            properties["department_id"] = departmentId
        }
        
        return AnalyticsEvent(
            name: "employee_performance_viewed",
            properties: properties
        )
    }
}
