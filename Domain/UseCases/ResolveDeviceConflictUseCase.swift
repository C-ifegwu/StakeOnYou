import Foundation
import Combine

// MARK: - Resolve Device Conflict Use Case
struct ResolveDeviceConflictUseCase {
    private let conflictRepository: ConflictRepository
    private let realTimeRepository: RealTimeRepository
    private let userRepository: UserRepository
    private let analyticsService: AnalyticsService
    
    init(
        conflictRepository: ConflictRepository,
        realTimeRepository: RealTimeRepository,
        userRepository: UserRepository,
        analyticsService: AnalyticsService
    ) {
        self.conflictRepository = conflictRepository
        self.realTimeRepository = realTimeRepository
        self.userRepository = userRepository
        self.analyticsService = analyticsService
    }
    
    func execute(conflict: DeviceConflict) async throws -> ConflictResolution {
        // Track analytics
        analyticsService.track(event: .conflictResolutionStarted(
            userId: conflict.userId,
            conflictType: conflict.conflictType,
            entityType: conflict.entityType
        ))
        
        // Attempt automatic resolution first
        if let autoResolution = try? await attemptAutomaticResolution(conflict: conflict) {
            try await conflictRepository.updateConflictStatus(
                conflictId: conflict.id,
                status: .resolved,
                resolution: autoResolution
            )
            
            // Track successful auto-resolution
            analyticsService.track(event: .conflictAutoResolved(
                userId: conflict.userId,
                conflictId: conflict.id,
                resolutionType: autoResolution.resolutionType
            ))
            
            return autoResolution
        }
        
        // If automatic resolution fails, mark for manual resolution
        try await conflictRepository.updateConflictStatus(
            conflictId: conflict.id,
            status: .resolving
        )
        
        // Track manual resolution required
        analyticsService.track(event: .conflictManualResolutionRequired(
            userId: conflict.userId,
            conflictId: conflict.id,
            conflictType: conflict.conflictType
        ))
        
        throw ConflictError.manualResolutionRequired(conflict: conflict)
    }
    
    func resolveConflictManually(
        conflictId: String,
        resolutionType: ResolutionType,
        chosenVersion: ConflictVersion,
        mergeData: [String: String]? = nil,
        notes: String? = nil,
        resolvedBy: String
    ) async throws -> ConflictResolution {
        let resolution = ConflictResolution(
            resolvedAt: Date(),
            resolvedBy: resolvedBy,
            resolutionType: resolutionType,
            chosenVersion: chosenVersion,
            mergeData: mergeData,
            notes: notes
        )
        
        // Update conflict status
        try await conflictRepository.updateConflictStatus(
            conflictId: conflictId,
            status: .resolved,
            resolution: resolution
        )
        
        // Apply the resolution to the data store
        try await applyResolution(resolution: resolution)
        
        // Track successful manual resolution
        analyticsService.track(event: .conflictManuallyResolved(
            userId: resolvedBy,
            conflictId: conflictId,
            resolutionType: resolutionType
        ))
        
        return resolution
    }
    
    func getActiveConflicts(userId: String) async throws -> [DeviceConflict] {
        return try await conflictRepository.getActiveConflicts(userId: userId)
    }
    
    func getConflictHistory(userId: String, limit: Int = 50) async throws -> [DeviceConflict] {
        return try await conflictRepository.getConflictHistory(userId: userId, limit: limit)
    }
    
    func ignoreConflict(conflictId: String, userId: String, reason: String?) async throws {
        let resolution = ConflictResolution(
            resolvedAt: Date(),
            resolvedBy: userId,
            resolutionType: .manual,
            chosenVersion: ConflictVersion(
                deviceId: "ignored",
                timestamp: Date(),
                version: 0,
                data: [:],
                checksum: ""
            ),
            notes: reason
        )
        
        try await conflictRepository.updateConflictStatus(
            conflictId: conflictId,
            status: .ignored,
            resolution: resolution
        )
        
        // Track ignored conflict
        analyticsService.track(event: .conflictIgnored(
            userId: userId,
            conflictId: conflictId,
            reason: reason
        ))
    }
    
    func detectConflicts(userId: String) async throws -> [DeviceConflict] {
        // Get user's active data from all devices
        let userData = try await realTimeRepository.getUserDataFromAllDevices(userId: userId)
        
        // Analyze for conflicts
        let conflicts = try await analyzeForConflicts(userData: userData, userId: userId)
        
        // Save detected conflicts
        for conflict in conflicts {
            try await conflictRepository.saveConflict(conflict)
        }
        
        // Track conflict detection
        if !conflicts.isEmpty {
            analyticsService.track(event: .conflictsDetected(
                userId: userId,
                count: conflicts.count,
                types: conflicts.map { $0.conflictType.rawValue }
            ))
        }
        
        return conflicts
    }
    
