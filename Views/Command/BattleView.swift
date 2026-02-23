import SwiftUI
import SwiftData
import AVFoundation
import TipKit

struct BattleView: View {
    @Query private var heroes: [Hero]
    @Query(filter: #Predicate<Quest> { $0.isActive && !$0.isCompleted }) private var activeQuests: [Quest]
    @Query(filter: #Predicate<Quest> { $0.isCompleted }, sort: \.createdAt, order: .reverse) private var completedQuests: [Quest]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    @State private var showCompletionAlert = false
    @State private var timerPulse = false
    
    // Overtime detection
    @AppStorage("focusDuration") private var focusDuration: Int = 25
    @AppStorage("selectedSoundID") private var selectedSoundID: Int = 1005
    @State private var showOvertimeAlert = false
    @State private var overtimeAlertShown = false // one-time per session
    @State private var showRechargeFromOvertime = false
    
    // Tips
    private let burnoutTip = BurnoutTip()
    private let flowModeTip = FlowModeTip()
    private let xpTip = XPTip()
    
    var hero: Hero { heroes.first ?? Hero() }
    var activeQuest: Quest? { activeQuests.first }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.voidBlack.ignoresSafeArea()
                
                // Glow effect when timer is active
                if activeQuest?.isTimerActive == true {
                    glowEffect
                }
                
                // GLITCH EFFECT: Burnout visual corruption
                if hero.totalFocusMinutes > 240 {
                    Color.purple.opacity(0.1)
                        .blendMode(.exclusion)
                        .offset(x: 5, y: 0)
                    Color.green.opacity(0.1)
                        .blendMode(.exclusion)
                        .offset(x: -5, y: 0)
                }
                
                ScrollView {
                    VStack(spacing: 20) {
                        headerView
                        HeroStatusCard(
                            hero: hero,
                            activeQuest: activeQuest,
                            showOvertimeAlert: showOvertimeAlert,
                            burnoutTip: burnoutTip,
                            xpTip: xpTip
                        )
                        
                        // Main Battle Card with sub-quest toggles
                        BattleCard(
                            activeQuest: activeQuest,
                            hero: hero,
                            onCompleteMission: { showCompletionAlert = true }
                        )
                        
                        // Last Merged Indicator
                        if let lastDone = completedQuests.first {
                            LastMergedBanner(quest: lastDone)
                                .padding(.horizontal)
                        }
                        
                        DeploymentHistoryCard(completedQuests: completedQuests)
                    }
                    .padding(.bottom, 120)
                }
                
                floatingCommandBar
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            // Complete Mission Alert
            .alert("⚡ DEPLOY MODULE?", isPresented: $showCompletionAlert) {
                Button("DEPLOY", role: .destructive) { completeMission() }
                Button("CANCEL", role: .cancel) { }
            } message: {
                Text("This will mark the mission as complete, award XP, and archive it to Deployment History.")
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
        // MARK: - Overtime Alert Popup
        .overlay {
            if showOvertimeAlert {
                overtimeAlertOverlay
            }
        }
        .fullScreenCover(isPresented: $showRechargeFromOvertime) {
            NavigationStack {
                RechargeHubView()
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button { showRechargeFromOvertime = false } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(Color.ashGrey)
                            }
                        }
                    }
            }
        }
    }
    
    // MARK: - Complete Mission Logic
    private func completeMission() {
        guard let quest = activeQuest else { return }
        
        // Stop timer if running
        if quest.isTimerActive {
            let elapsed = Date().timeIntervalSince(quest.lastStartedAt ?? Date())
            quest.timeSpent += elapsed
            quest.isTimerActive = false
            quest.lastStartedAt = nil
            
            let session = Session(taskName: quest.title, duration: elapsed)
            modelContext.insert(session)
        }
        
        // Mark complete
        quest.isCompleted = true
        quest.isActive = false
        
        // Mark all sub-quests complete
        for sub in quest.subQuests {
            sub.isCompleted = true
        }
        
        // Award XP
        hero.addXP(amount: quest.totalXP)
        
        Haptics.shared.notify(.success)
        
        do {
            try modelContext.save()
            print("ForgeFlow: Module deployed successfully.")
        } catch {
            print("ForgeFlow: Deploy Error - \(error)")
        }
    }
    
    // MARK: - Sub-Views
    
    private var glowEffect: some View {
        Circle()
            .fill(
                (activeQuest?.isBoss == true ? Color.alertRed : Color.electricCyan).opacity(0.15)
            )
            .frame(width: 300, height: 300)
            .blur(radius: 100)
            .offset(y: -100)
            .scaleEffect(timerPulse ? 1.15 : 1.0)
            .animation(reduceMotion ? nil : .easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: timerPulse)
            .onAppear { timerPulse = true }
            .accessibilityHidden(true)
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("COMMAND CENTER")
                    .font(.caption).fontDesign(.monospaced)
                    .foregroundStyle(Color.ashGrey).tracking(2)
                Text("FORGEFLOW")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
            Spacer()
            
            // Streak counter
            if hero.streakDays > 1 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(Color.ballisticOrange)
                    Text("\(hero.streakDays)")
                        .font(.system(.caption, design: .monospaced)).bold()
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(Color.ballisticOrange.opacity(0.15))
                .clipShape(Capsule())
                .accessibilityLabel("\(hero.streakDays) day streak")
            }
            
            levelBadge
        }
        .padding(.horizontal).padding(.top)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("ForgeFlow Command Center, Level \(hero.level)")
    }
    
    private var levelBadge: some View {
        HStack {
            Image(systemName: "cpu.fill").foregroundStyle(Color.toxicLime)
            Text("LVL \(hero.level)")
                .font(.headline).fontDesign(.monospaced)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(Color.carbonGrey).clipShape(Capsule())
        .accessibilityLabel("Level \(hero.level)")
    }
    
    private var floatingCommandBar: some View {
        VStack {
            Spacer()
            if let quest = activeQuest {
                TimelineView(.periodic(from: .now, by: 1.0)) { context in
                    let elapsed = questElapsed(quest, at: context.date)
                    let limitSeconds = TimeInterval(focusDuration * 60)
                    let isOvertime = quest.isTimerActive && elapsed > limitSeconds
                    let overtimeSeconds = max(0, elapsed - limitSeconds)
                    
                    VStack(spacing: 0) {
                        // Overtime warning banner
                        if isOvertime {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption2)
                                Text("OVERTIME +\(formatOvertimeShort(overtimeSeconds))")
                                    .font(.system(size: 10, weight: .black, design: .monospaced))
                            }
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(Color.alertRed)
                            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 12, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 12))
                        }
                        
                        HStack(spacing: 16) {
                            VStack(alignment: .leading) {
                                if quest.isTimerActive {
                                    LiveQuestTimer(quest: quest)
                                        .foregroundStyle(isOvertime ? Color.alertRed : Color.toxicLime)
                                } else {
                                    Text("STANDING BY")
                                        .font(.caption2.bold())
                                        .foregroundStyle(Color.ashGrey)
                                }
                                Text(quest.title)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                            }
                            Spacer()
                            
                            Button { toggleTimer(quest) } label: {
                                ZStack {
                                    if quest.isTimerActive {
                                        Circle()
                                            .stroke((isOvertime ? Color.alertRed : Color.toxicLime).opacity(0.3), lineWidth: 2)
                                            .frame(width: 62, height: 62)
                                            .scaleEffect(timerPulse ? 1.3 : 1.0)
                                            .opacity(timerPulse ? 0 : 0.6)
                                    }
                                    
                                    Image(systemName: quest.isTimerActive ? "pause.fill" : "play.fill")
                                        .font(.title2).foregroundStyle(.black)
                                        .frame(width: 56, height: 56)
                                        .background(
                                            quest.isTimerActive
                                            ? (isOvertime ? Color.alertRed : (quest.isBoss ? Color.alertRed : Color.toxicLime))
                                            : Color.white
                                        )
                                        .clipShape(Circle())
                                }
                            }
                            .accessibilityLabel(quest.isTimerActive ? "Pause timer" : "Start timer")
                            .accessibilityHint(quest.isTimerActive ? "Pauses the active mission timer" : "Starts the mission timer")
                            .popoverTip(flowModeTip, arrowEdge: .top)
                        }
                        .padding(16)
                        .background(
                            (isOvertime ? Color.alertRed.opacity(0.15) : Color.carbonGrey.opacity(0.95))
                        )
                        .clipShape(UnevenRoundedRectangle(topLeadingRadius: isOvertime ? 0 : 24, bottomLeadingRadius: 12, bottomTrailingRadius: 12, topTrailingRadius: isOvertime ? 0 : 24))
                    }
                    .cornerRadius(isOvertime ? 16 : 24)
                    .overlay(
                        RoundedRectangle(cornerRadius: isOvertime ? 16 : 24)
                            .stroke(isOvertime ? Color.alertRed.opacity(0.4) : Color.clear, lineWidth: isOvertime ? 1 : 0)
                    )
                    .padding(.horizontal).padding(.bottom, 20)
                    .onChange(of: isOvertime) { _, newValue in
                        if newValue && !overtimeAlertShown {
                            triggerOvertimeAlert()
                        }
                    }
                }
            } else {
                NavigationLink(destination: QuestBoardView()) {
                    HStack(spacing: 10) {
                        Image(systemName: "terminal.fill")
                        Text("INITIALIZE MISSION")
                            .font(.system(.headline, design: .monospaced)).bold()
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity).frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [Color.toxicLime, Color.electricCyan],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                }
                .padding(.horizontal).padding(.bottom, 20)
            }
        }
    }
    
    // MARK: - Overtime Helpers
    
    private func questElapsed(_ quest: Quest, at date: Date) -> TimeInterval {
        var currentSession: TimeInterval = 0
        if quest.isTimerActive, let start = quest.lastStartedAt {
            currentSession = date.timeIntervalSince(start)
        }
        return quest.timeSpent + currentSession
    }
    
    private func formatOvertimeShort(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        if mins > 0 { return "\(mins)m \(secs)s" }
        return "\(secs)s"
    }
    
    private func triggerOvertimeAlert() {
        overtimeAlertShown = true
        
        // Play the user's chosen alert sound
        AudioServicesPlaySystemSound(SystemSoundID(selectedSoundID))
        
        // Accelerate burnout
        hero.burnoutLevel = min(1.0, hero.burnoutLevel + 0.1)
        try? modelContext.save()
        
        // Show the popup
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            showOvertimeAlert = true
        }
    }
    
    // MARK: - Overtime Alert Overlay
    private var overtimeAlertOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation { showOvertimeAlert = false }
                }
            
            VStack(spacing: 20) {
                // Warning icon
                ZStack {
                    Circle()
                        .fill(Color.alertRed.opacity(0.15))
                        .frame(width: 70, height: 70)
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.ballisticOrange)
                }
                
                VStack(spacing: 8) {
                    Text("FOCUS LIMIT EXCEEDED")
                        .font(.system(.headline, design: .monospaced)).bold()
                        .foregroundStyle(Color.alertRed)
                    
                    Text("You've been focused for more than \(focusDuration) minutes. Taking a break improves performance and prevents burnout.")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(Color.smokeWhite.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
                
                // Action buttons
                VStack(spacing: 10) {
                    Button {
                        withAnimation { showOvertimeAlert = false }
                        // Navigate to Recharge hub
                        showRechargeFromOvertime = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "gamecontroller.fill")
                            Text("GO RECHARGE")
                                .font(.system(.subheadline, design: .monospaced)).bold()
                        }
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(colors: [Color.toxicLime, Color.electricCyan],
                                           startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(14)
                    }
                    
                    Button {
                        withAnimation { showOvertimeAlert = false }
                    } label: {
                        Text("CONTINUE ANYWAY")
                            .font(.system(.caption, design: .monospaced)).bold()
                            .foregroundStyle(Color.ashGrey)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                    }
                }
            }
            .padding(24)
            .background(Color.carbonGrey)
            .cornerRadius(24)
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.alertRed.opacity(0.3), lineWidth: 1))
            .padding(.horizontal, 30)
            .transition(.scale(scale: 0.85).combined(with: .opacity))
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Focus limit exceeded. You've been focused for over \(focusDuration) minutes.")
    }
    
    private func toggleTimer(_ quest: Quest) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            if quest.isTimerActive {
                let elapsed = Date().timeIntervalSince(quest.lastStartedAt ?? Date())
                quest.timeSpent += elapsed
                quest.isTimerActive = false
                quest.lastStartedAt = nil
                
                let minutesEarned = elapsed / 60
                hero.totalFocusMinutes += minutesEarned
                
                let session = Session(taskName: quest.title, duration: elapsed)
                modelContext.insert(session)
                
                // Reset overtime flag when stopping
                overtimeAlertShown = false
            } else {
                quest.lastStartedAt = Date()
                quest.isTimerActive = true
                overtimeAlertShown = false // reset for new run
            }
            
            do {
                try modelContext.save()
            } catch {
                print("ForgeFlow: Command Error - \(error)")
            }
        }
    }
}

