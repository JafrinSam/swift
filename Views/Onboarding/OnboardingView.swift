import SwiftUI
import SwiftData

// MARK: - Unified Onboarding + Walkthrough
// Pages:
//  0 — Welcome (splash)
//  1 — How it Works (XP/Burnout loop)
//  2 — Flow Engine (Focus Timer)
//  3 — Goal Registry (Quest Board)
//  4 — Vitality Hub (Analytics)
//  5 — Recharge Arcade (Mini-games)
//  6 — Developer Toolkit
//  7 — System Armory (Theme/Marketplace)
//  8 — Notifications permission
//  9 — Profile Setup → Launch

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("hasCompletedWalkthrough") private var hasCompletedWalkthrough = false

    @State private var currentPage = 0
    @State private var userName = ""
    @State private var selectedIdentity = "Full Stack Dev"
    @State private var animateIcon = false

    private let totalPages = 10
    private let identities = [
        "Full Stack Dev", "iOS Engineer", "ML Researcher",
        "Cybersecurity", "Game Dev", "Data Scientist",
        "Backend Dev", "UI/UX Designer"
    ]

    // Page accent colours (same index as pages)
    private let pageColors: [Color] = [
        .toxicLime, .electricCyan, .toxicLime,
        .electricCyan, .ballisticOrange, .toxicLime,
        .purple, .ashGrey, .electricCyan, .toxicLime
    ]

    private var accent: Color { pageColors[min(currentPage, pageColors.count - 1)] }

    var body: some View {
        ZStack {
            Color.voidBlack.ignoresSafeArea()

            // Ambient glow that follows accent colour
            VStack {
                accent.opacity(0.07)
                    .frame(height: 400)
                    .blur(radius: 100)
                    .offset(y: -80)
                Spacer()
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .animation(.easeInOut(duration: 0.5), value: currentPage)

            // Page content
            TabView(selection: $currentPage) {
                welcomePage.tag(0)
                howItWorksPage.tag(1)
                flowEnginePage.tag(2)
                goalRegistryPage.tag(3)
                vitalityHubPage.tag(4)
                rechargeArcadePage.tag(5)
                devToolkitPage.tag(6)
                systemArmoryPage.tag(7)
                permissionsPage.tag(8)
                setupPage.tag(9)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.35), value: currentPage)

            // Bottom Navigation Bar
            if currentPage < totalPages - 1 {
                bottomNav
            }
        }
    }

    // MARK: - Bottom Navigation

    private var bottomNav: some View {
        VStack {
            Spacer()

            HStack(alignment: .center) {
                // Page dots
                HStack(spacing: 7) {
                    ForEach(0..<totalPages, id: \.self) { i in
                        Capsule()
                            .fill(i == currentPage ? accent : Color.ashGrey.opacity(0.25))
                            .frame(width: i == currentPage ? 22 : 7, height: 7)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                    }
                }

                Spacer()

                // Permissions page has its own buttons
                if currentPage != 8 {
                    Button {
                        Haptics.shared.play(.light)
                        withAnimation { currentPage += 1 }
                    } label: {
                        HStack(spacing: 6) {
                            Text("NEXT")
                                .font(.system(size: 14, weight: .black, design: .monospaced))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundStyle(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 13)
                        .background(accent)
                        .clipShape(Capsule())
                    }
                    .animation(.spring(response: 0.3), value: currentPage)
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 50)
        }
    }

    // MARK: ── PAGE 0: Welcome ──────────────────────────────────────────────

    private var welcomePage: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(Color.toxicLime.opacity(0.15), lineWidth: 2)
                    .frame(width: 200, height: 200)
                    .scaleEffect(animateIcon ? 1.4 : 1.0)
                    .opacity(animateIcon ? 0 : 0.6)
                Circle()
                    .stroke(Color.toxicLime.opacity(0.1), lineWidth: 1)
                    .frame(width: 160, height: 160)
                Image(systemName: "bolt.shield.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(Color.toxicLime)
                    .scaleEffect(animateIcon ? 1 : 0.4)
            }
            .onAppear {
                withAnimation(.spring(response: 0.9, dampingFraction: 0.6)) {
                    animateIcon = true
                }
            }

            VStack(spacing: 10) {
                Text("FORGEFLOW")
                    .font(.system(size: 40, weight: .black, design: .monospaced))
                    .foregroundStyle(.white)

                Text("Productivity Command Center")
                    .font(.system(size: 15, design: .monospaced))
                    .foregroundStyle(Color.toxicLime)
                    .tracking(1)
            }

            Text("Transform deep work into a gamified system of measurable progress. Built for developers, by a developer.")
                .font(.system(.body, design: .monospaced))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.ashGrey)
                .padding(.horizontal, 32)

            // Feature pills
            HStack(spacing: 10) {
                featurePill("XP & Levels", icon: "star.fill", color: .toxicLime)
                featurePill("Burnout AI", icon: "flame.fill", color: .ballisticOrange)
                featurePill("Mini-Games", icon: "gamecontroller.fill", color: .electricCyan)
            }

            Spacer()
            Spacer()
        }
        .padding()
    }

    // MARK: ── PAGE 1: How It Works ───────────────────────────────────────

    private var howItWorksPage: some View {
        VStack(spacing: 24) {
            Spacer()

            sectionBadge("THE CORE LOOP", color: .electricCyan)

            Text("HOW FORGEFLOW WORKS")
                .font(.system(size: 24, weight: .black, design: .monospaced))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text("Every action feeds a dynamic developer profile that tracks your progress and wellbeing.")
                .font(.system(.subheadline, design: .monospaced))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.ashGrey)
                .padding(.horizontal, 24)

            // Loop diagram
            VStack(spacing: 2) {
                loopStep(num: "01", title: "Create Quests", detail: "Log tasks as Easy, Medium, or Boss missions", color: .electricCyan)
                loopArrow
                loopStep(num: "02", title: "Focus & Execute", detail: "Run Pomodoro or Flow timers to earn XP", color: .toxicLime)
                loopArrow
                loopStep(num: "03", title: "Monitor Burnout", detail: "AI tracks fatigue — recover in the Arcade", color: .ballisticOrange)
                loopArrow
                loopStep(num: "04", title: "Level Up", detail: "Unlock titles, themes, and achievements", color: .purple)
            }
            .padding(.horizontal, 24)

            Spacer()
            Spacer()
        }
        .padding()
    }

    // MARK: ── PAGE 2: Flow Engine ─────────────────────────────────────────

    private var flowEnginePage: some View {
        VStack(spacing: 28) {
            Spacer()

            sectionBadge("COMMAND CENTER", color: .toxicLime)

            // Timer mockup
            ZStack {
                Circle()
                    .stroke(Color.toxicLime.opacity(0.08), lineWidth: 10)
                    .frame(width: 150, height: 150)
                Circle()
                    .trim(from: 0, to: 0.68)
                    .stroke(Color.toxicLime, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: 150, height: 150)
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 4) {
                    Text("25:00")
                        .font(.system(size: 28, weight: .black, design: .monospaced))
                        .foregroundStyle(.white)
                    Text("FOCUS")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.toxicLime)
                        .tracking(3)
                }
            }
            .overlay(
                Text("FLOW MODE").font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.toxicLime)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Color.toxicLime.opacity(0.1)).cornerRadius(4)
                    .offset(y: 95)
            )

            pageTitle("FLOW ENGINE")
            pageDesc("Start Pomodoro sprints or unlimited Flow sessions directly from the Command tab. Each completed session awards XP and logs your focus time.")

            featureList([
                ("timer", "25/5 Pomodoro & unlimited Flow mode", .toxicLime),
                ("flame.fill", "Burnout rises with effort — rest to recover", .ballisticOrange),
                ("mic.fill", "Voice memo logs attached to each session", .electricCyan),
                ("livephoto", "Live Activity shown on the Lock Screen", .toxicLime)
            ])

            Spacer()
        }
        .padding()
    }

    // MARK: ── PAGE 3: Goal Registry ───────────────────────────────────────

    private var goalRegistryPage: some View {
        VStack(spacing: 24) {
            Spacer()

            sectionBadge("BOARD TAB", color: .electricCyan)

            // Quest board mockup
            VStack(spacing: 6) {
                questRow(title: "Refactor auth module", tier: "Boss", color: .ballisticOrange, done: false)
                questRow(title: "Write unit tests", tier: "Medium", color: .electricCyan, done: true)
                questRow(title: "Update README", tier: "Easy", color: .toxicLime, done: false)
            }
            .padding(14)
            .background(Color.carbonGrey)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.electricCyan.opacity(0.25), lineWidth: 1))
            .padding(.horizontal, 20)

            pageTitle("GOAL REGISTRY")
            pageDesc("Create and manage quests across three tiers. Boss quests represent technical debt and award 2× XP upon completion.")

            featureList([
                ("circle.fill", "Easy — daily micro-tasks", .toxicLime),
                ("exclamationmark.circle.fill", "Medium — sprint-level goals", .electricCyan),
                ("exclamationmark.triangle.fill", "Boss — tech debt, 2× XP reward", .ballisticOrange)
            ])

            Spacer()
        }
        .padding()
    }

    // MARK: ── PAGE 4: Vitality Hub ────────────────────────────────────────

    private var vitalityHubPage: some View {
        VStack(spacing: 24) {
            Spacer()

            sectionBadge("VITALITY TAB", color: .ballisticOrange)

            // Chart mockup
            VStack(spacing: 10) {
                HStack(alignment: .bottom, spacing: 5) {
                    ForEach([0.3, 0.6, 0.8, 0.5, 0.9, 0.7, 0.4], id: \.self) { v in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.ballisticOrange.opacity(v))
                            .frame(width: 18, height: CGFloat(v) * 70)
                    }
                }
                .frame(height: 70)
                HStack(spacing: 0) {
                    ForEach(["M","T","W","T","F","S","S"], id: \.self) { d in
                        Text(d).font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(Color.ashGrey.opacity(0.5))
                            .frame(maxWidth: .infinity)
                    }
                }
                // Burnout gauge
                HStack {
                    Text("BURNOUT LEVEL").font(.system(size: 9, design: .monospaced)).foregroundStyle(Color.ashGrey)
                    Spacer()
                    Text("34%").font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundStyle(Color.toxicLime)
                }
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(Color.white.opacity(0.05)).frame(height: 6)
                    RoundedRectangle(cornerRadius: 3).fill(Color.toxicLime).frame(width: 80, height: 6)
                }
            }
            .padding(16)
            .background(Color.carbonGrey)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.ballisticOrange.opacity(0.2), lineWidth: 1))
            .padding(.horizontal, 20)

            pageTitle("VITALITY HUB")
            pageDesc("Track your cognitive performance over time. See focus distribution, burnout history, and unlock achievements as you grow.")

            featureList([
                ("chart.bar.xaxis", "Daily focus breakdown by session", .ballisticOrange),
                ("square.grid.3x3.fill", "GitHub-style contribution heatmap", .electricCyan),
                ("trophy.fill", "Milestone achievements & rewards", .toxicLime)
            ])

            Spacer()
        }
        .padding()
    }

    // MARK: ── PAGE 5: Recharge Arcade ─────────────────────────────────────

    private var rechargeArcadePage: some View {
        VStack(spacing: 24) {
            Spacer()

            sectionBadge("VITALITY → RECHARGE", color: .toxicLime)

            // Game cards mockup
            HStack(spacing: 14) {
                gameCardMock(title: "CODE SNAKE", icon: "snake.fill", color: .toxicLime)
                gameCardMock(title: "MEMORY FLIP", icon: "rectangle.2.swap", color: .electricCyan)
            }
            .padding(.horizontal, 32)

            pageTitle("RECHARGE ARCADE")
            pageDesc("When burnout climbs, don't grind harder — play. Both mini-games actively reduce your burnout level while earning bonus XP.")

            featureList([
                ("snake.fill", "Code Snake — reflexes & focus", .toxicLime),
                ("rectangle.2.swap", "Memory Flip — pattern recognition", .electricCyan),
                ("heart.fill", "Each game session lowers burnout", .ballisticOrange),
                ("star.fill", "Bonus XP awarded for completing games", .purple)
            ])

            Spacer()
        }
        .padding()
    }

    // MARK: ── PAGE 6: Developer Toolkit ──────────────────────────────────

    private var devToolkitPage: some View {
        VStack(spacing: 24) {
            Spacer()

            sectionBadge("TOOLKIT TAB", color: .purple)

            ZStack {
                Circle().fill(Color.purple.opacity(0.08)).frame(width: 130, height: 130)
                Circle().stroke(Color.purple.opacity(0.15), lineWidth: 1).frame(width: 130, height: 130)
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(Color.purple)
                    .symbolEffect(.bounce, options: .nonRepeating)
            }

            pageTitle("DEVELOPER TOOLKIT")
            pageDesc("Quick-access utilities built for developers. Convert, format, and manage code without leaving the app.")

            featureList([
                ("wand.and.stars", "Base64 encode/decode", .purple),
                ("curlybraces", "JSON formatter & validator", .purple),
                ("book.closed.fill", "Personal code snippet vault", .electricCyan),
                ("bolt.fill", "Keyboard shortcut cheatsheet", .toxicLime)
            ])

            Spacer()
        }
        .padding()
    }

    // MARK: ── PAGE 7: System Armory ───────────────────────────────────────

    private var systemArmoryPage: some View {
        VStack(spacing: 24) {
            Spacer()

            sectionBadge("SYSTEM TAB", color: .ashGrey)

            // Theme preview mockup
            HStack(spacing: 10) {
                ForEach([Color.toxicLime, Color.electricCyan, Color.ballisticOrange, Color.purple, Color.pink], id: \.self) { c in
                    Circle()
                        .fill(c)
                        .frame(width: 44, height: 44)
                        .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
                }
            }
            .padding(16)
            .background(Color.carbonGrey)
            .cornerRadius(20)

            pageTitle("SYSTEM ARMORY")
            pageDesc("Spend Nanobytes — earned from completing quests — on accent themes, titles, and profile customisation.")

            featureList([
                ("paintpalette.fill", "5+ accent colour themes", .ballisticOrange),
                ("person.fill", "Developer titles tied to your level", .electricCyan),
                ("star.fill", "XP-based leveling from Lv.1 to Lv.50", .toxicLime),
                ("gearshape.fill", "Notification & display preferences", .ashGrey)
            ])

            Spacer()
        }
        .padding()
    }

    // MARK: ── PAGE 8: Permissions ─────────────────────────────────────────

    private var permissionsPage: some View {
        VStack(spacing: 28) {
            Spacer()

            sectionBadge("SYSTEM ACCESS", color: .electricCyan)

            // Notification preview
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "app.badge.fill").foregroundStyle(Color.toxicLime)
                    Text("FORGEFLOW").font(.system(size: 10, weight: .bold).monospaced()).foregroundStyle(Color.ashGrey)
                    Spacer()
                    Text("now").font(.system(size: 10).monospaced()).foregroundStyle(Color.ashGrey)
                }
                Text("Mission Complete 🎯")
                    .font(.system(size: 14, weight: .bold).monospaced())
                    .foregroundStyle(.white)
                Text("Backend Refactor conquered. +120 XP awarded.")
                    .font(.system(size: 12).monospaced())
                    .foregroundStyle(Color.ashGrey)
            }
            .padding(16)
            .background(Color.carbonGrey)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.electricCyan.opacity(0.3), lineWidth: 1))
            .padding(.horizontal, 24)

            pageTitle("ENABLE NOTIFICATIONS")
            pageDesc("Receive session-complete alerts, burnout warnings, and mission reminders to stay on track.")

            VStack(spacing: 14) {
                Button {
                    NotificationManager.shared.requestPermission()
                    Haptics.shared.notify(.success)
                    withAnimation { currentPage += 1 }
                } label: {
                    Text("ENABLE NOTIFICATIONS")
                        .font(.system(.headline, design: .monospaced).bold())
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.electricCyan)
                        .cornerRadius(14)
                }

                Button {
                    withAnimation { currentPage += 1 }
                } label: {
                    Text("MAYBE LATER")
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundStyle(Color.ashGrey)
                }
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .padding()
    }

    // MARK: ── PAGE 9: Profile Setup ───────────────────────────────────────

    private var setupPage: some View {
        VStack(spacing: 22) {
            Spacer()

            Image(systemName: "person.crop.circle.badge.checkmark")
                .font(.system(size: 52))
                .foregroundStyle(Color.toxicLime)

            Text("INITIALIZE PROFILE")
                .font(.system(size: 22, weight: .black, design: .monospaced))
                .foregroundStyle(.white)

            Text("Choose your operator name and specialization. This defines your developer identity inside ForgeFlow.")
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(Color.ashGrey)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            // Name input
            VStack(alignment: .leading, spacing: 8) {
                Text("OPERATOR NAME")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.ashGrey)
                    .tracking(2)
                TextField("Enter your name", text: $userName)
                    .textFieldStyle(.plain)
                    .font(.system(.title3, design: .monospaced).bold())
                    .foregroundStyle(.white)
                    .padding()
                    .background(Color.carbonGrey)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.toxicLime.opacity(0.3), lineWidth: 1))
            }
            .padding(.horizontal, 24)

            // Identity grid
            VStack(alignment: .leading, spacing: 8) {
                Text("SPECIALIZATION")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.ashGrey)
                    .tracking(2)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(identities, id: \.self) { id in
                        Button {
                            selectedIdentity = id
                            Haptics.shared.play(.light)
                        } label: {
                            Text(id)
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(selectedIdentity == id ? .black : .white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(selectedIdentity == id ? Color.toxicLime : Color.carbonGrey)
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(
                                    selectedIdentity == id ? Color.clear : Color.white.opacity(0.08), lineWidth: 1))
                        }
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            Button { createHeroAndLaunch() } label: {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.fill")
                    Text("INITIALIZE SYSTEM")
                        .font(.system(.headline, design: .monospaced).bold())
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.toxicLime)
                .cornerRadius(16)
                .shadow(color: Color.toxicLime.opacity(0.35), radius: 12)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
            .disabled(userName.trimmingCharacters(in: .whitespaces).isEmpty)
            .opacity(userName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.4 : 1.0)
        }
        .padding()
    }

    // MARK: - Reusable Components

    private func sectionBadge(_ label: String, color: Color) -> some View {
        Text(label)
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundStyle(color)
            .tracking(2)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(color.opacity(0.12))
            .cornerRadius(6)
    }

    private func pageTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 26, weight: .black, design: .monospaced))
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
    }

    private func pageDesc(_ text: String) -> some View {
        Text(text)
            .font(.system(.subheadline, design: .monospaced))
            .multilineTextAlignment(.center)
            .foregroundStyle(Color.ashGrey)
            .padding(.horizontal, 24)
    }

    private func featureList(_ items: [(String, String, Color)]) -> some View {
        VStack(spacing: 10) {
            ForEach(items, id: \.1) { icon, text, color in
                HStack(spacing: 14) {
                    Image(systemName: icon)
                        .font(.system(size: 13))
                        .foregroundStyle(color)
                        .frame(width: 28, height: 28)
                        .background(color.opacity(0.1))
                        .cornerRadius(8)
                    Text(text)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(Color.smokeWhite)
                    Spacer()
                    Image(systemName: "checkmark")
                        .font(.caption2.bold())
                        .foregroundStyle(color.opacity(0.5))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.carbonGrey.opacity(0.5))
                .cornerRadius(10)
            }
        }
        .padding(.horizontal, 24)
    }

    private func featurePill(_ label: String, icon: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 10))
            Text(label).font(.system(size: 10, weight: .bold, design: .monospaced))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }

    // Loop diagram helpers
    private func loopStep(num: String, title: String, detail: String, color: Color) -> some View {
        HStack(spacing: 14) {
            Text(num)
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.12))
                .cornerRadius(8)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .black, design: .monospaced))
                    .foregroundStyle(.white)
                Text(detail)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color.ashGrey)
            }
            Spacer()
        }
        .padding(12)
        .background(Color.carbonGrey.opacity(0.4))
        .cornerRadius(12)
    }

    private var loopArrow: some View {
        Image(systemName: "arrow.down")
            .font(.caption2)
            .foregroundStyle(Color.ashGrey.opacity(0.4))
            .padding(.vertical, 2)
    }

    // Quest row helper
    private func questRow(title: String, tier: String, color: Color, done: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(done ? color : Color.ashGrey.opacity(0.4))
                .font(.system(size: 16))
            Text(title)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(done ? Color.ashGrey : .white)
                .strikethrough(done, color: .ashGrey)
            Spacer()
            Text(tier)
                .font(.system(size: 9, weight: .black, design: .monospaced))
                .foregroundStyle(color)
                .padding(.horizontal, 6).padding(.vertical, 3)
                .background(color.opacity(0.12))
                .cornerRadius(4)
        }
    }

    // Game card mockup
    private func gameCardMock(title: String, icon: String, color: Color) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundStyle(color)
            Text(title)
                .font(.system(size: 9, weight: .black, design: .monospaced))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color.carbonGrey)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.25), lineWidth: 1))
    }

    // MARK: - Save Hero & Launch

    private func createHeroAndLaunch() {
        let hero = Hero(
            name: userName.trimmingCharacters(in: .whitespaces),
            identity: selectedIdentity
        )
        modelContext.insert(hero)
        try? modelContext.save()
        Haptics.shared.notify(.success)
        withAnimation(.easeInOut(duration: 0.5)) {
            hasSeenOnboarding = true
            hasCompletedWalkthrough = true  // mark walkthrough done too
        }
    }
}
