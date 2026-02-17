import SwiftUI
import SwiftData

// MARK: - Achievement Model
struct Achievement: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let category: AchievementCategory
    let rarity: AchievementRarity
    let condition: (Hero, [Quest]) -> Bool
}

enum AchievementCategory: String, CaseIterable {
    case modules = "Modules"
    case focus = "Focus"
    case growth = "Growth"
    case mastery = "Mastery"
    case special = "Special"
    
    var icon: String {
        switch self {
        case .modules: return "terminal.fill"
        case .focus: return "timer"
        case .growth: return "chart.line.uptrend.xyaxis"
        case .mastery: return "crown.fill"
        case .special: return "sparkles"
        }
    }
    
    var color: Color {
        switch self {
        case .modules: return .electricCyan
        case .focus: return .ballisticOrange
        case .growth: return .toxicLime
        case .mastery: return .purple
        case .special: return .yellow
        }
    }
}

enum AchievementRarity: String {
    case common = "COMMON"
    case rare = "RARE"
    case epic = "EPIC"
    case legendary = "LEGENDARY"
    
    var color: Color {
        switch self {
        case .common: return .ashGrey
        case .rare: return .electricCyan
        case .epic: return .purple
        case .legendary: return .yellow
        }
    }
}

// MARK: - All Achievements
// MARK: - All Achievements (split for compiler performance)
let allAchievements: [Achievement] = _moduleAchievements + _focusAchievements + _growthAchievements + _masteryAchievements + _specialAchievements

private let _moduleAchievements: [Achievement] = [
    Achievement(
        title: "Initial Commit",
        description: "Complete your first module.",
        icon: "bolt.fill",
        category: .modules, rarity: .common,
        condition: { _, quests in quests.filter { $0.isCompleted }.count >= 1 }
    ),
    Achievement(
        title: "Merge Master",
        description: "Complete 5 modules.",
        icon: "arrow.triangle.merge",
        category: .modules, rarity: .common,
        condition: { _, quests in quests.filter { $0.isCompleted }.count >= 5 }
    ),
    Achievement(
        title: "Clean Coder",
        description: "Complete 10 modules.",
        icon: "terminal.fill",
        category: .modules, rarity: .rare,
        condition: { _, quests in quests.filter { $0.isCompleted }.count >= 10 }
    ),
    Achievement(
        title: "Deployment Pipeline",
        description: "Complete 25 modules.",
        icon: "shippingbox.fill",
        category: .modules, rarity: .rare,
        condition: { _, quests in quests.filter { $0.isCompleted }.count >= 25 }
    ),
    Achievement(
        title: "Production Ready",
        description: "Complete 50 modules.",
        icon: "server.rack",
        category: .modules, rarity: .epic,
        condition: { _, quests in quests.filter { $0.isCompleted }.count >= 50 }
    ),
    Achievement(
        title: "Open Source Legend",
        description: "Complete 100 modules.",
        icon: "globe.americas.fill",
        category: .modules, rarity: .legendary,
        condition: { _, quests in quests.filter { $0.isCompleted }.count >= 100 }
    ),
    Achievement(
        title: "Legacy Conqueror",
        description: "Complete a Legacy difficulty sub-module.",
        icon: "exclamationmark.shield.fill",
        category: .modules, rarity: .epic,
        condition: { _, quests in
            quests.contains { (quest: Quest) in
                quest.subQuests.contains { (sub: SubQuest) in
                    sub.difficulty == QuestDifficulty.legacy && sub.isCompleted
                }
            }
        }
    ),
    Achievement(
        title: "Debt Crusher",
        description: "Complete a Technical Debt boss quest.",
        icon: "hammer.fill",
        category: .modules, rarity: .epic,
        condition: { _, quests in
            quests.contains { (quest: Quest) in
                quest.isCompleted && quest.isBoss
            }
        }
    ),
    Achievement(
        title: "Sub-Module Surgeon",
        description: "Complete 30 individual sub-modules.",
        icon: "checklist.checked",
        category: .modules, rarity: .rare,
        condition: { _, quests in
            let total = quests.flatMap { $0.subQuests }.filter { $0.isCompleted }.count
            return total >= 30
        }
    ),
]

