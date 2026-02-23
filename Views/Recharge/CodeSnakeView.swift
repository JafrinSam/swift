import SwiftUI
import SwiftData
import CoreMotion

// MARK: - Code Snake Game
struct CodeSnakeView: View {
    @Query private var heroes: [Hero]
    @Environment(\.modelContext) private var modelContext
    var hero: Hero? { heroes.first }

    // MARK: - Grid Configuration
    private let gridSize = 20
    private let cellSize: CGFloat = 22

    @State private var snake: [GridPos] = [GridPos(x: 10, y: 10)]
    @State private var direction: Direction = .right
    @State private var nextDirection: Direction = .right
    @State private var food: GridPos = GridPos(x: 15, y: 15)
    @State private var score: Int = 0
    @State private var isPlaying = false
    @State private var isGameOver = false
    @State private var timer: Timer?
    @State private var speed: Double = 0.15

    // MARK: - Buffer Overload Mode
    @State private var isBufferOverload = false          // Activates at score 50
    @State private var obstacles: [GridPos] = []         // Junk data obstacles
    @State private var obstacleTimer: Timer?             // Spawns new obstacles
    @State private var overloadTimeRemaining: Int = 30   // 30-second challenge
    @State private var overloadCountdownTimer: Timer?
    @State private var overloadCompleted = false         // Survived the 30s?
    @State private var borderFlash = false               // Red border pulse

    // MARK: - CoreMotion
    private let motionManager = CMMotionManager()
    @State private var isTiltMode = false

    // MARK: - Sensory Feedback Triggers
    @State private var tiltFeedbackTrigger = false
    @State private var eatFeedbackTrigger = false
    @State private var gameOverFeedbackTrigger = false
    @State private var overloadActivatedTrigger = false

    // MARK: - Collectibles
    private let collectibles = ["{}", "</>", "//", "[]", "=>", "&&"]
    @State private var currentCollectible = "{}"
    private let junkChars = ["#", "?", "!", "~", "%", "^", "*"]

    enum Direction {
        case up, down, left, right
        var opposite: Direction {
            switch self {
            case .up: return .down; case .down: return .up
            case .left: return .right; case .right: return .left
            }
        }
    }

    struct GridPos: Equatable {
        var x: Int
        var y: Int
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            Color.voidBlack.ignoresSafeArea()

            VStack(spacing: 16) {
                headerBar

                gameBoard
                    .shadow(color: isBufferOverload ? Color.alertRed.opacity(0.3) : Color.toxicLime.opacity(0.1), radius: 20)
                    .animation(.easeInOut(duration: 0.5), value: isBufferOverload)

                if isBufferOverload {
                    bufferOverloadBanner
                } else if isTiltMode {
                    tiltModeIndicator
                } else {
                    controlPad
                }
            }
            .padding()

