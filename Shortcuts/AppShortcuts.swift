import AppIntents
import SwiftUI

struct StartFocusIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Focus Session"
    static var description = IntentDescription("Opens the Command Center to start a focus session.")
    static var openAppWhenRun: Bool = true
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Here we would ideally find the active quest and start it.
        // For now, we open the app to the Command Center.
        return .result(dialog: "Opening Command Center...")
    }
}

struct ForgeFlowShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartFocusIntent(),
            phrases: [
                "Start Focus Session in \(.applicationName)",
                "Open Command Center in \(.applicationName)",
                "Initialize Mission in \(.applicationName)"
            ],
            shortTitle: "Start Focus",
            systemImageName: "terminal.fill"
        )
    }
}
