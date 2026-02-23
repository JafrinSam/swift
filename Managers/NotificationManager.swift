import Foundation
import UserNotifications
import Observation

@Observable
class NotificationManager {
    static let shared = NotificationManager()
    
    var isAuthorized = false
    
    // Using private init to enforce singleton, but allowing overrides for testing if needed
    private init() {
        checkStatus()
    }
    
    // MARK: - Permission Management
    func checkStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = (settings.authorizationStatus == .authorized)
            }
        }
    }
                                                                                                                                                                                                                                                                                              
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
            }
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
    
    // MARK: - Schedule Timer Complete (Live Activity End)
    func scheduleTimerComplete(seconds: TimeInterval, title: String) {
        let content = UNMutableNotificationContent()
        content.title = "Mission Complete"
        content.body = "\(title) mission accomplished. +XP awarded."
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Cancellation
    func cancelNotification(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [id]
        )
    }
    
    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
