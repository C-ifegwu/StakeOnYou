import Foundation
import CoreData
import Combine

// MARK: - Core Data User Repository Implementation
class CoreDataUserRepository: UserRepository {
    // MARK: - Properties
    private let coreDataStack: CoreDataStack
    private let logger: Logger
    
    // MARK: - Initialization
    init(coreDataStack: CoreDataStack, logger: Logger) {
        self.coreDataStack = coreDataStack
        self.logger = logger
    }
    
    // MARK: - CRUD Operations
    func createUser(_ user: User) async throws -> User {
        return try await coreDataStack.performBackgroundTask { context in
            let entity = UserEntity(context: context)
            
            // Map domain model to Core Data entity
            entity.id = user.id
            entity.email = user.email
            entity.username = user.username
            entity.displayName = user.displayName
            entity.bio = user.bio
            entity.dateOfBirth = user.dateOfBirth
            entity.profilePictureUrl = user.profilePictureUrl
            entity.referralCode = user.referralCode
            entity.referrerId = user.referrerId
            entity.referralCount = Int32(user.referralCount)
            entity.isVerified = user.isVerified
            entity.createdAt = user.createdAt
            entity.lastActiveAt = user.lastActiveAt
            entity.settings = user.settings
            
            try context.save()
            
            self.logger.info("Created user with ID: \(user.id)")
            return user
        }
    }
    
