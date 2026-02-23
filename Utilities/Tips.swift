import SwiftUI
import TipKit

// MARK: - Shared gate: all tips are hidden until the Daily Wisdom screen is dismissed
// Set Tips.appReady = true inside NeuralSyncView's dismiss button.

// MARK: - Burnout Tip
struct BurnoutTip: Tip {
    @Parameter static var appReady: Bool = false

    var rules: [Rule] {
        [#Rule(Self.$appReady) { $0 == true }]
    }

    var title: Text {
        Text("Manage Your Burnout")
    }

    var message: Text? {
        Text("Working too long without breaks increases burnout. High burnout reduces XP gain! Take recharge breaks to recover.")
    }

    var image: Image? {
        Image(systemName: "flame.fill")
    }
}

// MARK: - Flow Mode Tip
struct FlowModeTip: Tip {
    var rules: [Rule] {
        [#Rule(BurnoutTip.$appReady) { $0 == true }]
    }

    var title: Text {
        Text("Enter Flow State")
    }

    var message: Text? {
        Text("Flow Mode has no time limit. Use it for deep work sessions where you don't want to be interrupted by a timer.")
    }

    var image: Image? {
        Image(systemName: "infinity")
    }
}

// MARK: - Boss Quest Tip
struct BossQuestTip: Tip {
    var rules: [Rule] {
        [#Rule(BurnoutTip.$appReady) { $0 == true }]
    }

    var title: Text {
        Text("Conquer Technical Debt")
    }

    var message: Text? {
        Text("Boss Quests represent Technical Debt. They are harder but grant double XP upon completion!")
    }

    var image: Image? {
        Image(systemName: "exclamationmark.triangle.fill")
    }
}

// MARK: - XP Tip
struct XPTip: Tip {
    var rules: [Rule] {
        [#Rule(BurnoutTip.$appReady) { $0 == true }]
    }

    var title: Text {
        Text("Level Up Your Profile")
    }

    var message: Text? {
        Text("Complete quests to earn XP. Leveling up unlocks new titles and restores system integrity.")
    }

    var image: Image? {
        Image(systemName: "trophy.fill")
    }
}
