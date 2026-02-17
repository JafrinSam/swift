import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Query private var heroes: [Hero]
    @Query(filter: #Predicate<Quest> { $0.isCompleted }) private var completedQuests: [Quest]
    @Query(sort: \Session.date, order: .forward) private var sessions: [Session]
    @Environment(\.modelContext) private var modelContext
    
    @State private var showHistory = false
    @State private var showAbout = false
    @State private var showShareStats = false
    
    var hero: Hero { heroes.first ?? Hero() }
    
    // Logic for the Vitality Chart
    private var standardModules: Int { completedQuests.filter { !$0.isBoss }.count }
    private var debtResolved: Int { completedQuests.filter { $0.isBoss }.count }
    
    // Logic for Today's Focus (precision: minutes + seconds)
    private var focusTimeToday: (minutes: Int, seconds: Int) {
        let calendar = Calendar.current
        let todaySessions = sessions.filter { calendar.isDateInToday($0.date) }
        
        let totalSeconds = todaySessions.reduce(0.0) { $0 + $1.duration }
        
        let mins = Int(totalSeconds) / 60
        let secs = Int(totalSeconds) % 60
        return (mins, secs)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.voidBlack.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        
                        // 1. Header: System Identity
                        headerSection
                        
                        // 2. High-Priority Alert: Burnout Monitor
                        if hero.totalFocusMinutes > 240 {
                            BurnoutWarningCard()
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        // 3. Core Stats: Nanobytes & Focus
                        HStack(spacing: 16) {
                            StatBlock(title: "TODAY'S FOCUS", value: "\(focusTimeToday.minutes)m \(focusTimeToday.seconds)s", icon: "timer", color: .electricCyan)
                                .onTapGesture { showHistory = true }
                                .accessibilityLabel("Today's focus: \(focusTimeToday.minutes) minutes \(focusTimeToday.seconds) seconds")
                                .accessibilityHint("Tap to view focus history chart")
                            StatBlock(title: "NANOBYTES", value: "\(hero.nanobytes)", icon: "cpu", color: .toxicLime)
                                .accessibilityLabel("\(hero.nanobytes) nanobytes earned")
                        }
                        .padding(.horizontal)
                        
                        // 4. Completed Quest Timeline (Git Graph)
                        if !completedQuests.isEmpty {
                            QuestTimelineView(quests: completedQuests.sorted { $0.createdAt > $1.createdAt })
                                .padding(.horizontal)
                        }
                        
                        // 5. Vitality Analysis: Debt vs. Development
                        vitalityChartSection
                        
                        // 6. XP Integrity Metric
                        xpIntegrityCard
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Vitality")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showAbout = true } label: {
                        Image(systemName: "info.circle")
                            .foregroundStyle(Color.toxicLime)
                    }
                    .accessibilityLabel("About ForgeFlow")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showShareStats = true } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(Color.toxicLime)
                    }
                    .accessibilityLabel("Share your stats")
                }
            }
            .sheet(isPresented: $showHistory) {
                FocusHistoryView(sessions: sessions)
            }
            .sheet(isPresented: $showAbout) {
                AboutView()
            }
            .sheet(isPresented: $showShareStats) {
                NavigationStack {
                    ZStack {
                        Color.voidBlack.ignoresSafeArea()
                        ShareStatsView(
                            focusMinutes: focusTimeToday.minutes,
                            focusSeconds: focusTimeToday.seconds,
                            level: hero.level,
                            streak: hero.streakDays,
                            nanobytes: hero.nanobytes
                        )
                    }
                    .navigationTitle("Share")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showShareStats = false }
                                .foregroundStyle(Color.toxicLime)
                        }
                    }
                }
            }
            .onAppear {
                if heroes.isEmpty {
                    modelContext.insert(Hero())
                } else {
                    hero.checkAndResetDailyStats()
                    try? modelContext.save()
                }
            }
        }
    }
    
    // MARK: - Sub-Views
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("SYSTEM ARCHITECT STATUS")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Color.ashGrey)
                Text("Hi, \(hero.name.isEmpty ? "Architect" : hero.name)") // Personalization
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
            }
            Spacer()
            // Avatar with Level Glow
            ZStack {
                Circle()
                    .stroke(hero.totalFocusMinutes > 240 ? Color.alertRed : Color.toxicLime, lineWidth: 2)
                    .frame(width: 54, height: 54)
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 46, height: 46)
                    .foregroundStyle(Color.smokeWhite)
            }
        }
        .padding(.horizontal)
    }
    
    private var vitalityChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("VITALITY ANALYSIS", systemImage: "waveform.path.ecg")
                    .font(.caption.bold())
                    .foregroundStyle(Color.ashGrey)
                Spacer()
                Text("Weekly Sync")
                    .font(.caption2)
                    .foregroundStyle(Color.ashGrey)
            }
            
            Chart {
                BarMark(
                    x: .value("Metric", "Standard"),
                    y: .value("Count", standardModules)
                )
                .foregroundStyle(Color.electricCyan.gradient)
                .cornerRadius(6)
                
                BarMark(
                    x: .value("Metric", "Debt Resolved"),
                    y: .value("Count", debtResolved)
                )
                .foregroundStyle(Color.alertRed.gradient)
                .cornerRadius(6)
            }
            .frame(height: 180)
            .chartYAxisLabel("Modules")
            
            Text("Resolving Technical Debt grants 2x XP and increases System Integrity.")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.ashGrey)
        }
        .padding()
        .background(Color.carbonGrey.opacity(0.5))
        .cornerRadius(24)
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.05), lineWidth: 1))
        .padding(.horizontal)
    }
    
    private var xpIntegrityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("SYSTEM INTEGRITY")
                    .font(.caption.bold())
                Spacer()
                Text("\(Int((Double(hero.currentXP) / Double(hero.maxXP)) * 100))%")
                    .font(.system(.caption, design: .monospaced))
            }
            .foregroundStyle(Color.toxicLime)
            
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.1))
                    Capsule()
                        .fill(LinearGradient(colors: [Color.toxicLime, Color.electricCyan], startPoint: .leading, endPoint: .trailing))
                        .frame(width: g.size.width * CGFloat(Double(hero.currentXP) / Double(max(1, hero.maxXP))))
                }
            }
            .frame(height: 8)
            
            Text("\(hero.currentXP) / \(hero.maxXP) XP to Next Optimization")
                .font(.caption2)
                .foregroundStyle(Color.ashGrey)
        }
        .padding()
        .background(Color.carbonGrey)
        .cornerRadius(20)
        .padding(.horizontal)
    }
}

