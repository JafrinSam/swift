import SwiftUI
import SwiftData
import Foundation
import AVFoundation
import Observation
#if false // Change to 'canImport(ActivityKit)'
import ActivityKit
#endif

// MARK: - Timer Phase
enum TimerPhase: String {
    case focus = "FOCUS"
    case shortBreak = "SHORT BREAK"
    case longBreak = "LONG BREAK"
    case idle = "IDLE"
    
    var color: Color {
        switch self {
        case .focus: return Color.electricCyan
        case .shortBreak: return Color.toxicLime
        case .longBreak: return Color.ballisticOrange
        case .idle: return Color.ashGrey
        }
    }
    
    var icon: String {
        switch self {
        case .focus: return "bolt.fill"
        case .shortBreak: return "cup.and.saucer.fill"
        case .longBreak: return "moon.stars.fill"
        case .idle: return "circle.dotted"
        }
    }
}

// MARK: - Preset Duration
struct TimerPreset: Identifiable {
    let id = UUID()
    let label: String
    let minutes: Int
    let icon: String
}

struct FocusTimerView: View {
    var hero: Hero
    var activeQuest: Quest?
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Timer State
    @State private var timeRemaining: TimeInterval = 25 * 60
    @State private var totalTime: TimeInterval = 25 * 60
    @State private var isRunning = false
    @State private var isFlowMode = false
    @State private var timer: Timer?
#if false // Change to 'canImport(ActivityKit)'
    @State private var currentActivity: Activity<FocusAttributes>? = nil
#endif
    
    // MARK: - Pomodoro State
    @State private var currentPhase: TimerPhase = .idle
    @State private var sessionCount: Int = 0
    @State private var totalSessions: Int = 4
    
    // MARK: - Break Settings (read from AppStorage synced with SettingsView)
    @AppStorage("focusDuration") private var focusDuration: Int = 25
    @AppStorage("shortBreakDuration") private var shortBreakDuration: Int = 5
    @AppStorage("longBreakDuration") private var longBreakDuration: Int = 15
    @AppStorage("autoStartBreak") private var autoStartBreak: Bool = true
    @AppStorage("selectedSoundID") private var selectedSoundID: Int = 1005
    
    // MARK: - Managers
    @State private var audioRecorder = AudioRecorder()
    @State private var showMusicPicker = false
    @ObservedObject private var soundManager = SoundManager.shared
    
    // MARK: - UI State
    @State private var quickTaskTitle = ""
    @State private var pulse: CGFloat = 1.0
    @State private var showCustomTimeSheet = false
    @State private var customMinutesInput = 25
    
    private let presets: [TimerPreset] = [
        TimerPreset(label: "25m", minutes: 25, icon: "bolt"),
        TimerPreset(label: "30m", minutes: 30, icon: "bolt.fill"),
        TimerPreset(label: "50m", minutes: 50, icon: "flame"),
    ]