// MARK: - Hero Status Card
struct HeroStatusCard: View {
    var hero: Hero
    var activeQuest: Quest?
    var showOvertimeAlert: Bool
    var burnoutTip: BurnoutTip
    var xpTip: XPTip
    
    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(Color.carbonGrey)
                    .frame(width: 60, height: 60)
                Image(systemName: "person.fill")
                    .foregroundStyle(Color.toxicLime)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("SYSTEM ARCHITECT")
                        .font(.caption2.bold())
                        .foregroundStyle(Color.ashGrey)
                    if hero.burnoutLevel > 0.5 {
                        Text("⚠️ BURNOUT")
                            .font(.system(size: 8, weight: .black, design: .monospaced))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(Color.ballisticOrange)
                            .cornerRadius(4)
                            .popoverTip(burnoutTip, arrowEdge: .top)
                    }
                }
                HStack {
                    Text("\(hero.nanobytes)")
                        .font(.headline).foregroundStyle(.white)
                    Text("Nanobytes")
                        .font(.caption).foregroundStyle(Color.ashGrey)
                }
                ProgressView(value: Double(hero.currentXP), total: Double(hero.maxXP))
                    .tint(Color.toxicLime)
            }
            .popoverTip(xpTip, arrowEdge: .bottom)
        }
        .padding(16)
        .background(Color.carbonGrey.opacity(0.3))
        .cornerRadius(20)
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("System Architect, \(hero.nanobytes) nanobytes, \(hero.currentXP) of \(hero.maxXP) XP\(hero.burnoutLevel > 0.5 ? ", burnout warning active" : "")")
        .sensoryFeedback(trigger: activeQuest?.isTimerActive) { old, new in
            guard let new = new else { return nil }
            return new ? .impact(weight: .light) : .impact(weight: .medium)
        }
        .sensoryFeedback(.warning, trigger: showOvertimeAlert)
    }
}

