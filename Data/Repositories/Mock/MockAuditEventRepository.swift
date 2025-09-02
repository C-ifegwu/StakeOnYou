import Foundation
import Combine

// MARK: - Mock Audit Event Repository Implementation
class MockAuditEventRepository: AuditEventRepository {
    // MARK: - Properties
    private var auditEvents: [String: AuditEvent] = [:]
    private let logger: Logger
    
    // MARK: - Initialization
    init(logger: Logger = ConsoleLogger()) {
        self.logger = logger
        setupMockData()
    }
    
    // MARK: - CRUD Operations
    func createAuditEvent(_ event: AuditEvent) async throws -> AuditEvent {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        var newEvent = event
        if newEvent.id.isEmpty {
            newEvent = AuditEvent(
                id: UUID().uuidString,
                eventType: event.eventType,
                userId: event.userId,
                entityType: event.entityType,
                entityId: event.entityId,
                action: event.action,
                description: event.description,
                metadata: event.metadata,
                ipAddress: event.ipAddress,
                userAgent: event.userAgent,
                timestamp: Date(),
                severity: event.severity
            )
        }
        
        auditEvents[newEvent.id] = newEvent
        logger.info("Mock: Created audit event with ID: \(newEvent.id)")
        return newEvent
    }
    
    func getAuditEvent(id: String) async throws -> AuditEvent? {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 200_000_000)
        