private let _focusAchievements: [Achievement] = [
    Achievement(
        title: "First Boot",
        description: "Log your first focus session.",
        icon: "power",
        category: .focus, rarity: .common,
        condition: { hero, _ in hero.totalFocusMinutes > 0 }
    ),
    Achievement(
        title: "Deep Work",
        description: "Focus for 60 minutes total.",
        icon: "brain.head.profile.fill",
        category: .focus, rarity: .common,
        condition: { hero, _ in hero.totalFocusMinutes >= 60 }
    ),
    Achievement(
        title: "Pomodoro Pro",
        description: "Focus for 200 minutes total.",
        icon: "timer",
        category: .focus, rarity: .rare,
        condition: { hero, _ in hero.totalFocusMinutes >= 200 }
    ),
    Achievement(
        title: "Flow State",
        description: "Focus for 500 minutes total.",
        icon: "wind",
        category: .focus, rarity: .rare,
        condition: { hero, _ in hero.totalFocusMinutes >= 500 }
    ),
    Achievement(
        title: "Hyperfocus",
        description: "Focus for 1,000 minutes total.",
        icon: "bolt.trianglebadge.exclamationmark.fill",
        category: .focus, rarity: .epic,
        condition: { hero, _ in hero.totalFocusMinutes >= 1000 }
    ),
    Achievement(
        title: "10x Engineer",
        description: "Focus for 5,000 minutes total.",
        icon: "cpu.fill",
        category: .focus, rarity: .legendary,
        condition: { hero, _ in hero.totalFocusMinutes >= 5000 }
    ),
]

private let _growthAchievements: [Achievement] = [
    Achievement(
        title: "Junior Dev",
        description: "Reach Level 3.",
        icon: "person.fill",
        category: .growth, rarity: .common,
        condition: { hero, _ in hero.level >= 3 }
    ),
    Achievement(
        title: "Mid-Level",
        description: "Reach Level 5.",
        icon: "person.fill.checkmark",
        category: .growth, rarity: .common,
        condition: { hero, _ in hero.level >= 5 }
    ),
    Achievement(
        title: "Senior Architect",
        description: "Reach Level 10.",
        icon: "crown.fill",
        category: .growth, rarity: .rare,
        condition: { hero, _ in hero.level >= 10 }
    ),
    Achievement(
        title: "Staff Engineer",
        description: "Reach Level 20.",
        icon: "star.circle.fill",
        category: .growth, rarity: .epic,
        condition: { hero, _ in hero.level >= 20 }
    ),
    Achievement(
        title: "CTO",
        description: "Reach Level 50.",
        icon: "building.2.fill",
        category: .growth, rarity: .legendary,
        condition: { hero, _ in hero.level >= 50 }
    ),
    Achievement(
        title: "Uptime Streak",
        description: "Maintain a 3-day work streak.",
        icon: "flame.fill",
        category: .growth, rarity: .common,
        condition: { hero, _ in hero.streakDays >= 3 }
    ),
    Achievement(
        title: "Weekly Sprint",
        description: "Maintain a 7-day work streak.",
        icon: "flame.circle.fill",
        category: .growth, rarity: .rare,
        condition: { hero, _ in hero.streakDays >= 7 }
    ),
    Achievement(
        title: "Monthly Marathon",
        description: "Maintain a 30-day work streak.",
        icon: "flame.circle.fill",
        category: .growth, rarity: .epic,
        condition: { hero, _ in hero.streakDays >= 30 }
    ),
    Achievement(
        title: "100 Day Commit",
        description: "Maintain a 100-day streak. Unstoppable.",
        icon: "flame.fill",
        category: .growth, rarity: .legendary,
        condition: { hero, _ in hero.streakDays >= 100 }
    ),
]

private let _masteryAchievements: [Achievement] = [
    Achievement(
        title: "Seed Round",
        description: "Earn 500 Nanobytes.",
        icon: "bitcoinsign.circle.fill",
        category: .mastery, rarity: .common,
        condition: { hero, _ in hero.nanobytes >= 500 }
    ),
    Achievement(
        title: "Series A",
        description: "Earn 2,000 Nanobytes.",
        icon: "banknote.fill",
        category: .mastery, rarity: .rare,
        condition: { hero, _ in hero.nanobytes >= 2000 }
    ),
    Achievement(
        title: "Unicorn",
        description: "Earn 10,000 Nanobytes.",
        icon: "sparkle",
        category: .mastery, rarity: .epic,
        condition: { hero, _ in hero.nanobytes >= 10000 }
    ),
    Achievement(
        title: "Theme Collector",
        description: "Unlock 3 themes from the Armory.",
        icon: "paintpalette.fill",
        category: .mastery, rarity: .rare,
        condition: { hero, _ in hero.unlockedItems.count >= 3 }
    ),
    Achievement(
        title: "Arsenal",
        description: "Unlock 5 items from the Armory.",
        icon: "shield.checkered",
        category: .mastery, rarity: .epic,
        condition: { hero, _ in hero.unlockedItems.count >= 5 }
    ),
]

