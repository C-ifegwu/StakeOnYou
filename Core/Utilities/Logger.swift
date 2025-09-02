import Foundation
import os.log

// MARK: - Logging System
enum LogLevel: String, CaseIterable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    case critical = "CRITICAL"
    
    var emoji: String {
        switch self {
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        case .critical: return "🚨"
        }
    }
    
    var osLogType: OSLogType {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        case .critical: return .fault
        }
    }
}

// MARK: - Logger Protocol
protocol LoggerProtocol {
    func log(_ level: LogLevel, message: String, category: String, file: String, function: String, line: Int)
    func debug(_ message: String, category: String, file: String, function: String, line: Int)
    func info(_ message: String, category: String, file: String, function: String, line: Int)
    func warning(_ message: String, category: String, file: String, function: String, line: Int)
    func error(_ message: String, category: String, file: String, function: String, line: Int)
    func critical(_ message: String, category: String, file: String, function: String, line: Int)
}

// MARK: - App Logger
class AppLogger: LoggerProtocol {
    static let shared = AppLogger()
    
    private let osLog = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "StakeOnYou", category: "App")
    private let dateFormatter = DateFormatter()
    
    private init() {
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    }
    
    func log(_ level: LogLevel, message: String, category: String, file: String, function: String, line: Int) {
        let timestamp = dateFormatter.string(from: Date())
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        
        let logMessage = "\(level.emoji) [\(timestamp)] [\(level.rawValue)] [\(category)] [\(fileName):\(line)] \(function): \(message)"
        
        // Console output
        print(logMessage)
        
        // OS Log (for Console.app and system logs)
        os_log("%{public}@", log: osLog, type: level.osLogType, logMessage)
        
        // TODO: Send to analytics service if enabled and not sensitive
        if level == .error || level == .critical {
            AnalyticsService.shared.trackError(level: level, message: message, category: category)
        }
    }
    
    func debug(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
        log(.debug, message: message, category: category, file: file, function: function, line: line)
    }
    
    func info(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
        log(.info, message: message, category: category, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
        log(.warning, message: message, category: category, file: file, function: function, line: line)
    }
    
    func error(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
        log(.error, message: message, category: category, file: file, function: function, line: line)
    }
    
    func critical(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
        log(.critical, message: message, category: category, file: file, function: function, line: line)
    }
}

// MARK: - Privacy-Conscious Logging
extension AppLogger {
    func logUserAction(_ action: String, category: String = "UserAction") {
        // Log user actions without PII
        info("User performed action: \(action)", category: category)
    }
    
    func logGoalCreation(_ category: String, hasStake: Bool) {
        // Log goal creation without personal details
        info("Goal created - Category: \(category), Has Stake: \(hasStake)", category: "Goal")
    }
    
    func logStakeAction(_ action: String, amount: Decimal, currency: String) {
        // Log stake actions without user identification
        info("Stake \(action) - Amount: \(amount) \(currency)", category: "Staking")
    }
    
    func logPermissionRequest(_ permission: String, granted: Bool) {
        // Log permission requests for analytics
        info("Permission \(permission) \(granted ? "granted" : "denied")", category: "Permissions")
    }
}

// MARK: - Convenience Extensions
func logDebug(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
    AppLogger.shared.debug(message, category: category, file: file, function: function, line: line)
}

func logInfo(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
    AppLogger.shared.info(message, category: category, file: file, function: function, line: line)
}

func logWarning(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
    AppLogger.shared.warning(message, category: category, file: file, function: function, line: line)
}

func logError(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
    AppLogger.shared.error(message, category: category, file: file, function: function, line: line)
}

func logCritical(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
    AppLogger.shared.critical(message, category: category, file: file, function: function, line: line)
}