// MARK: - Battle Card (with Sub-Quest Toggles + Complete Button)
struct BattleCard: View {
    var activeQuest: Quest?
    var hero: Hero
    var onCompleteMission: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            if let quest = activeQuest {
                // Boss Warning Banner
                if quest.isBoss {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.black)
                        Text("TECHNICAL DEBT DETECTED — PRIORITY: CRITICAL")
                            .font(.system(size: 9, weight: .black, design: .monospaced))
                            .foregroundStyle(.black)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(Color.alertRed)
                }
                
                VStack(spacing: 16) {
                    // Quest Title + Status
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(quest.title)
                                .font(.title3.bold())
                                .foregroundStyle(.white)
                            
                            Text(quest.isBoss ? "BOSS MODULE" : "ACTIVE MODULE")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(quest.isBoss ? Color.alertRed : Color.ashGrey)
                        }
                        
                        Spacer()
                        
                        // Time spent badge
                        VStack(spacing: 2) {
                            Text(formatTime(quest.totalTimeSpent))
                                .font(.system(.caption, design: .monospaced)).bold()
                                .foregroundStyle(Color.electricCyan)
                            Text("ELAPSED")
                                .font(.system(size: 7, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color.ashGrey)
                        }
                        .padding(8)
                        .background(Color.electricCyan.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // Progress Bar
                    VStack(spacing: 6) {
                        ProgressView(value: quest.progress)
                            .tint(quest.isBoss ? Color.alertRed : Color.electricCyan)
                        
                        HStack {
                            Text("\(Int(quest.progress * 100))% Compiled")
                                .font(.caption2).foregroundStyle(Color.ashGrey)
                            Spacer()
                            if !quest.subQuests.isEmpty {
                                Text("\(quest.subQuests.filter { $0.isCompleted }.count)/\(quest.subQuests.count) sub-modules")
                                    .font(.caption2).foregroundStyle(Color.ashGrey)
                            }
                        }
                    }
                    
                    // Sub-Quest Toggles
                    if !quest.subQuests.isEmpty {
                        VStack(spacing: 0) {
                            ForEach(quest.subQuests, id: \.id) { sub in
                                SubQuestToggleRow(subQuest: sub)
                            }
                        }
                        .background(Color.voidBlack.opacity(0.4))
                        .cornerRadius(12)
                    }
                    
                    // Complete Mission Button (shows when progress >= 100% or anytime)
                    Button(action: onCompleteMission) {
                        HStack(spacing: 8) {
                            Image(systemName: quest.progress >= 1.0 ? "checkmark.seal.fill" : "arrow.right.circle.fill")
                            Text(quest.progress >= 1.0 ? "DEPLOY MODULE" : "FORCE DEPLOY")
                                .font(.system(.subheadline, design: .monospaced)).bold()
                        }
                        .foregroundStyle(quest.progress >= 1.0 ? .black : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            quest.progress >= 1.0
                            ? AnyShapeStyle(LinearGradient(colors: [Color.toxicLime, Color.electricCyan], startPoint: .leading, endPoint: .trailing))
                            : AnyShapeStyle(Color.white.opacity(0.1))
                        )
                        .cornerRadius(14)
                    }
                }
                .padding()
                .background(
                    quest.isBoss
                    ? Color.alertRed.opacity(0.05)
                    : Color.carbonGrey.opacity(1)
                )
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            quest.isBoss ? Color.alertRed.opacity(0.3) : Color.white.opacity(0.05),
                            lineWidth: quest.isBoss ? 2 : 1
                        )
                )
            } else {
                // Styled Empty State
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .stroke(Color.toxicLime.opacity(0.1), lineWidth: 1)
                            .frame(width: 80, height: 80)
                        Image(systemName: "server.rack")
                            .font(.system(size: 32))
                            .foregroundStyle(Color.ashGrey.opacity(0.4))
                    }
                    .accessibilityHidden(true)
                    
                    VStack(spacing: 6) {
                        Text("NO ACTIVE MODULES")
                            .font(.system(.headline, design: .monospaced))
                            .foregroundStyle(Color.ashGrey)
                        Text("Initialize a mission from the Registry to begin your operation.")
                            .font(.caption)
                            .foregroundStyle(Color.ashGrey.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(30)
                .frame(maxWidth: .infinity)
                .background(Color.carbonGrey.opacity(0.3))
                .cornerRadius(20)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("No active modules. Initialize a mission from the Registry to begin.")
            }
        }
        .padding(.horizontal)
    }
    
    private func formatTime(_ interval: TimeInterval) -> String {
        let total = Int(interval)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 { return String(format: "%dh %02dm", h, m) }
        return String(format: "%dm %02ds", m, s)
    }
}

