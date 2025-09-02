import Foundation
import Combine

// MARK: - User Repository Protocol
protocol UserRepository {
    // MARK: - CRUD Operations
    func createUser(_ user: User) async throws -> User
    func getUser(id: String) async throws -> User?
    func updateUser(_ user: User) async throws -> User
    func deleteUser(id: String) async throws -> Bool
    
    // MARK: - Query Operations
    func getAllUsers() async throws -> [User]
    func searchUsers(query: String) async throws -> [User]
    func getUsers(byReferrerId: String) async throws -> [User]
    func getUsers(byDateRange: DateInterval) async throws -> [User]
    
    // MARK: - Authentication Operations
    func getCurrentUser() async throws -> User?
    func getUserByEmail(email: String) async throws -> User?
    func getUserByUsername(username: String) async throws -> User?
    func getUserByReferralCode(code: String) async throws -> User?
    
    // MARK: - Profile Operations
    func updateProfile(_ user: User) async throws -> User
    func updateProfilePicture(userId: String, imageUrl: String) async throws -> User
    func updateSettings(userId: String, settings: UserSettings) async throws -> User
    
    // MARK: - Referral Operations
    func incrementReferralCount(userId: String) async throws -> User
    func getReferralStats(userId: String) async throws -> ReferralStats
    
    // MARK: - Analytics Operations
    func getUserStatistics() async throws -> UserStatistics
    func getActiveUsersCount() async throws -> Int
    func getNewUsersCount(inTimeRange: TimeRange) async throws -> Int
    
    // MARK: - Bulk Operations
    func bulkUpdateUsers(_ users: [User]) async throws -> [User]
    func deleteInactiveUsers(olderThan date: Date) async throws -> Int
}

// MARK: - Supporting Models
struct ReferralStats {
    let totalReferrals: Int
    let successfulReferrals: Int
    let totalEarnings: Decimal
    let referralHistory: [ReferralHistoryItem]
}

struct ReferralHistoryItem {
    let referredUserId: String
    let referredUserName: String
    let referralDate: Date
    let status: ReferralStatus
    let earnings: Decimal
}

enum ReferralStatus: String, CaseIterable {
    case pending = "pending"
    case active = "active"
    case completed = "completed"
    case failed = "failed"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .active: return "Active"
        case .completed: return "Completed"
        case .failed: return "Failed"
        }
    }
}

struct UserStatistics {
    let totalUsers: Int
    let activeUsers: Int
    let newUsersThisMonth: Int
    let verifiedUsers: Int
    let averageReferrals: Double
    let topReferrers: [TopReferrer]
}

struct TopReferrer {
    let userId: String
    let userName: String
    let referralCount: Int
    let totalEarnings: Decimal
}

// MARK: - User Repository Extensions
extension UserRepository {
    // MARK: - Convenience Methods
    func getActiveUsers() async throws -> [User] {
        let users = try await getAllUsers()
        return users.filter { $0.lastActiveAt ?? Date.distantPast > Date().addingTimeInterval(-7 * 24 * 60 * 60) }
    }
    
    func getVerifiedUsers() async throws -> [User] {
        let users = try await getAllUsers()
        return users.filter { $0.isVerified }
    }
    
    func getUsersWithReferrals() async throws -> [User] {
        let users = try await getAllUsers()
        return users.filter { $0.referralCount > 0 }
    }
    
    func getUserByPartialMatch(query: String) async throws -> [User] {
        let users = try await getAllUsers()
        return users.filter { user in
            user.displayName?.localizedCaseInsensitiveContains(query) == true ||
            user.username?.localizedCaseInsensitiveContains(query) == true ||
            user.email.localizedCaseInsensitiveContains(query) == true
        }
    }
    
    func getUsersByActivityLevel(activeWithinDays days: Int) async throws -> [User] {
        let users = try await getAllUsers()
        let cutoffDate = Date().addingTimeInterval(TimeInterval(-days * 24 * 60 * 60))
        
        return users.filter { user in
            guard let lastActive = user.lastActiveAt else { return false }
            return lastActive > cutoffDate
        }
    }
}

// MARK: - User Repository Error
enum UserRepositoryError: LocalizedError {
    case userNotFound
    case invalidUserData
    case duplicateEmail
    case duplicateUsername
    case invalidReferralCode
    case databaseError(Error)
    case networkError(Error)
    case permissionDenied
    case quotaExceeded
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not found"
        case .invalidUserData:
            return "Invalid user data"
        case .duplicateEmail:
            return "Email already exists"
        case .duplicateUsername:
            return "Username already exists"
        case .invalidReferralCode:
            return "Invalid referral code"
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
