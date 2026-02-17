import SwiftUI
import SwiftData

struct CyberBackground: View {
    var body: some View {
        ZStack {
            // Deep Space Background
            Color(hex: "0f0f1a").ignoresSafeArea()
            
            // Grid Effect
            GeometryReader { geo in
                Path { path in
                    let step: CGFloat = 40
                    for x in stride(from: 0, through: geo.size.width, by: step) {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: geo.size.height))
                    }
                    for y in stride(from: 0, through: geo.size.height, by: step) {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geo.size.width, y: y))
                    }
                }
                .stroke(Color.electricCyan.opacity(0.1), lineWidth: 1)
            }
            
            // Vignette (Darken edges)
            RadialGradient(
                colors: [.clear, .black.opacity(0.8)],
                center: .center,
                startRadius: 100,
                endRadius: 600
            )
            .ignoresSafeArea()
        }
    }
}

struct SanctuaryView: View {
    @Query private var heroes: [Hero]
    @Query(filter: #Predicate<Quest> { $0.isActive && !$0.isCompleted }) private var activeQuests: [Quest]
    @Environment(\.modelContext) private var modelContext
    
    var hero: Hero { heroes.first ?? Hero() }
    var activeQuest: Quest? { activeQuests.first }
    
    var body: some View {
        NavigationStack {
            ZStack {
                CyberBackground()
                
                GeometryReader { geo in
                    let isIPad = geo.size.width > 600
                    
                    VStack(spacing: 0) {
                        // 1. Top HUD (Stats)
                        HeroHUDView(hero: hero)
                            .padding(.top)
                        
                        Spacer()
                        
                        // 2. The Avatar (Center Stage)
                        ZStack {
                            // Magic Glow behind avatar
                            Circle()
                                .fill(activeQuest != nil ? Color.hotPink : Color.toxicLime)
                                .frame(width: isIPad ? 400 : 250, height: isIPad ? 400 : 250)
                                .blur(radius: 60)
                                .opacity(0.5)
                            
                            SpriteView(
                                imageName: activeQuest != nil ? "hero_attack" : "hero_idle",
                                frameCount: activeQuest != nil ? 4 : 7,
                                width: isIPad ? 350 : 220,
                                height: isIPad ? 350 : 220
                            )
                            .shadow(color: .black.opacity(0.5), radius: 20, y: 10)
                        }
                        
                        Spacer()
                        
                        // 3. The Modern Timer Control
                        FocusTimerView(hero: hero, activeQuest: activeQuest)
                            .frame(maxWidth: isIPad ? 600 : .infinity) // Limit width on iPad
                            .padding(.bottom, 20)
                    }
                    .padding(.horizontal)
                }
            }
            // Hide standard nav bar for immersion
            .toolbarBackground(.hidden, for: .navigationBar)
            .onAppear { ensureHeroExists() }
        }
    }
    
    private func ensureHeroExists() {
        if heroes.isEmpty { modelContext.insert(Hero()) }
    }
}

// Subview: The Stats Bar
struct HeroHUDView: View {
    var hero: Hero
    
    var body: some View {
        HStack {
            // Level Badge
            ZStack {
                Circle().fill(Color.primaryGradient)
                    .frame(width: 60, height: 60)
                    .shadow(radius: 10)
                VStack(spacing: 0) {
                    Text("LVL").font(.system(size: 10, weight: .bold))
                    Text("\(hero.level)").font(.title2.bold())
                }
            }
            
            // XP Bar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Experience").font(.caption).bold().foregroundStyle(.secondary)
                    Spacer()
                    Text("\(hero.currentXP)/\(hero.maxXP)").font(.caption).monospacedDigit()
                }
                
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.1))
                        Capsule().fill(Color.flowGradient)
                            .frame(width: g.size.width * (Double(hero.currentXP) / Double(hero.maxXP)))
                    }
                }
                .frame(height: 8)
            }
            
            Spacer()
            
            // Streak
            VStack {
                Image(systemName: "flame.fill").foregroundStyle(.orange).font(.title2)
                Text("\(hero.streakDays)").font(.caption.bold())
            }
            .padding(10)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
        .background(.ultraThinMaterial) // Glass effect
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}


