import Foundation
import UserNotifications

final class ScheduleLocalNotificationUseCase {
    func execute(id: String = UUID().uuidString, title: String, body: String, at date: Date, userInfo: [AnyHashable: Any] = [:]) async throws {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.userInfo = userInfo
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        try await center.add(request)
    }
}


