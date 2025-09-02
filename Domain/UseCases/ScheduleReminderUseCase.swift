import Foundation
import Combine
import UserNotifications

// MARK: - Schedule Reminder Use Case
struct ScheduleReminderUseCase {
    private let notificationRepository: NotificationRepository
    private let goalRepository: GoalRepository
    private let userRepository: UserRepository
    private let notificationScheduler: LocalNotificationScheduler
    private let analyticsService: AnalyticsService
    
    init(
        notificationRepository: NotificationRepository,
        goalRepository: GoalRepository,
        userRepository: UserRepository,
        notificationScheduler: LocalNotificationScheduler,
        analyticsService: AnalyticsService
    ) {
        self.notificationRepository = notificationRepository
        self.goalRepository = goalRepository
        self.userRepository = userRepository
        self.notificationScheduler = notificationScheduler
        self.analyticsService = analyticsService
    }
    
    func execute(request: ReminderRequest) async throws -> ScheduledReminder {
        // Track analytics
        analyticsService.track(event: .reminderScheduled(
            userId: request.userId,
            goalId: request.goalId,
            reminderType: request.reminderType
        ))
        
        // Validate reminder request
        try validateReminderRequest(request)
        
        // Create notification content
        let content = try await createNotificationContent(for: request)
        
        // Schedule the notification
        let scheduledReminder = try await notificationScheduler.scheduleNotification(
            content: content,
            trigger: request.trigger,
            identifier: request.identifier
        )
        
        // Save to repository
        let reminder = ScheduledReminder(
            id: scheduledReminder.id,
            userId: request.userId,
            goalId: request.goalId,
            title: request.title,
            message: request.message,
            reminderType: request.reminderType,
            scheduledDate: request.trigger.scheduledDate,
            isActive: true,
            notificationId: scheduledReminder.notificationId,
            metadata: request.metadata
        )
        
        try await notificationRepository.saveReminder(reminder)
        
        return reminder
    }
    
    func scheduleGoalReminders(for goal: Goal, userId: String) async throws -> [ScheduledReminder] {
        var reminders: [ScheduledReminder] = []
        
        // Schedule deadline reminder (1 day before)
        let deadlineReminder = try await scheduleDeadlineReminder(for: goal, userId: userId)
        reminders.append(deadlineReminder)
        
        // Schedule milestone reminders
        let milestoneReminders = try await scheduleMilestoneReminders(for: goal, userId: userId)
        reminders.append(contentsOf: milestoneReminders)
        
        // Schedule progress check reminders (weekly)
        let progressReminder = try await scheduleProgressReminder(for: goal, userId: userId)
        reminders.append(progressReminder)
        
        // Schedule verification reminders if applicable
        if goal.verificationMethod != .none {
            let verificationReminder = try await scheduleVerificationReminder(for: goal, userId: userId)
            reminders.append(verificationReminder)
        }
        
        return reminders
    }
    
    func cancelReminder(reminderId: String, userId: String) async throws {
        let reminder = try await notificationRepository.getReminder(id: reminderId)
        
        guard reminder.userId == userId else {
            throw ReminderError.unauthorized
        }
        
        // Cancel the notification
        try await notificationScheduler.cancelNotification(identifier: reminder.notificationId)
        
        // Update repository
        try await notificationRepository.updateReminderStatus(
            reminderId: reminderId,
            isActive: false
        )
        
        // Track cancellation
        analyticsService.track(event: .reminderCancelled(
            userId: userId,
            reminderId: reminderId,
            goalId: reminder.goalId
        ))
    }
    
    func updateReminder(reminderId: String, request: ReminderUpdateRequest) async throws -> ScheduledReminder {
        let reminder = try await notificationRepository.getReminder(id: reminderId)
        
        guard reminder.userId == request.userId else {
            throw ReminderError.unauthorized
        }
        
        // Cancel existing notification
        try await notificationScheduler.cancelNotification(identifier: reminder.notificationId)
        
        // Create new notification content
        let content = try await createNotificationContent(for: request.toReminderRequest())
        
        // Schedule updated notification
        let scheduledReminder = try await notificationScheduler.scheduleNotification(
            content: content,
            trigger: request.trigger,
            identifier: request.identifier ?? reminderId
        )
        
        // Update repository
        let updatedReminder = ScheduledReminder(
            id: reminderId,
            userId: request.userId,
            goalId: request.goalId ?? reminder.goalId,
            title: request.title ?? reminder.title,
            message: request.message ?? reminder.message,
            reminderType: request.reminderType ?? reminder.reminderType,
            scheduledDate: request.trigger.scheduledDate,
            isActive: true,
            notificationId: scheduledReminder.notificationId,
            metadata: request.metadata ?? reminder.metadata
        )
        
        try await notificationRepository.updateReminder(updatedReminder)
        
        // Track update
        analyticsService.track(event: .reminderUpdated(
            userId: request.userId,
            reminderId: reminderId,
            goalId: updatedReminder.goalId
        ))
        
        return updatedReminder
    }
    
