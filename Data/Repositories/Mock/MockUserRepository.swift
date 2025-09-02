import Foundation
import Combine

// MARK: - Mock User Repository Implementation
class MockUserRepository: UserRepository {
    // MARK: - Properties
    private var users: [String: User] = [:]
    private let logger: Logger
    
    // MARK: - Initialization
    init(logger: Logger = ConsoleLogger()) {
        self.logger = logger
        setupMockData()
    }
    
    // MARK: - CRUD Operations
    func createUser(_ user: User) async throws -> User {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        var newUser = user
        if newUser.id.isEmpty {
            newUser = User(
                id: UUID().uuidString,
                email: user.email,
                username: user.username,
                displayName: user.displayName,
                bio: user.bio,
                dateOfBirth: user.dateOfBirth,
                profilePictureUrl: user.profilePictureUrl,
                referralCode: user.referralCode,
                referrerId: user.referrerId,
                referralCount: user.referralCount,
                isVerified: user.isVerified,
                lastActiveAt: Date(),
                settings: user.settings,
                createdAt: Date(),
                updatedAt: Date()
            )
        }
        
        users[newUser.id] = newUser
        logger.info("Mock: Created user with ID: \(newUser.id)")
        return newUser
    }
    
    func getUser(id: String) async throws -> User? {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 200_000_000)
        
