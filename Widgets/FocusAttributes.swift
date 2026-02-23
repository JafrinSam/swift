#if false // Change to 'canImport(ActivityKit)' to enable Live Activities on device
import ActivityKit
import SwiftUI

// Attributes for the Live Activity
struct FocusAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic state that updates (e.g., remaining time)
        var endTime: Date
    }

    // Static data (e.g., mission name)
    var missionName: String
}
#endif