    func syncUserData(userId: String, deviceId: String) async throws -> SyncResult {
        // Track sync request
        analyticsService.track(event: .syncRequested(
            userId: userId,
            deviceId: deviceId
        ))
        
        // Check for conflicts before syncing
        let conflicts = try await detectConflicts(userId: userId)
        
        if !conflicts.isEmpty {
            // Resolve conflicts first
            for conflict in conflicts {
                try await execute(conflict: conflict)
            }
        }
        
        // Perform data sync
        let syncResult = try await realTimeRepository.syncUserData(
            userId: userId,
            deviceId: deviceId
        )
        
        // Track successful sync
        analyticsService.track(event: .syncCompleted(
            userId: userId,
            deviceId: deviceId,
            entitiesSynced: syncResult.entitiesSynced,
            conflictsResolved: conflicts.count
        ))
        
        return syncResult
    }
    
    // MARK: - Private Methods
    
    private func attemptAutomaticResolution(conflict: DeviceConflict) async throws -> ConflictResolution? {
        switch conflict.conflictType {
        case .versionMismatch:
            return try await resolveVersionMismatch(conflict: conflict)
        case .deletionConflict:
            return try await resolveDeletionConflict(conflict: conflict)
        case .concurrentModification:
            return try await resolveConcurrentModification(conflict: conflict)
        case .dataDivergence:
            return try await resolveDataDivergence(conflict: conflict)
        case .relationshipConflict:
            return try await resolveRelationshipConflict(conflict: conflict)
        case .validationConflict:
            return try await resolveValidationConflict(conflict: conflict)
        }
    }
    
    private func resolveVersionMismatch(conflict: DeviceConflict) async throws -> ConflictResolution? {
        // Choose the version with the higher version number
        let chosenVersion = conflict.localVersion.version > conflict.remoteVersion.version 
            ? conflict.localVersion 
            : conflict.remoteVersion
        
        return ConflictResolution(
            resolvedAt: Date(),
            resolvedBy: "system",
            resolutionType: .autoResolve,
            chosenVersion: chosenVersion
        )
    }
    
    private func resolveDeletionConflict(conflict: DeviceConflict) async throws -> ConflictResolution? {
        // If one version was deleted, prefer the non-deleted version
        let localIsDeleted = conflict.localVersion.data["deleted"] == "true"
        let remoteIsDeleted = conflict.remoteVersion.data["deleted"] == "true"
        
        if localIsDeleted && !remoteIsDeleted {
            return ConflictResolution(
                resolvedAt: Date(),
                resolvedBy: "system",
                resolutionType: .useRemote,
                chosenVersion: conflict.remoteVersion
            )
        } else if !localIsDeleted && remoteIsDeleted {
            return ConflictResolution(
                resolvedAt: Date(),
                resolvedBy: "system",
                resolutionType: .useLocal,
                chosenVersion: conflict.localVersion
            )
        }
        
        // If both are deleted or both are not deleted, use the more recent version
        let chosenVersion = conflict.localVersion.timestamp > conflict.remoteVersion.timestamp 
            ? conflict.localVersion 
            : conflict.remoteVersion
        
        return ConflictResolution(
            resolvedAt: Date(),
            resolvedBy: "system",
            resolutionType: .autoResolve,
            chosenVersion: chosenVersion
        )
    }
    
    private func resolveConcurrentModification(conflict: DeviceConflict) async throws -> ConflictResolution? {
        // For concurrent modifications, prefer the version with more recent activity
        let chosenVersion = conflict.localVersion.timestamp > conflict.remoteVersion.timestamp 
            ? conflict.localVersion 
            : conflict.remoteVersion
        
        return ConflictResolution(
            resolvedAt: Date(),
            resolvedBy: "system",
            resolutionType: .autoResolve,
            chosenVersion: chosenVersion
        )
    }
    
    private func resolveDataDivergence(conflict: DeviceConflict) async throws -> ConflictResolution? {
        // For data divergence, attempt to merge the data
        let mergedData = mergeData(
            localData: conflict.localVersion.data,
            remoteData: conflict.remoteVersion.data
        )
        
        let mergedVersion = ConflictVersion(
            deviceId: "merged",
            timestamp: Date(),
            version: max(conflict.localVersion.version, conflict.remoteVersion.version) + 1,
            data: mergedData,
            checksum: calculateChecksum(data: mergedData)
        )
        
        return ConflictResolution(
            resolvedAt: Date(),
            resolvedBy: "system",
            resolutionType: .merge,
            chosenVersion: mergedVersion,
            mergeData: mergedData
        )
    }
    
