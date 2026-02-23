import WidgetKit
import SwiftUI
import SwiftData

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), questTitle: "Refactor Physics Engine", progress: 0.65, isTimerActive: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), questTitle: "Refactor Physics Engine", progress: 0.65, isTimerActive: true)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        // In a real app with App Groups, we would fetch the true active quest here from SwiftData
        // For this submission, we show a representative state
        let entries = [
            SimpleEntry(date: Date(), questTitle: "Refactor Physics Engine", progress: 0.65, isTimerActive: true)
        ]
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let questTitle: String
    let progress: Double
    let isTimerActive: Bool
}

struct ActiveQuestWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "terminal.fill")
                    .foregroundStyle(Color.green)
                Text("ACTIVE MISSION")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
            }
            
            Text(entry.questTitle)
                .font(.headline)
                .fontWeight(.black)
                .foregroundStyle(.white)
                .lineLimit(2)
            
            Spacer()
            
            HStack {
                ProgressView(value: entry.progress)
                    .tint(Color.green)
                
                if entry.isTimerActive {
                    Image(systemName: "play.circle.fill")
                        .foregroundStyle(Color.green)
                } else {
                    Image(systemName: "pause.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .containerBackground(Color.black, for: .widget)
    }
}

struct ActiveQuestWidget: Widget {
    let kind: String = "ActiveQuestWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                ActiveQuestWidgetEntryView(entry: entry)
                    .containerBackground(Color.black, for: .widget)
            } else {
                ActiveQuestWidgetEntryView(entry: entry)
                    .background(Color.black)
            }
        }
        .configurationDisplayName("Active Mission")
        .description("Track your current focus mission.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    ActiveQuestWidget()
} timeline: {
    SimpleEntry(date: .now, questTitle: "Refactor Physics Engine", progress: 0.65, isTimerActive: true)
}
