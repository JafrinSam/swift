import SwiftUI
import SwiftData

// MARK: - Recharge Hub (Game Picker)
struct RechargeHubView: View {
    @Query private var heroes: [Hero]
    
    var hero: Hero? { heroes.first }
    
    @State private var selectedGame: RechargeGame?
    
    enum RechargeGame: String, CaseIterable, Identifiable {
        case memoryFlip
        case codeSnake
        case bugSquash
        
        var id: String { rawValue }
        
        var title: String {
            switch self {
            case .memoryFlip: return "Memory Flip"
            case .codeSnake:  return "Code Snake"
            case .bugSquash:  return "Bug Squash"
            }
        }
        
        var emoji: String {
            switch self {
            case .memoryFlip: return "🃏"
            case .codeSnake:  return "🐍"
            case .bugSquash:  return "🎯"
            }
        }
        
        var subtitle: String {
            switch self {
            case .memoryFlip: return "Match dev emoji pairs"
            case .codeSnake:  return "Collect brackets, avoid walls"
            case .bugSquash:  return "Tap bugs before they escape"
            }
        }
        
        var vibe: String {
            switch self {
            case .memoryFlip: return "🧘 Calm"
            case .codeSnake:  return "🎮 Chill"
            case .bugSquash:  return "⚡ Quick"
            }
        }
        
        var color: Color {
            switch self {
            case .memoryFlip: return Color.electricCyan
            case .codeSnake:  return Color.toxicLime
            case .bugSquash:  return Color.ballisticOrange
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.voidBlack.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        headerSection
                        
                        // Burnout indicator
                        if let hero = hero, hero.burnoutLevel > 0.1 {
                            burnoutBanner(level: hero.burnoutLevel)
                        }
                        
                        // Game Cards
                        VStack(spacing: 12) {
                            ForEach(RechargeGame.allCases) { game in
                                NavigationLink(destination: destinationView(for: game)) {
                                    gameCard(game)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Footer tip
                        footerTip
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Recharge")
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("🎮")
                .font(.system(size: 40))
            Text("RECHARGE ARCADE")
                .font(.system(size: 16, weight: .black, design: .monospaced))
                .foregroundStyle(.white)
            Text("Take a break. Play a game. Reduce burnout.")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(Color.ashGrey)
        }
        .padding(.top, 10)
    }
    
    // MARK: - Burnout Banner
    private func burnoutBanner(level: Double) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "heart.text.square.fill")
                .foregroundStyle(level > 0.6 ? Color.alertRed : Color.ballisticOrange)
            
            VStack(alignment: .leading, spacing: 3) {
                Text("Burnout Level: \(Int(level * 100))%")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                Text("Playing games reduces burnout!")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.ashGrey)
            }
            
            Spacer()
            
            // Mini progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.1))
                    Capsule()
                        .fill(level > 0.6 ? Color.alertRed : Color.ballisticOrange)
                        .frame(width: geo.size.width * level)
                }
            }
            .frame(width: 60, height: 6)
        }
        .padding(14)
        .background(Color.carbonGrey.opacity(0.4))
        .cornerRadius(14)
        .padding(.horizontal)
    }
    
    // MARK: - Game Card
    private func gameCard(_ game: RechargeGame) -> some View {
        HStack(spacing: 14) {
            // Emoji icon
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(game.color.opacity(0.12))
                    .frame(width: 60, height: 60)
                Text(game.emoji)
                    .font(.system(size: 28))
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(game.title.uppercased())
                    .font(.system(size: 13, weight: .black, design: .monospaced))
                    .foregroundStyle(.white)
                Text(game.subtitle)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color.ashGrey)
                
                // Vibe tag
                Text(game.vibe)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(game.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(game.color.opacity(0.1))
                    .cornerRadius(6)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(Color.ashGrey.opacity(0.5))
        }
        .padding(14)
        .background(Color.carbonGrey.opacity(0.3))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(game.color.opacity(0.08), lineWidth: 1)
        )
    }
    
    // MARK: - Destination
    @ViewBuilder
    private func destinationView(for game: RechargeGame) -> some View {
        switch game {
        case .memoryFlip: MemoryGameView()
        case .codeSnake:  CodeSnakeView()
        case .bugSquash:  BugSquashView()
        }
    }
    
    // MARK: - Footer
    private var footerTip: some View {
        HStack(spacing: 6) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 10))
                .foregroundStyle(Color.toxicLime.opacity(0.4))
            Text("All games reduce burnout & award XP")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(Color.ashGrey.opacity(0.4))
        }
        .padding(.top, 8)
    }
}
