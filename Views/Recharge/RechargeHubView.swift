import SwiftUI
import TipKit
import SwiftData

// MARK: - Recharge Hub (Game Picker)
struct RechargeHubView: View {
    @Query private var heroes: [Hero]
    
    // Tips
    private let burnoutTip = BurnoutTip()
    
    var hero: Hero? { heroes.first }
    
    @State private var selectedGame: RechargeGame?
    
    enum RechargeGame: String, CaseIterable, Identifiable {
        case memoryFlip
        case codeSnake
        
        var id: String { rawValue }
        
        var title: String {
            switch self {
            case .memoryFlip: return "Memory Flip"
            case .codeSnake:  return "Code Snake"
            }
        }
        

        
        var iconName: String {
            switch self {
            case .memoryFlip: return "MemoryIcon"
            case .codeSnake:  return "SnakeIcon"
            }
        }
        
        var subtitle: String {
            switch self {
            case .memoryFlip: return "Match dev emoji pairs"
            case .codeSnake:  return "Collect brackets, avoid walls"
            }
        }
        
        var vibe: String {
            switch self {
            case .memoryFlip: return "🧘 Calm"
            case .codeSnake:  return "🎮 Chill"
            }
        }
        
        var color: Color {
            switch self {
            case .memoryFlip: return Color.electricCyan
            case .codeSnake:  return Color.toxicLime
            }
        }
    }
    
    var body: some View {
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
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image("ArcadeHeader")
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .frame(width: 44, height: 44)
                .foregroundStyle(Color.toxicLime)
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Burnout level: \(Int(level * 100)) percent. Playing games reduces burnout.")
        .popoverTip(burnoutTip, arrowEdge: .top)
    }
    
    // MARK: - Game Card
    private func gameCard(_ game: RechargeGame) -> some View {
        HStack(spacing: 14) {
            // Game Icon from Assets
            ZStack {
                Image(game.iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(game.color.opacity(0.3), lineWidth: 1)
                    )
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(game.title): \(game.subtitle). Vibe: \(game.vibe)")
        .accessibilityAddTraits(.isButton)
    }
    
    // MARK: - Destination
    @ViewBuilder
    private func destinationView(for game: RechargeGame) -> some View {
        switch game {
        case .memoryFlip: MemoryGameView()
        case .codeSnake:  CodeSnakeView()
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
