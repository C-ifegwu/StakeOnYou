import Foundation

// MARK: - Real Time Event
struct RealTimeEvent: Identifiable, Codable, Equatable {
    let id: String
    let type: RealTimeEventType
    let entityType: RealTimeEntityType
    let entityId: String
    let userId: String
    let timestamp: Date
    let data: [String: String]
    let deviceId: String
    let sessionId: String
    let priority: RealTimeEventPriority
    
    init(
        id: String = UUID().uuidString,
        type: RealTimeEventType,
        entityType: RealTimeEntityType,
        entityId: String,
        userId: String,
        timestamp: Date = Date(),
        data: [String: String] = [:],
        deviceId: String,
        sessionId: String,
        priority: RealTimeEventPriority = .normal
    ) {
        self.id = id
        self.type = type
        self.entityType = entityType
        self.entityId = entityId
        self.userId = userId
        self.timestamp = timestamp
        self.data = data
        self.deviceId = deviceId
        self.sessionId = sessionId
        self.priority = priority
    }
}

enum RealTimeEventType: String, Codable, CaseIterable {
    case created = "created"
    case updated = "updated"
    case deleted = "deleted"
    case statusChanged = "status_changed"
    case progressUpdated = "progress_updated"
    case milestoneReached = "milestone_reached"
    case stakeAccrued = "stake_accrued"
    case verificationSubmitted = "verification_submitted"
    case verificationApproved = "verification_approved"
    case verificationRejected = "verification_rejected"
    case groupMemberJoined = "group_member_joined"
    case groupMemberLeft = "group_member_left"
    case corporateUpdate = "corporate_update"
    case notificationSent = "notification_sent"
    case conflictDetected = "conflict_detected"
    case syncRequested = "sync_requested"
    case syncCompleted = "sync_completed"
    case syncFailed = "sync_failed"
    
    var displayName: String {
        switch self {
        case .created: return "Created"
        case .updated: return "Updated"
        case .deleted: return "Deleted"
        case .statusChanged: return "Status Changed"
        case .progressUpdated: return "Progress Updated"
        case .milestoneReached: return "Milestone Reached"
        case .stakeAccrued: return "Stake Accrued"
        case .verificationSubmitted: return "Verification Submitted"
        case .verificationApproved: return "Verification Approved"
        case .verificationRejected: return "Verification Rejected"
        case .groupMemberJoined: return "Group Member Joined"
        case .groupMemberLeft: return "Group Member Left"
        case .corporateUpdate: return "Corporate Update"
        case .notificationSent: return "Notification Sent"
        case .conflictDetected: return "Conflict Detected"
        case .syncRequested: return "Sync Requested"
        case .syncCompleted: return "Sync Completed"
        case .syncFailed: return "Sync Failed"
        }
    }
    
    var iconName: String {
        switch self {
        case .created: return "plus.circle"
        case .updated: return "pencil.circle"
        case .deleted: return "minus.circle"
        case .statusChanged: return "arrow.triangle.2.circlepath"
        case .progressUpdated: return "chart.line.uptrend.xyaxis"
        case .milestoneReached: return "flag"
        case .stakeAccrued: return "dollarsign.circle"
        case .verificationSubmitted: return "checkmark.shield"
        case .verificationApproved: return "checkmark.shield.fill"
        case .verificationRejected: return "xmark.shield"
        case .groupMemberJoined: return "person.badge.plus"
        case .groupMemberLeft: return "person.badge.minus"
        case .corporateUpdate: return "building.2"
        case .notificationSent: return "bell"
        case .conflictDetected: return "exclamationmark.triangle"
        case .syncRequested: return "arrow.clockwise"
        case .syncCompleted: return "checkmark.circle"
        case .syncFailed: return "xmark.circle"
        }
    }
}

enum RealTimeEntityType: String, Codable, CaseIterable {
    case goal = "goal"
    case stake = "stake"
    case user = "user"
    case group = "group"
    case corporateAccount = "corporate_account"
    case charity = "charity"
    case transaction = "transaction"
    case milestone = "milestone"
    case verification = "verification"
    case notification = "notification"
    case activity = "activity"
    
    var displayName: String {
        switch self {
        case .goal: return "Goal"
        case .stake: return "Stake"
        case .user: return "User"
        case .group: return "Group"
        case .corporateAccount: return "Corporate Account"
        case .charity: return "Charity"
        case .transaction: return "Transaction"
        case .milestone: return "Milestone"
        case .verification: return "Verification"
        case .notification: return "Notification"
        case .activity: return "Activity"
        }
    }
}

