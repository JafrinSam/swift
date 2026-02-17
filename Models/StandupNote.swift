import Foundation
import SwiftData

@Model
class StandupNote {
    var id: UUID = UUID()
    var date: Date = Date()
    var yesterday: String = ""
    var today: String = ""
    var blockers: String = ""
    var createdAt: Date = Date()
    
    init(date: Date = Date(), yesterday: String = "", today: String = "", blockers: String = "") {
        self.id = UUID()
        self.date = date
        self.yesterday = yesterday
        self.today = today
        self.blockers = blockers
        self.createdAt = Date()
    }
    
    /// Checks if the note has any content
    var isEmpty: Bool {
        yesterday.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        today.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        blockers.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Formatted date for display
    var dayLabel: String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }
    
    /// Full date for section headers
    var fullDateLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d, yyyy"
        return formatter.string(from: date)
    }
    
    /// Shareable plain-text output
    var shareText: String {
        var text = "📋 Standup — \(fullDateLabel)\n"
        text += "━━━━━━━━━━━━━━━━━━━━\n"
        if !yesterday.isEmpty { text += "✅ Yesterday:\n\(yesterday)\n\n" }
        if !today.isEmpty { text += "🎯 Today:\n\(today)\n\n" }
        if !blockers.isEmpty { text += "🚧 Blockers:\n\(blockers)\n" }
        return text
    }
}
