import SwiftUI
import SwiftData

// MARK: - Card Model
struct MemoryCard: Identifiable, Equatable {
    let id = UUID()
    let symbol: String
    let pairID: Int
    var isFaceUp: Bool = false
    var isMatched: Bool = false
}

// MARK: - Difficulty
enum MemoryDifficulty: String, CaseIterable {
    case easy   = "EASY"
    case medium = "MEDIUM"
    case hard   = "HARD"

    var pairs: Int {
        switch self { case .easy: return 6; case .medium: return 8; case .hard: return 10 }
    }
    var flipBackDelay: Double {
        switch self { case .easy: return 1.2; case .medium: return 0.9; case .hard: return 0.55 }
    }
    var timerSeconds: Int {
        switch self { case .easy: return 90; case .medium: return 60; case .hard: return 45 }
    }
    var bonusXP: Int {
        switch self { case .easy: return 5; case .medium: return 10; case .hard: return 20 }
    }
    var columns: Int {
        switch self { case .easy: return 3; case .medium: return 4; case .hard: return 4 }
    }
    var color: Color {
        switch self { case .easy: return .toxicLime; case .medium: return .electricCyan; case .hard: return .alertRed }
    }
}

// MARK: - Card Deck
enum CardDeck: String, CaseIterable {
    case emoji    = "EMOJI"
    case code     = "CODE"
    case terminal = "TERMINAL"

    var symbols: [String] {
        switch self {
        case .emoji:
            return ["🐛", "🔧", "⚡", "🚀", "💻", "🎯", "🔐", "🧠", "🌐", "🎮"]
        case .code:
            return ["{}", "</>", "//", "[]", "=>", "&&", "!=", "++", "??", "::"]
        case .terminal:
            return ["git", "npm", "ssh", "vim", "curl", "grep", "sudo", "ping", "diff", "chmod"]
        }
    }

    var icon: String {
        switch self { case .emoji: return "face.smiling"; case .code: return "curlybraces"; case .terminal: return "terminal" }
    }
}

// MARK: - Memory Game View
struct MemoryGameView: View {
    @Query private var heroes: [Hero]
    @Environment(\.modelContext) private var modelContext
    var hero: Hero? { heroes.first }

    // Game State
    @State private var cards: [MemoryCard] = []
    @State private var firstFlipped: Int? = nil
    @State private var secondFlipped: Int? = nil
    @State private var moves: Int = 0
    @State private var matchedPairs: Int = 0
    @State private var isProcessing = false
    @State private var showComplete = false
    @State private var burnoutReduced: Double = 0.0
    @State private var xpEarned: Int = 0

    // Difficulty & Deck
    @State private var difficulty: MemoryDifficulty = .easy
    @State private var selectedDeck: CardDeck = .emoji
    @State private var gameStarted = false

    // Countdown Timer
    @State private var timeRemaining: Int = 90
    @State private var countdownTimer: Timer? = nil
    @State private var timedOut = false

    // Streak
    @State private var currentStreak: Int = 0
    @State private var showStreakBanner = false
    @State private var streakBonusXP: Int = 0

    // Best Score (AppStorage)
    @AppStorage("memoryBestMovesEasy")   private var bestMovesEasy: Int = 0
    @AppStorage("memoryBestMovesMedium") private var bestMovesMedium: Int = 0
    @AppStorage("memoryBestMovesHard")   private var bestMovesHard: Int = 0
    @State private var isNewRecord = false

    // Sensory Feedback Triggers
    @State private var flipTrigger = false
    @State private var matchTrigger = false
    @State private var missTrigger = false
    @State private var streakTrigger = false
    @State private var completeTrigger = false

