import Foundation
import Combine

// MARK: - Mock Device Conflict Repository Implementation
class MockDeviceConflictRepository: ConflictRepository {
    // MARK: - Properties
    private var deviceConflicts: [String: DeviceConflict] = [:]
    private let logger: Logger
    
    // MARK: - Initialization
    init(logger: Logger = ConsoleLogger()) {
        self.logger = logger
        setupMockData()
    }
    
    // MARK: - CRUD Operations
    func createDeviceConflict(_ conflict: DeviceConflict) async throws -> DeviceConflict {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 600_000_000)
        
        var newConflict = conflict
        if newConflict.id.isEmpty {
            newConflict = DeviceConflict(
                id: UUID().uuidString,
                userId: conflict.userId,
                entityType: conflict.entityType,
                entityId: conflict.entityId,
                deviceId: conflict.deviceId,
                conflictType: conflict.conflictType,
                localData: conflict.localData,
                remoteData: conflict.remoteData,
                resolution: conflict.resolution,
                status: conflict.status,
                createdAt: Date(),
                updatedAt: Date()
            )
        }
        
        deviceConflicts[newConflict.id] = newConflict
        logger.info("Mock: Created device conflict with ID: \(newConflict.id)")
        return newConflict
    }
    
    func getDeviceConflict(id: String) async throws -> DeviceConflict? {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 200_000_000)
        
        let conflict = deviceConflicts[id]
        logger.info("Mock: Retrieved device conflict with ID: \(id), found: \(conflict != nil)")
        return conflict
    }
    
    func updateDeviceConflict(_ conflict: DeviceConflict) async throws -> DeviceConflict {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        guard deviceConflicts[conflict.id] != nil else {
            throw ConflictRepositoryError.conflictNotFound
        }
        
        var updatedConflict = conflict
        updatedConflict.updatedAt = Date()
        deviceConflicts[conflict.id] = updatedConflict
        
        logger.info("Mock: Updated device conflict with ID: \(conflict.id)")
        return updatedConflict
    }
    
    func deleteDeviceConflict(id: String) async throws -> Bool {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        guard deviceConflicts[id] != nil else {
            throw ConflictRepositoryError.conflictNotFound
        }
        
        deviceConflicts.removeValue(forKey: id)
        logger.info("Mock: Deleted device conflict with ID: \(id)")
        return true
    }
    
    // MARK: - Query Operations
    func getDeviceConflicts(forUserId: String) async throws -> [DeviceConflict] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let userConflicts = deviceConflicts.values.filter { $0.userId == forUserId }
        logger.info("Mock: Retrieved \(userConflicts.count) device conflicts for user: \(forUserId)")
        return userConflicts
    }
    
    func getDeviceConflicts(forDeviceId: String) async throws -> [DeviceConflict] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let deviceConflicts = deviceConflicts.values.filter { $0.deviceId == forDeviceId }
        logger.info("Mock: Retrieved \(deviceConflicts.count) device conflicts for device: \(forDeviceId)")
        return deviceConflicts
    }
    
    func getDeviceConflicts(forEntityType: String, entityId: String) async throws -> [DeviceConflict] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let entityConflicts = deviceConflicts.values.filter { $0.entityType == forEntityType && $0.entityId == entityId }
        logger.info("Mock: Retrieved \(entityConflicts.count) device conflicts for entity: \(forEntityType):\(entityId)")
        return entityConflicts
    }
    
    func getDeviceConflicts(byType: ConflictType) async throws -> [DeviceConflict] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let typeConflicts = deviceConflicts.values.filter { $0.conflictType == byType }
        logger.info("Mock: Retrieved \(typeConflicts.count) device conflicts with type: \(byType)")
        return typeConflicts
    }
    
    func getDeviceConflicts(byStatus: ConflictStatus) async throws -> [DeviceConflict] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let statusConflicts = deviceConflicts.values.filter { $0.status == byStatus }
        logger.info("Mock: Retrieved \(statusConflicts.count) device conflicts with status: \(byStatus)")
        return statusConflicts
    }
    
    func getDeviceConflicts(byResolution: ConflictResolution) async throws -> [DeviceConflict] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let resolutionConflicts = deviceConflicts.values.filter { $0.resolution == byResolution }
        logger.info("Mock: Retrieved \(resolutionConflicts.count) device conflicts with resolution: \(byResolution)")
        return resolutionConflicts
    }
    
    func getDeviceConflicts(byDateRange: DateInterval) async throws -> [DeviceConflict] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let dateRangeConflicts = deviceConflicts.values.filter { conflict in
            return conflict.createdAt >= dateRange.start && conflict.createdAt <= dateRange.end
        }
        
        logger.info("Mock: Retrieved \(dateRangeConflicts.count) device conflicts in date range")
        return dateRangeConflicts
    }
    
    // MARK: - Conflict Detection
    func detectConflicts(forUserId: String, entityType: String, entityId: String) async throws -> [DeviceConflict] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        let existingConflicts = deviceConflicts.values.filter { conflict in
            conflict.userId == forUserId &&
            conflict.entityType == entityType &&
            conflict.entityId == entityId &&
            conflict.status == .pending
        }
        
        logger.info("Mock: Detected \(existingConflicts.count) conflicts for entity: \(entityType):\(entityId)")
        return existingConflicts
    }
    
    func checkForDataConflicts(localData: [String: Any], remoteData: [String: Any], entityType: String) async throws -> [DataConflict] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        // Mock conflict detection logic - in real implementation this would compare data structures
        var conflicts: [DataConflict] = []
        
        // Simulate finding some conflicts
        if localData.count != remoteData.count {
            conflicts.append(DataConflict(
                field: "count",
                localValue: "\(localData.count)",
                remoteValue: "\(remoteData.count)",
                conflictType: .dataMismatch,
                severity: .medium
            ))
        }
        
        // Check for timestamp conflicts
        if let localTimestamp = localData["updatedAt"] as? Date,
           let remoteTimestamp = remoteData["updatedAt"] as? Date {
            if localTimestamp != remoteTimestamp {
                conflicts.append(DataConflict(
                    field: "updatedAt",
                    localValue: localTimestamp.description,
                    remoteValue: remoteTimestamp.description,
                    conflictType: .timestampConflict,
                    severity: .low
                ))
            }
        }
        
        logger.info("Mock: Detected \(conflicts.count) data conflicts for entity type: \(entityType)")
        return conflicts
    }
    
    // MARK: - Conflict Resolution
    func resolveConflict(id: String, resolution: ConflictResolution, resolvedData: [String: Any]) async throws -> DeviceConflict {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 600_000_000)
        
        guard var conflict = deviceConflicts[id] else {
            throw ConflictRepositoryError.conflictNotFound
        }
        
        conflict.resolution = resolution
        conflict.status = .resolved
        conflict.updatedAt = Date()
        
        // In real implementation, this would update the resolved data
        deviceConflicts[id] = conflict
        
        logger.info("Mock: Resolved conflict \(id) with resolution: \(resolution)")
        return conflict
    }
    
    func autoResolveConflicts(forUserId: String) async throws -> [DeviceConflict] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 800_000_000)
        
        let pendingConflicts = deviceConflicts.values.filter { conflict in
            conflict.userId == forUserId && conflict.status == .pending
        }
        
        var resolvedConflicts: [DeviceConflict] = []
        
        for var conflict in pendingConflicts {
            // Mock auto-resolution logic
            if conflict.conflictType == .timestampConflict {
                conflict.resolution = .useLatest
                conflict.status = .resolved
                conflict.updatedAt = Date()
                deviceConflicts[conflict.id] = conflict
                resolvedConflicts.append(conflict)
            }
        }
        
        logger.info("Mock: Auto-resolved \(resolvedConflicts.count) conflicts for user: \(forUserId)")
        return resolvedConflicts
    }
    
    func mergeConflictingData(localData: [String: Any], remoteData: [String: Any], mergeStrategy: MergeStrategy) async throws -> [String: Any] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        var mergedData: [String: Any] = [:]
        
        switch mergeStrategy {
        case .useLocal:
            mergedData = localData
        case .useRemote:
            mergedData = remoteData
        case .useLatest:
            // Mock latest timestamp logic
            if let localTimestamp = localData["updatedAt"] as? Date,
               let remoteTimestamp = remoteData["updatedAt"] as? Date {
                mergedData = localTimestamp > remoteTimestamp ? localData : remoteData
            } else {
                mergedData = localData
            }
        case .mergeFields:
            // Mock field merging logic
            mergedData = localData
            for (key, value) in remoteData {
                if mergedData[key] == nil {
                    mergedData[key] = value
                }
            }
        case .custom:
            // Mock custom merge logic
            mergedData = localData
            mergedData["mergedAt"] = Date()
            mergedData["mergeStrategy"] = "custom"
        }
        
        logger.info("Mock: Merged conflicting data using strategy: \(mergeStrategy)")
        return mergedData
    }
    
    // MARK: - Conflict Prevention
    func preventConflicts(forUserId: String, entityType: String, entityId: String) async throws -> Bool {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        // Mock conflict prevention logic
        let existingConflicts = deviceConflicts.values.filter { conflict in
            conflict.userId == forUserId &&
            conflict.entityType == entityType &&
            conflict.entityId == entityId &&
            conflict.status == .pending
        }
        
        // In real implementation, this would implement conflict prevention strategies
        let prevented = existingConflicts.isEmpty
        
        logger.info("Mock: Conflict prevention for entity \(entityType):\(entityId) - prevented: \(prevented)")
        return prevented
    }
    
    func setConflictPreventionRules(forUserId: String, rules: [ConflictPreventionRule]) async throws -> Bool {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Mock setting conflict prevention rules
        logger.info("Mock: Set \(rules.count) conflict prevention rules for user: \(forUserId)")
        return true
    }
    
    // MARK: - Analytics and Reporting
    func getConflictStatistics(forUserId: String) async throws -> ConflictStatistics {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        let userConflicts = deviceConflicts.values.filter { $0.userId == forUserId }
        
        let statistics = ConflictStatistics(
            userId: forUserId,
            totalConflicts: userConflicts.count,
            pendingConflicts: userConflicts.filter { $0.status == .pending }.count,
            resolvedConflicts: userConflicts.filter { $0.status == .resolved }.count,
            conflictsByType: Dictionary(grouping: userConflicts) { $0.conflictType }.mapValues { $0.count },
            conflictsByEntity: Dictionary(grouping: userConflicts) { $0.entityType }.mapValues { $0.count },
            averageResolutionTime: 2.5, // hours
            mostCommonConflictType: getMostCommonConflictType(userConflicts),
            lastConflictDate: userConflicts.max(by: { $0.createdAt < $1.createdAt })?.createdAt
        )
        
        logger.info("Mock: Generated conflict statistics for user: \(forUserId)")
        return statistics
    }
    
    func generateConflictReport(forUserId: String, dateRange: DateInterval) async throws -> ConflictReport {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 600_000_000)
        
        let userConflicts = deviceConflicts.values.filter { conflict in
            conflict.userId == forUserId &&
            conflict.createdAt >= dateRange.start &&
            conflict.createdAt <= dateRange.end
        }
        
        let report = ConflictReport(
            userId: forUserId,
            dateRange: dateRange,
            totalConflicts: userConflicts.count,
            conflictsByType: Dictionary(grouping: userConflicts) { $0.conflictType }.mapValues { $0.count },
            conflictsByStatus: Dictionary(grouping: userConflicts) { $0.status }.mapValues { $0.count },
            conflictsByEntity: Dictionary(grouping: userConflicts) { $0.entityType }.mapValues { $0.count },
            resolutionTime: 2.5, // average hours
            autoResolvedCount: userConflicts.filter { $0.resolution == .useLatest }.count,
            manualResolvedCount: userConflicts.filter { $0.resolution != .useLatest && $0.status == .resolved }.count,
            recommendations: [
                "Implement better offline sync strategies",
                "Reduce concurrent editing scenarios",
                "Improve conflict detection algorithms"
            ],
            generatedAt: Date()
        )
        
        logger.info("Mock: Generated conflict report for user: \(forUserId)")
        return report
    }
    
    // MARK: - Search and Filtering
    func searchDeviceConflicts(query: String, filters: ConflictSearchFilters?) async throws -> [DeviceConflict] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        var searchResults = deviceConflicts.values
        
        // Apply text search
        if !query.isEmpty {
            searchResults = searchResults.filter { conflict in
                conflict.entityType.localizedCaseInsensitiveContains(query) ||
                conflict.entityId.localizedCaseInsensitiveContains(query) ||
                conflict.deviceId.localizedCaseInsensitiveContains(query)
            }
        }
        
        // Apply filters
        if let filters = filters {
            if let conflictType = filters.conflictType {
                searchResults = searchResults.filter { $0.conflictType == conflictType }
            }
            
            if let status = filters.status {
                searchResults = searchResults.filter { $0.status == status }
            }
            
            if let resolution = filters.resolution {
                searchResults = searchResults.filter { $0.resolution == resolution }
            }
            
            if let entityType = filters.entityType {
                searchResults = searchResults.filter { $0.entityType == entityType }
            }
            
            if let startDate = filters.startDate {
                searchResults = searchResults.filter { $0.createdAt >= startDate }
            }
            
            if let endDate = filters.endDate {
                searchResults = searchResults.filter { $0.createdAt <= endDate }
            }
        }
        
        logger.info("Mock: Search returned \(searchResults.count) device conflicts for query: \(query)")
        return searchResults
    }
    
    // MARK: - Bulk Operations
    func bulkResolveConflicts(ids: [String], resolution: ConflictResolution) async throws -> [DeviceConflict] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        var resolvedConflicts: [DeviceConflict] = []
        
        for id in ids {
            if let conflict = deviceConflicts[id] {
                let resolvedConflict = try await resolveConflict(id: id, resolution: resolution, resolvedData: [:])
                resolvedConflicts.append(resolvedConflict)
            }
        }
        
        logger.info("Mock: Bulk resolved \(resolvedConflicts.count) device conflicts")
        return resolvedConflicts
    }
    
    func getDeviceConflictsByBatch(ids: [String]) async throws -> [DeviceConflict] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        let batchConflicts = ids.compactMap { deviceConflicts[$0] }
        logger.info("Mock: Retrieved \(batchConflicts.count) device conflicts by batch")
        return batchConflicts
    }
    
    // MARK: - Private Helper Methods
    private func getMostCommonConflictType(_ conflicts: [DeviceConflict]) -> ConflictType? {
        let typeCounts = Dictionary(grouping: conflicts) { $0.conflictType }
            .mapValues { $0.count }
        
        return typeCounts.max(by: { $0.value < $1.value })?.key
    }
    
    private func setupMockData() {
        // Create some mock device conflicts for testing
        let mockConflicts = [
            DeviceConflict(
                id: "conflict-1",
                userId: "user-1",
                entityType: "Goal",
                entityId: "goal-1",
                deviceId: "device-iphone-1",
                conflictType: .timestampConflict,
                localData: ["updatedAt": Date().addingTimeInterval(-1 * 60 * 60)],
                remoteData: ["updatedAt": Date().addingTimeInterval(-2 * 60 * 60)],
                resolution: .unresolved,
                status: .pending,
                createdAt: Date().addingTimeInterval(-30 * 60),
                updatedAt: Date().addingTimeInterval(-30 * 60)
            ),
            DeviceConflict(
                id: "conflict-2",
                userId: "user-1",
                entityType: "Stake",
                entityId: "stake-1",
                deviceId: "device-iphone-1",
                conflictType: .dataMismatch,
                localData: ["amount": 500.0, "status": "active"],
                remoteData: ["amount": 500.0, "status": "completed"],
                resolution: .unresolved,
                status: .pending,
                createdAt: Date().addingTimeInterval(-1 * 60 * 60),
                updatedAt: Date().addingTimeInterval(-1 * 60 * 60)
            ),
            DeviceConflict(
                id: "conflict-3",
                userId: "user-2",
                entityType: "Goal",
                entityId: "goal-2",
                deviceId: "device-android-1",
                conflictType: .timestampConflict,
                localData: ["updatedAt": Date().addingTimeInterval(-30 * 60)],
                remoteData: ["updatedAt": Date().addingTimeInterval(-45 * 60)],
                resolution: .useLatest,
                status: .resolved,
                createdAt: Date().addingTimeInterval(-2 * 60 * 60),
                updatedAt: Date().addingTimeInterval(-1 * 60 * 60)
            ),
            DeviceConflict(
                id: "conflict-4",
                userId: "user-2",
                entityType: "Transaction",
                entityId: "txn-5",
                deviceId: "device-android-1",
                conflictType: .dataMismatch,
                localData: ["status": "pending", "amount": 750.0],
                remoteData: ["status": "completed", "amount": 750.0],
                resolution: .useRemote,
                status: .resolved,
                createdAt: Date().addingTimeInterval(-3 * 60 * 60),
                updatedAt: Date().addingTimeInterval(-2 * 60 * 60)
            ),
            DeviceConflict(
                id: "conflict-5",
                userId: "user-3",
                entityType: "User",
                entityId: "user-3",
                deviceId: "device-ipad-1",
                conflictType: .fieldConflict,
                localData: ["preferences": ["theme": "dark"], "lastActive": Date()],
                remoteData: ["preferences": ["theme": "light"], "lastActive": Date().addingTimeInterval(-1 * 60 * 60)],
                resolution: .mergeFields,
                status: .resolved,
                createdAt: Date().addingTimeInterval(-4 * 60 * 60),
                updatedAt: Date().addingTimeInterval(-3 * 60 * 60)
            ),
            DeviceConflict(
                id: "conflict-6",
                userId: "user-1",
                entityType: "Goal",
                entityId: "goal-3",
                deviceId: "device-mac-1",
                conflictType: .timestampConflict,
                localData: ["updatedAt": Date().addingTimeInterval(-15 * 60)],
                remoteData: ["updatedAt": Date().addingTimeInterval(-20 * 60)],
                resolution: .unresolved,
                status: .pending,
                createdAt: Date().addingTimeInterval(-10 * 60),
                updatedAt: Date().addingTimeInterval(-10 * 60)
            ),
            DeviceConflict(
                id: "conflict-7",
                userId: "user-4",
                entityType: "Group",
                entityId: "group-1",
                deviceId: "device-iphone-2",
                conflictType: .dataMismatch,
                localData: ["memberCount": 5, "isActive": true],
                remoteData: ["memberCount": 6, "isActive": true],
                resolution: .useRemote,
                status: .resolved,
                createdAt: Date().addingTimeInterval(-6 * 60 * 60),
                updatedAt: Date().addingTimeInterval(-5 * 60 * 60)
            ),
            DeviceConflict(
                id: "conflict-8",
                userId: "user-5",
                entityType: "Notification",
                entityId: "notification-1",
                deviceId: "device-android-2",
                conflictType: .fieldConflict,
                localData: ["isRead": false, "priority": "high"],
                remoteData: ["isRead": true, "priority": "medium"],
                resolution: .custom,
                status: .resolved,
                createdAt: Date().addingTimeInterval(-8 * 60 * 60),
                updatedAt: Date().addingTimeInterval(-7 * 60 * 60)
            )
        ]
        
        for conflict in mockConflicts {
            deviceConflicts[conflict.id] = conflict
        }
        
        logger.info("Mock: Setup \(mockConflicts.count) mock device conflicts")
    }
}
