import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    // MARK: - Permission
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, error in
            if let error = error {
                print("ForgeFlow: Notification permission error: \(error)")
            }
            print("ForgeFlow: Notifications \(granted ? "enabled" : "denied")")
        }
    }
    
    // MARK: - Schedule a Todo Reminder
    func scheduleTodoReminder(for todo: TodoItem) {
        // Remove any existing notification for this todo
        cancelNotification(id: todo.notificationID)
        
        // Don't schedule if already completed
        guard !todo.isCompleted else { return }
        
        // Don't schedule if reminder date is in the past
        let fireDate = todo.reminderDate
        guard fireDate > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "⚡ ForgeFlow Reminder"
        content.body = todo.title
        if !todo.notes.isEmpty {
            content.subtitle = todo.notes
        }
        content.sound = .default
        content.badge = 1
        
        // Add priority to the notification
        switch todo.priority {
        case .critical:
            content.title = "🚨 CRITICAL Deadline"
            content.interruptionLevel = .critical
        case .high:
            content.title = "⚠️ High Priority Reminder"
            content.interruptionLevel = .timeSensitive
        case .medium:
            content.title = "⚡ ForgeFlow Reminder"
            content.interruptionLevel = .active
        case .low:
            content.title = "📌 Task Reminder"
            content.interruptionLevel = .passive
        }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: fireDate
        )
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: todo.notificationID,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("ForgeFlow: Failed to schedule notification: \(error)")
            } else {
                print("ForgeFlow: Reminder scheduled for \(fireDate)")
            }
        }
    }
    
    // MARK: - Cancel
    func cancelNotification(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [id]
        )
    }
    
    func cancelAllTodoNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
