import Foundation
import Combine

// MARK: - Mock Group Repository Implementation
class MockGroupRepository: GroupRepository {
    // MARK: - Properties
    private var groups: [String: Group] = [:]
    private let logger: Logger
    
    // MARK: - Initialization
    init(logger: Logger = ConsoleLogger()) {
        self.logger = logger
        setupMockData()
    }
    
    // MARK: - CRUD Operations
    func createGroup(_ group: Group) async throws -> Group {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 800_000_000)
        
        var newGroup = group
        if newGroup.id.isEmpty {
            newGroup = Group(
                id: UUID().uuidString,
                name: group.name,
                description: group.description,
                createdBy: group.createdBy,
                members: group.members,
                inviteCode: generateInviteCode(),
                isPrivate: group.isPrivate,
                maxMembers: group.maxMembers,
                createdAt: Date(),
                updatedAt: Date()
            )
        }
        
        groups[newGroup.id] = newGroup
        logger.info("Mock: Created group with ID: \(newGroup.id)")
        return newGroup
    }
    
    func getGroup(id: String) async throws -> Group? {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let group = groups[id]
        logger.info("Mock: Retrieved group with ID: \(id), found: \(group != nil)")
        return group
    }
    
    func updateGroup(_ group: Group) async throws -> Group {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        guard groups[group.id] != nil else {
            throw GroupRepositoryError.groupNotFound
        }
        
        var updatedGroup = group
        updatedGroup.updatedAt = Date()
        groups[group.id] = updatedGroup
        
        logger.info("Mock: Updated group with ID: \(group.id)")
        return updatedGroup
    }
    
    func deleteGroup(id: String) async throws -> Bool {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 600_000_000)
        
        guard groups[id] != nil else {
            throw GroupRepositoryError.groupNotFound
        }
        
        groups.removeValue(forKey: id)
        logger.info("Mock: Deleted group with ID: \(id)")
        return true
    }
    
    // MARK: - Query Operations
    func getGroups(forUserId: String) async throws -> [Group] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        let userGroups = groups.values.filter { group in
            group.members.contains { $0.userId == forUserId } || group.createdBy == forUserId
        }
        
        logger.info("Mock: Retrieved \(userGroups.count) groups for user: \(forUserId)")
        return userGroups
    }
    
    func getGroups(byName: String) async throws -> [Group] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let nameGroups = groups.values.filter { $0.name.localizedCaseInsensitiveContains(byName) }
        logger.info("Mock: Retrieved \(nameGroups.count) groups with name containing: \(byName)")
        return nameGroups
    }
    
    func getPublicGroups() async throws -> [Group] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let publicGroups = groups.values.filter { !$0.isPrivate }
        logger.info("Mock: Retrieved \(publicGroups.count) public groups")
        return publicGroups
    }
    
    func getGroups(byMemberCount: Int, comparison: ComparisonType) async throws -> [Group] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let filteredGroups = groups.values.filter { group in
            switch comparison {
            case .greaterThan:
                return group.members.count > byMemberCount
            case .greaterThanOrEqual:
                return group.members.count >= byMemberCount
            case .lessThan:
                return group.members.count < byMemberCount
            case .lessThanOrEqual:
                return group.members.count <= byMemberCount
            case .equal:
                return group.members.count == byMemberCount
            }
        }
        
        logger.info("Mock: Retrieved \(filteredGroups.count) groups with member count \(comparison.rawValue) \(byMemberCount)")
        return filteredGroups
    }
    
    // MARK: - Member Management
    func addMember(toGroupId: String, member: GroupMember) async throws -> Group {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 600_000_000)
        
        guard var group = groups[toGroupId] else {
            throw GroupRepositoryError.groupNotFound
        }
        
        // Check if member already exists
        if group.members.contains(where: { $0.userId == member.userId }) {
            throw GroupRepositoryError.memberAlreadyExists
        }
        
        // Check if group is full
        if group.members.count >= group.maxMembers {
            throw GroupRepositoryError.groupFull
        }
        
        group.members.append(member)
        group.updatedAt = Date()
        groups[toGroupId] = group
        
        logger.info("Mock: Added member \(member.userId) to group: \(toGroupId)")
        return group
    }
    
    func removeMember(fromGroupId: String, memberId: String) async throws -> Group {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        guard var group = groups[fromGroupId] else {
            throw GroupRepositoryError.groupNotFound
        }
        
        guard let memberIndex = group.members.firstIndex(where: { $0.userId == memberId }) else {
            throw GroupRepositoryError.memberNotFound
        }
        
        // Prevent removing the creator
        if group.createdBy == memberId {
            throw GroupRepositoryError.cannotRemoveCreator
        }
        
        group.members.remove(at: memberIndex)
        group.updatedAt = Date()
        groups[fromGroupId] = group
        
        logger.info("Mock: Removed member \(memberId) from group: \(fromGroupId)")
        return group
    }
    
    func updateMemberRole(inGroupId: String, memberId: String, newRole: GroupMemberRole) async throws -> Group {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        guard var group = groups[inGroupId] else {
            throw GroupRepositoryError.groupNotFound
        }
        
        guard let memberIndex = group.members.firstIndex(where: { $0.userId == memberId }) else {
            throw GroupRepositoryError.memberNotFound
        }
        
        group.members[memberIndex].role = newRole
        group.updatedAt = Date()
        groups[inGroupId] = group
        
        logger.info("Mock: Updated member \(memberId) role to \(newRole) in group: \(inGroupId)")
        return group
    }
    
    func getGroupMembers(forGroupId: String) async throws -> [GroupMember] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        guard let group = groups[forGroupId] else {
            throw GroupRepositoryError.groupNotFound
        }
        
        logger.info("Mock: Retrieved \(group.members.count) members for group: \(forGroupId)")
        return group.members
    }
    
    // MARK: - Invitation Management
    func generateInviteCode(forGroupId: String) async throws -> String {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        guard groups[forGroupId] != nil else {
            throw GroupRepositoryError.groupNotFound
        }
        
        let inviteCode = generateInviteCode()
        logger.info("Mock: Generated new invite code for group: \(forGroupId)")
        return inviteCode
    }
    
    func joinGroup(withInviteCode: String, userId: String) async throws -> Group {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 600_000_000)
        
        guard let group = groups.values.first(where: { $0.inviteCode == withInviteCode }) else {
            throw GroupRepositoryError.invalidInviteCode
        }
        
        // Check if user is already a member
        if group.members.contains(where: { $0.userId == userId }) {
            throw GroupRepositoryError.memberAlreadyExists
        }
        
        // Check if group is full
        if group.members.count >= group.maxMembers {
            throw GroupRepositoryError.groupFull
        }
        
        var updatedGroup = group
        let newMember = GroupMember(
            userId: userId,
            role: .member,
            joinedAt: Date(),
            isActive: true
        )
        updatedGroup.members.append(newMember)
        updatedGroup.updatedAt = Date()
        groups[group.id] = updatedGroup
        
        logger.info("Mock: User \(userId) joined group \(group.id) with invite code")
        return updatedGroup
    }
    
    func validateInviteCode(_ inviteCode: String) async throws -> Group? {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 200_000_000)
        
        let group = groups.values.first { $0.inviteCode == inviteCode }
        logger.info("Mock: Validated invite code: \(inviteCode), found group: \(group?.id ?? "none")")
        return group
    }
    
    // MARK: - Group Activities
    func getGroupActivity(forGroupId: String, limit: Int) async throws -> [GroupActivity] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        guard groups[forGroupId] != nil else {
            throw GroupRepositoryError.groupNotFound
        }
        
        // Mock group activities
        let activities = [
            GroupActivity(
                id: UUID().uuidString,
                groupId: forGroupId,
                type: .memberJoined,
                description: "New member joined the group",
                userId: "user-123",
                timestamp: Date().addingTimeInterval(-3600), // 1 hour ago
                metadata: ["memberName": "John Doe"]
            ),
            GroupActivity(
                id: UUID().uuidString,
                groupId: forGroupId,
                type: .goalCompleted,
                description: "Group goal 'Weekly Challenge' completed!",
                userId: "user-456",
                timestamp: Date().addingTimeInterval(-7200), // 2 hours ago
                metadata: ["goalName": "Weekly Challenge", "completionRate": "100%"]
            )
        ]
        
        logger.info("Mock: Retrieved \(activities.count) activities for group: \(forGroupId)")
        return Array(activities.prefix(limit))
    }
    
    func addGroupActivity(_ activity: GroupActivity) async throws -> GroupActivity {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        guard groups[activity.groupId] != nil else {
            throw GroupRepositoryError.groupNotFound
        }
        
        logger.info("Mock: Added group activity: \(activity.type.rawValue) for group: \(activity.groupId)")
        return activity
    }
    
    // MARK: - Search and Discovery
    func searchGroups(query: String, filters: GroupSearchFilters?) async throws -> [Group] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        var searchResults = groups.values
        
        // Apply text search
        if !query.isEmpty {
            searchResults = searchResults.filter { group in
                group.name.localizedCaseInsensitiveContains(query) ||
                group.description.localizedCaseInsensitiveContains(query)
            }
        }
        
        // Apply filters
        if let filters = filters {
            if let isPrivate = filters.isPrivate {
                searchResults = searchResults.filter { $0.isPrivate == isPrivate }
            }
            
            if let maxMembers = filters.maxMembers {
                searchResults = searchResults.filter { $0.members.count <= maxMembers }
            }
            
            if let createdAfter = filters.createdAfter {
                searchResults = searchResults.filter { $0.createdAt >= createdAfter }
            }
        }
        
        logger.info("Mock: Search returned \(searchResults.count) groups for query: \(query)")
        return searchResults
    }
    
    func getRecommendedGroups(forUserId: String) async throws -> [Group] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        // Mock recommendation logic - return public groups that user is not part of
        let userGroups = groups.values.filter { group in
            group.members.contains { $0.userId == forUserId } || group.createdBy == forUserId
        }
        
        let userGroupIds = Set(userGroups.map { $0.id })
        let recommendedGroups = groups.values.filter { group in
            !userGroupIds.contains(group.id) && !group.isPrivate
        }
        
        logger.info("Mock: Generated \(recommendedGroups.count) recommended groups for user: \(forUserId)")
        return Array(recommendedGroups.prefix(5)) // Limit to 5 recommendations
    }
    
    // MARK: - Analytics
    func getGroupStatistics(forGroupId: String) async throws -> GroupStatistics {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        guard let group = groups[forGroupId] else {
            throw GroupRepositoryError.groupNotFound
        }
        
        let activeMembers = group.members.filter { $0.isActive }.count
        let inactiveMembers = group.members.count - activeMembers
        
        let statistics = GroupStatistics(
            totalMembers: group.members.count,
            activeMembers: activeMembers,
            inactiveMembers: inactiveMembers,
            memberGrowthRate: 0.15, // 15% growth
            averageMemberRetention: 0.85, // 85% retention
            topContributors: Array(group.members.prefix(3).map { $0.userId }),
            groupEngagementScore: 0.78
        )
        
        logger.info("Mock: Generated group statistics for group: \(forGroupId)")
        return statistics
    }
    
    // MARK: - Private Helper Methods
    private func generateInviteCode() -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<8).map { _ in characters.randomElement()! })
    }
    
    private func setupMockData() {
        // Create some mock groups for testing
        let mockGroups = [
            Group(
                id: "group-1",
                name: "Fitness Warriors",
                description: "A group dedicated to achieving fitness goals together. We support each other in our health and wellness journey.",
                createdBy: "user-1",
                members: [
                    GroupMember(userId: "user-1", role: .admin, joinedAt: Date().addingTimeInterval(-30 * 24 * 60 * 60), isActive: true),
                    GroupMember(userId: "user-2", role: .moderator, joinedAt: Date().addingTimeInterval(-25 * 24 * 60 * 60), isActive: true),
                    GroupMember(userId: "user-3", role: .member, joinedAt: Date().addingTimeInterval(-20 * 24 * 60 * 60), isActive: true),
                    GroupMember(userId: "user-4", role: .member, joinedAt: Date().addingTimeInterval(-15 * 24 * 60 * 60), isActive: false)
                ],
                inviteCode: "FITNESS123",
                isPrivate: false,
                maxMembers: 50,
                createdAt: Date().addingTimeInterval(-30 * 24 * 60 * 60),
                updatedAt: Date().addingTimeInterval(-5 * 24 * 60 * 60)
            ),
            Group(
                id: "group-2",
                name: "Book Club Elite",
                description: "Monthly book reading challenges with intellectual discussions and goal setting.",
                createdBy: "user-5",
                members: [
                    GroupMember(userId: "user-5", role: .admin, joinedAt: Date().addingTimeInterval(-45 * 24 * 60 * 60), isActive: true),
                    GroupMember(userId: "user-6", role: .member, joinedAt: Date().addingTimeInterval(-40 * 24 * 60 * 60), isActive: true),
                    GroupMember(userId: "user-7", role: .member, joinedAt: Date().addingTimeInterval(-35 * 24 * 60 * 60), isActive: true)
                ],
                inviteCode: "BOOKS456",
                isPrivate: true,
                maxMembers: 20,
                createdAt: Date().addingTimeInterval(-45 * 24 * 60 * 60),
                updatedAt: Date().addingTimeInterval(-10 * 24 * 60 * 60)
            ),
            Group(
                id: "group-3",
                name: "Coding Masters",
                description: "Learn programming languages together, complete coding challenges, and build amazing projects.",
                createdBy: "user-8",
                members: [
                    GroupMember(userId: "user-8", role: .admin, joinedAt: Date().addingTimeInterval(-20 * 24 * 60 * 60), isActive: true),
                    GroupMember(userId: "user-9", role: .moderator, joinedAt: Date().addingTimeInterval(-18 * 24 * 60 * 60), isActive: true),
                    GroupMember(userId: "user-10", role: .member, joinedAt: Date().addingTimeInterval(-15 * 24 * 60 * 60), isActive: true),
                    GroupMember(userId: "user-11", role: .member, joinedAt: Date().addingTimeInterval(-12 * 24 * 60 * 60), isActive: true),
                    GroupMember(userId: "user-12", role: .member, joinedAt: Date().addingTimeInterval(-10 * 24 * 60 * 60), isActive: true)
                ],
                inviteCode: "CODE789",
                isPrivate: false,
                maxMembers: 100,
                createdAt: Date().addingTimeInterval(-20 * 24 * 60 * 60),
                updatedAt: Date().addingTimeInterval(-2 * 24 * 60 * 60)
            ),
            Group(
                id: "group-4",
                name: "Language Learners",
                description: "Master new languages through daily practice, conversation partners, and cultural immersion.",
                createdBy: "user-13",
                members: [
                    GroupMember(userId: "user-13", role: .admin, joinedAt: Date().addingTimeInterval(-60 * 24 * 60 * 60), isActive: true),
                    GroupMember(userId: "user-14", role: .moderator, joinedAt: Date().addingTimeInterval(-55 * 24 * 60 * 60), isActive: true),
                    GroupMember(userId: "user-15", role: .member, joinedAt: Date().addingTimeInterval(-50 * 24 * 60 * 60), isActive: true),
                    GroupMember(userId: "user-16", role: .member, joinedAt: Date().addingTimeInterval(-45 * 24 * 60 * 60), isActive: true),
                    GroupMember(userId: "user-17", role: .member, joinedAt: Date().addingTimeInterval(-40 * 24 * 60 * 60), isActive: false)
                ],
                inviteCode: "LANG101",
                isPrivate: false,
                maxMembers: 75,
                createdAt: Date().addingTimeInterval(-60 * 24 * 60 * 60),
                updatedAt: Date().addingTimeInterval(-7 * 24 * 60 * 60)
            )
        ]
        
        for group in mockGroups {
            groups[group.id] = group
        }
        
        logger.info("Mock: Setup \(mockGroups.count) mock groups")
    }
}