    func getUser(id: String) async throws -> User? {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(UserEntity.self, predicate: CoreDataUtilities.createPredicate(format: "id == %@", arguments: [id]))
            request.fetchLimit = 1
            
            let results = try context.fetch(request)
            guard let entity = results.first else { return nil }
            
            return self.mapEntityToUser(entity)
        }
    }
    
    func updateUser(_ user: User) async throws -> User {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(UserEntity.self, predicate: CoreDataUtilities.createPredicate(format: "id == %@", arguments: [user.id]))
            request.fetchLimit = 1
            
            let results = try context.fetch(request)
            guard let entity = results.first else {
                throw UserRepositoryError.userNotFound
            }
            
            // Update entity with new values
            entity.email = user.email
            entity.username = user.username
            entity.displayName = user.displayName
            entity.bio = user.bio
            entity.dateOfBirth = user.dateOfBirth
            entity.profilePictureUrl = user.profilePictureUrl
            entity.referralCode = user.referralCode
            entity.referrerId = user.referrerId
            entity.referralCount = Int32(user.referralCount)
            entity.isVerified = user.isVerified
            entity.lastActiveAt = user.lastActiveAt
            entity.settings = user.settings
            
            try context.save()
            
            self.logger.info("Updated user with ID: \(user.id)")
            return user
        }
    }
    
    func deleteUser(id: String) async throws -> Bool {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(UserEntity.self, predicate: CoreDataUtilities.createPredicate(format: "id == %@", arguments: [id]))
            request.fetchLimit = 1
            
            let results = try context.fetch(request)
            guard let entity = results.first else {
                throw UserRepositoryError.userNotFound
            }
            
            context.delete(entity)
            try context.save()
            
            self.logger.info("Deleted user with ID: \(id)")
            return true
        }
    }
    
    // MARK: - Query Operations
    func getAllUsers() async throws -> [User] {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(UserEntity.self)
            let results = try context.fetch(request)
            
            return results.map { self.mapEntityToUser($0) }
        }
    }
    
    func searchUsers(query: String) async throws -> [User] {
        return try await coreDataStack.performBackgroundTask { context in
            let predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
                CoreDataUtilities.createPredicate(format: "displayName CONTAINS[cd] %@", arguments: [query]),
                CoreDataUtilities.createPredicate(format: "username CONTAINS[cd] %@", arguments: [query]),
                CoreDataUtilities.createPredicate(format: "email CONTAINS[cd] %@", arguments: [query])
            ])
            
            let request = CoreDataUtilities.createFetchRequest(UserEntity.self, predicate: predicate)
            let results = try context.fetch(request)
            
            return results.map { self.mapEntityToUser($0) }
        }
    }
    
    func getUsers(byReferrerId: String) async throws -> [User] {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(UserEntity.self, predicate: CoreDataUtilities.createPredicate(format: "referrerId == %@", arguments: [referrerId]))
            let results = try context.fetch(request)
            
            return results.map { self.mapEntityToUser($0) }
        }
    }
    
    func getUsers(byDateRange: DateInterval) async throws -> [User] {
        return try await coreDataStack.performBackgroundTask { context in
            let predicate = CoreDataUtilities.createPredicate(format: "createdAt >= %@ AND createdAt <= %@", arguments: [dateRange.start, dateRange.end])
            let request = CoreDataUtilities.createFetchRequest(UserEntity.self, predicate: predicate)
            let results = try context.fetch(request)
            
            return results.map { self.mapEntityToUser($0) }
        }
    }
    
    // MARK: - Authentication Operations
    func getCurrentUser() async throws -> User? {
        // This would typically check for the currently authenticated user
        // For now, return the most recently active user
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(UserEntity.self, sortDescriptors: [CoreDataUtilities.createSortDescriptor(key: "lastActiveAt", ascending: false)])
            request.fetchLimit = 1
            
            let results = try context.fetch(request)
            guard let entity = results.first else { return nil }
            
            return self.mapEntityToUser(entity)
        }
    }
    
    func getUserByEmail(email: String) async throws -> User? {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(UserEntity.self, predicate: CoreDataUtilities.createPredicate(format: "email == %@", arguments: [email]))
            request.fetchLimit = 1
            
            let results = try context.fetch(request)
            guard let entity = results.first else { return nil }
            
            return self.mapEntityToUser(entity)
        }
    }
    
    func getUserByUsername(username: String) async throws -> User? {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(UserEntity.self, predicate: CoreDataUtilities.createPredicate(format: "username == %@", arguments: [username]))
            request.fetchLimit = 1
            
            let results = try context.fetch(request)
            guard let entity = results.first else { return nil }
            
            return self.mapEntityToUser(entity)
        }
    }
    
    func getUserByReferralCode(code: String) async throws -> User? {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(UserEntity.self, predicate: CoreDataUtilities.createPredicate(format: "referralCode == %@", arguments: [code]))
            request.fetchLimit = 1
            
            let results = try context.fetch(request)
            guard let entity = results.first else { return nil }
            
            return self.mapEntityToUser(entity)
        }
    }
    
    // MARK: - Profile Operations
    func updateProfile(_ user: User) async throws -> User {
        return try await updateUser(user)
    }
    
    func updateProfilePicture(userId: String, imageUrl: String) async throws -> User {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(UserEntity.self, predicate: CoreDataUtilities.createPredicate(format: "id == %@", arguments: [userId]))
            request.fetchLimit = 1
            
            let results = try context.fetch(request)
            guard let entity = results.first else {
                throw UserRepositoryError.userNotFound
            }
            
            entity.profilePictureUrl = imageUrl
            try context.save()
            
            self.logger.info("Updated profile picture for user: \(userId)")
            return self.mapEntityToUser(entity)
        }
    }
    
    func updateSettings(userId: String, settings: UserSettings) async throws -> User {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(UserEntity.self, predicate: CoreDataUtilities.createPredicate(format: "id == %@", arguments: [userId]))
            request.fetchLimit = 1
            
            let results = try context.fetch(request)
            guard let entity = results.first else {
                throw UserRepositoryError.userNotFound
            }
            
            entity.settings = settings
            try context.save()
            
            self.logger.info("Updated settings for user: \(userId)")
            return self.mapEntityToUser(entity)
        }
    }
    
    // MARK: - Referral Operations
    func incrementReferralCount(userId: String) async throws -> User {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(UserEntity.self, predicate: CoreDataUtilities.createPredicate(format: "id == %@", arguments: [userId]))
            request.fetchLimit = 1
            
            let results = try context.fetch(request)
            guard let entity = results.first else {
                throw UserRepositoryError.userNotFound
            }
            
            entity.referralCount += 1
            try context.save()
            
            self.logger.info("Incremented referral count for user: \(userId)")
            return self.mapEntityToUser(entity)
        }
    }
    
    func getReferralStats(userId: String) async throws -> ReferralStats {
        // This would need to be implemented with actual referral tracking
        // For now, return mock data
        return ReferralStats(
            totalReferrals: 0,
            successfulReferrals: 0,
            totalEarnings: Decimal(0),
            referralHistory: []
        )
    }
    
    // MARK: - Analytics Operations
    func getUserStatistics() async throws -> UserStatistics {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(UserEntity.self)
            let results = try context.fetch(request)
            
            let totalUsers = results.count
            let verifiedUsers = results.filter { $0.isVerified }.count
            let activeUsers = results.filter { 
                guard let lastActive = $0.lastActiveAt else { return false }
                return lastActive > Date().addingTimeInterval(-7 * 24 * 60 * 60)
            }.count
            
            let totalReferrals = results.reduce(0) { $0 + Int($1.referralCount) }
            let averageReferrals = totalUsers > 0 ? Double(totalReferrals) / Double(totalUsers) : 0.0
            
            let topReferrers = results
                .filter { $0.referralCount > 0 }
                .sorted { $0.referralCount > $1.referralCount }
                .prefix(10)
                .map { TopReferrer(userId: $0.id ?? "", userName: $0.displayName ?? $0.username ?? "", referralCount: Int($0.referralCount), totalEarnings: Decimal(0)) }
            
            return UserStatistics(
                totalUsers: totalUsers,
                activeUsers: activeUsers,
                newUsersThisMonth: 0, // Would need date filtering
                verifiedUsers: verifiedUsers,
                averageReferrals: averageReferrals,
                topReferrers: Array(topReferrers)
            )
        }
    }
    
    func getActiveUsersCount() async throws -> Int {
        return try await coreDataStack.performBackgroundTask { context in
            let request = CoreDataUtilities.createFetchRequest(UserEntity.self)
            let results = try context.fetch(request)
            
            return results.filter { 
                guard let lastActive = $0.lastActiveAt else { return false }
                return lastActive > Date().addingTimeInterval(-7 * 24 * 60 * 60)
            }.count
        }
    }
    
    func getNewUsersCount(inTimeRange: TimeRange) async throws -> Int {
        return try await coreDataStack.performBackgroundTask { context in
            let dateInterval = inTimeRange.dateInterval
            let predicate = CoreDataUtilities.createPredicate(format: "createdAt >= %@ AND createdAt <= %@", arguments: [dateInterval.start, dateInterval.end])
            
            let request = CoreDataUtilities.createFetchRequest(UserEntity.self, predicate: predicate)
            let results = try context.fetch(request)
            
            return results.count
        }
    }
    
    // MARK: - Bulk Operations
    func bulkUpdateUsers(_ users: [User]) async throws -> [User] {
        return try await coreDataStack.performBackgroundTask { context in
            var updatedUsers: [User] = []
            
            for user in users {
                let request = CoreDataUtilities.createFetchRequest(UserEntity.self, predicate: CoreDataUtilities.createPredicate(format: "id == %@", arguments: [user.id]))
                request.fetchLimit = 1
                
                let results = try context.fetch(request)
                if let entity = results.first {
                    // Update existing entity
                    entity.email = user.email
                    entity.username = user.username
                    entity.displayName = user.displayName
                    entity.bio = user.bio
                    entity.dateOfBirth = user.dateOfBirth
                    entity.profilePictureUrl = user.profilePictureUrl
                    entity.referralCode = user.referralCode
                    entity.referrerId = user.referrerId
                    entity.referralCount = Int32(user.referralCount)
                    entity.isVerified = user.isVerified
                    entity.lastActiveAt = user.lastActiveAt
                    entity.settings = user.settings
                    
                    updatedUsers.append(user)
                }
            }
            
            try context.save()
            self.logger.info("Bulk updated \(updatedUsers.count) users")
            return updatedUsers
        }
    }
    
    func deleteInactiveUsers(olderThan date: Date) async throws -> Int {
        return try await coreDataStack.performBackgroundTask { context in
            let predicate = CoreDataUtilities.createPredicate(format: "lastActiveAt < %@", arguments: [date])
            let request = CoreDataUtilities.createFetchRequest(UserEntity.self, predicate: predicate)
            let results = try context.fetch(request)
            
            let count = results.count
            for entity in results {
                context.delete(entity)
            }
            
            try context.save()
            self.logger.info("Deleted \(count) inactive users")
            return count
        }
    }
    
    // MARK: - Private Helper Methods
    private func mapEntityToUser(_ entity: UserEntity) -> User {
        return User(
            id: entity.id ?? "",
            email: entity.email ?? "",
            username: entity.username,
            displayName: entity.displayName,
            bio: entity.bio,
            dateOfBirth: entity.dateOfBirth,
            profilePictureUrl: entity.profilePictureUrl,
            referralCode: entity.referralCode,
            referrerId: entity.referrerId,
            referralCount: Int(entity.referralCount),
            isVerified: entity.isVerified,
            createdAt: entity.createdAt ?? Date(),
            lastActiveAt: entity.lastActiveAt,
            settings: entity.settings
        )
    }
}