    var body: some View {
        VStack(spacing: 20) {
            questHeader
            phaseIndicator
            reactorDisplay
            
            // Preset Duration Selector (only when idle)
            if !isRunning && currentPhase == .idle {
                presetSelector
            }
            
            controlCluster
            utilityRow
        }
        .padding(25)
        .background(Color.voidBlack.opacity(0.8))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.white.opacity(0.1), lineWidth: 1))
        .sheet(isPresented: $showCustomTimeSheet) {
            customTimeSheet
        }
    }

    // MARK: - Phase Indicator
    @ViewBuilder
    private var phaseIndicator: some View {
        HStack(spacing: 12) {
            // Phase badge
            HStack(spacing: 6) {
                Image(systemName: currentPhase.icon)
                    .font(.caption2)
                Text(currentPhase == .idle ? "READY" : currentPhase.rawValue)
                    .font(.system(size: 10, weight: .black, design: .monospaced))
            }
            .foregroundStyle(currentPhase == .idle ? Color.ashGrey : currentPhase.color)
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(currentPhase.color.opacity(0.12))
            .clipShape(Capsule())
            
            Spacer()
            
            // Session counter
            HStack(spacing: 4) {
                ForEach(0..<totalSessions, id: \.self) { i in
                    Circle()
                        .fill(i < sessionCount ? Color.toxicLime : Color.ashGrey.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
                Text("Session \(min(sessionCount + 1, totalSessions))/\(totalSessions)")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.ashGrey)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(currentPhase.rawValue) phase, session \(sessionCount + 1) of \(totalSessions)")
    }

    // MARK: - Sub-Views
    
    @ViewBuilder
    private var questHeader: some View {
        if let quest = activeQuest {
            HStack {
                Image(systemName: "bolt.circle.fill")
                    .font(.title2)
                    .foregroundStyle(currentPhase.color)
                VStack(alignment: .leading) {
                    Text("ACTIVE MODULE").font(.caption2).foregroundStyle(Color.ashGrey)
                    Text(quest.title).font(.headline).lineLimit(1).foregroundStyle(.white)
                }
                Spacer()
            }
            .padding()
            .background(Color.carbonGrey.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        } else {
            TextField("Enter Quick Task...", text: $quickTaskTitle)
                .textFieldStyle(PlainTextFieldStyle())
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
        }
    }

    @ViewBuilder
    private var reactorDisplay: some View {
        ZStack {
            // Tick marks
            ForEach(0..<60) { i in
                Rectangle()
                    .fill(i % 5 == 0 ? Color.white.opacity(0.5) : Color.white.opacity(0.1))
                    .frame(width: 2, height: i % 5 == 0 ? 15 : 8)
                    .offset(y: -110)
                    .rotationEffect(.degrees(Double(i) * 6))
            }
            
            // Background ring
            Circle()
                .stroke(Color.black.opacity(0.5), lineWidth: 20)
                .frame(width: 200, height: 200)
            
            // Progress ring - changes color based on phase
            Circle()
                .trim(from: 0, to: isFlowMode ? 1.0 : CGFloat(max(0, timeRemaining) / max(1, totalTime)))
                .stroke(
                    currentPhase == .idle ? Color.electricCyan : currentPhase.color,
                    style: StrokeStyle(lineWidth: 15, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 200, height: 200)
            
            VStack(spacing: 4) {
                if isFlowMode {
                    Text("FLOW")
                        .font(.system(.caption2, design: .monospaced)).bold()
                        .foregroundStyle(Color.toxicLime)
                } else if currentPhase == .shortBreak || currentPhase == .longBreak {
                    Text("BREAK")
                        .font(.system(.caption2, design: .monospaced)).bold()
                        .foregroundStyle(currentPhase.color)
                }
                
                Text(formatTime(timeRemaining))
                    .font(.system(size: 44, weight: .bold, design: .monospaced))
                    .foregroundStyle(
                        isFlowMode ? Color.toxicLime :
                        (currentPhase == .idle ? .white : currentPhase.color)
                    )
                    .onTapGesture { if !isRunning { showCustomTimeSheet = true } }
            }
        }
        .scaleEffect(isRunning ? pulse : 1.0)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isFlowMode ? "Flow mode active" : "Timer: \(formatTime(timeRemaining)) remaining")
        .accessibilityValue(isRunning ? "Running" : "Paused")
    }
    
    // MARK: - Preset Selector
    @ViewBuilder
    private var presetSelector: some View {
        HStack(spacing: 10) {
            ForEach(presets) { preset in
                Button {
                    setDuration(preset.minutes)
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: preset.icon)
                            .font(.caption)
                        Text(preset.label)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                    }
                    .foregroundStyle(
                        Int(totalTime / 60) == preset.minutes ? .black : Color.smokeWhite
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        Int(totalTime / 60) == preset.minutes
                        ? Color.electricCyan
                        : Color.carbonGrey
                    )
                    .cornerRadius(12)
                }
            }
            
            // Custom button
            Button {
                showCustomTimeSheet = true
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.caption)
                    Text("Custom")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                }
                .foregroundStyle(Color.smokeWhite)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.carbonGrey)
                .cornerRadius(12)
            }
        }
    }

    @ViewBuilder
    private var controlCluster: some View {
        HStack(spacing: 30) {
            // Reset / Skip Break
            if currentPhase == .shortBreak || currentPhase == .longBreak {
                ControlCircle(icon: "forward.fill", color: Color.toxicLime) { skipBreak() }
                    .accessibilityLabel("Skip break")
                    .accessibilityHint("Skips the current break and starts the next focus session")
            } else {
                ControlCircle(icon: "xmark", color: Color.alertRed) { resetTimer() }
                    .accessibilityLabel("Reset timer")
                    .accessibilityHint("Resets the focus timer to its starting value")
            }
            
            // Play / Pause
            Button(action: toggleTimer) {
                ZStack {
                    Circle()
                        .fill(currentPhase == .idle ? Color.white : currentPhase.color)
                        .frame(width: 80, height: 80)
                    Image(systemName: isRunning ? "pause.fill" : "play.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.black)
                }
            }
            .accessibilityLabel(isRunning ? "Pause focus timer" : "Start focus timer")
            
            // Complete
            ControlCircle(icon: "checkmark", color: Color.toxicLime) { completeSession() }
                .accessibilityLabel("Complete session")
                .accessibilityHint("Marks the current session as complete and logs your focus time")
        }
    }

    @ViewBuilder
    private var utilityRow: some View {
        HStack {
            Button { if hero.level >= 5 { showMusicPicker = true } } label: {
                Label("Music", systemImage: hero.level >= 5 ? "music.note" : "lock.fill")
                    .font(.caption.bold()).padding(10)
                    .background(hero.level >= 5 ? Color.electricCyan.opacity(0.2) : Color.ashGrey.opacity(0.1))
                    .clipShape(Capsule())
            }
            Spacer()
            Button {
                if let url = audioRecorder.toggleRecording() {
                    if let quest = activeQuest {
                        quest.voiceNotePath = url.path
                        try? modelContext.save()
                    }
                }
            } label: {
                HStack {
                    Image(systemName: audioRecorder.isRecording ? "waveform" : "mic.fill")
                        .scaleEffect(audioRecorder.isRecording ? CGFloat(1.0 + audioRecorder.amplitude) : 1.0)
                    if audioRecorder.isRecording { Text("REC").font(.caption2.bold()) }
                }
                .padding(12)
                .background(audioRecorder.isRecording ? Color.alertRed : Color.carbonGrey)
                .foregroundStyle(.white)
                .clipShape(Capsule())
            }
        }
    }

    @ViewBuilder
    private var customTimeSheet: some View {
        NavigationStack {
            ZStack {
                Color.voidBlack.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("ADJUST REACTOR CYCLE")
                        .font(.system(.headline, design: .monospaced))
                        .foregroundStyle(Color.electricCyan)
                    
                    VStack(spacing: 16) {
                        HStack {
                            Text("Duration")
                            Spacer()
                            Text("\(customMinutesInput) min")
                                .font(.system(.title3, design: .monospaced)).bold()
                                .foregroundStyle(Color.electricCyan)
                        }
                        
                        Slider(value: Binding(
                            get: { Double(customMinutesInput) },
                            set: { customMinutesInput = Int($0) }
                        ), in: 5...120, step: 5)
                        .tint(Color.electricCyan)
                    }
                    .padding()
                    .background(Color.carbonGrey)
                    .cornerRadius(16)
                    
                    Button {
                        setDuration(customMinutesInput)
                        showCustomTimeSheet = false
                    } label: {
                        Text("CONFIRM")
                            .font(.system(.headline, design: .monospaced)).bold()
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.electricCyan)
                            .cornerRadius(14)
                    }
                }
                .padding()
            }
            .navigationTitle("Custom Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { showCustomTimeSheet = false }
                        .foregroundStyle(Color.toxicLime)
                }
            }
        }
        .presentationDetents([.height(300)])
    }

    // MARK: - Logic
    
    private func setDuration(_ mins: Int) {
        timeRemaining = TimeInterval(mins * 60)
        totalTime = timeRemaining
        focusDuration = mins
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let t = Int(abs(time))
        let h = t / 3600
        let m = (t % 3600) / 60
        let s = t % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }

    private func toggleTimer() {
        if isRunning {
            stopTimer()
        } else {
            if currentPhase == .idle {
                currentPhase = .focus
                timeRemaining = TimeInterval(focusDuration * 60)
                totalTime = timeRemaining
            }
            startTimer()
        }
    }

    private func startTimer() {
        isRunning = true
        withAnimation(.easeInOut(duration: 2).repeatForever()) { pulse = 1.05 }
        
        // Start Live Activity
        startLiveActivity(endTime: Date().addingTimeInterval(timeRemaining))
        
        // Schedule notification
        NotificationManager.shared.scheduleTimerComplete(
            seconds: timeRemaining,
            title: activeQuest?.title ?? "Focus Session"
        )
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 1 {
                timeRemaining -= 1
            } else {
                // Timer hit zero — stop immediately and handle transition
                timeRemaining = 0
                timerCompleted()
            }
        }
    }

    private func stopTimer() {
        isRunning = false
        pulse = 1.0
        timer?.invalidate()
        timer = nil
        
        stopLiveActivity()
        NotificationManager.shared.cancelAll()
    }
    
    private func timerCompleted() {
        stopTimer()
        playNotificationSound()
        
        switch currentPhase {
        case .focus:
            let secondsSpent = totalTime
            let minutesSpent = secondsSpent / 60
            hero.totalFocusMinutes += minutesSpent
            
            let session = Session(
                taskName: activeQuest?.title ?? (quickTaskTitle.isEmpty ? "Focus Cycle" : quickTaskTitle),
                duration: secondsSpent
            )
            modelContext.insert(session)
            hero.addXP(amount: 15)
            try? modelContext.save()
            
            sessionCount += 1
            
            if sessionCount >= totalSessions {
                currentPhase = .longBreak
                timeRemaining = TimeInterval(longBreakDuration * 60)
                totalTime = timeRemaining
                sessionCount = 0
            } else {
                currentPhase = .shortBreak
                timeRemaining = TimeInterval(shortBreakDuration * 60)
                totalTime = timeRemaining
            }
            
            if autoStartBreak {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    startTimer()
                }
            }
            
        case .shortBreak, .longBreak:
            // Break is over — transition back to focus and auto-start
            playNotificationSound()
            
            // Active Recovery: Breaks reduce burnout
            let recoveryAmount = (currentPhase == .longBreak) ? 0.15 : 0.05
            hero.recoverBurnout(amount: recoveryAmount)
            
            currentPhase = .focus
            timeRemaining = TimeInterval(focusDuration * 60)
            totalTime = timeRemaining
            
            // Auto-restart focus after break
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                startTimer()
            }
            
        case .idle:
            break
        }
    }
    
    private func skipBreak() {
        stopTimer()
        currentPhase = .focus
        timeRemaining = TimeInterval(focusDuration * 60)
        totalTime = timeRemaining
    }
    
    // MARK: - Live Activity Logic
    
    private func startLiveActivity(endTime: Date) {
#if false // Change to 'canImport(ActivityKit)'
        let attributes = FocusAttributes(missionName: activeQuest?.title ?? "Focus Session")
        let contentState = FocusAttributes.ContentState(endTime: endTime)
        let content = ActivityContent(state: contentState, staleDate: endTime)
        
        do {
            currentActivity = try Activity<FocusAttributes>.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
        } catch {
            print("Error starting Live Activity: \(error.localizedDescription)")
        }
#endif
    }
    
    private func stopLiveActivity() {
#if false // Change to 'canImport(ActivityKit)'
        guard let activity = currentActivity else { return }
        let contentState = FocusAttributes.ContentState(endTime: Date())
        
        Task {
            await activity.end(ActivityContent(state: contentState, staleDate: nil), dismissalPolicy: .immediate)
        }
        currentActivity = nil
#endif
    }
    
    private func playNotificationSound() {
        AudioServicesPlaySystemSound(SystemSoundID(selectedSoundID))
    }

    private func resetTimer() {
        stopTimer()
        currentPhase = .idle
        sessionCount = 0
        timeRemaining = TimeInterval(focusDuration * 60)
        totalTime = timeRemaining
        isFlowMode = false
    }

    private func completeSession() {
        stopTimer()
        let secondsSpent = totalTime - timeRemaining
        let minutesSpent = max(0, secondsSpent / 60)
        hero.totalFocusMinutes += minutesSpent
        
        let session = Session(
            taskName: activeQuest?.title ?? (quickTaskTitle.isEmpty ? "Deep Work Cycle" : quickTaskTitle),
            duration: secondsSpent
        )
        modelContext.insert(session)
        hero.addXP(amount: isFlowMode ? 30 : 15)
        
        if let quest = activeQuest {
            quest.isCompleted = true
            quest.isActive = false
            hero.addXP(amount: 50)
        }
        
        try? modelContext.save()
        resetTimer()
    }
}

// MARK: - Supporting Component
struct ControlCircle: View {
    var icon: String
    var color: Color
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.carbonGrey.opacity(0.6))
                    .frame(width: 55, height: 55)
                    .overlay(Circle().stroke(color.opacity(0.3), lineWidth: 1))
                
                Image(systemName: icon)
                    .font(.title3.bold())
                    .foregroundStyle(color)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