    private func resolveRelationshipConflict(conflict: DeviceConflict) async throws -> ConflictResolution? {
        // For relationship conflicts, prefer the version with more complete data
        let localDataCount = conflict.localVersion.data.count
        let remoteDataCount = conflict.remoteVersion.data.count
        
        let chosenVersion = localDataCount >= remoteDataCount 
            ? conflict.localVersion 
            : conflict.remoteVersion
        
        return ConflictResolution(
            resolvedAt: Date(),
            resolvedBy: "system",
            resolutionType: .autoResolve,
            chosenVersion: chosenVersion
        )
    }
    
    private func resolveValidationConflict(conflict: DeviceConflict) async throws -> ConflictResolution? {
        // For validation conflicts, prefer the version that passes validation
        let localValid = validateData(conflict.localVersion.data)
        let remoteValid = validateData(conflict.remoteVersion.data)
        
        if localValid && !remoteValid {
            return ConflictResolution(
                resolvedAt: Date(),
                resolvedBy: "system",
                resolutionType: .useLocal,
                chosenVersion: conflict.localVersion
            )
        } else if !localValid && remoteValid {
            return ConflictResolution(
                resolvedAt: Date(),
                resolvedBy: "system",
                resolutionType: .useRemote,
                chosenVersion: conflict.remoteVersion
            )
        }
        
        // If both are valid or both are invalid, use the more recent version
        let chosenVersion = conflict.localVersion.timestamp > conflict.remoteVersion.timestamp 
            ? conflict.localVersion 
            : conflict.remoteVersion
        
        return ConflictResolution(
            resolvedAt: Date(),
            resolvedBy: "system",
            resolutionType: .autoResolve,
            chosenVersion: chosenVersion
        )
    }
    
    private func mergeData(localData: [String: String], remoteData: [String: String]) -> [String: String] {
        var merged = localData
        
        for (key, value) in remoteData {
            if let localValue = localData[key] {
                // If both have the same key, prefer the more recent value
                // For now, we'll use the remote value as it's likely more recent
                merged[key] = value
            } else {
                // If local doesn't have this key, add it
                merged[key] = value
            }
        }
        
        return merged
    }
    
    private func validateData(_ data: [String: String]) -> Bool {
        // Simple validation - check if required fields are present
        // In a real implementation, this would be more sophisticated
        let requiredFields = ["id", "userId", "timestamp"]
        return requiredFields.allSatisfy { data.keys.contains($0) }
    }
    
    private func calculateChecksum(data: [String: String]) -> String {
        // Simple checksum calculation
        // In a real implementation, use a proper hashing algorithm
        let sortedData = data.sorted { $0.key < $1.key }
        let dataString = sortedData.map { "\($0.key):\($0.value)" }.joined(separator: "|")
        return String(dataString.hashValue)
    }
    
    private func analyzeForConflicts(userData: [String: [ConflictVersion]], userId: String) async throws -> [DeviceConflict] {
        var conflicts: [DeviceConflict] = []
        
        for (entityId, versions) in userData {
            if versions.count > 1 {
                // Multiple versions of the same entity - potential conflict
                let sortedVersions = versions.sorted { $0.timestamp < $1.timestamp }
                
                for i in 0..<sortedVersions.count - 1 {
                    let localVersion = sortedVersions[i]
                    let remoteVersion = sortedVersions[i + 1]
                    
                    let conflictType = determineConflictType(local: localVersion, remote: remoteVersion)
                    
                    let conflict = DeviceConflict(
                        entityType: .goal, // This would need to be determined from the entity
                        entityId: entityId,
                        userId: userId,
                        conflictType: conflictType,
                        localVersion: localVersion,
                        remoteVersion: remoteVersion
                    )
                    
                    conflicts.append(conflict)
                }
            }
        }
        
        return conflicts
    }
    
    private func determineConflictType(local: ConflictVersion, remote: ConflictVersion) -> ConflictType {
        if local.version != remote.version {
            return .versionMismatch
        } else if local.timestamp == remote.timestamp {
            return .concurrentModification
        } else if local.data != remote.data {
            return .dataDivergence
        } else {
            return .validationConflict
        }
    }
    
    private func applyResolution(resolution: ConflictResolution) async throws {
        // Apply the chosen version to the data store
        // This would involve updating the local data with the resolved version
        try await realTimeRepository.applyConflictResolution(resolution: resolution)
    }
}

// MARK: - Supporting Structures
struct SyncResult: Codable, Equatable {
    let success: Bool
    let entitiesSynced: Int
    let conflictsResolved: Int
    let errors: [String]
    let timestamp: Date
    
    init(
        success: Bool,
        entitiesSynced: Int = 0,
        conflictsResolved: Int = 0,
        errors: [String] = [],
        timestamp: Date = Date()
    ) {
        self.success = success
        self.entitiesSynced = entitiesSynced
        self.conflictsResolved = conflictsResolved
        self.errors = errors
        self.timestamp = timestamp
    }
}

