import SwiftUI

struct LiveQuestTimer: View {
    @Bindable var quest: Quest
    
    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0)) { context in
            Text(formattedDuration(date: context.date))
                .font(.system(.body, design: .monospaced))
                .bold()
                .foregroundStyle(Color.toxicLime)
        }
    }
    
    private func formattedDuration(date: Date) -> String {
        var currentSession: TimeInterval = 0
        if quest.isTimerActive, let start = quest.lastStartedAt {
            currentSession = date.timeIntervalSince(start)
        }
        
        let total = quest.timeSpent + currentSession
        
        let hours = Int(total) / 3600
        let minutes = (Int(total) % 3600) / 60
        let seconds = Int(total) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}