private let _specialAchievements: [Achievement] = [
    Achievement(
        title: "Balanced Dev",
        description: "Keep burnout below 20% for a full session.",
        icon: "leaf.fill",
        category: .special, rarity: .rare,
        condition: { hero, _ in hero.burnoutLevel < 0.2 && hero.totalFocusMinutes > 30 }
    ),
    Achievement(
        title: "Night Owl",
        description: "Use the app after midnight.",
        icon: "moon.stars.fill",
        category: .special, rarity: .rare,
        condition: { _, _ in
            let hour = Calendar.current.component(.hour, from: Date())
            return hour >= 0 && hour < 5
        }
    ),
    Achievement(
        title: "Early Bird",
        description: "Use the app before 7 AM.",
        icon: "sunrise.fill",
        category: .special, rarity: .rare,
        condition: { _, _ in
            let hour = Calendar.current.component(.hour, from: Date())
            return hour >= 5 && hour < 7
        }
    ),
    Achievement(
        title: "Multitasker",
        description: "Have 5 active modules at once.",
        icon: "square.stack.3d.up.fill",
        category: .special, rarity: .rare,
        condition: { _, quests in quests.filter { !$0.isCompleted }.count >= 5 }
    ),
    Achievement(
        title: "Perfectionist",
        description: "Complete a module with all sub-modules done.",
        icon: "checkmark.seal.fill",
        category: .special, rarity: .common,
        condition: { _, quests in
            quests.contains { (quest: Quest) in
                quest.isCompleted && !quest.subQuests.isEmpty &&
                quest.subQuests.allSatisfy { $0.isCompleted }
            }
        }
    ),
    Achievement(
        title: "Swift Student",
        description: "Reach Level 5 with 10+ completed modules.",
        icon: "swift",
        category: .special, rarity: .legendary,
        condition: { hero, quests in
            hero.level >= 5 && quests.filter { $0.isCompleted }.count >= 10
        }
    ),
]

// MARK: - Achievement View
struct AchievementsView: View {
    @Query private var heroes: [Hero]
    @Query private var quests: [Quest]
    
    var hero: Hero { heroes.first ?? Hero() }
    
    @State private var selectedCategory: AchievementCategory? = nil
    
    private var displayedAchievements: [Achievement] {
        guard let cat = selectedCategory else { return allAchievements }
        return allAchievements.filter { $0.category == cat }
    }
    
    private var unlockedCount: Int {
        allAchievements.filter { $0.condition(hero, quests) }.count
    }
    
    let columns = [GridItem(.adaptive(minimum: 155))]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.voidBlack.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Progress Summary
                        progressHeader
                        
                        // Category Filter
                        categoryFilter
                        
