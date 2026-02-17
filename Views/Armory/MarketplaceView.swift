import SwiftUI
import SwiftData

struct ShopItem: Identifiable {
    let id: String
    let name: String
    let icon: String
    let price: Int
    let type: ItemType
    let color: Color
    let minLevel: Int
}

enum ItemType { case theme, avatar }

// MARK: - Shared Catalog
let shopCatalog: [ShopItem] = [
    // Themes (progressively gated)
    ShopItem(id: "theme_cyber", name: "Spec-Ops", icon: "bolt.fill", price: 100, type: .theme, color: Color(hex: "FF9500"), minLevel: 1),
    ShopItem(id: "theme_ocean", name: "Deep Sea", icon: "drop.fill", price: 200, type: .theme, color: Color(hex: "00F2FF"), minLevel: 3),
    ShopItem(id: "theme_fire", name: "Inferno", icon: "flame.fill", price: 250, type: .theme, color: Color.alertRed, minLevel: 5),
    
    // SECRET THEME — Elite tier
    ShopItem(id: "theme_hacker", name: "Construct", icon: "lock.laptopcomputer", price: 500, type: .theme, color: Color(hex: "00FF41"), minLevel: 8),
    
    // Avatars
    ShopItem(id: "avatar_robot", name: "Bot Unit", icon: "desktopcomputer", price: 300, type: .avatar, color: Color.smokeWhite, minLevel: 2),
    ShopItem(id: "avatar_alien", name: "Invader", icon: "ant.fill", price: 500, type: .avatar, color: Color(hex: "00F2FF"), minLevel: 6)
]

// MARK: - Marketplace View (The Armory)
struct MarketplaceView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var heroes: [Hero]
    var hero: Hero { heroes.first ?? Hero() }
    
    @State private var showPreviewAlert = false
    @State private var showThemeConfig = false
    
    let columns = [GridItem(.adaptive(minimum: 140))]
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 20) {
                        // Header: Wallet + Level
                        HStack {
                            VStack(alignment: .leading) {
                                Text("black_market_v2")
                                    .font(.caption.monospaced())
                                    .foregroundStyle(Color.ashGrey)
                                Text("THE ARMORY")
                                    .font(.largeTitle.bold())
                                    .foregroundStyle(.white)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                HStack(spacing: 6) {
                                    Image(systemName: "cpu")
                                        .foregroundStyle(Color.creditsGold)
                                    Text("\(hero.nanobytes)")
                                        .font(.title2.monospaced())
                                        .foregroundStyle(.white)
                                }
                                Text("RANK \(hero.level)")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundStyle(Color.toxicLime)
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .padding()
                        
                        // Preview Mode Banner
                        if ThemeManager.shared.isPreviewing {
                            HStack(spacing: 10) {
                                Image(systemName: "eye.fill")
                                    .foregroundStyle(ThemeManager.shared.previewColor ?? .white)
                                Text("PREVIEW MODE ACTIVE")
                                    .font(.system(size: 11, weight: .black, design: .monospaced))
                                    .foregroundStyle(.white)
                                Spacer()
                                Button("EXIT") {
                                    ThemeManager.shared.cancelPreview()
                                    Haptics.shared.play(.light)
                                }
                                .font(.system(size: 10, weight: .black, design: .monospaced))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.alertRed)
                                .clipShape(Capsule())
                            }
                            .padding(12)
                            .background(Color.carbonGrey)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(ThemeManager.shared.previewColor ?? .white, lineWidth: 1)
                            )
                            .padding(.horizontal)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        // The Grid
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(shopCatalog) { item in
                                ShopItemCard(item: item, hero: hero)
                            }
                        }
                        .padding()
                    }
                }
                .background(Color.voidBlack.ignoresSafeArea())
            }
            .navigationTitle("Registry")
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showThemeConfig = true } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(Color.toxicLime)
                    }
                    .accessibilityLabel("Theme Configuration")
                }
            }
            .sheet(isPresented: $showThemeConfig) {
                ThemeConfigurationView(availableThemes: shopCatalog.filter { $0.type == .theme })
            }
            // System Alert: Leaving Armory with active preview
            .alert("⚠️ PREVIEW STILL ACTIVE", isPresented: $showPreviewAlert) {
                Button("REVERT TO DEPLOYED", role: .destructive) {
                    ThemeManager.shared.cancelPreview()
                }
                Button("KEEP BROWSING", role: .cancel) { }
            } message: {
                Text("A theme preview is still staged. Leaving the Armory will revert to your deployed hardware configuration.")
            }
            .onDisappear {
                // Auto-cancel preview when leaving the Armory
                if ThemeManager.shared.isPreviewing {
                    ThemeManager.shared.cancelPreview()
                }
            }
        }
    }
}

// MARK: - Shop Item Card (with Preview + Level Gating + Shake)
struct ShopItemCard: View {
    let item: ShopItem
    var hero: Hero
    @State private var shakeOffset: CGFloat = 0
    