            if isGameOver {
                gameOverOverlay
            }
        }
        .gesture(isTiltMode ? nil : swipeGesture)
        .sensoryFeedback(.impact(weight: .light), trigger: tiltFeedbackTrigger)
        .sensoryFeedback(.success, trigger: eatFeedbackTrigger)
        .sensoryFeedback(.warning, trigger: gameOverFeedbackTrigger)
        .sensoryFeedback(.impact(weight: .heavy), trigger: overloadActivatedTrigger)
        .onDisappear {
            stopMotion()
            pauseGame()
            stopOverloadTimers()
        }
    }

    // MARK: - Header Bar
    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("🐍 CODE SNAKE")
                        .font(.system(size: 14, weight: .black, design: .monospaced))
                        .foregroundStyle(.white)
                    if isBufferOverload {
                        Text("⚠ OVERLOAD")
                            .font(.system(size: 8, weight: .black, design: .monospaced))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(Color.alertRed)
                            .cornerRadius(4)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                Text(isTiltMode ? "Tilt to steer" : "Swipe or use arrows")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.ashGrey)
            }

            Spacer()

            HStack(spacing: 10) {
                VStack(spacing: 2) {
                    Text("\(score)")
                        .font(.system(.title3, design: .monospaced)).bold()
                        .foregroundStyle(isBufferOverload ? Color.alertRed : Color.toxicLime)
                        .animation(.easeInOut, value: isBufferOverload)
                    Text("SCORE")
                        .font(.system(size: 7, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.ashGrey)
                }

                // Tilt toggle
                Button {
                    isTiltMode.toggle()
                    if isTiltMode { startMotion() } else { stopMotion() }
                } label: {
                    Image(systemName: isTiltMode ? "gyroscope" : "dpad")
                        .font(.body)
                        .foregroundStyle(isTiltMode ? Color.toxicLime : Color.ashGrey)
                        .frame(width: 36, height: 36)
                        .background(isTiltMode ? Color.toxicLime.opacity(0.15) : Color.carbonGrey.opacity(0.6))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(isTiltMode ? Color.toxicLime.opacity(0.4) : Color.clear, lineWidth: 1))
                }
                .accessibilityLabel(isTiltMode ? "Switch to D-pad" : "Switch to tilt control")

                // Play/Pause
                Button {
                    isPlaying ? pauseGame() : startGame()
                } label: {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.title3)
                        .foregroundStyle(.black)
                        .frame(width: 40, height: 40)
                        .background(Color.toxicLime)
                        .clipShape(Circle())
                }
                .accessibilityLabel(isPlaying ? "Pause" : "Play")
            }
        }
    }

    // MARK: - Game Board
    private var gameBoard: some View {
        let totalSize = CGFloat(gridSize) * cellSize

        return ZStack {
            // Background
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.carbonGrey.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isBufferOverload
                                ? (borderFlash ? Color.alertRed : Color.alertRed.opacity(0.3))
                                : Color.toxicLime.opacity(0.2),
                            lineWidth: isBufferOverload ? 2.5 : 1.5
                        )
                        .animation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true), value: borderFlash)
                )

            // Grid lines
            Canvas { context, size in
                for i in 0...gridSize {
                    let pos = CGFloat(i) * cellSize
                    context.stroke(
                        Path { p in p.move(to: CGPoint(x: pos, y: 0)); p.addLine(to: CGPoint(x: pos, y: size.height)) },
                        with: .color(Color.white.opacity(0.05)), lineWidth: 0.5
                    )
                    context.stroke(
                        Path { p in p.move(to: CGPoint(x: 0, y: pos)); p.addLine(to: CGPoint(x: size.width, y: pos)) },
                        with: .color(Color.white.opacity(0.05)), lineWidth: 0.5
                    )
                }
            }

            // Obstacles (Buffer Overload junk data)
            ForEach(Array(obstacles.enumerated()), id: \.offset) { _, obs in
                Text(junkChars.randomElement() ?? "#")
                    .font(.system(size: cellSize * 0.65, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.alertRed.opacity(0.85))
                    .position(
                        x: CGFloat(obs.x) * cellSize + cellSize / 2,
                        y: CGFloat(obs.y) * cellSize + cellSize / 2
                    )
            }

            // Food
            Text(currentCollectible)
                .font(.system(size: cellSize * 0.75, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.toxicLime)
                .position(
                    x: CGFloat(food.x) * cellSize + cellSize / 2,
                    y: CGFloat(food.y) * cellSize + cellSize / 2
                )

            // Snake
            ForEach(Array(snake.enumerated()), id: \.offset) { idx, seg in
                let isHead = idx == 0
                RoundedRectangle(cornerRadius: isHead ? 6 : 4)
                    .fill(isHead ? Color.toxicLime : Color.toxicLime.opacity(max(0.15, 0.7 - Double(idx) * 0.02)))
                    .frame(width: cellSize * 0.85, height: cellSize * 0.85)
                    .scaleEffect(isHead ? 1.0 : 0.9)
                    .position(
                        x: CGFloat(seg.x) * cellSize + cellSize / 2,
                        y: CGFloat(seg.y) * cellSize + cellSize / 2
                    )
            }

            // Start prompt
            if !isPlaying && !isGameOver {
                VStack(spacing: 6) {
                    Text("TAP ▶ TO DEPLOY")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.toxicLime)
                    Text(isTiltMode ? "Tilt device to steer" : "Swipe or use arrows")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Color.ashGrey)
                    Text("Buffer Overload activates at 50pts")
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundStyle(Color.alertRed.opacity(0.7))
                }
                .padding(14)
                .background(Color.carbonGrey.opacity(0.9))
                .cornerRadius(12)
            }
        }
        .frame(width: totalSize, height: totalSize)
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Buffer Overload Banner
    private var bufferOverloadBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.alertRed)
                .font(.body)
                .symbolEffect(.pulse, isActive: isBufferOverload)

            VStack(alignment: .leading, spacing: 2) {
                Text("⚠ BUFFER OVERLOAD ACTIVE")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(Color.alertRed)
                Text("Avoid junk data • Survive \(overloadTimeRemaining)s for 2× Nanobytes")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(Color.ashGrey)
            }

            Spacer()

            // Countdown ring
            ZStack {
                Circle()
                    .stroke(Color.alertRed.opacity(0.2), lineWidth: 3)
                    .frame(width: 36, height: 36)
                Circle()
                    .trim(from: 0, to: CGFloat(overloadTimeRemaining) / 30.0)
                    .stroke(Color.alertRed, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 36, height: 36)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: overloadTimeRemaining)
                Text("\(overloadTimeRemaining)")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(Color.alertRed)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.alertRed.opacity(0.08))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.alertRed.opacity(0.25), lineWidth: 1))
        .cornerRadius(14)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    // MARK: - Tilt Mode Indicator
    private var tiltModeIndicator: some View {
        HStack(spacing: 12) {
            Image(systemName: "gyroscope")
                .font(.body)
                .foregroundStyle(Color.toxicLime)
                .symbolEffect(.pulse, isActive: isPlaying)

            VStack(alignment: .leading, spacing: 2) {
                Text("TILT MODE ACTIVE")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(Color.toxicLime)
                Text("Tilt your device to steer the snake")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(Color.ashGrey)
            }
            Spacer()
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(Color.toxicLime.opacity(0.08))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.toxicLime.opacity(0.2), lineWidth: 1))
        .cornerRadius(14)
    }

    // MARK: - D-Pad
    private var controlPad: some View {
        VStack(spacing: 6) {
            dpadButton(icon: "chevron.up", dir: .up)
            HStack(spacing: 30) {
                dpadButton(icon: "chevron.left", dir: .left)
                Circle().fill(Color.carbonGrey).frame(width: 30, height: 30)
                dpadButton(icon: "chevron.right", dir: .right)
            }
            dpadButton(icon: "chevron.down", dir: .down)
        }
    }

    private func dpadButton(icon: String, dir: Direction) -> some View {
        Button { changeDirection(dir) } label: {
            Image(systemName: icon)
                .font(.title2.bold())
                .foregroundStyle(Color.toxicLime)
                .frame(width: 50, height: 50)
                .background(Color.carbonGrey.opacity(0.6))
                .clipShape(Circle())
        }
        .accessibilityLabel("Move \(dir)")
    }

    // MARK: - Swipe Gesture
    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 20, coordinateSpace: .global)
            .onEnded { value in
                let dx = value.translation.width
                let dy = value.translation.height
                if abs(dx) > abs(dy) {
                    changeDirection(dx > 0 ? .right : .left)
                } else {
                    changeDirection(dy > 0 ? .down : .up)
                }
            }
    }

    // MARK: - CoreMotion
    private func startMotion() {
        guard motionManager.isAccelerometerAvailable else { return }
        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.startAccelerometerUpdates(to: .main) { data, _ in
            guard let data = data, isPlaying else { return }
            let x = data.acceleration.x
            let y = data.acceleration.y
            let threshold = 0.30

            if abs(x) > abs(y) {
                if x < -threshold { changeDirection(.left) }
                else if x > threshold { changeDirection(.right) }
            } else {
                if y > threshold { changeDirection(.up) }
                else if y < -threshold { changeDirection(.down) }
            }
        }
    }

    private func stopMotion() {
        motionManager.stopAccelerometerUpdates()
    }

    // MARK: - Buffer Overload Logic
    private func activateBufferOverload() {
        guard !isBufferOverload else { return }
        withAnimation(.spring(response: 0.4)) {
            isBufferOverload = true
            borderFlash = true
        }
        overloadActivatedTrigger.toggle()
        overloadTimeRemaining = 30

        // Spawn obstacles every 3 seconds
        obstacleTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            spawnObstacle()
        }

        // Countdown timer
        overloadCountdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if overloadTimeRemaining > 0 {
                overloadTimeRemaining -= 1
            } else {
                // Survived!
                overloadCompleted = true
                stopOverloadTimers()
                withAnimation {
                    isBufferOverload = false
                    obstacles = []
                }
            }
        }
    }

    private func spawnObstacle() {
        var pos: GridPos
        var attempts = 0
        repeat {
            pos = GridPos(x: Int.random(in: 0..<gridSize), y: Int.random(in: 0..<gridSize))
            attempts += 1
        } while (snake.contains(where: { $0 == pos }) || pos == food || obstacles.contains(pos)) && attempts < 20
        if attempts < 20 {
            obstacles.append(pos)
        }
    }

    private func stopOverloadTimers() {
        obstacleTimer?.invalidate()
        obstacleTimer = nil
        overloadCountdownTimer?.invalidate()
        overloadCountdownTimer = nil
    }

    // MARK: - Game Logic
    private func changeDirection(_ newDir: Direction) {
        guard newDir != direction.opposite else { return }
        guard newDir != nextDirection else { return }
        nextDirection = newDir
        tiltFeedbackTrigger.toggle()
    }

    private func startGame() {
        if isGameOver { resetGame() }
        isPlaying = true
        spawnFood()
        if isTiltMode { startMotion() }
        timer = Timer.scheduledTimer(withTimeInterval: speed, repeats: true) { _ in tick() }
    }

    private func pauseGame() {
        isPlaying = false
        timer?.invalidate()
        timer = nil
        if isTiltMode { stopMotion() }
    }

    private func resetGame() {
        timer?.invalidate(); timer = nil
        stopOverloadTimers()
        snake = [GridPos(x: 10, y: 10)]
        direction = .right; nextDirection = .right
        score = 0; isPlaying = false; isGameOver = false
        speed = 0.15
        isBufferOverload = false
        overloadCompleted = false
        obstacles = []
        overloadTimeRemaining = 30
        borderFlash = false
    }

    private func tick() {
        direction = nextDirection
        var newHead = snake[0]

        switch direction {
        case .up:    newHead.y -= 1
        case .down:  newHead.y += 1
        case .left:  newHead.x -= 1
        case .right: newHead.x += 1
        }

        // Wall collision
        if newHead.x < 0 || newHead.x >= gridSize || newHead.y < 0 || newHead.y >= gridSize {
            endGame(); return
        }
        // Self collision
        if snake.contains(where: { $0 == newHead }) {
            endGame(); return
        }
        // Obstacle collision (Buffer Overload)
        if obstacles.contains(where: { $0 == newHead }) {
            endGame(); return
        }

        snake.insert(newHead, at: 0)

        if newHead == food {
            score += 10
            eatFeedbackTrigger.toggle()
            spawnFood()

            // Activate Buffer Overload at 50 points
            if score >= 50 && !isBufferOverload && !overloadCompleted {
                activateBufferOverload()
            }

            // Speed up
            if speed > 0.07 {
                speed -= 0.005
                timer?.invalidate()
                timer = Timer.scheduledTimer(withTimeInterval: speed, repeats: true) { _ in tick() }
            }

            // Reduce burnout
            hero?.recoverBurnout(amount: 0.02)
            try? modelContext.save()
        } else {
            snake.removeLast()
        }
    }

    private func spawnFood() {
        var pos: GridPos
        repeat {
            pos = GridPos(x: Int.random(in: 0..<gridSize), y: Int.random(in: 0..<gridSize))
        } while snake.contains(where: { $0 == pos }) || obstacles.contains(where: { $0 == pos })
        food = pos
        currentCollectible = collectibles.randomElement() ?? "{}"
    }

    private func endGame() {
        timer?.invalidate(); timer = nil
        isPlaying = false
        stopMotion()
        stopOverloadTimers()

        withAnimation(.spring(response: 0.5)) { isGameOver = true }
        gameOverFeedbackTrigger.toggle()

        // Award XP + Nanobyte bonus
        if let hero = hero, score > 0 {
            let xp = min(score / 2, 25)
            hero.addXP(amount: xp)

            // 2× nanobyte bonus for surviving Buffer Overload
            if overloadCompleted {
                hero.nanobytes += score * 2
            } else {
                hero.nanobytes += score
            }
            try? modelContext.save()
        }
    }

    // MARK: - Game Over Overlay
    private var gameOverOverlay: some View {
        VStack(spacing: 16) {
            Spacer()

            VStack(spacing: 14) {
                Text(overloadCompleted ? "🏆" : "💥")
                    .font(.system(size: 50))

                Text(overloadCompleted ? "BUFFER CLEARED" : "STACK OVERFLOW")
                    .font(.system(size: 18, weight: .black, design: .monospaced))
                    .foregroundStyle(overloadCompleted ? Color.toxicLime : .white)

                Text("Score: \(score)")
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundStyle(Color.electricCyan)

                if score > 0 {
                    VStack(spacing: 4) {
                        Text("+\(min(score / 2, 25)) XP Earned")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.toxicLime)

                        if overloadCompleted {
                            Text("+\(score * 2) Nanobytes (2× Overload Bonus!)")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color.ballisticOrange)
                        } else {
                            Text("+\(score) Nanobytes")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(Color.ashGrey)
                        }
                    }
                }

                if !overloadCompleted && score >= 50 {
                    Text("Tip: Survive 30s in Overload for 2× Nanobytes!")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Color.alertRed.opacity(0.8))
                        .multilineTextAlignment(.center)
                }

                Button {
                    withAnimation { isGameOver = false }
                    resetGame()
                    startGame()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("RETRY")
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
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(
                overloadCompleted ? Color.toxicLime.opacity(0.4) : Color.alertRed.opacity(0.2)
            ))
            .padding(.horizontal, 30)

            Spacer()
        }
        .background(Color.black.opacity(0.75).ignoresSafeArea())
        .transition(.opacity)
    }
}
