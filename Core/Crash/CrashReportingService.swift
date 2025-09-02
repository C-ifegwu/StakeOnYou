import Foundation

public protocol CrashReportingService: AnyObject {
    func start()
    func capture(error: Error, context: [String: String]?)
    func setUser(id: String?, email: String?)
    func addBreadcrumb(_ message: String)
}

public final class DefaultCrashReportingService: CrashReportingService {
    public static let shared = DefaultCrashReportingService()
    private init() {}

    public func start() {
        // Hook third-party SDK initialization here (e.g., SentrySDK.start or Crashlytics)
        // For now, no-op.
    }

    public func capture(error: Error, context: [String: String]? = nil) {
        #if DEBUG
        print("[CrashReporter] Captured error: \(error) context: \(context ?? [:])")
        #endif
    }

    public func setUser(id: String?, email: String?) {
        #if DEBUG
        print("[CrashReporter] Set user id=\(id ?? "nil") email=\(email ?? "nil")")
        #endif
    }

    public func addBreadcrumb(_ message: String) {
        #if DEBUG
        print("[CrashReporter] Breadcrumb: \(message)")
        #endif
    }
}