// MARK: - Repository Protocols
protocol ConflictRepository {
    func saveConflict(_ conflict: DeviceConflict) async throws
    func getActiveConflicts(userId: String) async throws -> [DeviceConflict]
    func getConflictHistory(userId: String, limit: Int) async throws -> [DeviceConflict]
    func updateConflictStatus(
        conflictId: String,
        status: ConflictStatus,
        resolution: ConflictResolution?
    ) async throws
}

protocol RealTimeRepository {
    func getUserDataFromAllDevices(userId: String) async throws -> [String: [ConflictVersion]]
    func syncUserData(userId: String, deviceId: String) async throws -> SyncResult
    func applyConflictResolution(resolution: ConflictResolution) async throws
}

// MARK: - Errors
enum ConflictError: LocalizedError {
    case manualResolutionRequired(conflict: DeviceConflict)
    case resolutionFailed(String)
    case invalidResolution(ConflictResolution)
    
    var errorDescription: String? {
        switch self {
        case .manualResolutionRequired(let conflict):
            return "Manual resolution required for conflict: \(conflict.conflictType.displayName)"
        case .resolutionFailed(let reason):
            return "Conflict resolution failed: \(reason)"
        case .invalidResolution(let resolution):
            return "Invalid resolution: \(resolution.resolutionType.displayName)"
        }
    }
}

// MARK: - Analytics Events
extension AnalyticsEvent {
    static func conflictResolutionStarted(
        userId: String,
        conflictType: ConflictType,
        entityType: RealTimeEntityType
    ) -> AnalyticsEvent {
        AnalyticsEvent(
            name: "conflict_resolution_started",
            properties: [
                "user_id": userId,
                "conflict_type": conflictType.rawValue,
                "entity_type": entityType.rawValue,
                "timestamp": Date().timeIntervalSince1970
            ]
        )
    }
    
    static func conflictAutoResolved(
        userId: String,
        conflictId: String,
        resolutionType: ResolutionType
    ) -> AnalyticsEvent {
        AnalyticsEvent(
            name: "conflict_auto_resolved",
            properties: [
                "user_id": userId,
                "conflict_id": conflictId,
                "resolution_type": resolutionType.rawValue,
                "timestamp": Date().timeIntervalSince1970
            ]
        )
    }
    
    static func conflictManualResolutionRequired(
        userId: String,
        conflictId: String,
        conflictType: ConflictType
    ) -> AnalyticsEvent {
        AnalyticsEvent(
            name: "conflict_manual_resolution_required",
            properties: [
                "user_id": userId,
                "conflict_id": conflictId,
                "conflict_type": conflictType.rawValue,
                "timestamp": Date().timeIntervalSince1970
            ]
        )
    }
    
    static func conflictManuallyResolved(
        userId: String,
        conflictId: String,
        resolutionType: ResolutionType
    ) -> AnalyticsEvent {
        AnalyticsEvent(
            name: "conflict_manually_resolved",
            properties: [
                "user_id": userId,
                "conflict_id": conflictId,
                "resolution_type": resolutionType.rawValue,
                "timestamp": Date().timeIntervalSince1970
            ]
        )
    }
    
    static func conflictIgnored(
        userId: String,
        conflictId: String,
        reason: String?
    ) -> AnalyticsEvent {
        var properties: [String: Any] = [
            "user_id": userId,
            "conflict_id": conflictId,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if let reason = reason {
            properties["reason"] = reason
        }
        
        return AnalyticsEvent(
            name: "conflict_ignored",
            properties: properties
        )
    }
    
    static func conflictsDetected(
        userId: String,
        count: Int,
        types: [String]
    ) -> AnalyticsEvent {
        AnalyticsEvent(
            name: "conflicts_detected",
            properties: [
                "user_id": userId,
                "count": count,
                "types": types,
                "timestamp": Date().timeIntervalSince1970
            ]
        )
    }
    
    static func syncRequested(userId: String, deviceId: String) -> AnalyticsEvent {
        AnalyticsEvent(
            name: "sync_requested",
            properties: [
                "user_id": userId,
                "device_id": deviceId,
                "timestamp": Date().timeIntervalSince1970
            ]
        )
    }
    
    static func syncCompleted(
        userId: String,
        deviceId: String,
        entitiesSynced: Int,
        conflictsResolved: Int
    ) -> AnalyticsEvent {
        AnalyticsEvent(
            name: "sync_completed",
            properties: [
                "user_id": userId,
                "device_id": deviceId,
                "entities_synced": entitiesSynced,
                "conflicts_resolved": conflictsResolved,
                "timestamp": Date().timeIntervalSince1970
            ]
        )
    }
}
