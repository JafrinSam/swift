import Foundation
import SwiftData
import SwiftUI

@Model
class DevProfile {
    // MARK: - Identity & Leveling
    var name: String = "Dev_User"
    var level: Int = 1
    var currentXP: Int = 0
    var maxXP: Int = 100
    var nanobytes: Int = 0 // Formerly "Gold"
    var identity: DeveloperIdentity = DeveloperIdentity.fullStack
    
    // MARK: - Burnout Engine (The Innovation)
    /// Ranges from 0.0 (Fresh) to 1.0 (Critical Burnout)
    var burnoutLevel: Double = 0.0
    var lastActivityTimestamp: Date = Date()
    var totalFocusMinutes: Double = 0.0
    var streakDays: Int = 1
    
    // MARK: - Unlocks
    var unlockedThemes: [String] = ["theme_default"]
    var equippedTheme: String = "theme_default"

    init(name: String = "New Developer", identity: DeveloperIdentity = .fullStack) {
        self.name = name
        self.identity = identity
        self.level = 1
        self.currentXP = 0
        self.maxXP = 100
        self.nanobytes = 0
        self.burnoutLevel = 0.0
        self.lastActivityTimestamp = Date()
    }

    // MARK: - Core Logic
    
    /// Adds XP while calculating the Burnout Penalty
    func addXP(amount: Int, difficulty: Double = 1.0) {
        refreshBurnout() // First, see how much we've recovered since last time
        
        // 1. Calculate Multiplier (Wellness Logic)
        // If burnout is over 70%, you only get half XP.
        // This encourages the user to take a break.
        let wellnessMultiplier = burnoutLevel > 0.7 ? 0.5 : 1.0
        let finalXP = Int(Double(amount) * wellnessMultiplier)
        
        // 2. Apply Rewards
        currentXP += finalXP
        nanobytes += (finalXP / 2) // Passive credit gain
        
        // 3. Increase Burnout
        // Harder tasks increase burnout faster
        let burnoutIncrease = 0.05 * difficulty
        burnoutLevel = min(1.0, burnoutLevel + burnoutIncrease)
        
        // 4. Update Activity
        lastActivityTimestamp = Date()
        
        // 5. Check for Level Up
        if currentXP >= maxXP {
            levelUp()
        }
    }

    /// Automatically reduces burnout based on time elapsed since the last work session
    func refreshBurnout() {
        let secondsSinceLastWork = Date().timeIntervalSince(lastActivityTimestamp)
        let hoursSinceLastWork = secondsSinceLastWork / 3600
        
        if hoursSinceLastWork > 0.5 {
            // Recovery Rate: 20% burnout reduction per hour of rest
            let recovery = hoursSinceLastWork * 0.2
            burnoutLevel = max(0.0, burnoutLevel - recovery)
        }
    }

    private func levelUp() {
        currentXP -= maxXP
        level += 1
        maxXP = level * 120 // Progression gets harder
        nanobytes += 100 // Level up bonus
        
        // Haptic feedback should be triggered in the View,
        // but we record the logic here.
    }
    
    // MARK: - Computed Properties for UI
    var burnoutStatus: BurnoutStatus {
        if burnoutLevel < 0.3 { return .optimal }
        if burnoutLevel < 0.7 { return .strained }
        return .critical
    }
}

// MARK: - Enums & Supporting Types

enum DeveloperIdentity: String, Codable, CaseIterable {
    case security = "Security Engineer"
    case ai = "AI Architect"
    case fullStack = "Full Stack Dev"
    case mobile = "iOS Specialist"
    
    var icon: String {
        switch self {
        case .security: return "shield.shared.off.fill"
        case .ai: return "brain.head.profile"
        case .fullStack: return "layers.fill"
        case .mobile: return "iphone.gen3"
        }
    }
}

enum BurnoutStatus {
    case optimal, strained, critical
    
    var label: String {
        switch self {
        case .optimal: return "SYSTEM OPTIMAL"
        case .strained: return "STRESS DETECTED"
        case .critical: return "THERMAL OVERLOAD"
        }
    }
    
    var color: Color {
        switch self {
        case .optimal: return .toxicLime
        case .strained: return .ballisticOrange
        case .critical: return .alertRed
        }
    }
}