// MARK: - Sub-Quest Toggle Row
struct SubQuestToggleRow: View {
    @Bindable var subQuest: SubQuest
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                subQuest.isCompleted.toggle()
            }
            Haptics.shared.play(.light)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: subQuest.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.body)
                    .foregroundStyle(subQuest.isCompleted ? Color.toxicLime : Color.ashGrey)
                    .symbolEffect(.bounce, value: subQuest.isCompleted)
                
                Text(subQuest.title)
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(subQuest.isCompleted ? Color.ashGrey : Color.smokeWhite)
                    .strikethrough(subQuest.isCompleted, color: Color.ashGrey)
                
                Spacer()
                
                // Difficulty tag
                Text(subQuest.difficulty.rawValue)
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundStyle(difficultyColor)
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .background(difficultyColor.opacity(0.12))
                    .cornerRadius(4)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(subQuest.title), \(subQuest.isCompleted ? "completed" : "incomplete")")
        .accessibilityHint("Tap to toggle completion")
    }
    
    private var difficultyColor: Color {
        switch subQuest.difficulty {
        case .routine: return Color.toxicLime
        case .complex: return Color.ballisticOrange
        case .legacy: return Color.alertRed
        }
    }
}

// MARK: - Last Merged Banner
struct LastMergedBanner: View {
    let quest: Quest
    