enum RealTimeEventPriority: String, Codable, CaseIterable {
    case low = "low"
    case normal = "normal"
    case high = "high"
    case critical = "critical"
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .normal: return "Normal"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }
    
    var color: String {
        switch self {
        case .low: return "green"
        case .normal: return "blue"
        case .high: return "orange"
        case .critical: return "red"
        }
    }
}

// MARK: - Device Conflict
struct DeviceConflict: Identifiable, Codable, Equatable {
    let id: String
    let entityType: RealTimeEntityType
    let entityId: String
    let userId: String
    let conflictType: ConflictType
    let localVersion: ConflictVersion
    let remoteVersion: ConflictVersion
    let detectedAt: Date
    let status: ConflictStatus
    let resolution: ConflictResolution?
    let metadata: [String: String]
    
    init(
        id: String = UUID().uuidString,
        entityType: RealTimeEntityType,
        entityId: String,
        userId: String,
        conflictType: ConflictType,
        localVersion: ConflictVersion,
        remoteVersion: ConflictVersion,
        detectedAt: Date = Date(),
        status: ConflictStatus = .detected,
        resolution: ConflictResolution? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.entityType = entityType
        self.entityId = entityId
        self.userId = userId
        self.conflictType = conflictType
        self.localVersion = localVersion
        self.remoteVersion = remoteVersion
        self.detectedAt = detectedAt
        self.status = status
        self.resolution = resolution
        self.metadata = metadata
    }
}

enum ConflictType: String, Codable, CaseIterable {
    case dataDivergence = "data_divergence"
    case concurrentModification = "concurrent_modification"
    case versionMismatch = "version_mismatch"
    case deletionConflict = "deletion_conflict"
    case relationshipConflict = "relationship_conflict"
    case validationConflict = "validation_conflict"
    
    var displayName: String {
        switch self {
        case .dataDivergence: return "Data Divergence"
        case .concurrentModification: return "Concurrent Modification"
        case .versionMismatch: return "Version Mismatch"
        case .deletionConflict: return "Deletion Conflict"
        case .relationshipConflict: return "Relationship Conflict"
        case .validationConflict: return "Validation Conflict"
        }
    }
    
    var description: String {
        switch self {
        case .dataDivergence: return "Data has diverged between devices"
        case .concurrentModification: return "Same data was modified on multiple devices"
        case .versionMismatch: return "Version numbers don't match expected sequence"
        case .deletionConflict: return "Data was deleted on one device but modified on another"
        case .relationshipConflict: return "Related data has conflicting relationships"
        case .validationConflict: return "Data validation rules conflict between versions"
        }
    }
    
    var iconName: String {
        switch self {
        case .dataDivergence: return "arrow.triangle.branch"
        case .concurrentModification: return "clock.arrow.circlepath"
        case .versionMismatch: return "number.circle"
        case .deletionConflict: return "minus.circle.badge.questionmark"
        case .relationshipConflict: return "link.badge.plus"
        case .validationConflict: return "exclamationmark.triangle"
        }
    }
}

struct ConflictVersion: Codable, Equatable {
    let deviceId: String
    let timestamp: Date
    let version: Int
    let data: [String: String]
    let checksum: String
    
    init(
        deviceId: String,
        timestamp: Date,
        version: Int,
        data: [String: String],
        checksum: String
    ) {
        self.deviceId = deviceId
        self.timestamp = timestamp
        self.version = version
        self.data = data
        self.checksum = checksum
    }
}

enum ConflictStatus: String, Codable, CaseIterable {
    case detected = "detected"
    case resolving = "resolving"
    case resolved = "resolved"
    case failed = "failed"
    case ignored = "ignored"
    
    var displayName: String {
        switch self {
        case .detected: return "Detected"
        case .resolving: return "Resolving"
        case .resolved: return "Resolved"
        case .failed: return "Failed"
        case .ignored: return "Ignored"
        }
    }
    
    var color: String {
        switch self {
        case .detected: return "orange"
        case .resolving: return "blue"
        case .resolved: return "green"
        case .failed: return "red"
        case .ignored: return "gray"
        }
    }
}

struct ConflictResolution: Codable, Equatable {
    let resolvedAt: Date
    let resolvedBy: String
    let resolutionType: ResolutionType
    let chosenVersion: ConflictVersion
    let mergeData: [String: String]?
    let notes: String?
    