// MARK: - Supporting Components (Decomposed to fix Scope errors)

struct StatBlock: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.title3)
            
            Text(value)
                .font(.system(.title2, design: .monospaced)).bold()
                .foregroundStyle(.white)
            
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.ashGrey)
                .tracking(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.carbonGrey)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}

struct BurnoutWarningCard: View {
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundStyle(.black)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("BURNOUT THRESHOLD DETECTED")
                    .font(.system(size: 10, weight: .black))
                Text("Your current focus cycle exceeds safe parameters. System recommends an immediate offline interval.")
                    .font(.caption2)
                    .lineLimit(2)
            }
            .foregroundStyle(.black)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.ballisticOrange)
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

// MARK: - Focus History Chart
struct FocusHistoryView: View {
    var sessions: [Session]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.voidBlack.ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 20) {
                    Text("FOCUS VELOCITY")
                        .font(.caption.bold())
                        .foregroundStyle(Color.ashGrey)
                        .padding(.horizontal)
                    
                    Chart {
                        ForEach(groupedSessions, id: \.date) { data in
                            BarMark(
                                x: .value("Date", data.date, unit: .day),
                                y: .value("Minutes", data.minutes)
                            )
                            .foregroundStyle(Color.electricCyan.gradient)
                            .cornerRadius(4)
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { _ in
                            AxisValueLabel(format: .dateTime.weekday().day())
                                .foregroundStyle(Color.ashGrey)
                        }
                    }
                    .chartYAxis {
                        AxisMarks { value in
                            AxisValueLabel()
                                .foregroundStyle(Color.ashGrey)
                            AxisGridLine()
                                .foregroundStyle(Color.white.opacity(0.1))
                        }
                    }
                    .frame(height: 250)
                    .padding()
                    .background(Color.carbonGrey.opacity(0.3))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(.top)
            }
            .navigationTitle("Temporal Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Dismiss") { dismiss() }
                        .foregroundStyle(Color.toxicLime)
                }
            }
        }
    }
    
    // Group sessions by day
    private var groupedSessions: [(date: Date, minutes: Double)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: sessions) { session in
            calendar.startOfDay(for: session.date)
        }
        
        return grouped.map { (key, value) in
            let totalSeconds = value.reduce(0) { $0 + $1.duration }
            return (date: key, minutes: totalSeconds / 60)
        }.sorted { $0.date < $1.date }
    }
}

// MARK: - Quest Timeline (Git Graph Style)
struct QuestTimelineView: View {
    let quests: [Quest]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section Header
            HStack {
                Label("COMMIT HISTORY", systemImage: "point.3.connected.trianglepath.dotted")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.ashGrey)
                Spacer()
                Text("\(quests.count) merged")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color.ashGrey.opacity(0.7))
            }
            .padding(.bottom, 16)
            
            // Timeline Nodes (scrollable)
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(quests.enumerated()), id: \.offset) { index, quest in
                        QuestTimelineNode(
                            quest: quest,
                            isFirst: index == 0,
                            isLast: index == quests.count - 1
                        )
                    }
                }
            }
            .frame(maxHeight: 350)
        }
        .padding(20)
        .background(Color.carbonGrey.opacity(0.5))
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}

struct QuestTimelineNode: View {
    let quest: Quest
    let isFirst: Bool
    let isLast: Bool
    
    @State private var isExpanded = false
    