    func getUserReminders(userId: String, activeOnly: Bool = true) async throws -> [ScheduledReminder] {
        return try await notificationRepository.getUserReminders(userId: userId, activeOnly: activeOnly)
    }
    
    func getGoalReminders(goalId: String, userId: String) async throws -> [ScheduledReminder] {
        return try await notificationRepository.getGoalReminders(goalId: goalId, userId: userId)
    }
    
    func scheduleRecurringReminder(request: RecurringReminderRequest) async throws -> [ScheduledReminder] {
        var reminders: [ScheduledReminder] = []
        
        let dates = generateRecurringDates(for: request)
        
        for (index, date) in dates.enumerated() {
            let trigger = NotificationTrigger.scheduledDate(date)
            let identifier = "\(request.identifier)_\(index)"
            
            let reminderRequest = ReminderRequest(
                userId: request.userId,
                goalId: request.goalId,
                title: request.title,
                message: request.message,
                reminderType: request.reminderType,
                trigger: trigger,
                identifier: identifier,
                metadata: request.metadata
            )
            
            let reminder = try await execute(request: reminderRequest)
            reminders.append(reminder)
        }
        
        return reminders
    }
    
    // MARK: - Private Methods
    
    private func validateReminderRequest(_ request: ReminderRequest) throws {
        guard !request.title.isEmpty else {
            throw ReminderError.invalidTitle
        }
        
        guard !request.message.isEmpty else {
            throw ReminderError.invalidMessage
        }
        
        guard request.scheduledDate > Date() else {
            throw ReminderError.pastDate
        }
        
        // Check if user has permission to schedule notifications
        guard await notificationScheduler.hasPermission() else {
            throw ReminderError.notificationPermissionDenied
        }
    }
    
    private func createNotificationContent(for request: ReminderRequest) async throws -> UNNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = request.title
        content.body = request.message
        content.sound = .default
        
        // Add category identifier for actions
        content.categoryIdentifier = "GOAL_REMINDER"
        
        // Add user info for deep linking
        content.userInfo = [
            "reminder_id": request.identifier,
            "goal_id": request.goalId ?? "",
            "user_id": request.userId,
            "reminder_type": request.reminderType.rawValue
        ]
        
