import Foundation
import SwiftData

enum QuestDifficulty: String, Codable, CaseIterable {
    case routine = "Routine"   // Formerly Easy
    case complex = "Complex"   // Formerly Medium
    case legacy  = "Legacy"    // Formerly Hard (The Boss)
    
    var xpReward: Int {
        switch self {
        case .routine: return 10
        case .complex: return 25
        case .legacy:  return 50
        }
    }
    
    var burnoutImpact: Double {
        switch self {
        case .routine: return 0.03
        case .complex: return 0.07
        case .legacy:  return 0.15 // Legacy code is mentally draining
        }
    }
}
@Model
class SubQuest {
    var id: UUID = UUID()
    var title: String = ""
    var difficulty: QuestDifficulty = QuestDifficulty.routine
    var isCompleted: Bool = false
    
    // Timer Properties
    var timeSpent: TimeInterval = 0
    var lastStartedAt: Date? = nil
    var isTimerActive: Bool = false
    
    // Relationship: Links back to the parent Quest
    var parentQuest: Quest?

    init(title: String, difficulty: QuestDifficulty = .routine) {
        self.title = title
        self.difficulty = difficulty
        self.id = UUID()
        self.isCompleted = false
        self.timeSpent = 0
        self.isTimerActive = false
    }
}

@Model
class Quest {
    var title: String = ""
    var details: String = ""
    var isCompleted: Bool = false
    var createdAt: Date = Date()
    var isActive: Bool = false
    
    // Timer Properties
    var timeSpent: TimeInterval = 0
    var lastStartedAt: Date? = nil
    var isTimerActive: Bool = false
    var isFlowMode: Bool = false
    var voiceNotePath: String? = nil
    
    // RELATIONSHIP: Cascade delete ensures clean data management
    @Relationship(deleteRule: .cascade, inverse: \SubQuest.parentQuest) 
    var subQuests: [SubQuest] = []
    
    init(title: String, details: String = "") {
        self.title = title
        self.details = details
        self.isCompleted = false
        self.createdAt = Date()
        self.isActive = false
        self.timeSpent = 0
        self.isTimerActive = false
        self.subQuests = []
    }
    
    // MARK: - Advanced Logic
    
    /// Total XP including a "Clean Code" bonus for completion
    var totalXP: Int {
        let subXP = subQuests.reduce(0) { $0 + $1.difficulty.xpReward }
        let bonus = isBoss ? 100 : 50 // Double reward for conquering Technical Debt
        return subXP + bonus
    }
    
    /// TECHNICAL DEBT: If a module is ignored for > 3 days, it mutates into a "Boss"
    var isBoss: Bool {
        let ageInSeconds = Date().timeIntervalSince(createdAt)
        return !isCompleted && ageInSeconds > 259200 
    }
    
    /// Calculates progress based on sub-module completion
    var progress: Double {
        guard !subQuests.isEmpty else { return isCompleted ? 1.0 : 0.0 }
        let completedCount = subQuests.filter { $0.isCompleted }.count
        return Double(completedCount) / Double(subQuests.count)
    }
    
    /// Aggregates all time spent across main module and sub-tasks
    var totalTimeSpent: TimeInterval {
        let mainTime = timeSpent + (isTimerActive ? Date().timeIntervalSince(lastStartedAt ?? Date()) : 0)
        let subTime = subQuests.reduce(0) { total, sub in
            let active = sub.isTimerActive ? Date().timeIntervalSince(sub.lastStartedAt ?? Date()) : 0
            return total + sub.timeSpent + active
        }
        return mainTime + subTime
    }
}