    private var totalPairs: Int { difficulty.pairs }

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 10), count: difficulty.columns)
    }

    // Best moves for current difficulty
    private var bestMoves: Int {
        get {
            switch difficulty {
            case .easy:   return bestMovesEasy
            case .medium: return bestMovesMedium
            case .hard:   return bestMovesHard
            }
        }
    }

    var body: some View {
        ZStack {
            Color.voidBlack.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    if !gameStarted {
                        setupPanel
                    } else {
                        headerSection
                        statsBar
                        if showStreakBanner { streakBanner }
                        cardGrid
                        tipSection
                    }
                }
                .padding()
            }

            if showComplete { completionOverlay }
            if timedOut    { timeoutOverlay }
        }
        .navigationTitle("Memory Flip")
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if gameStarted {
                    Button { endGame() } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .foregroundStyle(Color.toxicLime)
                    }
                }
            }
        }
        // Sensory feedback
        .sensoryFeedback(.impact(weight: .light),  trigger: flipTrigger)
        .sensoryFeedback(.success,                  trigger: matchTrigger)
        .sensoryFeedback(.error,                    trigger: missTrigger)
        .sensoryFeedback(.impact(weight: .heavy),   trigger: streakTrigger)
        .sensoryFeedback(.success,                  trigger: completeTrigger)
        .onDisappear { stopTimer() }
    }

    // MARK: - Setup Panel (Difficulty + Deck picker)
    private var setupPanel: some View {
        VStack(spacing: 24) {
            VStack(spacing: 6) {
                Text("🧠 MEMORY RECHARGE")
                    .font(.system(size: 16, weight: .black, design: .monospaced))
                    .foregroundStyle(.white)
                Text("Train your working memory")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color.ashGrey)
            }
            .padding(.top, 8)

            // Difficulty picker
            VStack(alignment: .leading, spacing: 10) {
                Text("DIFFICULTY")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(Color.ashGrey)

                HStack(spacing: 10) {
                    ForEach(MemoryDifficulty.allCases, id: \.self) { diff in
                        Button {
                            withAnimation(.spring(response: 0.3)) { difficulty = diff }
                        } label: {
                            VStack(spacing: 4) {
                                Text(diff.rawValue)
                                    .font(.system(size: 11, weight: .black, design: .monospaced))
                                Text("\(diff.pairs) pairs • \(diff.timerSeconds)s")
                                    .font(.system(size: 8, design: .monospaced))
                            }
                            .foregroundStyle(difficulty == diff ? .black : diff.color)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(difficulty == diff ? diff.color : diff.color.opacity(0.1))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(diff.color.opacity(0.3), lineWidth: 1))
                        }
                    }
                }
            }
            .padding()
            .background(Color.carbonGrey.opacity(0.4))
            .cornerRadius(16)

            // Deck picker
            VStack(alignment: .leading, spacing: 10) {
                Text("CARD DECK")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(Color.ashGrey)

                HStack(spacing: 10) {
                    ForEach(CardDeck.allCases, id: \.self) { deck in
                        Button {
                            withAnimation(.spring(response: 0.3)) { selectedDeck = deck }
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: deck.icon)
                                    .font(.title3)
                                Text(deck.rawValue)
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                            }
                            .foregroundStyle(selectedDeck == deck ? .black : Color.electricCyan)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(selectedDeck == deck ? Color.electricCyan : Color.electricCyan.opacity(0.08))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.electricCyan.opacity(0.25), lineWidth: 1))
                        }
                    }
                }
            }
            .padding()
            .background(Color.carbonGrey.opacity(0.4))
            .cornerRadius(16)

            // Best score
            if bestMoves > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "trophy.fill")
                        .foregroundStyle(Color.ballisticOrange)
                        .font(.caption)
                    Text("Best: \(bestMoves) moves on \(difficulty.rawValue)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Color.ashGrey)
                }
            }

            // Start button
            Button { startGame() } label: {
                HStack(spacing: 10) {
                    Image(systemName: "play.fill")
                    Text("DEPLOY MEMORY PROTOCOL")
                        .font(.system(.subheadline, design: .monospaced)).bold()
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(difficulty.color)
                .cornerRadius(14)
                .shadow(color: difficulty.color.opacity(0.3), radius: 10)
            }
        }
    }

    // MARK: - Header (in-game)
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("🧠 MEMORY RECHARGE")
                    .font(.system(size: 13, weight: .black, design: .monospaced))
                    .foregroundStyle(.white)
                HStack(spacing: 6) {
                    Text(difficulty.rawValue)
                        .font(.system(size: 8, weight: .black, design: .monospaced))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(difficulty.color)
                        .cornerRadius(4)
                    Text(selectedDeck.rawValue + " DECK")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.electricCyan)
                }
            }
            Spacer()

            // Countdown ring
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 4)
                    .frame(width: 50, height: 50)
                Circle()
                    .trim(from: 0, to: CGFloat(timeRemaining) / CGFloat(difficulty.timerSeconds))
                    .stroke(
                        timeRemaining <= 10 ? Color.alertRed : difficulty.color,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: timeRemaining)
                Text("\(timeRemaining)")
                    .font(.system(size: 13, weight: .black, design: .monospaced))
                    .foregroundStyle(timeRemaining <= 10 ? Color.alertRed : .white)
            }
        }
    }

    // MARK: - Stats Bar
    private var statsBar: some View {
        HStack(spacing: 10) {
            statBadge(label: "MOVES", value: "\(moves)", color: Color.electricCyan)
            statBadge(label: "PAIRS", value: "\(matchedPairs)/\(totalPairs)", color: difficulty.color)
            statBadge(label: "STREAK", value: "🔥\(currentStreak)", color: currentStreak >= 3 ? Color.ballisticOrange : Color.ashGrey)
            if bestMoves > 0 {
                statBadge(label: "BEST", value: "\(bestMoves)", color: Color.ballisticOrange)
            }
        }
    }

    private func statBadge(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.subheadline, design: .monospaced)).bold()
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 7, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.ashGrey)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.07))
        .cornerRadius(12)
    }

    // MARK: - Streak Banner
    private var streakBanner: some View {
        HStack(spacing: 10) {
            Text("🔥")
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text("HOT STREAK x\(currentStreak)!")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundStyle(Color.ballisticOrange)
                Text("+\(currentStreak * 2) bonus XP per match")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(Color.ashGrey)
            }
            Spacer()
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(Color.ballisticOrange.opacity(0.1))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.ballisticOrange.opacity(0.3), lineWidth: 1))
        .cornerRadius(12)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Card Grid
    private var cardGrid: some View {
        LazyVGrid(columns: gridColumns, spacing: 10) {
            ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                CardView(card: card, accentColor: difficulty.color)
                    .onTapGesture { flipCard(at: index) }
                    .accessibilityLabel(card.isFaceUp || card.isMatched ? card.symbol : "Hidden card")
                    .accessibilityHint("Tap to flip")
            }
        }
    }

    // MARK: - Tip
    private var tipSection: some View {
        HStack(spacing: 6) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 9))
                .foregroundStyle(Color.toxicLime.opacity(0.5))
            Text("Each match reduces burnout by 5% • 3+ streak = bonus XP")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(Color.ashGrey.opacity(0.5))
        }
        .padding(.top, 4)
    }

    // MARK: - Completion Overlay
    private var completionOverlay: some View {
        VStack(spacing: 16) {
            Spacer()
            VStack(spacing: 16) {
                Text(isNewRecord ? "🏆" : "🎉")
                    .font(.system(size: 60))

                Text(isNewRecord ? "NEW RECORD!" : "RECHARGED!")
                    .font(.system(size: 22, weight: .black, design: .monospaced))
                    .foregroundStyle(isNewRecord ? Color.ballisticOrange : .white)

                Text("Completed in \(moves) moves")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(Color.ashGrey)

                VStack(spacing: 10) {
                    if xpEarned > 0 {
                        rewardRow(icon: "bolt.fill", text: "+\(xpEarned) XP Earned", color: Color.electricCyan)
                    }
                    if burnoutReduced > 0 {
                        rewardRow(icon: "heart.fill", text: String(format: "-%.0f%% Burnout", burnoutReduced * 100), color: Color.toxicLime)
                    }
                    if streakBonusXP > 0 {
                        rewardRow(icon: "flame.fill", text: "+\(streakBonusXP) Streak Bonus XP", color: Color.ballisticOrange)
                    }
                    if timeRemaining > 0 {
                        rewardRow(icon: "timer", text: "+\(difficulty.bonusXP) Speed Bonus XP (\(timeRemaining)s left)", color: difficulty.color)
                    }
                }
                .padding()
                .background(Color.carbonGrey.opacity(0.5))
                .cornerRadius(14)

                Button {
                    endGame()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("PLAY AGAIN")
                            .font(.system(.headline, design: .monospaced)).bold()
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity).padding(14)
                    .background(difficulty.color)
                    .cornerRadius(14)
                }
            }
            .padding(28)
            .background(Color.carbonGrey)
            .cornerRadius(24)
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(difficulty.color.opacity(0.3)))
            .padding(.horizontal, 20)
            Spacer()
        }
        .background(Color.black.opacity(0.75).ignoresSafeArea())
        .transition(.opacity)
    }

    // MARK: - Timeout Overlay
    private var timeoutOverlay: some View {
        VStack(spacing: 16) {
            Spacer()
            VStack(spacing: 16) {
                Text("⏱️")
                    .font(.system(size: 60))
                Text("TIME'S UP")
                    .font(.system(size: 22, weight: .black, design: .monospaced))
                    .foregroundStyle(Color.alertRed)
                Text("\(matchedPairs)/\(totalPairs) pairs found in \(moves) moves")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(Color.ashGrey)
                Button {
                    endGame()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("TRY AGAIN")
                            .font(.system(.headline, design: .monospaced)).bold()
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity).padding(14)
                    .background(Color.alertRed)
                    .cornerRadius(14)
                }
            }
            .padding(28)
            .background(Color.carbonGrey)
            .cornerRadius(24)
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.alertRed.opacity(0.3)))
            .padding(.horizontal, 20)
            Spacer()
        }
        .background(Color.black.opacity(0.75).ignoresSafeArea())
        .transition(.opacity)
    }

    private func rewardRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).foregroundStyle(color)
            Text(text)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
            Spacer()
        }
    }

    // MARK: - Game Logic

    private func startGame() {
        let symbols = Array(selectedDeck.symbols.prefix(totalPairs))
        var newCards: [MemoryCard] = []
        for (idx, sym) in symbols.enumerated() {
            newCards.append(MemoryCard(symbol: sym, pairID: idx))
            newCards.append(MemoryCard(symbol: sym, pairID: idx))
        }
        cards = newCards.shuffled()
        moves = 0; matchedPairs = 0
        showComplete = false; timedOut = false
        burnoutReduced = 0; xpEarned = 0
        streakBonusXP = 0; currentStreak = 0
        isNewRecord = false; showStreakBanner = false
        timeRemaining = difficulty.timerSeconds
        firstFlipped = nil; secondFlipped = nil; isProcessing = false

        withAnimation(.spring(response: 0.4)) { gameStarted = true }
        startTimer()
    }

    private func endGame() {
        stopTimer()
        withAnimation(.easeInOut(duration: 0.3)) {
            showComplete = false; timedOut = false; gameStarted = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            cards = []; firstFlipped = nil; secondFlipped = nil; isProcessing = false
        }
    }

    private func startTimer() {
        stopTimer()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                stopTimer()
                withAnimation(.spring(response: 0.5)) { timedOut = true }
            }
        }
    }

    private func stopTimer() {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }

    private func flipCard(at index: Int) {
        guard !isProcessing else { return }
        guard !cards[index].isFaceUp, !cards[index].isMatched else { return }

        flipTrigger.toggle()

        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
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
            // ✅ Match!
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.spring(response: 0.4)) {
                    cards[first].isMatched = true
                    cards[second].isMatched = true
                }
                matchTrigger.toggle()
                matchedPairs += 1
                currentStreak += 1

                // Streak bonus
                if currentStreak >= 3 {
                    let bonus = currentStreak * 2
                    streakBonusXP += bonus
                    streakTrigger.toggle()
                    withAnimation(.spring(response: 0.3)) { showStreakBanner = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation { showStreakBanner = false }
                    }
                }

                // Burnout reduction
                if let hero = hero {
                    let reduction = 0.05
                    hero.recoverBurnout(amount: reduction)
                    burnoutReduced += reduction
                    try? modelContext.save()
                }

                if matchedPairs == totalPairs { completeGame() }

                firstFlipped = nil; secondFlipped = nil; isProcessing = false
            }
        } else {
            // ❌ No match
            missTrigger.toggle()
            currentStreak = 0
            withAnimation { showStreakBanner = false }

            DispatchQueue.main.asyncAfter(deadline: .now() + difficulty.flipBackDelay) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    cards[first].isFaceUp = false
                    cards[second].isFaceUp = false
                }
                firstFlipped = nil; secondFlipped = nil; isProcessing = false
            }
        }
    }

    private func completeGame() {
        stopTimer()

        // Base XP
        var totalXP = 15
        // Speed bonus
        if timeRemaining > 0 { totalXP += difficulty.bonusXP }
        // Streak bonus
        totalXP += streakBonusXP

        xpEarned = totalXP
        hero?.addXP(amount: totalXP)
        try? modelContext.save()

        // Best score check
        let currentBest = bestMoves
        if currentBest == 0 || moves < currentBest {
            isNewRecord = true
            switch difficulty {
            case .easy:   bestMovesEasy   = moves
            case .medium: bestMovesMedium = moves
            case .hard:   bestMovesHard   = moves
            }
        }

        completeTrigger.toggle()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showComplete = true
            }
        }
    }
}

