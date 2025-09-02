import Foundation
import Combine

// MARK: - Conflict Repository Protocol
protocol ConflictRepository {
    // MARK: - CRUD Operations
    func createConflict(_ conflict: DeviceConflict) async throws -> DeviceConflict
    func getConflict(id: String) async throws -> DeviceConflict?
    func updateConflict(_ conflict: DeviceConflict) async throws -> DeviceConflict
    func deleteConflict(id: String) async throws -> Bool
    
    // MARK: - Query Operations
    func getConflicts(forUserId: String) async throws -> [DeviceConflict]
    func getConflicts(byType: ConflictType) async throws -> [DeviceConflict]
    func getConflicts(byStatus: ConflictStatus) async throws -> [DeviceConflict]
    func getConflicts(byDateRange: DateInterval) async throws -> [DeviceConflict]
    func getActiveConflicts(forUserId: String) async throws -> [DeviceConflict]
    func getResolvedConflicts(forUserId: String) async throws -> [DeviceConflict]
    
    // MARK: - Conflict Resolution Operations
    func resolveConflict(id: String, resolution: ConflictResolution) async throws -> DeviceConflict
    func autoResolveConflict(id: String) async throws -> DeviceConflict
    func ignoreConflict(id: String) async throws -> DeviceConflict
    func escalateConflict(id: String, reason: String) async throws -> DeviceConflict
    
    // MARK: - Conflict Detection Operations
    func detectConflicts(forUserId: String) async throws -> [DeviceConflict]
    func checkForConflicts(entityId: String, entityType: String, userId: String) async throws -> [DeviceConflict]
    func getConflictsForEntity(entityId: String, entityType: String) async throws -> [DeviceConflict]
    
    // MARK: - Analytics Operations
    func getConflictStatistics(forUserId: String) async throws -> ConflictStatistics
    func getConflictPerformance(forUserId: String, timeRange: TimeRange) async throws -> ConflictPerformance
    func getConflictResolutionMetrics(forUserId: String) async throws -> ConflictResolutionMetrics
    
    // MARK: - Bulk Operations
    func bulkUpdateConflicts(_ conflicts: [DeviceConflict]) async throws -> [DeviceConflict]
    func deleteResolvedConflicts(olderThan date: Date) async throws -> Int
    func deleteIgnoredConflicts(olderThan date: Date) async throws -> Int
}

// MARK: - Supporting Models
struct ConflictStatistics {
    let totalConflicts: Int
    let activeConflicts: Int
    let resolvedConflicts: Int
    let ignoredConflicts: Int
    let conflictsByType: [ConflictTypeStats]
    let conflictsByStatus: [ConflictStatusStats]
    let averageResolutionTime: TimeInterval
}

struct ConflictTypeStats {
    let type: ConflictType
    let count: Int
    let resolvedCount: Int
    let ignoredCount: Int
    let averageResolutionTime: TimeInterval
}

struct ConflictStatusStats {
    let status: ConflictStatus
    let count: Int
    let averageAge: TimeInterval
    let resolutionRate: Double
}

struct ConflictPerformance {
    let detectionRate: Double
    let resolutionRate: Double
    let autoResolutionRate: Double
    let averageResolutionTime: TimeInterval
    let userSatisfactionScore: Double
}

struct ConflictResolutionMetrics {
    let overallResolutionRate: Double
    let resolutionRateByType: [ConflictType: Double]
    let resolutionRateByStatus: [ConflictStatus: Double]
    let autoResolutionSuccessRate: Double
    let manualResolutionSuccessRate: Double
    let userFeedback: [ConflictFeedback]
}

struct ConflictFeedback {
    let conflictId: String
    let userId: String
    let resolutionSatisfaction: Int // 1-5 scale
    let feedback: String?
    let timestamp: Date
    let wasAutoResolved: Bool
}

// MARK: - Conflict Repository Extensions
extension ConflictRepository {
    // MARK: - Convenience Methods
    func getRecentConflicts(forUserId: String, limit: Int = 10) async throws -> [DeviceConflict] {
        let conflicts = try await getConflicts(forUserId: userId)
        return Array(conflicts.prefix(limit))
    }
    
    func getConflictsByEntityType(forUserId: String, entityType: String) async throws -> [DeviceConflict] {
        let conflicts = try await getConflicts(forUserId: userId)
        return conflicts.filter { $0.entityType == entityType }
    }
    
    func getConflictsByPriority(forUserId: String, priority: ConflictPriority) async throws -> [DeviceConflict] {
        let conflicts = try await getConflicts(forUserId: userId)
        return conflicts.filter { $0.priority == priority }
    }
    
    func getConflictsByDate(forUserId: String, date: Date) async throws -> [DeviceConflict] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
        
