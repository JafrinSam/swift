import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var heroes: [Hero]
    
    @State private var showWisdom = true 
    @AppStorage("selectedTab") private var selectedTab = 0
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showLevelUp = false
    @State private var levelUpLevel = 1
    
    var hero: Hero? { heroes.first }
    
    var body: some View {
        if !hasSeenOnboarding && heroes.isEmpty {
            OnboardingView()
        } else {
            mainAppView
                .onAppear {
                    // Auto-mark onboarding complete for existing users
                    if !hasSeenOnboarding && !heroes.isEmpty {
                        hasSeenOnboarding = true
                    }
                }
        }
    }
    
    private var mainAppView: some View {
        ZStack {
            // 1. THE MAIN SYSTEM CORE
            TabView(selection: $selectedTab) {
                BattleView()
                    .tag(0)
                    .tabItem {
                        Label("Command", systemImage: "terminal.fill")
                    }
                
                QuestBoardView()
                    .tag(1)
                    .tabItem {
                        Label("Registry", systemImage: "square.stack.3d.up.fill")
                    }
                
                TodoListView()
                    .tag(2)
                    .tabItem {
                        Label("Deadlines", systemImage: "bell.badge.fill")
                    }
                
                DashboardView()
                    .tag(3)
                    .tabItem {
                        Label("Vitality", systemImage: "waveform.path.ecg")
                    }
                
                AchievementsView()
                    .tag(4)
                    .tabItem { 
                        Label("Milestones", systemImage: "trophy.circle.fill") 
                    }
                
                MarketplaceView()
                    .tag(5)
                    .tabItem {
                        Label("Armory", systemImage: "cart.fill")
                    }
                
                SnippetLibraryView() // FIXED: Renamed from Grimoire
                    .tag(6)
                    .tabItem {
                        Label("Library", systemImage: "book.closed.fill")
                    }
                
                SettingsView()
                    .tag(7)
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
            }
            .tint(Color.toxicLime) // Use our high-tech green glow
            
            // 2. THE SYSTEM OVERLAYS
            if showWisdom {
                NeuralSyncView(isVisible: $showWisdom)
                    .zIndex(2)
                    .transition(.asymmetric(
                        insertion: AnyTransition.opacity,
                        removal: AnyTransition.move(edge: .top).combined(with: AnyTransition.opacity)
                    ))
            }
            
            // 3. LEVEL UP OVERLAY (Global — shows on any tab)
            if showLevelUp {
                LevelUpAlert(
                    newLevel: levelUpLevel,
                    rewards: [
                        "+100 Nanobytes",
                        "New XP Threshold: \(levelUpLevel * 120)",
                        "System Integrity Restored"
                    ],
                    onDismiss: {
                        withAnimation(.easeOut(duration: 0.3)) {
                            showLevelUp = false
                        }
                    }
                )
                .transition(.opacity.combined(with: .scale))
                .zIndex(10)
            }
        }
        // Forces dark mode even if the user's phone is in light mode
        .preferredColorScheme(.dark)
        // High-end visual tweak: Ensures the ZStack content ignores safe areas where needed
        .background(Color.voidBlack.ignoresSafeArea())
        .onAppear {
            checkForDailyReset()
        }
        .onChange(of: hero?.level) { oldValue, newValue in
            if let newVal = newValue, let oldVal = oldValue, newVal > oldVal {
                levelUpLevel = newVal
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showLevelUp = true
                }
            }
        }
    }
    
    private func checkForDailyReset() {
        if let hero = heroes.first {
            let calendar = Calendar.current
            if !calendar.isDateInToday(hero.lastActivityTimestamp) {
                // If last activity wasn't today, reset the daily focus counter
                hero.totalFocusMinutes = 0
                hero.lastActivityTimestamp = Date()
                // Also reset burnout slightly for a fresh start
                hero.burnoutLevel = max(0, hero.burnoutLevel - 0.3) 
            }
        }
    }
}