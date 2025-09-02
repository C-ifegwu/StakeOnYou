import Foundation

public enum AppNotificationType: String, Equatable {
	case escrowHeld
	case preDeadlineReminder
	case accrualUpdate
	case goalCompletedSuccess
	case goalCompletedFailure
	case distributionExecuted
	case disputeFiled
	case disputeResolved
}

public protocol NotificationService: AnyObject {
	func notify(userIds: [String], type: AppNotificationType, title: String, body: String, context: [String: String]) async
}

public final class MockNotificationService: NotificationService {
	public init() {}
	public private(set) var sent: [(userIds: [String], type: AppNotificationType, title: String, body: String, context: [String: String])] = []
	public func notify(userIds: [String], type: AppNotificationType, title: String, body: String, context: [String: String]) async {
		sent.append((userIds, type, title, body, context))
	}
}
