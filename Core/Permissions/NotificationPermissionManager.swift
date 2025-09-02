import Foundation
import UserNotifications

final class NotificationPermissionManager {
    static let shared = NotificationPermissionManager()
    private init() {}

    func requestAuthorizationIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let current = await center.notificationSettings()
        guard current.authorizationStatus == .notDetermined else { return }
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            #if DEBUG
            print("Notifications permission granted? \(granted)")
            #endif
        } catch {
            #if DEBUG
            print("Notifications permission request failed: \(error)")
            #endif
        }
    }
}


