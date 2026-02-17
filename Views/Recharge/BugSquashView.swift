import SwiftUI
import SwiftData

// MARK: - Bug Model
struct Bug: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var emoji: String
    var size: CGFloat
    var createdAt: Date = Date()
    var isSplat: Bool = false
    var kind: BugKind = .normal
    
    enum BugKind {
        case normal
        case golden   // 5x points, extra burnout reduction
        case red      // Penalty bug, adds burnout
    }
    
    var pointValue: Int {
        switch kind {
        case .normal:  return 10
        case .golden:  return 50
        case .red:     return -1 // Penalty marker
        }
    }
}

// MARK: - Floating Text ("+10", "COMBO!", etc.)
struct FloatingText: Identifiable {
    let id = UUID()
    var text: String
    var x: CGFloat
    var y: CGFloat
    var color: Color
    var createdAt: Date = Date()
}

// MARK: - Splat Stain
struct SplatStain: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var createdAt: Date = Date()
}

// MARK: - Bug Squash Game
struct BugSquashView: View {
    @Query private var heroes: [Hero]
    @Environment(\.modelContext) private var modelContext
    @AppStorage("bugSquashHighScore") private var highScore: Int = 0
    
    var hero: Hero? { heroes.first }
    
    @State private var bugs: [Bug] = []
    @State private var splats: [SplatStain] = []
    @State private var floatingTexts: [FloatingText] = []
    @State private var squashed: Int = 0
    @State private var escaped: Int = 0
    @State private var score: Int = 0
    @State private var combo: Int = 0
    @State private var bestCombo: Int = 0
    @State private var lastSquashTime: Date = .distantPast
    @State private var isPlaying = false
    @State private var timeRemaining: Int = 30
    @State private var isGameOver = false
    @State private var spawnTimer: Timer?
    @State private var gameTimer: Timer?
    @State private var moveTimer: Timer?
    @State private var shakeOffset: CGFloat = 0
    @State private var bonusTimeFlash = false
    
    private let bugEmojis = ["🐛", "🪲", "🐜", "🦗", "🕷️", "🪳"]
    private let maxBugs = 10
    
    // Difficulty ramps over time
    private var spawnInterval: Double {
        let elapsed = 30 - timeRemaining
        return max(0.4, 0.8 - Double(elapsed) * 0.015) // 0.8s → 0.4s
    }
    
    private var escapeTime: Double {
        let elapsed = 30 - timeRemaining
        return max(1.8, 3.0 - Double(elapsed) * 0.04) // 3s → 1.8s
    }
    
    // Rank based on score
    private var rank: (emoji: String, title: String) {
        switch score {
        case 0..<50:    return ("🐛", "Novice")
        case 50..<150:  return ("🔨", "Debugger")
        case 150..<300: return ("⚡", "Exterminator")
        case 300..<500: return ("🏆", "Bug-Free Master")
        default:        return ("👑", "Legendary")
        }
    }
    
