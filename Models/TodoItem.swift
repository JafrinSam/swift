import Foundation
import SwiftData

enum TodoPriority: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
    
    var xpReward: Int {
        switch self {
        case .low: return 5
        case .medium: return 10
        case .high: return 20
        case .critical: return 40
        }
    }
    
    var sortOrder: Int {
        switch self {
        case .critical: return 0
        case .high: return 1
        case .medium: return 2
        case .low: return 3
        }
    }
}

enum ReminderOffset: String, Codable, CaseIterable {
    case atTime = "At Time"
    case fiveMin = "5 min before"
    case fifteenMin = "15 min before"
    case thirtyMin = "30 min before"
    case oneHour = "1 hour before"
    case oneDay = "1 day before"
    
    var seconds: TimeInterval {
        switch self {
        case .atTime: return 0
        case .fiveMin: return 5 * 60
        case .fifteenMin: return 15 * 60
        case .thirtyMin: return 30 * 60
        case .oneHour: return 60 * 60
        case .oneDay: return 24 * 60 * 60
        }
    }
}

@Model
class TodoItem {
    var id: UUID = UUID()
    var title: String = ""
    var notes: String = ""
    var dueDate: Date = Date()
    var reminderOffset: ReminderOffset = ReminderOffset.atTime
    var priority: TodoPriority = TodoPriority.medium
    var isCompleted: Bool = false
    var completedAt: Date?
    var createdAt: Date = Date()
    
    init(
        title: String,
        notes: String = "",
        dueDate: Date,
        reminderOffset: ReminderOffset = .atTime,
        priority: TodoPriority = .medium
    ) {
        self.id = UUID()
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.reminderOffset = reminderOffset
        self.priority = priority
        self.isCompleted = false
        self.createdAt = Date()
    }
    
    var isOverdue: Bool {
        !isCompleted && dueDate < Date()
    }
    
    var reminderDate: Date {
        dueDate.addingTimeInterval(-reminderOffset.seconds)
    }
    
    var notificationID: String {
        "todo_\(id.uuidString)"
    }
}