                        // Achievements Grid
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(displayedAchievements) { achievement in
                                AchievementCard(
                                    achievement: achievement,
                                    isUnlocked: achievement.condition(hero, quests)
                                )
                            }
                        }
                        .animation(.spring(response: 0.3), value: selectedCategory)
                    }
                    .padding()
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Milestones")
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
    
    // MARK: - Progress Header
    private var completionFraction: CGFloat {
        CGFloat(unlockedCount) / CGFloat(max(1, allAchievements.count))
    }
    
    private var completionPercent: Int {
        Int(completionFraction * 100)
    }
    
    private var progressHeader: some View {
        VStack(spacing: 12) {
            HStack {
                headerText
                Spacer()
                completionRing
            }
            
            ProgressView(value: Double(unlockedCount), total: Double(allAchievements.count))
                .tint(Color.toxicLime)
            
            rarityRow
        }
        .padding(16)
        .background(Color.carbonGrey.opacity(0.5))
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.05)))
    }
    
    private var headerText: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("SYSTEM CLEARANCE")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.ashGrey)
            
            Text("\(unlockedCount)/\(allAchievements.count)")
                .font(.system(.title, design: .monospaced)).bold()
                .foregroundStyle(.white)
        }
    }
    
    private var completionRing: some View {
        ZStack {
            Circle()
                .stroke(Color.carbonGrey, lineWidth: 6)
                .frame(width: 50, height: 50)
            Circle()
                .trim(from: 0, to: completionFraction)
                .stroke(Color.toxicLime, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 50, height: 50)
            
            Text("\(completionPercent)%")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.toxicLime)
        }
    }
    
    private var rarityRow: some View {
        HStack(spacing: 16) {
            rarityCount(.common)
            rarityCount(.rare)
            rarityCount(.epic)
            rarityCount(.legendary)
        }
    }
    
    private func rarityCount(_ rarity: AchievementRarity) -> some View {
        let total: Int = allAchievements.filter { $0.rarity == rarity }.count
        let unlocked: Int = allAchievements.filter { $0.rarity == rarity && $0.condition(hero, quests) }.count
        
        return HStack(spacing: 4) {
            Circle()
                .fill(rarity.color)
                .frame(width: 6, height: 6)
            Text("\(unlocked)/\(total)")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(rarity.color)
        }
    }
    
    // MARK: - Category Filter
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // ALL
                categoryChip(label: "All", icon: "square.grid.2x2", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                
                ForEach(AchievementCategory.allCases, id: \.self) { cat in
                    categoryChip(
                        label: cat.rawValue,
                        icon: cat.icon,
                        isSelected: selectedCategory == cat
                    ) {
                        selectedCategory = cat
                    }
                }
            }
        }
    }
    
    private func categoryChip(label: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3)) { action() }
            Haptics.shared.play(.light)
        }) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(label)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
            }
            .foregroundStyle(isSelected ? .black : Color.smokeWhite)
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(isSelected ? Color.toxicLime : Color.carbonGrey)
            .cornerRadius(10)
        }
    }
}

// MARK: - Achievement Card (Upgraded)
struct AchievementCard: View {
    var achievement: Achievement
    var isUnlocked: Bool
    
    private var accentColor: Color { achievement.category.color }
    private var bgColor: Color { isUnlocked ? accentColor.opacity(0.04) : Color.carbonGrey.opacity(0.3) }
    private var borderColor: Color { isUnlocked ? accentColor.opacity(0.2) : Color.white.opacity(0.03) }
    
    var body: some View {
        VStack(spacing: 12) {
            rarityHeader
            iconCircle
            textContent
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(bgColor)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(borderColor, lineWidth: 1))
    }
    
    private var rarityHeader: some View {
        HStack {
            let rarityColor: Color = isUnlocked ? achievement.rarity.color : Color.ashGrey.opacity(0.4)
            let badgeBg: Color = (isUnlocked ? achievement.rarity.color : Color.ashGrey).opacity(0.12)
            
            Text(achievement.rarity.rawValue)
                .font(.system(size: 7, weight: .black, design: .monospaced))
                .foregroundStyle(rarityColor)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(badgeBg)
                .cornerRadius(4)
            
            Spacer()
            
            let catColor: Color = isUnlocked ? achievement.category.color : Color.ashGrey.opacity(0.3)
            Image(systemName: achievement.category.icon)
                .font(.system(size: 8))
                .foregroundStyle(catColor)
        }
    }
    
    private var iconCircle: some View {
        let fillColor: Color = isUnlocked ? accentColor.opacity(0.15) : Color.ashGrey.opacity(0.08)
        let iconName: String = isUnlocked ? achievement.icon : "lock.fill"
        let iconColor: Color = isUnlocked ? accentColor : Color.ashGrey.opacity(0.4)
        let glowColor: Color = isUnlocked ? accentColor : .clear
        
        return ZStack {
            Circle()
                .fill(fillColor)
                .frame(width: 60, height: 60)
            
            Image(systemName: iconName)
                .font(.system(size: 24))
                .foregroundStyle(iconColor)
                .neonGlow(color: glowColor, radius: 5)
        }
    }
    
    private var textContent: some View {
        let titleColor: Color = isUnlocked ? Color.smokeWhite : Color.ashGrey.opacity(0.5)
        let descOpacity: Double = isUnlocked ? 0.8 : 0.4
        
        return VStack(spacing: 3) {
            Text(achievement.title)
                .font(.system(.caption, design: .monospaced)).bold()
                .foregroundStyle(titleColor)
                .lineLimit(1)
            
            Text(achievement.description)
                .font(.system(size: 9, design: .monospaced))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.ashGrey.opacity(descOpacity))
                .lineLimit(2)
                .frame(height: 28)
        }
    }
}