        let dateInterval = DateInterval(start: startOfDay, end: endOfDay)
        return try await getConflicts(byDateRange: dateInterval).filter { $0.userId == userId }
    }
    
    func getConflictsByWeek(forUserId: String, weekOfYear: Int, year: Int) async throws -> [DeviceConflict] {
        let calendar = Calendar.current
        let dateComponents = DateComponents(weekOfYear: weekOfYear, yearForWeekOfYear: year)
        guard let startOfWeek = calendar.date(from: dateComponents),
              let endOfWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: startOfWeek) else {
            return []
        }
        
        let dateInterval = DateInterval(start: startOfWeek, end: endOfWeek)
        return try await getConflicts(byDateRange: dateInterval).filter { $0.userId == userId }
    }
    
    func getConflictsByMonth(forUserId: String, month: Int, year: Int) async throws -> [DeviceConflict] {
        let calendar = Calendar.current
        let dateComponents = DateComponents(month: month, year: year)
        guard let startOfMonth = calendar.date(from: dateComponents),
              let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) else {
            return []
        }
        
        let dateInterval = DateInterval(start: startOfMonth, end: endOfMonth)
        return try await getConflicts(byDateRange: dateInterval).filter { $0.userId == userId }
    }
    
    func getConflictCount(forUserId: String) async throws -> Int {
        let conflicts = try await getConflicts(forUserId: userId)
        return conflicts.count
    }
    
    func getActiveConflictCount(forUserId: String) async throws -> Int {
        let activeConflicts = try await getActiveConflicts(forUserId: userId)
        return activeConflicts.count
    }
    
    func getResolvedConflictCount(forUserId: String) async throws -> Int {
        let resolvedConflicts = try await getResolvedConflicts(forUserId: userId)
        return resolvedConflicts.count
    }
    
    func hasActiveConflicts(forUserId: String) async throws -> Bool {
        let activeCount = try await getActiveConflictCount(forUserId: userId)
        return activeCount > 0
    }
    
    func getConflictsByTypeAndStatus(forUserId: String, type: ConflictType, status: ConflictStatus) async throws -> [DeviceConflict] {
        let conflicts = try await getConflicts(forUserId: userId)
        return conflicts.filter { $0.conflictType == type && $0.status == status }
    }
    
    func getConflictsByDateRangeAndType(forUserId: String, dateRange: DateInterval, type: ConflictType) async throws -> [DeviceConflict] {
        let conflicts = try await getConflicts(byDateRange: dateRange)
        return conflicts.filter { $0.userId == userId && $0.conflictType == type }
    }
    
    func getHighPriorityConflicts(forUserId: String) async throws -> [DeviceConflict] {
        let conflicts = try await getConflicts(forUserId: userId)
        return conflicts.filter { $0.priority == .high && $0.status == .active }
    }
    
    func getConflictsRequiringAttention(forUserId: String) async throws -> [DeviceConflict] {
        let activeConflicts = try await getActiveConflicts(forUserId: userId)
        return activeConflicts.filter { $0.priority == .high || $0.priority == .medium }
    }
    
    func getConflictsByResolutionType(forUserId: String, resolutionType: ResolutionType) async throws -> [DeviceConflict] {
        let conflicts = try await getConflicts(forUserId: userId)
        return conflicts.filter { $0.resolution?.type == resolutionType }
    }
    
    func getConflictsByAge(forUserId: String, olderThan days: Int) async throws -> [DeviceConflict] {
        let conflicts = try await getConflicts(forUserId: userId)
        let cutoffDate = Date().addingTimeInterval(TimeInterval(-days * 24 * 60 * 60))
        
        return conflicts.filter { $0.createdAt < cutoffDate }
    }
    
    func getConflictsByDevice(forUserId: String, deviceId: String) async throws -> [DeviceConflict] {
        let conflicts = try await getConflicts(forUserId: userId)
        // This would need to be implemented with actual device tracking
        // For now, return all conflicts
        return conflicts
    }
}

// MARK: - Conflict Repository Error
enum ConflictRepositoryError: LocalizedError {
    case conflictNotFound
    case invalidConflictData
    case conflictAlreadyExists
    case invalidResolution
    case autoResolutionFailed
    case insufficientPermissions
    case databaseError(Error)
    case networkError(Error)
    case permissionDenied
    case quotaExceeded
    
    var errorDescription: String? {
        switch self {
        case .conflictNotFound:
            return "Conflict not found"
        case .invalidConflictData:
            return "Invalid conflict data"
        case .conflictAlreadyExists:
            return "Conflict already exists"
        case .invalidResolution:
            return "Invalid conflict resolution"
        case .autoResolutionFailed:
            return "Auto-resolution failed"
        case .insufficientPermissions:
            return "Insufficient permissions for this operation"
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