// MARK: - Card View (3D Flip + Glow)
struct CardView: View {
    let card: MemoryCard
    let accentColor: Color

    @State private var glowPulse = false

    var body: some View {
        ZStack {
            // Back face
            if !card.isFaceUp && !card.isMatched {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.carbonGrey.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(accentColor.opacity(0.1), lineWidth: 1)
                    )
                Image(systemName: "questionmark")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.ashGrey.opacity(0.3))
            }

            // Front face
            if card.isFaceUp || card.isMatched {
                RoundedRectangle(cornerRadius: 14)
                    .fill(card.isMatched ? accentColor.opacity(0.12) : Color.carbonGrey)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                card.isMatched ? accentColor.opacity(glowPulse ? 0.7 : 0.25) : Color.white.opacity(0.05),
                                lineWidth: card.isMatched ? 1.5 : 1
                            )
                    )
                    .shadow(color: card.isMatched ? accentColor.opacity(glowPulse ? 0.35 : 0.0) : .clear, radius: 8)

                // Symbol — emoji or text
                if card.symbol.count <= 3 {
                    Text(card.symbol)
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundStyle(card.isMatched ? accentColor : .white)
                        .opacity(card.isMatched ? 0.85 : 1.0)
                } else {
                    Text(card.symbol)
                        .font(.system(size: 32))
                        .opacity(card.isMatched ? 0.7 : 1.0)
                }
            }
        }
        .frame(height: 80)
        .rotation3DEffect(
            .degrees(card.isFaceUp || card.isMatched ? 0 : 180),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.5
        )
        .onChange(of: card.isMatched) { _, matched in
            if matched {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    glowPulse = true
                }
            }
        }
    }
}
