import Foundation
import Security

// MARK: - Keychain Service Implementation
class KeychainServiceImpl: KeychainService {
    
    // MARK: - Properties
    private let service: String
    private let accessGroup: String?
    
    init(service: String = "com.stakeonyou.app", accessGroup: String? = nil) {
        self.service = service
        self.accessGroup = accessGroup
    }
    
    // MARK: - Save Data
    func save(_ data: Data, for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Check if item already exists
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecDuplicateItem {
            // Item exists, update it
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: key
            ]
            
            let updateAttributes: [String: Any] = [
                kSecValueData as String: data
            ]
            
            let updateStatus = SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)
            
            guard updateStatus == errSecSuccess else {
                throw KeychainError.saveFailed(updateStatus)
            }
        } else if status != errSecSuccess {
            throw KeychainError.saveFailed(status)
        }
        
        logInfo("Data saved to keychain for key: \(key)", category: "KeychainService")
    }
    
    // MARK: - Load Data
    func load(for key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return nil
            }
            throw KeychainError.loadFailed(status)
        }
        
        guard let data = result as? Data else {
            throw KeychainError.invalidData
        }
        
        return data
    }
    
    // MARK: - Delete Data
    func delete(for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
        
        logInfo("Data deleted from keychain for key: \(key)", category: "KeychainService")
    }
    
    // MARK: - Check Existence
    func exists(for key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: false,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    // MARK: - Helper Methods
    
    /// Save string to keychain
    func saveString(_ string: String, for key: String) throws {
        guard let data = string.data(using: .utf8) else {
            throw KeychainError.invalidData
        }
        try save(data, for: key)
    }
    
    /// Load string from keychain
    func loadString(for key: String) throws -> String? {
        guard let data = try load(for: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    /// Save boolean to keychain
    func saveBool(_ value: Bool, for key: String) throws {
        let data = Data([value ? 1 : 0])
        try save(data, for: key)
    }
    
    /// Load boolean from keychain
    func loadBool(for key: String) throws -> Bool? {
        guard let data = try load(for: key), data.count == 1 else { return nil }
        return data[0] == 1
    }
    
    /// Save codable object to keychain
    func save<T: Codable>(_ object: T, for key: String) throws {
        let data = try JSONEncoder().encode(object)
        try save(data, for: key)
    }
    
    /// Load codable object from keychain
    func load<T: Codable>(_ type: T.Type, for key: String) throws -> T? {
        guard let data = try load(for: key) else { return nil }
        return try JSONDecoder().decode(type, from: data)
    }
    
    /// Clear all items for this service
    func clearAll() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
        
        logInfo("All keychain data cleared for service: \(service)", category: "KeychainService")
    }
    
    /// Get all keys for this service
    func getAllKeys() throws -> [String] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return []
            }
            throw KeychainError.loadFailed(status)
        }
        
        guard let items = result as? [[String: Any]] else {
            throw KeychainError.invalidData
        }
        
        return items.compactMap { $0[kSecAttrAccount as String] as? String }
    }
}

// MARK: - Keychain Errors
enum KeychainError: LocalizedError, Equatable {
    case saveFailed(OSStatus)
    case loadFailed(OSStatus)
    case deleteFailed(OSStatus)
    case invalidData
    case itemNotFound
    case duplicateItem
    case userCancelled
    case notAvailable
    case unknown(OSStatus)
    
    static func fromOSStatus(_ status: OSStatus) -> KeychainError {
        switch status {
        case errSecSuccess:
            return .unknown(status) // This shouldn't happen
        case errSecItemNotFound:
            return .itemNotFound
        case errSecDuplicateItem:
            return .duplicateItem
        case errSecUserCanceled:
            return .userCancelled
        case errSecNotAvailable:
            return .notAvailable
        default:
            return .unknown(status)
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let status):
            return "Failed to save to keychain: \(status)"
        case .loadFailed(let status):
            return "Failed to load from keychain: \(status)"
        case .deleteFailed(let status):
            return "Failed to delete from keychain: \(status)"
        case .invalidData:
            return "Invalid data format"
        case .itemNotFound:
            return "Item not found in keychain"
        case .duplicateItem:
            return "Item already exists in keychain"
        case .userCancelled:
            return "Operation was cancelled by user"
        case .notAvailable:
            return "Keychain is not available"
        case .unknown(let status):
            return "Unknown keychain error: \(status)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .saveFailed, .loadFailed, .deleteFailed, .unknown:
            return "Please try again or contact support if the problem persists"
        case .invalidData:
            return "The data format is not supported"
        case .itemNotFound:
            return "The requested item was not found"
        case .duplicateItem:
            return "The item already exists"
        case .userCancelled:
            return "The operation was cancelled"
        case .notAvailable:
            return "Keychain access is not available on this device"
        }
    }
}

// MARK: - Keychain Constants
struct KeychainConstants {
    static let accessTokenKey = "access_token"
    static let refreshTokenKey = "refresh_token"
    static let userIdKey = "user_id"
    static let biometricEnabledKey = "biometric_enabled"
    static let rememberMeKey = "remember_me"
    static let lastLoginKey = "last_login"
    static let sessionExpiryKey = "session_expiry"
    
    static let tokenExpiryBuffer: TimeInterval = 300 // 5 minutes buffer
}

// MARK: - Keychain Analytics
extension KeychainServiceImpl {
    func trackKeychainEvent(_ event: KeychainAnalyticsEvent) {
        trackAnalyticsEvent(event.name, properties: event.properties)
    }
}

enum KeychainAnalyticsEvent {
    case saveSuccess(String)
    case saveFailure(String, KeychainError)
    case loadSuccess(String)
    case loadFailure(String, KeychainError)
    case deleteSuccess(String)
    case deleteFailure(String, KeychainError)
    case clearAll
    
    var name: String {
        switch self {
        case .saveSuccess:
            return "keychain_save_success"
        case .saveFailure:
            return "keychain_save_failure"
        case .loadSuccess:
            return "keychain_load_success"
        case .loadFailure:
            return "keychain_load_failure"
        case .deleteSuccess:
            return "keychain_delete_success"
        case .deleteFailure:
            return "keychain_delete_failure"
        case .clearAll:
            return "keychain_clear_all"
        }
    }
    
    var properties: [String: Any] {
        switch self {
        case .saveSuccess(let key):
            return ["key": key, "timestamp": Date().timeIntervalSince1970]
        case .saveFailure(let key, let error):
            return [
                "key": key,
                "error": error.localizedDescription,
                "timestamp": Date().timeIntervalSince1970
            ]
        case .loadSuccess(let key):
            return ["key": key, "timestamp": Date().timeIntervalSince1970]
        case .loadFailure(let key, let error):
            return [
                "key": key,
                "error": error.localizedDescription,
                "timestamp": Date().timeIntervalSince1970
            ]
        case .deleteSuccess(let key):
            return ["key": key, "timestamp": Date().timeIntervalSince1970]
        case .deleteFailure(let key, let error):
            return [
                "key": key,
                "error": error.localizedDescription,
                "timestamp": Date().timeIntervalSince1970
            ]
        case .clearAll:
            return ["timestamp": Date().timeIntervalSince1970]
        }
    }
}
