import SwiftUI
import TipKit

struct NeuralSyncView: View {
    @Binding var isVisible: Bool

    // MARK: - Expanded Cyber-Wellness & Dev-Humor Quote Library
    let quotes = [
        "System integrity begins with a rested architect. Log out to recharge.",
        "A clear mind is the most secure firewall. Clear your cache with a 5-minute break.",
        "Code is a marathon, not a sprint. Pace your processors to avoid thermal throttling.",
        "First, secure your peace. Then, secure the network.",
        "Even the most advanced systems require a reboot. Stand up and stretch.",
        "Your focus is the CPU of this mission. Avoid overheating by hydrating.",
        "Technical debt isn't just in the code; it's in your fatigue. Refactor your rest.",
        "It's not a bug in your brain, it's a feature of your humanity.",
        "Git commit -m 'Fixed my mental state' and take a walk.",
        "Coffee: The liquid compiler for your brain's morning boot sequence.",
        "Your brain is like a server; if it's at 100% CPU for too long, it will crash.",
        "Stack Overflow is for code blocks, not for your sanity. Step away.",
        "Real architects count from zero, but they also take breaks every 60 minutes.",
        "There's no place like 127.0.0.1, but the park is a close second.",
        "If at first you don't succeed, call it version 1.0 and go get some sleep.",
        "Compiling your thoughts... please stand by for a 5-minute system idle."
    ]

    @State private var currentQuote = ""
    @State private var tacticalRecommendation = ""
    @State private var bootProgress: CGFloat = 0.0
    @State private var isFullyBooted = false
    @State private var bootCompleteTrigger = false

    // Use ThemeManager accent if available, fallback to toxicLime
    private var accent: Color { ThemeManager.shared.currentAccent }

    var body: some View {
        ZStack {
            Color.voidBlack.ignoresSafeArea()

            // Dynamic background glow
            Circle()
                .fill(accent.opacity(0.08))
                .frame(width: 400, height: 400)
                .blur(radius: 80)
                .offset(y: -100)
                .animation(.easeInOut(duration: 2), value: isFullyBooted)

            VStack(spacing: 30) {

                // MARK: - Brain Icon with Pulse
                ZStack {
                    Circle()
                        .stroke(accent.opacity(0.15), lineWidth: 1)
                        .frame(width: 120, height: 120)
                    Circle()
                        .stroke(accent.opacity(0.08), lineWidth: 1)
                        .frame(width: 100, height: 100)

                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 50))
                        .foregroundStyle(accent)
                        .symbolEffect(.pulse, options: .repeating)
                }
                .padding(.top, 40)

                // MARK: - Boot Progress Bar
                VStack(spacing: 10) {
                    Text(isFullyBooted ? "NEURAL SYNC COMPLETE" : "INITIALIZING NEURAL SYNC...")
                        .font(.system(.caption, design: .monospaced))
                        .tracking(3)
                        .foregroundStyle(isFullyBooted ? accent : Color.ashGrey)
                        .animation(.easeInOut(duration: 0.4), value: isFullyBooted)

                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 220, height: 3)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    colors: [accent, accent.opacity(0.6)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 220 * bootProgress, height: 3)
                            .animation(.linear(duration: 2.0), value: bootProgress)
                    }

                    // Kernel log lines (cosmetic)
                    if !isFullyBooted {
                        VStack(spacing: 3) {
                            ForEach(kernelLines(for: bootProgress), id: \.self) { line in
                                Text(line)
                                    .font(.system(size: 8, design: .monospaced))
                                    .foregroundStyle(Color.ashGrey.opacity(0.5))
                            }
                        }
                        .frame(height: 36)
                        .transition(.opacity)
                    }
                }

                // MARK: - Quote & Tactical Recommendation
                VStack(spacing: 15) {
                    Text("\"\(currentQuote)\"")
                        .font(.system(.title3, design: .rounded))
                        .italic()
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 40)

                    if !tacticalRecommendation.isEmpty {
                        Label("ACTION: \(tacticalRecommendation)", systemImage: "bolt.shield.fill")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(accent)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(accent.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(accent.opacity(0.2), lineWidth: 1)
                            )
                            .cornerRadius(6)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(minHeight: 160)
                .opacity(isFullyBooted ? 1 : 0)
                .animation(.easeIn(duration: 0.5), value: isFullyBooted)

                Spacer()

                // MARK: - Enter Button
                if isFullyBooted {
                    Button {
                        // Unlock TipKit tips now that the user is in the app
                        BurnoutTip.appReady = true
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isVisible = false
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "terminal.fill")
                            Text("ENTER COMMAND CENTER")
                        }
                        .font(.system(.subheadline, design: .monospaced)).bold()
                        .foregroundStyle(.black)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 32)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(accent)
                        )
                        .shadow(color: accent.opacity(0.35), radius: 12)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 60)
                }
            }
        }
        .sensoryFeedback(.impact(weight: .heavy), trigger: bootCompleteTrigger)
        .onAppear {
            runBootSequence()
        }
    }

    // MARK: - Boot Sequence Logic
    private func runBootSequence() {
        currentQuote = quotes.randomElement() ?? "Hello, Architect."
        tacticalRecommendation = generateTacticalRecommendation(for: currentQuote)

        // Animate progress bar over 2 seconds
        withAnimation(.linear(duration: 2.0)) {
            bootProgress = 1.0
        }

        // Mark as booted after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isFullyBooted = true
            }
            bootCompleteTrigger.toggle()
        }
    }

    // MARK: - Contextual Tactical Recommendation Engine
    private func generateTacticalRecommendation(for quote: String) -> String {
        let q = quote.lowercased()

        if q.contains("firewall") || q.contains("secure") || q.contains("dnd") {
            return "ENGAGE 'DO NOT DISTURB' PROTOCOL"
        }
        if q.contains("reboot") || q.contains("stretch") || q.contains("walk") || q.contains("stand") {
            return "PERFORM PHYSICAL SYSTEM RESET"
        }
        if q.contains("cpu") || q.contains("overheating") || q.contains("hydrat") {
            return "FLUID INTAKE REQUIRED"
        }
        if q.contains("coffee") || q.contains("morning") || q.contains("compiler") {
            return "CHECK CAFFEINE OVERCLOCK LEVELS"
        }
        if q.contains("sleep") || q.contains("recharge") || q.contains("offline") {
            return "SCHEDULE OFFLINE RECOVERY CYCLE"
        }
        if q.contains("crash") || q.contains("100%") || q.contains("server") {
            return "THROTTLE WORKLOAD — REDUCE LOAD"
        }
        if q.contains("git") || q.contains("commit") || q.contains("version") {
            return "CHECKPOINT: SAVE PROGRESS & PAUSE"
        }
        if q.contains("stack overflow") || q.contains("sanity") {
            return "EMERGENCY CONTEXT SWITCH REQUIRED"
        }
        if q.contains("127.0.0.1") || q.contains("park") {
            return "DEPLOY TO OUTDOOR ENVIRONMENT"
        }
        return "OPTIMIZE MENTAL BANDWIDTH"
    }

    // MARK: - Cosmetic Kernel Log Lines
    private func kernelLines(for progress: CGFloat) -> [String] {
        let all = [
            "[ OK ] Mounting focus subsystem...",
            "[ OK ] Loading neural pathways...",
            "[ OK ] Syncing cognitive cache...",
            "[ OK ] Calibrating attention kernel...",
            "[ OK ] Establishing secure session..."
        ]
        let count = max(1, Int(progress * CGFloat(all.count)))
        return Array(all.prefix(count))
    }
}