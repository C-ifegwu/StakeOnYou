import Foundation
import Combine

// MARK: - Group Repository Protocol
protocol GroupRepository {
    // MARK: - CRUD Operations
    func createGroup(_ group: Group) async throws -> Group
    func getGroup(id: String) async throws -> Group?
    func updateGroup(_ group: Group) async throws -> Group
    func deleteGroup(id: String) async throws -> Bool
    
    // MARK: - Query Operations
    func getGroupsForUser(userId: String) async throws -> [Group]
    func getGroups(byCategory: String) async throws -> [Group]
    func getGroups(byDateRange: DateInterval) async throws -> [Group]
    func getPublicGroups() async throws -> [Group]
    func getPrivateGroups(forUserId: String) async throws -> [Group]
    
    // MARK: - Member Operations
    func addMemberToGroup(groupId: String, userId: String) async throws -> Group
    func removeMemberFromGroup(groupId: String, userId: String) async throws -> Group
    func getGroupMembers(groupId: String) async throws -> [User]
    func isUserMemberOfGroup(userId: String, groupId: String) async throws -> Bool
    func isUserOwnerOfGroup(userId: String, groupId: String) async throws -> Bool
    
    // MARK: - Group Management
    func updateGroupRules(groupId: String, rules: GroupRules) async throws -> Group
    func updateGroupSettings(groupId: String, settings: GroupSettings) async throws -> Group
    func transferGroupOwnership(groupId: String, newOwnerId: String) async throws -> Group
    
    // MARK: - Analytics Operations
    func getGroupStatistics(groupId: String) async throws -> GroupStatistics
    func getGroupPerformance(groupId: String, timeRange: TimeRange) async throws -> GroupPerformance
    func getTopGroups(limit: Int) async throws -> [GroupWithStats]
    
    // MARK: - Bulk Operations
    func bulkUpdateGroups(_ groups: [Group]) async throws -> [Group]
    func deleteEmptyGroups() async throws -> Int
}

// MARK: - Supporting Models
struct GroupSettings {
    let allowMemberInvites: Bool
    let requireApprovalForJoining: Bool
    let maxMembers: Int
    let isPrivate: Bool
    let allowPublicGoals: Bool
    let notificationPreferences: GroupNotificationPreferences
}

struct GroupNotificationPreferences {
    let goalUpdates: Bool
    let memberActivity: Bool
    let milestoneCompletions: Bool
    let weeklySummaries: Bool
}

struct GroupStatistics {
    let totalMembers: Int
    let activeMembers: Int
    let totalGoals: Int
    let completedGoals: Int
    let totalStakeAmount: Decimal
    let averageGoalCompletionRate: Double
    let memberActivityScore: Double
}

struct GroupPerformance {
    let totalReturn: Decimal
    let returnRate: Decimal
    let memberRetentionRate: Double
    let goalSuccessRate: Double
    let averageGoalDuration: TimeInterval
}

struct GroupWithStats {
    let group: Group
    let statistics: GroupStatistics
    let recentActivity: [GroupActivityItem]
}

struct GroupActivityItem {
    let type: GroupActivityType
    let userId: String
    let userName: String
    let timestamp: Date
    let details: String
}

enum GroupActivityType: String, CaseIterable {
    case memberJoined = "member_joined"
    case memberLeft = "member_left"
    case goalCreated = "goal_created"
    case goalCompleted = "goal_completed"
    case milestoneReached = "milestone_reached"
    case stakePlaced = "stake_placed"
    case stakeWon = "stake_won"
    case stakeLost = "stake_lost"
    
    var displayName: String {
        switch self {
        case .memberJoined: return "Member Joined"
        case .memberLeft: return "Member Left"
        case .goalCreated: return "Goal Created"
        case .goalCompleted: return "Goal Completed"
        case .milestoneReached: return "Milestone Reached"
        case .stakePlaced: return "Stake Placed"
        case .stakeWon: return "Stake Won"
        case .stakeLost: return "Stake Lost"
        }
    }
}

// MARK: - Group Repository Extensions
extension GroupRepository {
    // MARK: - Convenience Methods
    func getActiveGroups(forUserId: String) async throws -> [Group] {
        let groups = try await getGroupsForUser(userId: userId)
        return groups.filter { group in
            // Consider a group active if it has recent activity or active goals
            // This is a simplified check - in practice, you'd want more sophisticated logic
            return true
        }
    }
    
    func getGroupsByMemberCount(minMembers: Int, maxMembers: Int? = nil) async throws -> [Group] {
        let groups = try await getPublicGroups()
        return groups.filter { group in
            let memberCount = group.memberIds.count
            if let max = maxMembers {
                return memberCount >= minMembers && memberCount <= max
            } else {
                return memberCount >= minMembers
            }
        }
    }
    
    func getGroupsByActivityLevel(activeWithinDays days: Int) async throws -> [Group] {
        let groups = try await getPublicGroups()
        let cutoffDate = Date().addingTimeInterval(TimeInterval(-days * 24 * 60 * 60))
        
        // This would need to be implemented with actual activity tracking
        // For now, return all groups
        return groups
    }
    
    func getGroupsWithHighStakes(threshold: Decimal) async throws -> [Group] {
        let groups = try await getPublicGroups()
        // This would need to be implemented with actual stake data
        // For now, return all groups
        return groups
    }
    
    func getGroupsByCategory(category: String) async throws -> [Group] {
        return try await getGroups(byCategory: category)
    }
    
    func getGroupsByTags(tags: [String]) async throws -> [Group] {
        let groups = try await getPublicGroups()
        return groups.filter { group in
            let groupTags = group.tags ?? []
            return !Set(groupTags).isDisjoint(with: Set(tags))
        }
    }
}

// MARK: - Group Repository Error
enum GroupRepositoryError: LocalizedError {
    case groupNotFound
    case invalidGroupData
    case userNotMember
    case userAlreadyMember
    case insufficientPermissions
    case groupFull
    case invalidGroupRules
    case databaseError(Error)
    case networkError(Error)
    case permissionDenied
    case quotaExceeded
    
    var errorDescription: String? {
        switch self {
        case .groupNotFound:
            return "Group not found"
        case .invalidGroupData:
            return "Invalid group data"
        case .userNotMember:
            return "User is not a member of this group"
        case .userAlreadyMember:
            return "User is already a member of this group"
        case .insufficientPermissions:
            return "Insufficient permissions for this operation"
        case .groupFull:
            return "Group has reached maximum member limit"
        case .invalidGroupRules:
            return "Invalid group rules"
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