    init(
        resolvedAt: Date,
        resolvedBy: String,
        resolutionType: ResolutionType,
        chosenVersion: ConflictVersion,
        mergeData: [String: String]? = nil,
        notes: String? = nil
    ) {
        self.resolvedAt = resolvedAt
        self.resolvedBy = resolvedBy
        self.resolutionType = resolutionType
        self.chosenVersion = chosenVersion
        self.mergeData = mergeData
        self.notes = notes
    }
}

enum ResolutionType: String, Codable, CaseIterable {
    case useLocal = "use_local"
    case useRemote = "use_remote"
    case merge = "merge"
    case manual = "manual"
    case autoResolve = "auto_resolve"
    
    var displayName: String {
        switch self {
        case .useLocal: return "Use Local"
        case .useRemote: return "Use Remote"
        case .merge: return "Merge"
        case .manual: return "Manual"
        case .autoResolve: return "Auto Resolve"
        }
    }
    
    var description: String {
        switch self {
        case .useLocal: return "Keep local version"
        case .useRemote: return "Accept remote version"
        case .merge: return "Combine both versions"
        case .manual: return "Manual resolution required"
        case .autoResolve: return "Automatically resolved"
        }
    }
}

// MARK: - Sync Status
struct SyncStatus: Codable, Equatable {
    let isConnected: Bool
    let lastSyncAt: Date?
    let nextSyncAt: Date?
    let syncProgress: Double
    let pendingEvents: Int
    let failedEvents: Int
    let connectionType: ConnectionType
    let deviceId: String
    let sessionId: String
    
    init(
        isConnected: Bool = false,
        lastSyncAt: Date? = nil,
        nextSyncAt: Date? = nil,
        syncProgress: Double = 0.0,
        pendingEvents: Int = 0,
        failedEvents: Int = 0,
        connectionType: ConnectionType = .disconnected,
        deviceId: String,
        sessionId: String
    ) {
        self.isConnected = isConnected
        self.lastSyncAt = lastSyncAt
        self.nextSyncAt = nextSyncAt
        self.syncProgress = syncProgress
        self.pendingEvents = pendingEvents
        self.failedEvents = failedEvents
        self.connectionType = connectionType
        self.deviceId = deviceId
        self.sessionId = sessionId
    }
}

enum ConnectionType: String, Codable, CaseIterable {
    case disconnected = "disconnected"
    case websocket = "websocket"
    case polling = "polling"
    case push = "push"
    case manual = "manual"
    
    var displayName: String {
        switch self {
        case .disconnected: return "Disconnected"
        case .websocket: return "WebSocket"
        case .polling: return "Polling"
        case .push: return "Push"
        case .manual: return "Manual"
        }
    }
    
    var iconName: String {
        switch self {
        case .disconnected: return "wifi.slash"
        case .websocket: return "wifi"
        case .polling: return "arrow.clockwise"
        case .push: return "bell"
        case .manual: return "hand.tap"
        }
    }
}

// MARK: - Sync Request
struct SyncRequest: Codable, Equatable {
    let id: String
    let userId: String
    let deviceId: String
    let sessionId: String
    let requestType: SyncRequestType
    let entityType: RealTimeEntityType?
    let entityId: String?
    let timestamp: Date
    let priority: RealTimeEventPriority
    
    init(
        id: String = UUID().uuidString,
        userId: String,
        deviceId: String,
        sessionId: String,
        requestType: SyncRequestType,
        entityType: RealTimeEntityType? = nil,
        entityId: String? = nil,
        timestamp: Date = Date(),
        priority: RealTimeEventPriority = .normal
    ) {
        self.id = id
        self.userId = userId
        self.deviceId = deviceId
        self.sessionId = sessionId
        self.requestType = requestType
        self.entityType = entityType
        self.entityId = entityId
        self.timestamp = timestamp
        self.priority = priority
    }
}

enum SyncRequestType: String, Codable, CaseIterable {
    case fullSync = "full_sync"
    case incrementalSync = "incremental_sync"
    case entitySync = "entity_sync"
    case conflictResolution = "conflict_resolution"
    case statusUpdate = "status_update"
    case heartbeat = "heartbeat"
    
    var displayName: String {
        switch self {
        case .fullSync: return "Full Sync"
        case .incrementalSync: return "Incremental Sync"
        case .entitySync: return "Entity Sync"
        case .conflictResolution: return "Conflict Resolution"
        case .statusUpdate: return "Status Update"
        case .heartbeat: return "Heartbeat"
        }
    }
}
