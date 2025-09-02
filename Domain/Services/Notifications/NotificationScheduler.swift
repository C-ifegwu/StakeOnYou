import Foundation

public protocol NotificationScheduler: AnyObject {
	func schedule(date: Date, type: AppNotificationType, userIds: [String], context: [String: String]) async
}

public final class MockNotificationScheduler: NotificationScheduler {
	public init() {}
	public private(set) var scheduled: [(Date, AppNotificationType, [String], [String: String])] = []
	public func schedule(date: Date, type: AppNotificationType, userIds: [String], context: [String: String]) async {
		scheduled.append((date, type, userIds, context))
	}
}