        return content
    }
    
    private func scheduleDeadlineReminder(for goal: Goal, userId: String) async throws -> ScheduledReminder {
        let deadlineDate = goal.deadline
        let reminderDate = Calendar.current.date(byAdding: .day, value: -1, to: deadlineDate) ?? deadlineDate
        
        let request = ReminderRequest(
            userId: userId,
            goalId: goal.id,
            title: "Goal Deadline Tomorrow",
            message: "Your goal '\(goal.title)' is due tomorrow. Don't forget to complete it!",
            reminderType: .deadline,
            trigger: .scheduledDate(reminderDate),
            identifier: "deadline_\(goal.id)",
            metadata: ["goal_deadline": deadlineDate.timeIntervalSince1970.description]
        )
        
        return try await execute(request: request)
    }
    
    private func scheduleMilestoneReminders(for goal: Goal, userId: String) async throws -> [ScheduledReminder] {
        var reminders: [ScheduledReminder] = []
        
        for milestone in goal.milestones {
            let reminderDate = Calendar.current.date(byAdding: .day, value: -1, to: milestone.dueDate) ?? milestone.dueDate
            
            let request = ReminderRequest(
                userId: userId,
                goalId: goal.id,
                title: "Milestone Due Tomorrow",
                message: "Your milestone '\(milestone.title)' for goal '\(goal.title)' is due tomorrow.",
                reminderType: .milestone,
                trigger: .scheduledDate(reminderDate),
                identifier: "milestone_\(milestone.id)",
                metadata: [
                    "milestone_id": milestone.id,
                    "milestone_due_date": milestone.dueDate.timeIntervalSince1970.description
                ]
            )
            
            let reminder = try await execute(request: request)
            reminders.append(reminder)
        }
        
        return reminders
    }
    
    private func scheduleProgressReminder(for goal: Goal, userId: String) async throws -> ScheduledReminder {
        let startDate = goal.createdAt
        let endDate = goal.deadline
        let duration = endDate.timeIntervalSince(startDate)
        let weeklyInterval = duration / 7.0
        
        let reminderDate = startDate.addingTimeInterval(weeklyInterval)
        
        let request = ReminderRequest(
            userId: userId,
            goalId: goal.id,
            title: "Goal Progress Check",
            message: "How's your progress on '\(goal.title)'? Take a moment to update your progress.",
            reminderType: .progress,
            trigger: .scheduledDate(reminderDate),
            identifier: "progress_\(goal.id)",
            metadata: ["progress_check_interval": "weekly"]
        )
        
        return try await execute(request: request)
    }
    
    private func scheduleVerificationReminder(for goal: Goal, userId: String) async throws -> ScheduledReminder {
        let deadlineDate = goal.deadline
        let reminderDate = Calendar.current.date(byAdding: .hour, value: -2, to: deadlineDate) ?? deadlineDate
        
        let request = ReminderRequest(
            userId: userId,
            goalId: goal.id,
            title: "Submit Goal Verification",
            message: "Your goal '\(goal.title)' is due in 2 hours. Don't forget to submit your verification!",
            reminderType: .verification,
            trigger: .scheduledDate(reminderDate),
            identifier: "verification_\(goal.id)",
            metadata: ["verification_deadline": deadlineDate.timeIntervalSince1970.description]
        )
        
        return try await execute(request: request)
    }
    
    private func generateRecurringDates(for request: RecurringReminderRequest) -> [Date] {
        var dates: [Date] = []
        let calendar = Calendar.current
        let startDate = request.startDate
        let endDate = request.endDate ?? startDate.addingTimeInterval(365 * 24 * 60 * 60) // Default to 1 year
        
        var currentDate = startDate
        
        while currentDate <= endDate {
            dates.append(currentDate)
            
            switch request.frequency {
            case .daily:
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            case .weekly:
                currentDate = calendar.date(byAdding: .weekOfYear, value: 1, to: currentDate) ?? currentDate
            case .monthly:
                currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate
            case .custom(let interval):
                currentDate = calendar.date(byAdding: .day, value: interval, to: currentDate) ?? currentDate
            }
        }
        
        return dates
    }
}

// MARK: - Supporting Structures
struct ReminderRequest: Codable, Equatable {
    let userId: String
    let goalId: String?
    let title: String
    let message: String
    let reminderType: ReminderType
    let trigger: NotificationTrigger
    let identifier: String
    let metadata: [String: String]
    
    var scheduledDate: Date {
        trigger.scheduledDate
    }
}

struct ReminderUpdateRequest: Codable, Equatable {
    let userId: String
    let goalId: String?
    let title: String?
    let message: String?
    let reminderType: ReminderType?
    let trigger: NotificationTrigger
    let identifier: String?
    let metadata: [String: String]?
    
    func toReminderRequest() -> ReminderRequest {
        ReminderRequest(
            userId: userId,
            goalId: goalId,
            title: title ?? "",
            message: message ?? "",
            reminderType: reminderType ?? .general,
            trigger: trigger,
            identifier: identifier ?? UUID().uuidString,
            metadata: metadata ?? [:]
        )
    }
}

struct RecurringReminderRequest: Codable, Equatable {
    let userId: String
    let goalId: String?
    let title: String
    let message: String
    let reminderType: ReminderType
    let frequency: ReminderFrequency
    let startDate: Date
    let endDate: Date?
    let identifier: String
    let metadata: [String: String]
}

struct ScheduledReminder: Identifiable, Codable, Equatable {
    let id: String
    let userId: String
    let goalId: String?
    let title: String
    let message: String
    let reminderType: ReminderType
    let scheduledDate: Date
    let isActive: Bool
    let notificationId: String
    let metadata: [String: String]
    
    init(
        id: String = UUID().uuidString,
        userId: String,
        goalId: String?,
        title: String,
        message: String,
        reminderType: ReminderType,
        scheduledDate: Date,
        isActive: Bool = true,
        notificationId: String,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.userId = userId
        self.goalId = goalId
        self.title = title
        self.message = message
        self.reminderType = reminderType
        self.scheduledDate = scheduledDate
        self.isActive = isActive
        self.notificationId = notificationId
        self.metadata = metadata
    }
}