    var body: some View {
        ZStack {
            Color.voidBlack.ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerBar
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                gameArea
            }
            .offset(x: shakeOffset)
            
            // Floating texts layer
            ForEach(floatingTexts) { ft in
                Text(ft.text)
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .foregroundStyle(ft.color)
                    .position(x: ft.x, y: ft.y)
                    .transition(.opacity)
            }
            
            if isGameOver {
                gameOverOverlay
            }
        }
    }
    
    // MARK: - Header
    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("🎯 BUG SQUASH")
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .foregroundStyle(.white)
                
                // Combo display
                if combo >= 2 && isPlaying {
                    HStack(spacing: 4) {
                        Text("\(combo)x COMBO!")
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                            .foregroundStyle(combo >= 5 ? Color.ballisticOrange : Color.electricCyan)
                        if combo >= 5 {
                            Text("🔥")
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                } else {
                    Text("Tap bugs before they escape!")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Color.ashGrey)
                }
            }
            
            Spacer()
            
            HStack(spacing: 10) {
                // Score
                VStack(spacing: 2) {
                    Text("\(score)")
                        .font(.system(.title3, design: .monospaced)).bold()
                        .foregroundStyle(Color.toxicLime)
                    Text("SCORE")
                        .font(.system(size: 7, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.ashGrey)
                }
                
                // Timer
                VStack(spacing: 2) {
                    Text("\(timeRemaining)s")
                        .font(.system(.title3, design: .monospaced)).bold()
                        .foregroundStyle(timerColor)
                    Text("LEFT")
                        .font(.system(size: 7, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.ashGrey)
                }
                .overlay(
                    // Bonus time flash
                    bonusTimeFlash ?
                    Text("+3s")
                        .font(.system(size: 12, weight: .black, design: .monospaced))
                        .foregroundStyle(Color.toxicLime)
                        .offset(y: -22)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    : nil
                )
                
                if !isPlaying && !isGameOver {
                    Button {
                        startGame()
                    } label: {
                        Image(systemName: "play.fill")
                            .font(.title3)
                            .foregroundStyle(.black)
                            .frame(width: 40, height: 40)
                            .background(Color.toxicLime)
                            .clipShape(Circle())
                    }
                }
            }
        }
    }
    
    private var timerColor: Color {
        if timeRemaining <= 5 { return Color.alertRed }
        if timeRemaining <= 10 { return Color.ballisticOrange }
        return Color.electricCyan
    }
    
    // MARK: - Game Area
    private var gameArea: some View {
        GeometryReader { geo in
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.carbonGrey.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.toxicLime.opacity(0.08), lineWidth: 1)
                    )
                
                // Splat stains (persistent marks)
                ForEach(splats) { splat in
                    Text("💚")
                        .font(.system(size: 10))
                        .opacity(0.15)
                        .position(x: splat.x, y: splat.y)
                }
                
                // Start prompt
                if !isPlaying && !isGameOver {
                    startPrompt
                }
                
                // Bugs
                ForEach(bugs) { bug in
                    bugView(bug: bug, areaSize: geo.size)
                }
                
                // High score badge (top right corner)
                if highScore > 0 && !isPlaying {
                    VStack(spacing: 2) {
                        Text("🏆 \(highScore)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.ballisticOrange)
                        Text("BEST")
                            .font(.system(size: 7, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.ashGrey)
                    }
                    .padding(8)
                    .background(Color.carbonGrey.opacity(0.6))
                    .cornerRadius(8)
                    .position(x: geo.size.width - 40, y: 30)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }
    
    private var startPrompt: some View {
        VStack(spacing: 8) {
            Text("🐛")
                .font(.system(size: 50))
            Text("TAP PLAY TO START")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.toxicLime)
            Text("Squash bugs in 30 seconds")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(Color.ashGrey)
            
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Text("🪙").font(.system(size: 10))
                    Text("Golden = 5x points")
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundStyle(Color.ashGrey)
                }
                HStack(spacing: 6) {
                    Text("🔴").font(.system(size: 10))
                    Text("Red = adds burnout!")
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundStyle(Color.alertRed.opacity(0.7))
                }
            }
            .padding(.top, 4)
        }
    }
    
    // MARK: - Bug View
    private func bugView(bug: Bug, areaSize: CGSize) -> some View {
        Group {
            if bug.isSplat {
                // Splat effect
                Text("💥")
                    .font(.system(size: bug.size * 0.9))
                    .position(x: bug.x, y: bug.y)
                    .transition(.scale.combined(with: .opacity))
            } else {
                // Live bug with pulsing + wiggle
                ZStack {
                    // Glow for special bugs
                    if bug.kind == .golden {
                        Circle()
                            .fill(Color.yellow.opacity(0.2))
                            .frame(width: bug.size * 1.8, height: bug.size * 1.8)
                            .blur(radius: 8)
                    }
                    
                    Text(bugDisplay(bug))
                        .font(.system(size: bug.size))
                }
                .position(x: bug.x, y: bug.y)
                .scaleEffect(bugScale(bug))
                .rotationEffect(.degrees(wiggleAngle(bug)))
                .transition(.scale)
                .onTapGesture {
                    squashBug(bug)
                }
            }
        }
    }
    
    private func bugDisplay(_ bug: Bug) -> String {
        switch bug.kind {
        case .golden: return "🪙"
        case .red:    return "🔴"
        case .normal: return bug.emoji
        }
    }
    
    // Bugs pulse bigger right before they escape
    private func bugScale(_ bug: Bug) -> CGFloat {
        let age = Date().timeIntervalSince(bug.createdAt)
        let escTime = escapeTime
        if age > escTime * 0.7 {
            // Pulsing effect when about to escape
            return 1.2
        }
        return 1.0
    }
    
    // Wiggle angle based on time
    private func wiggleAngle(_ bug: Bug) -> Double {
        let age = Date().timeIntervalSince(bug.createdAt)
        return sin(age * 8) * 12 // Wiggle ±12 degrees
    }
    
    // MARK: - Game Logic
    
    private func startGame() {
        squashed = 0
        escaped = 0
        score = 0
        combo = 0
        bestCombo = 0
        timeRemaining = 30
        bugs = []
        splats = []
        floatingTexts = []
        isPlaying = true
        isGameOver = false
        lastSquashTime = .distantPast
        
        // Spawn bugs periodically (adapts to difficulty)
        scheduleSpawner()
        
        // Countdown timer
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            timeRemaining -= 1
            if timeRemaining <= 0 {
                endGame()
            }
        }
        
        // Move bugs & cleanup (60fps feel)
        moveTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            moveBugs()
            cleanupBugs()
            cleanupFloatingTexts()
        }
        
        // Spawn initial bugs
        for _ in 0..<3 {
            spawnBug()
        }
    }
    
    private func scheduleSpawner() {
        spawnTimer?.invalidate()
        spawnTimer = Timer.scheduledTimer(withTimeInterval: spawnInterval, repeats: false) { _ in
            if isPlaying {
                if bugs.filter({ !$0.isSplat }).count < maxBugs {
                    spawnBug()
                }
                scheduleSpawner() // Reschedule with updated interval
            }
        }
    }
    
    private func spawnBug() {
        let padding: CGFloat = 50
        let screenWidth = UIScreen.main.bounds.width - padding * 2
        let screenHeight = UIScreen.main.bounds.height * 0.5
        
        // Determine bug kind
        let roll = Int.random(in: 1...100)
        let kind: Bug.BugKind
        if roll <= 5 {
            kind = .golden     // 5% chance
        } else if roll <= 15 {
            kind = .red        // 10% chance
        } else {
            kind = .normal     // 85% chance
        }
        
        let bug = Bug(
            x: CGFloat.random(in: padding...screenWidth),
            y: CGFloat.random(in: padding...screenHeight),
            emoji: bugEmojis.randomElement() ?? "🐛",
            size: CGFloat.random(in: 28...42),
            kind: kind
        )
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            bugs.append(bug)
        }
    }
    
    // Move bugs around randomly (wiggle/crawl)
    private func moveBugs() {
        let padding: CGFloat = 30
        let screenWidth = UIScreen.main.bounds.width - padding * 2
        let screenHeight = UIScreen.main.bounds.height * 0.5
        
        for i in bugs.indices where !bugs[i].isSplat {
            // Small random walk
            let dx = CGFloat.random(in: -2.5...2.5)
            let dy = CGFloat.random(in: -2.5...2.5)
            
            bugs[i].x = min(max(bugs[i].x + dx, padding), screenWidth)
            bugs[i].y = min(max(bugs[i].y + dy, padding), screenHeight)
        }
    }
    
    private func cleanupBugs() {
        let now = Date()
        let escTime = escapeTime
        
        // Find escaping bugs
        let escaping = bugs.filter { !$0.isSplat && now.timeIntervalSince($0.createdAt) > escTime }
        
        if !escaping.isEmpty {
            escaped += escaping.count
            combo = 0 // Break combo on escape
            
            // Screen shake
            triggerShake()
            
            // Float "ESCAPED" text
            for bug in escaping {
                addFloatingText("ESCAPED!", x: bug.x, y: bug.y, color: Color.alertRed)
            }
        }
        
        withAnimation(.easeOut(duration: 0.2)) {
            bugs.removeAll { !$0.isSplat && now.timeIntervalSince($0.createdAt) > escTime }
        }
        
        // Clean up splats after 0.5s
        bugs.removeAll { $0.isSplat && now.timeIntervalSince($0.createdAt) > 0.5 }
        
        // Clean up old splat stains after 8s
        splats.removeAll { now.timeIntervalSince($0.createdAt) > 8.0 }
    }
    
    private func cleanupFloatingTexts() {
        let now = Date()
        withAnimation {
            floatingTexts.removeAll { now.timeIntervalSince($0.createdAt) > 1.0 }
        }
        
        // Move floating texts up
        for i in floatingTexts.indices {
            floatingTexts[i].y -= 1.5
        }
    }
    
    private func squashBug(_ bug: Bug) {
        guard let idx = bugs.firstIndex(where: { $0.id == bug.id }) else { return }
        guard !bugs[idx].isSplat else { return }
        
        let now = Date()
        
        // Handle RED bug (penalty)
        if bug.kind == .red {
            Haptics.shared.notify(.error)
            combo = 0
            
            // Add burnout!
            if let hero = hero {
                hero.burnoutLevel = min(1.0, hero.burnoutLevel + 0.05)
                try? modelContext.save()
            }
            
            addFloatingText("+5% BURNOUT!", x: bug.x, y: bug.y, color: Color.alertRed)
            triggerShake()
            
            withAnimation(.spring(response: 0.2)) {
                bugs[idx].isSplat = true
                bugs[idx].createdAt = now
            }
            return
        }
        
        // Normal or Golden squash
        squashed += 1
        
        // Combo system — combo if squashed within 1.2 seconds
        if now.timeIntervalSince(lastSquashTime) < 1.2 {
            combo += 1
        } else {
            combo = 1
        }
        bestCombo = max(bestCombo, combo)
        lastSquashTime = now
        
        // Calculate points
        var points = bug.kind == .golden ? 50 : 10
        if combo >= 3 { points = Int(Double(points) * 1.5) } // 1.5x for 3+ combo
        if combo >= 5 { points = Int(Double(points) * 1.2) } // Extra for 5+ combo
        score += points
        
        // Haptic
        if bug.kind == .golden {
            Haptics.shared.notify(.success)
        } else {
            Haptics.shared.play(.medium)
        }
        
        // Floating text
        var floatText = "+\(points)"
        if combo >= 3 {
            floatText += " ×\(combo)"
        }
        if bug.kind == .golden {
            floatText += " 🪙"
        }
        addFloatingText(
            floatText,
            x: bug.x,
            y: bug.y - 10,
            color: bug.kind == .golden ? Color.yellow : Color.toxicLime
        )
        
        // Combo announcement at milestones
        if combo == 3 {
            addFloatingText("COMBO!", x: UIScreen.main.bounds.width / 2, y: 200, color: Color.electricCyan)
        } else if combo == 5 {
            addFloatingText("🔥 FIRE!", x: UIScreen.main.bounds.width / 2, y: 200, color: Color.ballisticOrange)
        } else if combo == 10 {
            addFloatingText("⚡ UNSTOPPABLE!", x: UIScreen.main.bounds.width / 2, y: 200, color: Color.hotPink)
        }
        
        // Leave a splat stain
        splats.append(SplatStain(x: bug.x, y: bug.y))
        
        // Turn bug into splat
        withAnimation(.spring(response: 0.2)) {
            bugs[idx].isSplat = true
            bugs[idx].createdAt = now
        }
        
        // Reduce burnout
        if let hero = hero {
            let reduction = bug.kind == .golden ? 0.05 : 0.01
            hero.burnoutLevel = max(0, hero.burnoutLevel - reduction)
            try? modelContext.save()
        }
        
        // Bonus time every 10 squashes
        if squashed > 0 && squashed % 10 == 0 {
            timeRemaining += 3
            withAnimation(.spring) {
                bonusTimeFlash = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation { bonusTimeFlash = false }
            }
            addFloatingText("+3 SECONDS!", x: UIScreen.main.bounds.width / 2, y: 160, color: Color.toxicLime)
        }
    }
    
    private func addFloatingText(_ text: String, x: CGFloat, y: CGFloat, color: Color) {
        let ft = FloatingText(text: text, x: x, y: y, color: color)
        withAnimation { floatingTexts.append(ft) }
    }
    
    private func triggerShake() {
        withAnimation(.spring(response: 0.1, dampingFraction: 0.3)) {
            shakeOffset = -6
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.1, dampingFraction: 0.3)) {
                shakeOffset = 6
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.15, dampingFraction: 0.5)) {
                shakeOffset = 0
            }
        }
    }
    
    private func endGame() {
        spawnTimer?.invalidate()
        gameTimer?.invalidate()
        moveTimer?.invalidate()
        spawnTimer = nil
        gameTimer = nil
        moveTimer = nil
        isPlaying = false
        
        // Update high score
        if score > highScore {
            highScore = score
        }
        
        // Award XP
        if let hero = hero, score > 0 {
            let xp = min(score / 4, 30) // Cap at 30 XP
            hero.addXP(amount: xp)
            try? modelContext.save()
        }
        
        withAnimation(.spring(response: 0.5)) {
            isGameOver = true
        }
    }
    
    // MARK: - Game Over
    private var gameOverOverlay: some View {
        VStack(spacing: 16) {
            Spacer()
            
            VStack(spacing: 14) {
                Text(rank.emoji)
                    .font(.system(size: 50))
                
                Text(rank.title.uppercased())
                    .font(.system(size: 18, weight: .black, design: .monospaced))
                    .foregroundStyle(.white)
                
                // Score
                VStack(spacing: 4) {
                    Text("\(score)")
                        .font(.system(size: 36, weight: .black, design: .monospaced))
                        .foregroundStyle(Color.toxicLime)
                    Text("POINTS")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.ashGrey)
                }
                
                // Stats grid
                HStack(spacing: 16) {
                    statColumn(value: "\(squashed)", label: "Squashed", color: Color.toxicLime)
                    statColumn(value: "\(escaped)", label: "Escaped", color: Color.alertRed)
                    statColumn(value: "\(bestCombo)x", label: "Best Combo", color: Color.electricCyan)
                }
                .padding()
                .background(Color.carbonGrey.opacity(0.5))
                .cornerRadius(14)
                
                // New high score?
                if score >= highScore && score > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(Color.yellow)
                        Text("NEW HIGH SCORE!")
                            .font(.system(size: 12, weight: .black, design: .monospaced))
                            .foregroundStyle(Color.yellow)
                    }
                    .padding(8)
                    .background(Color.yellow.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // XP earned
                if score > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                            .foregroundStyle(Color.electricCyan)
                        Text("+\(min(score / 4, 30)) XP")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.electricCyan)
                    }
                }
                
                Button {
                    withAnimation { isGameOver = false }
                    startGame()
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
            .padding(24)
            .background(Color.carbonGrey)
            .cornerRadius(20)
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.toxicLime.opacity(0.2)))
            .padding(.horizontal, 30)
            
            Spacer()
        }
        .background(Color.black.opacity(0.7).ignoresSafeArea())
        .transition(.opacity)
    }
    
    private func statColumn(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(.title3, design: .monospaced)).bold()
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.ashGrey)
        }
        .frame(maxWidth: .infinity)
    }
}