    private var timeAgo: String {
        let interval = Date().timeIntervalSince(quest.createdAt)
        let hours = Int(interval / 3600)
        let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
        if hours > 24 { return "\(hours / 24)d ago" }
        if hours > 0 { return "\(hours)h ago" }
        return "\(minutes)m ago"
    }
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.toxicLime)
                .font(.caption)
            
            Text("Last merged:")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(Color.ashGrey)
            
            Text(quest.title)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.smokeWhite)
                .lineLimit(1)
            
            Spacer()
            
            Text(timeAgo)
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(Color.ashGrey.opacity(0.7))
        }
        .padding(12)
        .background(Color.toxicLime.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.toxicLime.opacity(0.1), lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Last merged: \(quest.title), \(timeAgo)")
    }
}

// MARK: - Deployment History Card
struct DeploymentHistoryCard: View {
    var completedQuests: [Quest]
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("DEPLOYMENT HISTORY")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.ashGrey)
                .padding(.leading)
            
            if completedQuests.isEmpty {
                Text("No deployments yet.")
                    .font(.caption)
                    .foregroundStyle(Color.ashGrey.opacity(0.5))
                    .padding(.leading)
            } else {
                ForEach(completedQuests.prefix(3)) { quest in
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(quest.isBoss ? Color.alertRed : Color.toxicLime)
                            .font(.caption)
                        Text(quest.title)
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundStyle(.white)
                        Spacer()
                        Text("+\(quest.totalXP) XP")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.electricCyan)
                    }
                    .padding(12)
                    .background(Color.carbonGrey.opacity(0.2))
                    .cornerRadius(12)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(quest.title), earned \(quest.totalXP) XP\(quest.isBoss ? ", debt module" : "")")
                }
            }
        }
        .padding(.horizontal)
    }
}