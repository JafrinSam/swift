import SwiftUI

// MARK: - Walkthrough Step Model

struct WalkthroughStep {
    let title: String
    let subtitle: String
    let description: String
    let icon: String
    let color: Color
    let features: [(icon: String, text: String)]
}

// MARK: - Main Walkthrough View

struct AppWalkthroughView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0

    private let steps: [WalkthroughStep] = [
        WalkthroughStep(
            title: "COMMAND CENTER",
            subtitle: "Your Mission HQ",
            description: "Start focus timers, log completed missions, and monitor your live burnout level.",
            icon: "terminal.fill",
            color: .toxicLime,
            features: [
                ("timer", "Pomodoro & Flow mode timers"),
                ("flame.fill", "Real-time burnout tracking"),
                ("mic.fill", "Voice logs for mission notes")
            ]
        ),
        WalkthroughStep(
            title: "GOAL REGISTRY",
            subtitle: "Mission Database",
            description: "Create, organize, and execute quests across three difficulty tiers.",
            icon: "square.stack.3d.up.fill",
            color: .electricCyan,
            features: [
                ("circle.fill", "Easy — daily tasks"),
                ("exclamationmark.circle.fill", "Medium — sprint goals"),
                ("exclamationmark.triangle.fill", "Boss — technical debt (2× XP)")
            ]
        ),
        WalkthroughStep(
            title: "VITALITY HUB",
            subtitle: "Cognitive Analytics",
            description: "Analyze your focus patterns, track burnout history, and celebrate achievements.",
            icon: "waveform.path.ecg",
            color: .ballisticOrange,
            features: [
                ("chart.bar.xaxis", "Daily focus breakdown"),
                ("square.grid.3x3.fill", "GitHub-style heatmap"),
                ("trophy.fill", "Milestone achievements")
            ]
        ),
        WalkthroughStep(
            title: "DEVELOPER TOOLKIT",
            subtitle: "Tech Utilities",
            description: "Quick-access tools and a personal snippet library for faster coding.",
            icon: "wrench.and.screwdriver.fill",
            color: .purple,
            features: [
                ("wand.and.stars", "Base64 & JSON formatters"),
                ("book.closed.fill", "Personal snippet vault"),
                ("bolt.fill", "Keyboard shortcuts")
            ]
        ),
        WalkthroughStep(
            title: "SYSTEM ARMORY",
            subtitle: "Customize & Level Up",
            description: "Spend earned Nanobytes on themes, and manage your developer profile.",
            icon: "gearshape.2.fill",
            color: .ashGrey,
            features: [
                ("paintpalette.fill", "Unlock accent themes"),
                ("person.fill", "Developer profile & titles"),
                ("star.fill", "XP & leveling system")
            ]
        )
    ]

    var body: some View {
        ZStack {
            Color.voidBlack.ignoresSafeArea()

            VStack(spacing: 0) {
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(steps.indices, id: \.self) { index in
                        StepCard(step: steps[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)

                // Bottom controls
                bottomBar
            }

            // Subtle top glow
            VStack {
                steps[currentPage].color
                    .opacity(0.06)
                    .frame(height: 300)
                    .blur(radius: 80)
                    .offset(y: -80)
                Spacer()
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentPage)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: 20) {
            // Page dots
            HStack(spacing: 8) {
                ForEach(steps.indices, id: \.self) { i in
                    Capsule()
                        .fill(i == currentPage ? steps[currentPage].color : Color.ashGrey.opacity(0.3))
                        .frame(width: i == currentPage ? 24 : 8, height: 8)
                        .animation(.spring(response: 0.3), value: currentPage)
                }
            }

            // Action buttons
            HStack(spacing: 16) {
                if currentPage > 0 {
                    Button {
                        Haptics.shared.play(.light)
                        withAnimation { currentPage -= 1 }
                    } label: {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color.ashGrey)
                            .frame(width: 50, height: 50)
                            .background(Color.carbonGrey)
                            .clipShape(Circle())
                    }
                    .transition(.scale.combined(with: .opacity))
                }

                Button {
                    if currentPage < steps.count - 1 {
                        Haptics.shared.play(.light)
                        withAnimation { currentPage += 1 }
                    } else {
                        Haptics.shared.notify(.success)
                        withAnimation { isPresented = false }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(currentPage == steps.count - 1 ? "START FORGING" : "NEXT")
                            .font(.system(size: 15, weight: .black, design: .monospaced))
                        Image(systemName: currentPage == steps.count - 1 ? "bolt.fill" : "arrow.right")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundStyle(.black)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .background(steps[currentPage].color)
                    .clipShape(Capsule())
                }

                if currentPage == 0 {
                    // Balance layout with invisible placeholder
                    Color.clear
                        .frame(width: 50, height: 50)
                }
            }
            .padding(.horizontal, 24)

            // Skip link
            if currentPage < steps.count - 1 {
                Button("Skip Tour") {
                    Haptics.shared.play(.light)
                    withAnimation { isPresented = false }
                }
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.ashGrey.opacity(0.6))
            } else {
                Color.clear.frame(height: 18)
            }
        }
        .padding(.bottom, 40)
    }
}

// MARK: - Individual Step Card

private struct StepCard: View {
    let step: WalkthroughStep

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Hero icon
                ZStack {
                    Circle()
                        .fill(step.color.opacity(0.1))
                        .frame(width: 140, height: 140)
                    Circle()
                        .stroke(step.color.opacity(0.2), lineWidth: 1)
                        .frame(width: 140, height: 140)
                    Image(systemName: step.icon)
                        .font(.system(size: 56))
                        .foregroundStyle(step.color)
                        .symbolEffect(.bounce, options: .nonRepeating)
                }
                .padding(.top, 48)

                // Title block
                VStack(spacing: 8) {
                    Text(step.title)
                        .font(.system(size: 26, weight: .black, design: .monospaced))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text(step.subtitle.uppercased())
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(step.color)
                        .tracking(3)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(step.color.opacity(0.1))
                        .cornerRadius(6)
                }

                // Description
                Text(step.description)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(Color.ashGrey)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                // Feature list
                VStack(spacing: 12) {
                    ForEach(step.features, id: \.text) { feature in
                        HStack(spacing: 14) {
                            Image(systemName: feature.icon)
                                .font(.system(size: 14))
                                .foregroundStyle(step.color)
                                .frame(width: 28, height: 28)
                                .background(step.color.opacity(0.1))
                                .cornerRadius(8)

                            Text(feature.text)
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundStyle(.white)

                            Spacer()

                            Image(systemName: "checkmark")
                                .font(.caption.bold())
                                .foregroundStyle(step.color.opacity(0.6))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.carbonGrey.opacity(0.5))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .scrollIndicators(.hidden)
    }
}

#Preview {
    AppWalkthroughView(isPresented: .constant(true))
        .preferredColorScheme(.dark)
}
