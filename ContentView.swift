import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Query private var heroes: [Hero]
    
    @State private var showWisdom = true
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
                    if !hasSeenOnboarding && !heroes.isEmpty {
                        hasSeenOnboarding = true
                    }
                }
        }
    }
    
    private var mainAppView: some View {
        ZStack {
            // Adaptive layout: Sidebar on iPad, Tabs on iPhone
            if sizeClass == .regular {
                iPadSidebarView
            } else {
                iPhoneTabView
            }
            
            // OVERLAYS (shared across both layouts)
            if showWisdom {
                NeuralSyncView(isVisible: $showWisdom)
                    .zIndex(2)
                    .transition(.asymmetric(
                        insertion: AnyTransition.opacity,
                        removal: AnyTransition.move(edge: .top).combined(with: AnyTransition.opacity)
                    ))
            }
            
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
        .preferredColorScheme(.dark)
        .background(Color.voidBlack.ignoresSafeArea())
        .onAppear { checkForDailyReset() }
        .onChange(of: hero?.level) { oldValue, newValue in
            if let newVal = newValue, let oldVal = oldValue, newVal > oldVal {
                levelUpLevel = newVal
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showLevelUp = true
                }
            }
        }
    }
    
    // =====================================================
    // MARK: - iPad: Sidebar Navigation
    // =====================================================
    
    @State private var sidebarSelection: SidebarItem? = .command
    
    private var iPadSidebarView: some View {
        NavigationSplitView {
            sidebarContent
                .navigationTitle("ForgeFlow")
        } detail: {
            sidebarDetailView
        }
        .tint(Color.toxicLime)
    }
    
    private var sidebarContent: some View {
        List(selection: $sidebarSelection) {
            // CORE
            Section {
                sidebarRow(.command)
                sidebarRow(.registry)
                sidebarRow(.deadlines)
                sidebarRow(.standup)
            } header: {
                Text("COMMAND CENTER")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
            }
            
            // TOOLS
            Section {
                sidebarRow(.devTools)
                sidebarRow(.library)
            } header: {
                Text("TOOLKIT")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
            }
            
            // ANALYTICS
            Section {
                sidebarRow(.vitality)
                sidebarRow(.milestones)
                sidebarRow(.recharge)
            } header: {
                Text("ANALYTICS")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
            }
            
            // SYSTEM
            Section {
                sidebarRow(.armory)
                sidebarRow(.settings)
            } header: {
                Text("SYSTEM")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(Color.voidBlack)
    }
    
    private func sidebarRow(_ item: SidebarItem) -> some View {
        Label(item.label, systemImage: item.icon)
            .font(.system(.subheadline, design: .monospaced))
            .tag(item)
    }
    
    @ViewBuilder
    private var sidebarDetailView: some View {
        switch sidebarSelection {
        case .command:    BattleView()
        case .registry:   QuestBoardView()
        case .deadlines:  TodoListView()
        case .standup:    StandupNotesView()
        case .devTools:   DevUtilitiesView()
        case .vitality:   DashboardView()
        case .milestones: AchievementsView()
        case .recharge:   RechargeHubView()
        case .armory:     MarketplaceView()
        case .library:    SnippetLibraryView()
        case .settings:   SettingsView()
        case nil:         BattleView()
        }
    }
    
    // =====================================================
    // MARK: - iPhone: 5-Tab Grouped Navigation
    // =====================================================
    
    @AppStorage("selectedTab") private var selectedTab = 0
    
    private var iPhoneTabView: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Command (Focus Timer)
            BattleView()
                .tag(0)
                .tabItem {
                    Label("Command", systemImage: "terminal.fill")
                }
            
            // Tab 2: Board (Registry + Deadlines + Standup)
            BoardHubView()
                .tag(1)
                .tabItem {
                    Label("Board", systemImage: "square.stack.3d.up.fill")
                }
            
            // Tab 3: Vitality (Dashboard + Milestones)
            VitalityHubView()
                .tag(2)
                .tabItem {
                    Label("Vitality", systemImage: "waveform.path.ecg")
                }
            
            // Tab 4: Toolkit (Dev Tools + Library)
            ToolkitHubView()
                .tag(3)
                .tabItem {
                    Label("Toolkit", systemImage: "wrench.and.screwdriver.fill")
                }
            
            // Tab 5: System (Armory + Settings)
            SystemHubView()
                .tag(4)
                .tabItem {
                    Label("System", systemImage: "gearshape.2.fill")
                }
        }
        .tint(Color.toxicLime)
    }
    
    // MARK: - Daily Reset
    private func checkForDailyReset() {
        if let hero = heroes.first {
            let calendar = Calendar.current
            if !calendar.isDateInToday(hero.lastActivityTimestamp) {
                hero.totalFocusMinutes = 0
                hero.lastActivityTimestamp = Date()
                hero.burnoutLevel = max(0, hero.burnoutLevel - 0.3)
            }
        }
    }
}

// =====================================================
// MARK: - Sidebar Item Enum
// =====================================================

enum SidebarItem: String, CaseIterable, Identifiable {
    case command, registry, deadlines, standup
    case devTools, library
    case vitality, milestones, recharge
    case armory, settings
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .command:    return "Command"
        case .registry:   return "Registry"
        case .deadlines:  return "Deadlines"
        case .standup:    return "Standup"
        case .devTools:   return "Dev Tools"
        case .library:    return "Library"
        case .vitality:   return "Vitality"
        case .milestones: return "Milestones"
        case .recharge:   return "Recharge"
        case .armory:     return "Armory"
        case .settings:   return "Settings"
        }
    }
    
    var icon: String {
        switch self {
        case .command:    return "terminal.fill"
        case .registry:   return "square.stack.3d.up.fill"
        case .deadlines:  return "bell.badge.fill"
        case .standup:    return "text.badge.checkmark"
        case .devTools:   return "wrench.and.screwdriver.fill"
        case .library:    return "book.closed.fill"
        case .vitality:   return "waveform.path.ecg"
        case .milestones: return "trophy.circle.fill"
        case .recharge:   return "gamecontroller.fill"
        case .armory:     return "cart.fill"
        case .settings:   return "gearshape.fill"
        }
    }
}