        let user = users[id]
        logger.info("Mock: Retrieved user with ID: \(id), found: \(user != nil)")
        return user
    }
    
    func updateUser(_ user: User) async throws -> User {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        guard users[user.id] != nil else {
            throw UserRepositoryError.userNotFound
        }
        
        var updatedUser = user
        updatedUser.updatedAt = Date()
        users[user.id] = updatedUser
        
        logger.info("Mock: Updated user with ID: \(user.id)")
        return updatedUser
    }
    
    func deleteUser(id: String) async throws -> Bool {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        guard users[id] != nil else {
            throw UserRepositoryError.userNotFound
        }
        
        users.removeValue(forKey: id)
        logger.info("Mock: Deleted user with ID: \(id)")
        return true
    }
    
    // MARK: - Query Operations
    func getAllUsers() async throws -> [User] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let allUsers = Array(users.values)
        logger.info("Mock: Retrieved all \(allUsers.count) users")
        return allUsers
    }
    
    func searchUsers(query: String) async throws -> [User] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        let searchResults = users.values.filter { user in
            user.displayName?.localizedCaseInsensitiveContains(query) == true ||
            user.username?.localizedCaseInsensitiveContains(query) == true ||
            user.email.localizedCaseInsensitiveContains(query) == true ||
            user.bio?.localizedCaseInsensitiveContains(query) == true
        }
        
        logger.info("Mock: Search for '\(query)' returned \(searchResults.count) results")
        return searchResults
    }
    
    func getUsers(byReferrerId: String) async throws -> [User] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let referredUsers = users.values.filter { $0.referrerId == byReferrerId }
        logger.info("Mock: Retrieved \(referredUsers.count) users referred by: \(byReferrerId)")
        return referredUsers
    }
    
    func getUsers(byDateRange: DateInterval) async throws -> [User] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let dateRangeUsers = users.values.filter { user in
            guard let createdAt = user.createdAt else { return false }
            return createdAt >= byDateRange.start && createdAt <= byDateRange.end
        }
        
        logger.info("Mock: Retrieved \(dateRangeUsers.count) users in date range")
        return dateRangeUsers
    }
    
    // MARK: - Authentication Operations
    func getCurrentUser() async throws -> User? {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // Mock implementation - return the first user as current user
        let currentUser = users.values.first
        logger.info("Mock: Retrieved current user, found: \(currentUser != nil)")
        return currentUser
    }
    
    func getUserByEmail(email: String) async throws -> User? {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 200_000_000)
        
        let user = users.values.first { $0.email == email }
        logger.info("Mock: Retrieved user by email: \(email), found: \(user != nil)")
        return user
    }
    
    func getUserByUsername(username: String) async throws -> User? {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 200_000_000)
        
        let user = users.values.first { $0.username == username }
        logger.info("Mock: Retrieved user by username: \(username), found: \(user != nil)")
        return user
    }
    
    func getUserByReferralCode(code: String) async throws -> User? {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 200_000_000)
        
        let user = users.values.first { $0.referralCode == code }
        logger.info("Mock: Retrieved user by referral code: \(code), found: \(user != nil)")
        return user
    }
    
    // MARK: - Profile Operations
    func updateProfile(_ user: User) async throws -> User {
        return try await updateUser(user)
    }
    
    func updateProfilePicture(userId: String, imageUrl: String) async throws -> User {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        guard var user = users[userId] else {
            throw UserRepositoryError.userNotFound
        }
        
        user.profilePictureUrl = imageUrl
        user.updatedAt = Date()
        users[userId] = user
        
        logger.info("Mock: Updated profile picture for user: \(userId)")
        return user
    }
    
    func updateSettings(userId: String, settings: UserSettings) async throws -> User {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        guard var user = users[userId] else {
            throw UserRepositoryError.userNotFound
        }
        
        user.settings = settings
        user.updatedAt = Date()
        users[userId] = user
        
        logger.info("Mock: Updated settings for user: \(userId)")
        return user
    }
    
    // MARK: - Referral Operations
    func incrementReferralCount(userId: String) async throws -> User {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        guard var user = users[userId] else {
            throw UserRepositoryError.userNotFound
        }
        
        user.referralCount += 1
        user.updatedAt = Date()
        users[userId] = user
        
        logger.info("Mock: Incremented referral count for user: \(userId)")
        return user
    }
    
    func getReferralStats(userId: String) async throws -> ReferralStats {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        let user = users[userId]
        let referredUsers = users.values.filter { $0.referrerId == userId }
        
        let stats = ReferralStats(
            totalReferrals: user?.referralCount ?? 0,
            successfulReferrals: referredUsers.count,
            totalEarnings: Decimal(referredUsers.count * 10), // Mock earnings
            referralHistory: referredUsers.map { user in
                ReferralHistoryItem(
                    referredUserId: user.id,
                    referredUserName: user.displayName ?? user.username ?? "Unknown",
                    referralDate: user.createdAt ?? Date(),
                    status: .completed,
                    earnings: 10.0
                )
            }
        )
        
        logger.info("Mock: Generated referral stats for user: \(userId)")
        return stats
    }
    
    // MARK: - Analytics Operations
    func getUserStatistics() async throws -> UserStatistics {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000)
        
        let allUsers = Array(users.values)
        let totalUsers = allUsers.count
        let activeUsers = allUsers.filter { user in
            guard let lastActive = user.lastActiveAt else { return false }
            return lastActive > Date().addingTimeInterval(-7 * 24 * 60 * 60) // Active within 7 days
        }.count
        let newUsersThisMonth = allUsers.filter { user in
            guard let createdAt = user.createdAt else { return false }
            let calendar = Calendar.current
            let now = Date()
            let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
            return createdAt >= startOfMonth
        }.count
        let verifiedUsers = allUsers.filter { $0.isVerified }.count
        let averageReferrals = allUsers.reduce(0) { $0 + $1.referralCount } / max(allUsers.count, 1)
        
        let topReferrers = allUsers
            .filter { $0.referralCount > 0 }
            .sorted { $0.referralCount > $1.referralCount }
            .prefix(5)
            .map { user in
                TopReferrer(
                    userId: user.id,
                    userName: user.displayName ?? user.username ?? "Unknown",
                    referralCount: user.referralCount,
                    totalEarnings: Decimal(user.referralCount * 10)
                )
            }
        
        let statistics = UserStatistics(
            totalUsers: totalUsers,
            activeUsers: activeUsers,
            newUsersThisMonth: newUsersThisMonth,
            verifiedUsers: verifiedUsers,
            averageReferrals: Double(averageReferrals),
            topReferrers: Array(topReferrers)
        )
        
        logger.info("Mock: Generated user statistics")
        return statistics
    }
    
    func getActiveUsersCount() async throws -> Int {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 200_000_000)
        
        let activeUsers = users.values.filter { user in
            guard let lastActive = user.lastActiveAt else { return false }
            return lastActive > Date().addingTimeInterval(-7 * 24 * 60 * 60) // Active within 7 days
        }.count
        
        logger.info("Mock: Retrieved active users count: \(activeUsers)")
        return activeUsers
    }
    
    func getNewUsersCount(inTimeRange: TimeRange) async throws -> Int {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 200_000_000)
        
        let newUsers = users.values.filter { user in
            guard let createdAt = user.createdAt else { return false }
            return createdAt >= inTimeRange.start && createdAt <= inTimeRange.end
        }.count
        
        logger.info("Mock: Retrieved new users count: \(newUsers) in time range")
        return newUsers
    }
    
    // MARK: - Bulk Operations
    func bulkUpdateUsers(_ users: [User]) async throws -> [User] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        var updatedUsers: [User] = []
        
        for user in users {
            if let existingUser = self.users[user.id] {
                var updatedUser = user
                updatedUser.updatedAt = Date()
                self.users[user.id] = updatedUser
                updatedUsers.append(updatedUser)
            }
        }
        
        logger.info("Mock: Bulk updated \(updatedUsers.count) users")
        return updatedUsers
    }
    
    func deleteInactiveUsers(olderThan date: Date) async throws -> Int {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 600_000_000)
        
        let inactiveUsers = users.values.filter { user in
            guard let lastActive = user.lastActiveAt else { return true }
            return lastActive < date
        }
        
        let count = inactiveUsers.count
        for user in inactiveUsers {
            users.removeValue(forKey: user.id)
        }
        
        logger.info("Mock: Deleted \(count) inactive users")
        return count
    }
    
    // MARK: - Private Helper Methods
    private func setupMockData() {
        // Create some mock users for testing
        let mockUsers = [
            User(
                id: "user-1",
                email: "john.doe@example.com",
                username: "johndoe",
                displayName: "John Doe",
                bio: "iOS Developer passionate about SwiftUI and Clean Architecture",
                dateOfBirth: Calendar.current.date(byAdding: .year, value: -30, to: Date()),
                profilePictureUrl: "https://example.com/john.jpg",
                referralCode: "JOHN123",
                referrerId: nil,
                referralCount: 5,
                isVerified: true,
                lastActiveAt: Date(),
                settings: UserSettings(
                    notifications: NotificationPreferences(
                        pushEnabled: true,
                        emailEnabled: true,
                        smsEnabled: false,
                        goalReminders: true,
                        milestoneUpdates: true,
                        weeklyReports: true
                    ),
                    privacy: PrivacySettings(
                        profileVisibility: .public,
                        goalVisibility: .friends,
                        activityVisibility: .friends,
                        allowReferrals: true
                    ),
                    appearance: AppearanceSettings(
                        theme: .system,
                        accentColor: .blue,
                        useDynamicType: true
                    )
                ),
                createdAt: Date().addingTimeInterval(-365 * 24 * 60 * 60), // 1 year ago
                updatedAt: Date().addingTimeInterval(-7 * 24 * 60 * 60) // 1 week ago
            ),
            User(
                id: "user-2",
                email: "jane.smith@example.com",
                username: "janesmith",
                displayName: "Jane Smith",
                bio: "Fitness enthusiast and goal achiever",
                dateOfBirth: Calendar.current.date(byAdding: .year, value: -28, to: Date()),
                profilePictureUrl: "https://example.com/jane.jpg",
                referralCode: "JANE456",
                referrerId: "user-1",
                referralCount: 2,
                isVerified: true,
                lastActiveAt: Date().addingTimeInterval(-2 * 24 * 60 * 60), // 2 days ago
                settings: UserSettings(
                    notifications: NotificationPreferences(
                        pushEnabled: true,
                        emailEnabled: false,
                        smsEnabled: false,
                        goalReminders: true,
                        milestoneUpdates: true,
                        weeklyReports: false
                    ),
                    privacy: PrivacySettings(
                        profileVisibility: .friends,
                        goalVisibility: .friends,
                        activityVisibility: .private,
                        allowReferrals: true
                    ),
                    appearance: AppearanceSettings(
                        theme: .dark,
                        accentColor: .green,
                        useDynamicType: false
                    )
                ),
                createdAt: Date().addingTimeInterval(-180 * 24 * 60 * 60), // 6 months ago
                updatedAt: Date().addingTimeInterval(-2 * 24 * 60 * 60) // 2 days ago
            ),
            User(
                id: "user-3",
                email: "bob.wilson@example.com",
                username: "bobwilson",
                displayName: "Bob Wilson",
                bio: "Learning new skills and building habits",
                dateOfBirth: Calendar.current.date(byAdding: .year, value: -35, to: Date()),
                profilePictureUrl: nil,
                referralCode: "BOB789",
                referrerId: "user-1",
                referralCount: 0,
                isVerified: false,
                lastActiveAt: Date().addingTimeInterval(-7 * 24 * 60 * 60), // 1 week ago
                settings: UserSettings(
                    notifications: NotificationPreferences(
                        pushEnabled: false,
                        emailEnabled: true,
                        smsEnabled: false,
                        goalReminders: false,
                        milestoneUpdates: true,
                        weeklyReports: false
                    ),
                    privacy: PrivacySettings(
                        profileVisibility: .private,
                        goalVisibility: .private,
                        activityVisibility: .private,
                        allowReferrals: false
                    ),
                    appearance: AppearanceSettings(
                        theme: .light,
                        accentColor: .orange,
                        useDynamicType: true
                    )
                ),
                createdAt: Date().addingTimeInterval(-90 * 24 * 60 * 60), // 3 months ago
                updatedAt: Date().addingTimeInterval(-7 * 24 * 60 * 60) // 1 week ago
            )
        ]
        
        for user in mockUsers {
            users[user.id] = user
        }
        
        logger.info("Mock: Setup \(mockUsers.count) mock users")
    }
}