    var isUnlocked: Bool { hero.unlockedItems.contains(item.id) }
    var isEquipped: Bool { ThemeManager.shared.activeThemeID == item.id }
    var isLockedByLevel: Bool { hero.level < item.minLevel }
    var isCurrentlyPreviewing: Bool {
        ThemeManager.shared.isPreviewing && ThemeManager.shared.previewThemeID == item.id
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon Display
            ZStack {
                Circle()
                    .fill(isLockedByLevel ? Color.ashGrey.opacity(0.1) : item.color.opacity(0.2))
                    .frame(width: 70, height: 70)
                
                Image(systemName: isLockedByLevel ? "lock.fill" : item.icon)
                    .font(.title)
                    .foregroundStyle(isLockedByLevel ? Color.ashGrey : item.color)
                    .symbolEffect(.bounce, value: isEquipped)
            }
            
            Text(isLockedByLevel ? "RANK \(item.minLevel) REQ" : item.name)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(isLockedByLevel ? Color.ashGrey : .white)
            
            interactionButton
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.carbonGrey.opacity(0.6))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(borderColor, lineWidth: 2)
        )
        .offset(x: shakeOffset)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.name), \(isLockedByLevel ? "locked, requires rank \(item.minLevel)" : isUnlocked ? (isEquipped ? "equipped" : "owned") : "\(item.price) nanobytes")")
    }
    
    private var borderColor: Color {
        if isCurrentlyPreviewing { return item.color.opacity(0.8) }
        if isEquipped { return item.color }
        return Color.white.opacity(0.05)
    }
    
    @ViewBuilder
    private var interactionButton: some View {
        if isLockedByLevel {
            // Locked — show nothing interactive
            Text("🔒")
                .font(.caption2)
        } else if isUnlocked {
            // Owned — Equip button
            Button(isEquipped ? "ACTIVE" : "EQUIP") {
                ThemeManager.shared.applyTheme(item.id, color: item.color)
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
            .buttonStyle(TacticalButtonStyle(color: item.color, isActive: isEquipped))
            .disabled(isEquipped)
        } else {
            // Not owned — Preview + Buy
            VStack(spacing: 8) {
                // Preview Button
                Button(isCurrentlyPreviewing ? "STOP PREVIEW" : "PREVIEW") {
                    if isCurrentlyPreviewing {
                        ThemeManager.shared.cancelPreview()
                    } else {
                        ThemeManager.shared.startPreview(id: item.id, color: item.color)
                    }
                    Haptics.shared.play(.light)
                }
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .foregroundStyle(isCurrentlyPreviewing ? item.color : Color.ashGrey)
                .padding(8)
                .frame(maxWidth: .infinity)
                .background(isCurrentlyPreviewing ? item.color.opacity(0.15) : Color.ashGrey.opacity(0.15))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isCurrentlyPreviewing ? item.color.opacity(0.5) : Color.clear, lineWidth: 1)
                )
                
                // Purchase Button
                Button { buyItem() } label: {
                    Label("\(item.price)", systemImage: "cpu.fill")
                }
                .buttonStyle(TacticalButtonStyle(color: .toxicLime, isActive: false))
                .disabled(hero.nanobytes < item.price)
            }
        }
    }
    
    private func buyItem() {
        if hero.nanobytes >= item.price {
            hero.nanobytes -= item.price
            hero.unlockedItems.append(item.id)
            
            // Auto-equip purchased themes
            if item.type == .theme {
                ThemeManager.shared.applyTheme(item.id, color: item.color)
            }
            
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else {
            // Shake animation — insufficient funds
            withAnimation(.default) { shakeOffset = 10 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.default) { shakeOffset = -10 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.default) { shakeOffset = 0 }
            }
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}

// MARK: - Theme Configuration View (Hardware Settings)
struct ThemeConfigurationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var heroes: [Hero]
    var hero: Hero { heroes.first ?? Hero() }
    
    let availableThemes: [ShopItem]
    
    var ownedThemes: [ShopItem] {
        availableThemes.filter { hero.unlockedItems.contains($0.id) }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.voidBlack.ignoresSafeArea()
                
                if ownedThemes.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "paintpalette")
                            .font(.system(size: 40))
                            .foregroundStyle(Color.ashGrey.opacity(0.5))
                        Text("NO THEMES DEPLOYED")
                            .font(.system(.headline, design: .monospaced))
                            .foregroundStyle(Color.ashGrey)
                        Text("Purchase themes from the Armory to customize your interface.")
                            .font(.caption)
                            .foregroundStyle(Color.ashGrey.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .padding(40)
                } else {
                    List {
                        // Default theme (always available)
                        Section("SYSTEM DEFAULT") {
                            themeRow(
                                id: "default",
                                name: "ForgeFlow Standard",
                                icon: "shield.fill",
                                color: Color(hex: "00F2FF"),
                                isActive: ThemeManager.shared.activeThemeID == "default"
                            )
                        }
                        
                        Section("DEPLOYED HARDWARE") {
                            ForEach(ownedThemes) { theme in
                                themeRow(
                                    id: theme.id,
                                    name: theme.name,
                                    icon: theme.icon,
                                    color: theme.color,
                                    isActive: ThemeManager.shared.activeThemeID == theme.id
                                )
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("System Themes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.toxicLime)
                }
            }
            .onDisappear {
                ThemeManager.shared.cancelPreview()
            }
        }
    }
    
    private func themeRow(id: String, name: String, icon: String, color: Color, isActive: Bool) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(.subheadline, design: .monospaced))
                    .bold()
                    .foregroundStyle(.white)
                if isActive {
                    Text("DEPLOYED")
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .foregroundStyle(color)
                }
            }
            
            Spacer()
            
            if isActive {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(color)
                    .symbolEffect(.bounce, value: isActive)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .listRowBackground(isActive ? color.opacity(0.08) : Color.carbonGrey.opacity(0.3))
        .onTapGesture {
            ThemeManager.shared.applyTheme(id, color: color)
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }
        .accessibilityLabel("\(name) theme\(isActive ? ", currently deployed" : "")")
    }
}

// MARK: - Tactical Button Style
struct TacticalButtonStyle: ButtonStyle {
    let color: Color
    let isActive: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isActive ? color.opacity(0.2) : color)
            .foregroundStyle(isActive ? color : .black)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isActive ? color : Color.clear, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}