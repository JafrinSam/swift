import SwiftUI
import SwiftData

// MARK: - Card Model
struct MemoryCard: Identifiable, Equatable {
    let id = UUID()
    let emoji: String
    let pairID: Int
    var isFaceUp: Bool = false
    var isMatched: Bool = false
}

// MARK: - Memory Game View
struct MemoryGameView: View {
    @Query private var heroes: [Hero]
    @Environment(\.modelContext) private var modelContext
    
    var hero: Hero? { heroes.first }
    
    @State private var cards: [MemoryCard] = []
    @State private var firstFlipped: Int? = nil
    @State private var secondFlipped: Int? = nil
    @State private var moves: Int = 0
    @State private var matchedPairs: Int = 0
    @State private var isProcessing = false
    @State private var showComplete = false
    @State private var burnoutReduced: Double = 0.0
    @State private var xpEarned: Int = 0
    
    private let totalPairs = 6
    private let devEmojis = ["🐛", "🔧", "⚡", "🚀", "💻", "🎯"]
    
    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    var body: some View {
        ZStack {
            Color.voidBlack.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    statsBar
                    cardGrid
                    
                    if !showComplete {
                        tipSection
                    }
                }
                .padding()
            }
            
            // Completion overlay
            if showComplete {
                completionOverlay
            }
        }
        .navigationTitle("Memory Flip")
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    resetGame()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .foregroundStyle(Color.toxicLime)
                }
            }
        }
        .onAppear { setupGame() }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 6) {
            Text("🧘 MEMORY RECHARGE")
                .font(.system(size: 16, weight: .black, design: .monospaced))
                .foregroundStyle(.white)
            Text("Match the pairs. No rush, no pressure.")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(Color.ashGrey)
        }
    }
    
    // MARK: - Stats
    private var statsBar: some View {
        HStack(spacing: 16) {
            statBadge(
                label: "MOVES",
                value: "\(moves)",
                color: Color.electricCyan
            )
            statBadge(
                label: "MATCHED",
                value: "\(matchedPairs)/\(totalPairs)",
                color: Color.toxicLime
            )
            statBadge(
                label: "BURNOUT",
                value: String(format: "%.0f%%", (hero?.burnoutLevel ?? 0) * 100),
                color: (hero?.burnoutLevel ?? 0) > 0.5 ? Color.alertRed : Color.ashGrey
            )
        }
    }
    
    private func statBadge(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.title3, design: .monospaced)).bold()
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.ashGrey)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.06))
        .cornerRadius(12)
    }
    
    // MARK: - Card Grid
    private var cardGrid: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                CardView(card: card)
                    .onTapGesture {
                        flipCard(at: index)
                    }
                    .accessibilityLabel(card.isFaceUp || card.isMatched ? card.emoji : "Hidden card")
                    .accessibilityHint("Tap to flip")
            }
        }
    }
    
    // MARK: - Tip
    private var tipSection: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.toxicLime.opacity(0.5))
                Text("Each match reduces burnout by 5%")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.ashGrey.opacity(0.5))
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Completion Overlay
    private var completionOverlay: some View {
        VStack(spacing: 20) {
            Spacer()
            
            VStack(spacing: 16) {
                Text("🎉")
                    .font(.system(size: 60))
                
                Text("RECHARGED!")
                    .font(.system(size: 22, weight: .black, design: .monospaced))
                    .foregroundStyle(.white)
                
                Text("You completed it in \(moves) moves")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(Color.ashGrey)
                
                // Stats
                VStack(spacing: 10) {
                    if xpEarned > 0 {
                        rewardRow(icon: "bolt.fill", text: "+\(xpEarned) XP Earned", color: Color.electricCyan)
                    }
                    if burnoutReduced > 0 {
                        rewardRow(icon: "heart.fill", text: String(format: "-%.0f%% Burnout", burnoutReduced * 100), color: Color.toxicLime)
                    }
                }
                .padding()
                .background(Color.carbonGrey.opacity(0.5))
                .cornerRadius(14)
                
                Button {
                    resetGame()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("PLAY AGAIN")
                            .font(.system(.headline, design: .monospaced)).bold()
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity).padding(14)
                    .background(Color.toxicLime)
                    .cornerRadius(14)
                }
            }
            .padding(28)
            .background(Color.carbonGrey)
            .cornerRadius(24)
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.toxicLime.opacity(0.2)))
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .background(Color.black.opacity(0.7).ignoresSafeArea())
        .transition(.opacity)
    }
    
    private func rewardRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(text)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
            Spacer()
        }
    }
    
    // MARK: - Game Logic
    
    private func setupGame() {
        guard cards.isEmpty else { return }
        var newCards: [MemoryCard] = []
        for (idx, emoji) in devEmojis.enumerated() {
            newCards.append(MemoryCard(emoji: emoji, pairID: idx))
            newCards.append(MemoryCard(emoji: emoji, pairID: idx))
        }
        cards = newCards.shuffled()
        moves = 0
        matchedPairs = 0
        showComplete = false
        burnoutReduced = 0
        xpEarned = 0
    }
    
    private func resetGame() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showComplete = false
        }
        
        // Brief delay to let UI settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            cards = []
            firstFlipped = nil
            secondFlipped = nil
            isProcessing = false
            setupGame()
        }
    }
    
    private func flipCard(at index: Int) {
        guard !isProcessing else { return }
        guard !cards[index].isFaceUp, !cards[index].isMatched else { return }
        
        Haptics.shared.play(.light)
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            cards[index].isFaceUp = true
        }
        
        if firstFlipped == nil {
            firstFlipped = index
        } else if secondFlipped == nil {
            secondFlipped = index
            moves += 1
            isProcessing = true
            checkMatch()
        }
    }
    
    private func checkMatch() {
        guard let first = firstFlipped, let second = secondFlipped else { return }
        
        if cards[first].pairID == cards[second].pairID {
            // Match found!
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.4)) {
                    cards[first].isMatched = true
                    cards[second].isMatched = true
                }
                
                matchedPairs += 1
                Haptics.shared.notify(.success)
                
                // Reduce burnout by 5% per match
                if let hero = hero {
                    let reduction = 0.05
                    hero.burnoutLevel = max(0, hero.burnoutLevel - reduction)
                    burnoutReduced += reduction
                    try? modelContext.save()
                }
                
                // Check if game complete
                if matchedPairs == totalPairs {
                    completeGame()
                }
                
                firstFlipped = nil
                secondFlipped = nil
                isProcessing = false
            }
        } else {
            // No match — flip back
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    cards[first].isFaceUp = false
                    cards[second].isFaceUp = false
                }
                firstFlipped = nil
                secondFlipped = nil
                isProcessing = false
            }
        }
    }
    
    private func completeGame() {
        // Award XP
        let xp = 15
        xpEarned = xp
        hero?.addXP(amount: xp)
        try? modelContext.save()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showComplete = true
            }
        }
    }
}

// MARK: - Individual Card View
struct CardView: View {
    let card: MemoryCard
    
    var body: some View {
        ZStack {
            if card.isFaceUp || card.isMatched {
                // Face up
                RoundedRectangle(cornerRadius: 14)
                    .fill(card.isMatched ? Color.toxicLime.opacity(0.12) : Color.carbonGrey)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(card.isMatched ? Color.toxicLime.opacity(0.3) : Color.white.opacity(0.05), lineWidth: 1)
                    )
                
                Text(card.emoji)
                    .font(.system(size: 36))
                    .opacity(card.isMatched ? 0.6 : 1.0)
            } else {
                // Face down
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.carbonGrey.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.toxicLime.opacity(0.08), lineWidth: 1)
                    )
                
                Image(systemName: "questionmark")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.ashGrey.opacity(0.3))
            }
        }
        .frame(height: 90)
        .rotation3DEffect(
            .degrees(card.isFaceUp || card.isMatched ? 0 : 180),
            axis: (x: 0, y: 1, z: 0)
        )
    }
}