        let event = auditEvents[id]
        logger.info("Mock: Retrieved audit event with ID: \(id), found: \(event != nil)")
        return event
    }
    
    func updateAuditEvent(_ event: AuditEvent) async throws -> AuditEvent {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        guard auditEvents[event.id] != nil else {
            throw AuditEventRepositoryError.eventNotFound
        }
        
        auditEvents[event.id] = event
        
        logger.info("Mock: Updated audit event with ID: \(event.id)")
        return event
    }
    
    func deleteAuditEvent(id: String) async throws -> Bool {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        guard auditEvents[id] != nil else {
            throw AuditEventRepositoryError.eventNotFound
        }
        
        auditEvents.removeValue(forKey: id)
        logger.info("Mock: Deleted audit event with ID: \(id)")
        return true
    }
    
    // MARK: - Query Operations
    func getAuditEvents(forUserId: String) async throws -> [AuditEvent] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let userEvents = auditEvents.values.filter { $0.userId == forUserId }
        logger.info("Mock: Retrieved \(userEvents.count) audit events for user: \(forUserId)")
        return userEvents
    }
    
    func getAuditEvents(forEntityType: String, entityId: String) async throws -> [AuditEvent] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let entityEvents = auditEvents.values.filter { $0.entityType == forEntityType && $0.entityId == entityId }
        logger.info("Mock: Retrieved \(entityEvents.count) audit events for entity: \(forEntityType):\(entityId)")
        return entityEvents
    }
    
    func getAuditEvents(byType: AuditEventType) async throws -> [AuditEvent] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let typeEvents = auditEvents.values.filter { $0.eventType == byType }
        logger.info("Mock: Retrieved \(typeEvents.count) audit events with type: \(byType)")
        return typeEvents
    }
    
    func getAuditEvents(byAction: String) async throws -> [AuditEvent] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let actionEvents = auditEvents.values.filter { $0.action == byAction }
        logger.info("Mock: Retrieved \(actionEvents.count) audit events with action: \(byAction)")
        return actionEvents
    }
    
    func getAuditEvents(bySeverity: AuditSeverity) async throws -> [AuditEvent] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let severityEvents = auditEvents.values.filter { $0.severity == bySeverity }
        logger.info("Mock: Retrieved \(severityEvents.count) audit events with severity: \(bySeverity)")
        return severityEvents
    }
    
    func getAuditEvents(byDateRange: DateInterval) async throws -> [AuditEvent] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let dateRangeEvents = auditEvents.values.filter { event in
            return event.timestamp >= dateRange.start && event.timestamp <= dateRange.end
        }
        
        logger.info("Mock: Retrieved \(dateRangeEvents.count) audit events in date range")
        return dateRangeEvents
    }
    
    func getAuditEvents(byIpAddress: String) async throws -> [AuditEvent] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let ipEvents = auditEvents.values.filter { $0.ipAddress == byIpAddress }
        logger.info("Mock: Retrieved \(ipEvents.count) audit events from IP: \(byIpAddress)")
        return ipEvents
    }
    
    // MARK: - Security and Compliance
    func getSecurityEvents(forUserId: String) async throws -> [AuditEvent] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        let securityEvents = auditEvents.values.filter { event in
            event.userId == forUserId && 
            (event.severity == .high || event.severity == .critical) &&
            (event.eventType == .security || event.eventType == .authentication)
        }
        
        logger.info("Mock: Retrieved \(securityEvents.count) security events for user: \(forUserId)")
        return securityEvents
    }
    
    func getFailedAuthenticationEvents(forUserId: String) async throws -> [AuditEvent] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let failedAuthEvents = auditEvents.values.filter { event in
            event.userId == forUserId && 
            event.eventType == .authentication && 
            event.action == "login_failed"
        }
        
        logger.info("Mock: Retrieved \(failedAuthEvents.count) failed authentication events for user: \(forUserId)")
        return failedAuthEvents
    }
    
    func getSuspiciousActivityEvents(forUserId: String) async throws -> [AuditEvent] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        let suspiciousEvents = auditEvents.values.filter { event in
            event.userId == forUserId && 
            event.severity == .high &&
            (event.eventType == .security || event.eventType == .dataAccess)
        }
        
        logger.info("Mock: Retrieved \(suspiciousEvents.count) suspicious activity events for user: \(forUserId)")
        return suspiciousEvents
    }
    
    // MARK: - Data Access Tracking
    func getDataAccessEvents(forUserId: String) async throws -> [AuditEvent] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let dataAccessEvents = auditEvents.values.filter { event in
            event.userId == forUserId && event.eventType == .dataAccess
        }
        
        logger.info("Mock: Retrieved \(dataAccessEvents.count) data access events for user: \(forUserId)")
        return dataAccessEvents
    }
    
    func getDataAccessEvents(forEntityType: String, entityId: String) async throws -> [AuditEvent] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let entityDataAccessEvents = auditEvents.values.filter { event in
            event.entityType == forEntityType && 
            event.entityId == entityId && 
            event.eventType == .dataAccess
        }
        
        logger.info("Mock: Retrieved \(entityDataAccessEvents.count) data access events for entity: \(forEntityType):\(entityId)")
        return entityDataAccessEvents
    }
    
    // MARK: - Financial Tracking
    func getFinancialEvents(forUserId: String) async throws -> [AuditEvent] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let financialEvents = auditEvents.values.filter { event in
            event.userId == forUserId && 
            (event.eventType == .financial || event.entityType == "Transaction" || event.entityType == "Stake")
        }
        
        logger.info("Mock: Retrieved \(financialEvents.count) financial events for user: \(forUserId)")
        return financialEvents
    }
    
    func getFinancialEvents(byAmount: Double, comparison: ComparisonType) async throws -> [AuditEvent] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        let financialEvents = auditEvents.values.filter { event in
            event.eventType == .financial || event.entityType == "Transaction" || event.entityType == "Stake"
        }
        
        // Mock amount filtering - in real implementation this would parse metadata for amounts
        let filteredEvents = financialEvents.filter { _ in
            // Simulate some events matching the criteria
            Bool.random()
        }
        
        logger.info("Mock: Retrieved \(filteredEvents.count) financial events with amount \(comparison.rawValue) \(byAmount)")
        return filteredEvents
    }
    
    // MARK: - Compliance and Reporting
    func generateAuditReport(forUserId: String, dateRange: DateInterval) async throws -> AuditReport {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 600_000_000)
        
        let userEvents = auditEvents.values.filter { event in
            event.userId == forUserId &&
            event.timestamp >= dateRange.start &&
            event.timestamp <= dateRange.end
        }
        
        let report = AuditReport(
            userId: forUserId,
            dateRange: dateRange,
            totalEvents: userEvents.count,
            eventsByType: Dictionary(grouping: userEvents) { $0.eventType }.mapValues { $0.count },
            eventsBySeverity: Dictionary(grouping: userEvents) { $0.severity }.mapValues { $0.count },
            eventsByAction: Dictionary(grouping: userEvents) { $0.action }.mapValues { $0.count },
            securityEvents: userEvents.filter { $0.eventType == .security }.count,
            dataAccessEvents: userEvents.filter { $0.eventType == .dataAccess }.count,
            financialEvents: userEvents.filter { $0.eventType == .financial }.count,
            highSeverityEvents: userEvents.filter { $0.severity == .high }.count,
            criticalSeverityEvents: userEvents.filter { $0.severity == .critical }.count,
            generatedAt: Date()
        )
        
        logger.info("Mock: Generated audit report for user: \(forUserId)")
        return report
    }
    
    func generateComplianceReport(dateRange: DateInterval) async throws -> ComplianceReport {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 800_000_000)
        
        let report = ComplianceReport(
            dateRange: dateRange,
            totalEvents: auditEvents.count,
            eventsByType: Dictionary(grouping: auditEvents.values) { $0.eventType }.mapValues { $0.count },
            eventsBySeverity: Dictionary(grouping: auditEvents.values) { $0.severity }.mapValues { $0.count },
            securityIncidents: auditEvents.values.filter { $0.severity == .critical && $0.eventType == .security }.count,
            dataBreaches: auditEvents.values.filter { $0.severity == .critical && $0.eventType == .dataAccess }.count,
            failedAuthentications: auditEvents.values.filter { $0.action == "login_failed" }.count,
            suspiciousActivities: auditEvents.values.filter { $0.severity == .high }.count,
            complianceScore: 0.95, // 95% compliance
            recommendations: [
                "Implement additional monitoring for high-severity events",
                "Review failed authentication patterns",
                "Enhance data access controls"
            ],
            generatedAt: Date()
        )
        
        logger.info("Mock: Generated compliance report")
        return report
    }
    
    // MARK: - Search and Filtering
    func searchAuditEvents(query: String, filters: AuditEventSearchFilters?) async throws -> [AuditEvent] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        var searchResults = auditEvents.values
        
        // Apply text search
        if !query.isEmpty {
            searchResults = searchResults.filter { event in
                event.description.localizedCaseInsensitiveContains(query) ||
                event.action.localizedCaseInsensitiveContains(query) ||
                event.entityType.localizedCaseInsensitiveContains(query)
            }
        }
        
        // Apply filters
        if let filters = filters {
            if let eventType = filters.eventType {
                searchResults = searchResults.filter { $0.eventType == eventType }
            }
            
            if let severity = filters.severity {
                searchResults = searchResults.filter { $0.severity == severity }
            }
            
            if let action = filters.action {
                searchResults = searchResults.filter { $0.action == action }
            }
            
            if let entityType = filters.entityType {
                searchResults = searchResults.filter { $0.entityType == entityType }
            }
            
            if let startDate = filters.startDate {
                searchResults = searchResults.filter { $0.timestamp >= startDate }
            }
            
            if let endDate = filters.endDate {
                searchResults = searchResults.filter { $0.timestamp <= endDate }
            }
        }
        
        logger.info("Mock: Search returned \(searchResults.count) audit events for query: \(query)")
        return searchResults
    }
    
    // MARK: - Bulk Operations
    func bulkCreateAuditEvents(_ events: [AuditEvent]) async throws -> [AuditEvent] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        var createdEvents: [AuditEvent] = []
        
        for event in events {
            let createdEvent = try await createAuditEvent(event)
            createdEvents.append(createdEvent)
        }
        
        logger.info("Mock: Bulk created \(createdEvents.count) audit events")
        return createdEvents
    }
    
    func getAuditEventsByBatch(ids: [String]) async throws -> [AuditEvent] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        let batchEvents = ids.compactMap { auditEvents[$0] }
        logger.info("Mock: Retrieved \(batchEvents.count) audit events by batch")
        return batchEvents
    }
    
    // MARK: - Data Retention and Cleanup
    func deleteOldAuditEvents(olderThan date: Date) async throws -> Int {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 600_000_000)
        
        let oldEvents = auditEvents.values.filter { $0.timestamp < date }
        let count = oldEvents.count
        
        for event in oldEvents {
            auditEvents.removeValue(forKey: event.id)
        }
        
        logger.info("Mock: Deleted \(count) old audit events")
        return count
    }
    
    func archiveAuditEvents(olderThan date: Date) async throws -> Int {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 800_000_000)
        
        let eventsToArchive = auditEvents.values.filter { $0.timestamp < date }
        let count = eventsToArchive.count
        
        // In real implementation, this would move events to archive storage
        logger.info("Mock: Archived \(count) audit events")
        return count
    }
    
    // MARK: - Private Helper Methods
    private func setupMockData() {
        // Create some mock audit events for testing
        let mockEvents = [
            AuditEvent(
                id: "audit-1",
                eventType: .authentication,
                userId: "user-1",
                entityType: "User",
                entityId: "user-1",
                action: "login_successful",
                description: "User successfully logged in",
                metadata: ["method": "email_password", "ip": "192.168.1.100"],
                ipAddress: "192.168.1.100",
                userAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X)",
                timestamp: Date().addingTimeInterval(-2 * 60 * 60), // 2 hours ago
                severity: .low
            ),
            AuditEvent(
                id: "audit-2",
                eventType: .authentication,
                userId: "user-1",
                entityType: "User",
                entityId: "user-1",
                action: "login_failed",
                description: "Failed login attempt",
                metadata: ["method": "email_password", "reason": "invalid_password"],
                ipAddress: "192.168.1.100",
                userAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X)",
                timestamp: Date().addingTimeInterval(-3 * 60 * 60), // 3 hours ago
                severity: .medium
            ),
            AuditEvent(
                id: "audit-3",
                eventType: .dataAccess,
                userId: "user-1",
                entityType: "Goal",
                entityId: "goal-1",
                action: "view",
                description: "User viewed goal details",
                metadata: ["goalTitle": "Run 5K"],
                ipAddress: "192.168.1.100",
                userAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X)",
                timestamp: Date().addingTimeInterval(-1 * 60 * 60), // 1 hour ago
                severity: .low
            ),
            AuditEvent(
                id: "audit-4",
                eventType: .dataAccess,
                userId: "user-1",
                entityType: "Goal",
                entityId: "goal-1",
                action: "update",
                description: "User updated goal progress",
                metadata: ["goalTitle": "Run 5K", "field": "progress"],
                ipAddress: "192.168.1.100",
                userAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X)",
                timestamp: Date().addingTimeInterval(-30 * 60), // 30 minutes ago
                severity: .low
            ),
            AuditEvent(
                id: "audit-5",
                eventType: .financial,
                userId: "user-1",
                entityType: "Stake",
                entityId: "stake-1",
                action: "create",
                description: "User created new stake",
                metadata: ["amount": "500.0", "goalTitle": "Run 5K"],
                ipAddress: "192.168.1.100",
                userAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X)",
                timestamp: Date().addingTimeInterval(-24 * 60 * 60), // 1 day ago
                severity: .medium
            ),
            AuditEvent(
                id: "audit-6",
                eventType: .security,
                userId: "user-2",
                entityType: "User",
                entityId: "user-2",
                action: "password_change",
                description: "User changed password",
                metadata: ["method": "forgot_password"],
                ipAddress: "10.0.0.50",
                userAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
                timestamp: Date().addingTimeInterval(-12 * 60 * 60), // 12 hours ago
                severity: .medium
            ),
            AuditEvent(
                id: "audit-7",
                eventType: .dataAccess,
                userId: "user-2",
                entityType: "Transaction",
                entityId: "txn-5",
                action: "view",
                description: "User viewed transaction history",
                metadata: ["transactionType": "deposit"],
                ipAddress: "10.0.0.50",
                userAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
                timestamp: Date().addingTimeInterval(-6 * 60 * 60), // 6 hours ago
                severity: .low
            ),
            AuditEvent(
                id: "audit-8",
                eventType: .security,
                userId: "user-3",
                entityType: "User",
                entityId: "user-3",
                action: "suspicious_activity",
                description: "Multiple failed login attempts detected",
                metadata: ["attempts": "5", "timeframe": "10_minutes"],
                ipAddress: "203.0.113.25",
                userAgent: "Unknown",
                timestamp: Date().addingTimeInterval(-45 * 60), // 45 minutes ago
                severity: .high
            ),
            AuditEvent(
                id: "audit-9",
                eventType: .dataAccess,
                userId: "admin-1",
                entityType: "User",
                entityId: "user-1",
                action: "admin_view",
                description: "Admin viewed user profile",
                metadata: ["reason": "support_request"],
                ipAddress: "172.16.0.10",
                userAgent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)",
                timestamp: Date().addingTimeInterval(-4 * 60 * 60), // 4 hours ago
                severity: .medium
            ),
            AuditEvent(
                id: "audit-10",
                eventType: .system,
                userId: "system",
                entityType: "System",
                entityId: "backup",
                action: "backup_completed",
                description: "System backup completed successfully",
                metadata: ["backupSize": "2.5GB", "duration": "15_minutes"],
                ipAddress: "127.0.0.1",
                userAgent: "System/1.0",
                timestamp: Date().addingTimeInterval(-8 * 60 * 60), // 8 hours ago
                severity: .low
            )
        ]
        
        for event in mockEvents {
            auditEvents[event.id] = event
        }
        
        logger.info("Mock: Setup \(mockEvents.count) mock audit events")
    }
}
