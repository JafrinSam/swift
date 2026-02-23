import Foundation
import SwiftData
import SwiftUI

@Model
class Hero {
    // MARK: - Identity & Leveling
    var name: String = "Dev_User"
    var level: Int = 1
    var currentXP: Int = 0
    var maxXP: Int = 100
    var nanobytes: Int = 0
    var identity: String = "Full Stack Dev" // Store as String for SwiftData compatibility
    
    // MARK: - Burnout Engine
    var burnoutLevel: Double = 0.0
    var lastActivityTimestamp: Date = Date()
    var totalFocusMinutes: Double = 0.0
    var streakDays: Int = 1
    var lastResetDate: Date = Date()
    
    // MARK: - Unlocks (stored as comma-separated string for SwiftData compatibility)
    var unlockedItemsRaw: String = "theme_default"
    var equippedTheme: String = "theme_default"
    
    /// Computed accessor for the unlocked items array
    var unlockedItems: [String] {
        get { unlockedItemsRaw.split(separator: ",").map(String.init) }
        set { unlockedItemsRaw = newValue.joined(separator: ",") }
    }

    // MARK: - THE INITIALIZER (The Fix)
    // SwiftData requires this to be explicit
    init(
        name: String = "New Developer",
        identity: String = "Full Stack Dev",
        level: Int = 1,
        currentXP: Int = 0,
        nanobytes: Int = 0
    ) {
        self.name = name
        self.identity = identity
        self.level = level
        self.currentXP = currentXP
        self.maxXP = level * 100
        self.nanobytes = nanobytes
        self.burnoutLevel = 0.0
        self.lastActivityTimestamp = Date()
        self.streakDays = 1
        self.unlockedItemsRaw = "theme_default"
        self.equippedTheme = "theme_default"
    }

    // MARK: - Logic Methods
    
    // MARK: - Logic Methods
    
    func addXP(amount: Int, difficultyMultiplier: Double = 1.0) {
        refreshBurnout()
        
        // Burnout Penalty: If burnout > 80%, XP is halved
        let wellnessMultiplier = burnoutLevel > 0.8 ? 0.5 : 1.0
        let finalXP = Int(Double(amount) * wellnessMultiplier)
        
        currentXP += finalXP
        nanobytes += (finalXP / 2)
        
        // Burnout Increase: Scaled by effort (approx 4% for 25m session)
        // Formula: Base 0.02 + (difficulty * 0.02)
        let burnoutIncrease = 0.02 + (0.02 * difficultyMultiplier)
        burnoutLevel = min(1.0, burnoutLevel + burnoutIncrease)
        
        lastActivityTimestamp = Date()
        
        if currentXP >= maxXP {
            levelUp()
        }
    }

    func refreshBurnout() {
        let secondsSinceLastWork = Date().timeIntervalSince(lastActivityTimestamp)
        let minutesSinceLastWork = secondsSinceLastWork / 60
        
        // Recovery kicks in after 15 minutes of rest (was 30)
        if minutesSinceLastWork > 15 {
            // Passive Recovery: 5% per 15 minutes
            let recoveryPeriods = floor(minutesSinceLastWork / 15)
            let recoveryAmount = recoveryPeriods * 0.05
            burnoutLevel = max(0.0, burnoutLevel - recoveryAmount)
        }
    }
    
    func recoverBurnout(amount: Double) {
        burnoutLevel = max(0.0, burnoutLevel - amount)
    }

    private func levelUp() {
        currentXP -= maxXP
        level += 1
        maxXP = level * 120
        nanobytes += 100
        
        // Level Up heals 20% burnout
        recoverBurnout(amount: 0.20)
    }
}

// MARK: - Daily Reset (System Maintenance)
extension Hero {
    func checkAndResetDailyStats() {
        let calendar = Calendar.current
        
        // Check if the last reset was on a previous day
        if !calendar.isDateInToday(self.lastResetDate) {
            print("ForgeFlow: Midnight Reset initiated. Clearing burnout telemetry...")
            
            // 1. Reset burnout tracking
            self.totalFocusMinutes = 0.0
            self.burnoutLevel = 0.0 // Full restore
            
            // 2. Update the anchor to today
            self.lastResetDate = Date()
        }
    }
}