enum ReminderType: String, Codable, CaseIterable {
    case deadline = "deadline"
    case milestone = "milestone"
    case progress = "progress"
    case verification = "verification"
    case general = "general"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .deadline: return "Deadline"
        case .milestone: return "Milestone"
        case .progress: return "Progress"
        case .verification: return "Verification"
        case .general: return "General"
        case .custom: return "Custom"
        }
    }
    
    var iconName: String {
        switch self {
        case .deadline: return "clock"
        case .milestone: return "flag"
        case .progress: return "chart.line.uptrend.xyaxis"
        case .verification: return "checkmark.shield"
        case .general: return "bell"
        case .custom: return "gear"
        }
    }
}

enum ReminderFrequency: Codable, Equatable {
    case daily
    case weekly
    case monthly
    case custom(interval: Int) // days
    
    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .custom(let interval): return "Every \(interval) days"
        }
    }
}

enum NotificationTrigger: Codable, Equatable {
    case scheduledDate(Date)
    case timeInterval(TimeInterval, repeats: Bool)
    case calendar(Calendar, dateComponents: DateComponents, repeats: Bool)
    
    var scheduledDate: Date {
        switch self {
        case .scheduledDate(let date):
            return date
        case .timeInterval(let interval, _):
            return Date().addingTimeInterval(interval)
        case .calendar(_, let components, _):
            return Calendar.current.date(from: components) ?? Date()
        }
    }
}

// MARK: - Repository Protocol
protocol NotificationRepository {
    func saveReminder(_ reminder: ScheduledReminder) async throws
    func getReminder(id: String) async throws -> ScheduledReminder
    func updateReminder(_ reminder: ScheduledReminder) async throws
    func updateReminderStatus(reminderId: String, isActive: Bool) async throws
    func getUserReminders(userId: String, activeOnly: Bool) async throws -> [ScheduledReminder]
    func getGoalReminders(goalId: String, userId: String) async throws -> [ScheduledReminder]
    func deleteReminder(reminderId: String) async throws
}

// MARK: - Notification Scheduler Protocol
protocol LocalNotificationScheduler {
    func scheduleNotification(
        content: UNNotificationContent,
        trigger: NotificationTrigger,
        identifier: String
    ) async throws -> ScheduledNotification
    
    func cancelNotification(identifier: String) async throws
    func hasPermission() async -> Bool
    func requestPermission() async -> Bool
}

struct ScheduledNotification: Codable, Equatable {
    let id: String
    let notificationId: String
    let scheduledDate: Date
    let isActive: Bool
}

// MARK: - Errors
enum ReminderError: LocalizedError {
    case invalidTitle
    case invalidMessage
    case pastDate
    case notificationPermissionDenied
    case unauthorized
    case reminderNotFound
    case schedulingFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidTitle:
            return "Reminder title cannot be empty"
        case .invalidMessage:
            return "Reminder message cannot be empty"
        case .pastDate:
            return "Cannot schedule reminders in the past"
        case .notificationPermissionDenied:
            return "Notification permission is required to schedule reminders"
        case .unauthorized:
            return "You are not authorized to modify this reminder"
        case .reminderNotFound:
            return "Reminder not found"
        case .schedulingFailed(let reason):
            return "Failed to schedule reminder: \(reason)"
        }
    }
}

// MARK: - Analytics Events
extension AnalyticsEvent {
    static func reminderScheduled(
        userId: String,
        goalId: String?,
        reminderType: ReminderType
    ) -> AnalyticsEvent {
        var properties: [String: Any] = [
            "user_id": userId,
            "reminder_type": reminderType.rawValue,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if let goalId = goalId {
            properties["goal_id"] = goalId
        }
        
        return AnalyticsEvent(
            name: "reminder_scheduled",
            properties: properties
        )
    }
    
    static func reminderCancelled(
        userId: String,
        reminderId: String,
        goalId: String?
    ) -> AnalyticsEvent {
        var properties: [String: Any] = [
            "user_id": userId,
            "reminder_id": reminderId,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if let goalId = goalId {
            properties["goal_id"] = goalId
        }
        
        return AnalyticsEvent(
            name: "reminder_cancelled",
            properties: properties
        )
    }
    
    static func reminderUpdated(
        userId: String,
        reminderId: String,
        goalId: String?
    ) -> AnalyticsEvent {
        var properties: [String: Any] = [
            "user_id": userId,
            "reminder_id": reminderId,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if let goalId = goalId {
            properties["goal_id"] = goalId
        }
        
        return AnalyticsEvent(
            name: "reminder_updated",
            properties: properties
        )
    }
}
