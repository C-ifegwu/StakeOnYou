import Foundation

public struct AuditEvent: Equatable, Codable {
	public let id: String
	public let action: String
	public let entityType: String
	public let entityId: String
	public let userId: String?
	public let metadata: [String: String]
	public let createdAt: Date
	public init(id: String = UUID().uuidString, action: String, entityType: String, entityId: String, userId: String?, metadata: [String: String], createdAt: Date = Date()) {
		self.id = id
		self.action = action
		self.entityType = entityType
		self.entityId = entityId
		self.userId = userId
		self.metadata = metadata
		self.createdAt = createdAt
	}
}

public protocol AuditService: AnyObject {
	func log(_ event: AuditEvent) async
}

public final class MockAuditService: AuditService {
	public init() {}
	public private(set) var events: [AuditEvent] = []
	public func log(_ event: AuditEvent) async {
		events.append(event)
	}
}
