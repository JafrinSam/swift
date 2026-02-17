import SwiftUI
import SwiftData

@main
struct MyApp: App {
    // This creates the SQLite container for all your data types
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Hero.self,
            Quest.self,
            SubQuest.self,
            Session.self,
            Snippet.self,
            TodoItem.self,
            StandupNote.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(sharedModelContainer)
    }
}