    private var nodeColor: Color {
        quest.isBoss ? Color.alertRed : Color.toxicLime
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, HH:mm"
        return formatter.string(from: quest.createdAt)
    }
    
    private var formattedTime: String {
        let total = Int(quest.totalTimeSpent)
        let h = total / 3600
        let m = (total % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Git Branch Line + Node
            VStack(spacing: 0) {
                // Line above node
                if !isFirst {
                    Rectangle()
                        .fill(Color.ashGrey.opacity(0.3))
                        .frame(width: 2, height: 16)
                } else {
                    Color.clear.frame(width: 2, height: 16)
                }
                
                // Commit Node (The Dot)
                ZStack {
                    Circle()
                        .fill(nodeColor.opacity(0.2))
                        .frame(width: 20, height: 20)
                    Circle()
                        .fill(nodeColor)
                        .frame(width: 10, height: 10)
                    if isFirst {
                        Circle()
                            .stroke(nodeColor.opacity(0.4), lineWidth: 2)
                            .frame(width: 20, height: 20)
                    }
                }
                
                // Line below node
                if !isLast {
                    Rectangle()
                        .fill(Color.ashGrey.opacity(0.3))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                } else {
                    // Fade-out tail
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.ashGrey.opacity(0.3), Color.clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 2, height: 20)
                }
            }
            .frame(width: 30)
            
            // Quest Content Card
            VStack(alignment: .leading, spacing: 0) {
                // Main Row (tap to expand)
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                    Haptics.shared.play(.light)
                } label: {
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                // Boss badge
                                if quest.isBoss {
                                    Text("DEBT")
                                        .font(.system(size: 8, weight: .black, design: .monospaced))
                                        .foregroundStyle(.black)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(Color.alertRed)
                                        .cornerRadius(4)
                                }
                                
                                Text(quest.title)
                                    .font(.system(.subheadline, design: .monospaced))
                                    .bold()
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                            }
                            
                            HStack(spacing: 8) {
                                Label(formattedDate, systemImage: "clock")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundStyle(Color.ashGrey)
                                
                                Text("•")
                                    .foregroundStyle(Color.ashGrey.opacity(0.5))
                                
                                Label("+\(quest.totalXP) XP", systemImage: "bolt.fill")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundStyle(nodeColor)
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption2.bold())
                            .foregroundStyle(Color.ashGrey)
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    }
                    .padding(12)
                    .background(Color.carbonGrey.opacity(isExpanded ? 0.8 : 0.4))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                
                // Expanded Details
                if isExpanded {
                    VStack(alignment: .leading, spacing: 10) {
                        // Details text
                        if !quest.details.isEmpty {
                            Text(quest.details)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(Color.smokeWhite.opacity(0.8))
                                .padding(.top, 4)
                        }
                        
                        // Stats Row
                        HStack(spacing: 16) {
                            statPill(icon: "timer", value: formattedTime, label: "TIME")
                            statPill(icon: "bolt.fill", value: "+\(quest.totalXP)", label: "XP")
                            if !quest.subQuests.isEmpty {
                                statPill(icon: "list.bullet", value: "\(quest.subQuests.count)", label: "SUBS")
                            }
                        }
                        
                        // Sub-quests list
                        if !quest.subQuests.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("SUB-MODULES")
                                    .font(.system(size: 9, weight: .black, design: .monospaced))
                                    .foregroundStyle(Color.ashGrey)
                                
                                ForEach(quest.subQuests, id: \.id) { sub in
                                    HStack(spacing: 8) {
                                        Image(systemName: sub.isCompleted ? "checkmark.circle.fill" : "circle")
                                            .font(.caption2)
                                            .foregroundStyle(sub.isCompleted ? Color.toxicLime : Color.ashGrey)
                                        
                                        Text(sub.title)
                                            .font(.system(.caption2, design: .monospaced))
                                            .foregroundStyle(Color.smokeWhite.opacity(0.8))
                                        
                                        Spacer()
                                        
                                        Text(sub.difficulty.rawValue)
                                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                                            .foregroundStyle(difficultyColor(sub.difficulty))
                                    }
                                }
                            }
                            .padding(10)
                            .background(Color.voidBlack.opacity(0.5))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(.leading, 6)
        }
        .padding(.bottom, isLast ? 0 : 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(quest.title), completed \(formattedDate), earned \(quest.totalXP) XP")
        .accessibilityHint("Tap to \(isExpanded ? "collapse" : "expand") details")
    }
    
    private func statPill(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 9))
                Text(value)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
            }
            .foregroundStyle(Color.toxicLime)
            
            Text(label)
                .font(.system(size: 7, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.ashGrey)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.toxicLime.opacity(0.08))
        .cornerRadius(8)
    }
    
    private func difficultyColor(_ diff: QuestDifficulty) -> Color {
        switch diff {
        case .routine: return Color.toxicLime
        case .complex: return Color.ballisticOrange
        case .legacy: return Color.alertRed
        }
    }
}