// =====================================================
// MARK: - iPhone Hub Views (Grouped Tabs)
// =====================================================

// MARK: Board Hub — Registry + Deadlines + Standup
struct BoardHubView: View {
    @State private var segment = 0
    
    var body: some View {
        VStack(spacing: 0) {
            segmentPicker
            
            TabView(selection: $segment) {
                QuestBoardView().tag(0)
                TodoListView().tag(1)
                StandupNotesView().tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .background(Color.voidBlack)
    }
    
    private var segmentPicker: some View {
        HStack(spacing: 0) {
            hubTab(label: "Registry", icon: "square.stack.3d.up.fill", index: 0)
            hubTab(label: "Deadlines", icon: "bell.badge.fill", index: 1)
            hubTab(label: "Standup", icon: "text.badge.checkmark", index: 2)
        }
        .padding(4)
        .background(Color.carbonGrey.opacity(0.6))
        .cornerRadius(14)
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
    
    private func hubTab(label: String, icon: String, index: Int) -> some View {
        let isActive = segment == index
        return Button {
            withAnimation(.spring(response: 0.3)) { segment = index }
            Haptics.shared.play(.light)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 10))
                Text(label).font(.system(size: 10, weight: .bold, design: .monospaced))
            }
            .foregroundStyle(isActive ? .black : Color.ashGrey)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isActive ? Color.toxicLime : Color.clear)
            .cornerRadius(10)
        }
    }
}

// MARK: Vitality Hub — Dashboard + Milestones
struct VitalityHubView: View {
    @State private var segment = 0
    
    var body: some View {
        VStack(spacing: 0) {
            segmentPicker
            
            TabView(selection: $segment) {
                DashboardView().tag(0)
                AchievementsView().tag(1)
                RechargeHubView().tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .background(Color.voidBlack)
    }
    
    private var segmentPicker: some View {
        HStack(spacing: 0) {
            hubTab(label: "Dashboard", icon: "waveform.path.ecg", index: 0)
            hubTab(label: "Milestones", icon: "trophy.circle.fill", index: 1)
            hubTab(label: "Recharge", icon: "gamecontroller.fill", index: 2)
        }
        .padding(4)
        .background(Color.carbonGrey.opacity(0.6))
        .cornerRadius(14)
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
    
    private func hubTab(label: String, icon: String, index: Int) -> some View {
        let isActive = segment == index
        return Button {
            withAnimation(.spring(response: 0.3)) { segment = index }
            Haptics.shared.play(.light)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 10))
                Text(label).font(.system(size: 10, weight: .bold, design: .monospaced))
            }
            .foregroundStyle(isActive ? .black : Color.ashGrey)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isActive ? Color.toxicLime : Color.clear)
            .cornerRadius(10)
        }
    }
}

// MARK: Toolkit Hub — Dev Tools + Library
struct ToolkitHubView: View {
    @State private var segment = 0
    
    var body: some View {
        VStack(spacing: 0) {
            segmentPicker
            
            TabView(selection: $segment) {
                DevUtilitiesView().tag(0)
                SnippetLibraryView().tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .background(Color.voidBlack)
    }
    
    private var segmentPicker: some View {
        HStack(spacing: 0) {
            hubTab(label: "Dev Tools", icon: "wrench.and.screwdriver.fill", index: 0)
            hubTab(label: "Library", icon: "book.closed.fill", index: 1)
        }
        .padding(4)
        .background(Color.carbonGrey.opacity(0.6))
        .cornerRadius(14)
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
    
    private func hubTab(label: String, icon: String, index: Int) -> some View {
        let isActive = segment == index
        return Button {
            withAnimation(.spring(response: 0.3)) { segment = index }
            Haptics.shared.play(.light)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 10))
                Text(label).font(.system(size: 10, weight: .bold, design: .monospaced))
            }
            .foregroundStyle(isActive ? .black : Color.ashGrey)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isActive ? Color.toxicLime : Color.clear)
            .cornerRadius(10)
        }
    }
}

// MARK: System Hub — Armory + Settings
struct SystemHubView: View {
    @State private var segment = 0
    
    var body: some View {
        VStack(spacing: 0) {
            segmentPicker
            
            TabView(selection: $segment) {
                MarketplaceView().tag(0)
                SettingsView().tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .background(Color.voidBlack)
    }
    
    private var segmentPicker: some View {
        HStack(spacing: 0) {
            hubTab(label: "Armory", icon: "cart.fill", index: 0)
            hubTab(label: "Settings", icon: "gearshape.fill", index: 1)
        }
        .padding(4)
        .background(Color.carbonGrey.opacity(0.6))
        .cornerRadius(14)
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
    
    private func hubTab(label: String, icon: String, index: Int) -> some View {
        let isActive = segment == index
        return Button {
            withAnimation(.spring(response: 0.3)) { segment = index }
            Haptics.shared.play(.light)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 10))
                Text(label).font(.system(size: 10, weight: .bold, design: .monospaced))
            }
            .foregroundStyle(isActive ? .black : Color.ashGrey)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isActive ? Color.toxicLime : Color.clear)
            .cornerRadius(10)
        }
    }
}