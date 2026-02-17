import SwiftUI
import SwiftData

// MARK: - Code Snake Game
struct CodeSnakeView: View {
    @Query private var heroes: [Hero]
    @Environment(\.modelContext) private var modelContext
    
    var hero: Hero? { heroes.first }
    
    // Grid configuration
    private let gridSize = 15
    private let cellSize: CGFloat = 20
    
    @State private var snake: [GridPos] = [GridPos(x: 7, y: 7)]
    @State private var direction: Direction = .right
    @State private var nextDirection: Direction = .right
    @State private var food: GridPos = GridPos(x: 10, y: 10)
    @State private var score: Int = 0
    @State private var isPlaying = false
    @State private var isGameOver = false
    @State private var timer: Timer?
    @State private var speed: Double = 0.18
    
    enum Direction {
        case up, down, left, right
        
        var opposite: Direction {
            switch self {
            case .up: return .down
            case .down: return .up
            case .left: return .right
            case .right: return .left
            }
        }
    }
    
    struct GridPos: Equatable {
        var x: Int
        var y: Int
    }
    
    // Dev-themed collectibles
    private let collectibles = ["{}", "</>", "//", "[]", "=>", "&&"]
    @State private var currentCollectible = "{}"
    
    var body: some View {
        ZStack {
            Color.voidBlack.ignoresSafeArea()
            
            VStack(spacing: 16) {
                headerBar
                gameBoard
                controlPad
            }
            .padding()
            
            if isGameOver {
                gameOverOverlay
            }
        }
        .gesture(swipeGesture)
    }
    
    // MARK: - Header
    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("🐍 CODE SNAKE")
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .foregroundStyle(.white)
                Text("Collect brackets, avoid walls")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.ashGrey)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                VStack(spacing: 2) {
                    Text("\(score)")
                        .font(.system(.title3, design: .monospaced)).bold()
                        .foregroundStyle(Color.toxicLime)
                    Text("SCORE")
                        .font(.system(size: 7, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.ashGrey)
                }
                
                Button {
                    if isPlaying {
                        pauseGame()
                    } else {
                        startGame()
                    }
                } label: {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.title3)
                        .foregroundStyle(.black)
                        .frame(width: 40, height: 40)
                        .background(Color.toxicLime)
                        .clipShape(Circle())
                }
            }
        }
    }
    
    // MARK: - Game Board
    private var gameBoard: some View {
        let totalSize = CGFloat(gridSize) * cellSize
        
        return ZStack {
            // Grid background
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.carbonGrey.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.toxicLime.opacity(0.15), lineWidth: 1)
                )
            
            // Grid lines
            Canvas { context, size in
                for i in 0...gridSize {
                    let pos = CGFloat(i) * cellSize
                    // Vertical
                    var vPath = Path()
                    vPath.move(to: CGPoint(x: pos, y: 0))
                    vPath.addLine(to: CGPoint(x: pos, y: size.height))
                    context.stroke(vPath, with: .color(Color.white.opacity(0.03)), lineWidth: 0.5)
                    // Horizontal
                    var hPath = Path()
                    hPath.move(to: CGPoint(x: 0, y: pos))
                    hPath.addLine(to: CGPoint(x: size.width, y: pos))
                    context.stroke(hPath, with: .color(Color.white.opacity(0.03)), lineWidth: 0.5)
                }
            }
            
            // Food
            Text(currentCollectible)
                .font(.system(size: cellSize * 0.7))
                .position(
                    x: CGFloat(food.x) * cellSize + cellSize / 2,
                    y: CGFloat(food.y) * cellSize + cellSize / 2
                )
            
            // Snake
            ForEach(Array(snake.enumerated()), id: \.offset) { idx, seg in
                let isHead = idx == 0
                RoundedRectangle(cornerRadius: isHead ? 5 : 3)
                    .fill(isHead ? Color.toxicLime : Color.toxicLime.opacity(0.6 - Double(idx) * 0.03))
                    .frame(width: cellSize - 2, height: cellSize - 2)
                    .position(
                        x: CGFloat(seg.x) * cellSize + cellSize / 2,
                        y: CGFloat(seg.y) * cellSize + cellSize / 2
                    )
            }
            
            // Start prompt
            if !isPlaying && !isGameOver {
                VStack(spacing: 6) {
                    Text("TAP PLAY TO START")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.toxicLime)
                    Text("Swipe or use arrows to steer")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Color.ashGrey)
                }
                .padding(12)
                .background(Color.carbonGrey.opacity(0.9))
                .cornerRadius(10)
            }
        }
        .frame(width: totalSize, height: totalSize)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - D-Pad Controls
    private var controlPad: some View {
        VStack(spacing: 6) {
            // Up
            dpadButton(icon: "chevron.up", dir: .up)
            
            HStack(spacing: 30) {
                dpadButton(icon: "chevron.left", dir: .left)
                
                // Center dot
                Circle()
                    .fill(Color.carbonGrey)
                    .frame(width: 30, height: 30)
                
                dpadButton(icon: "chevron.right", dir: .right)
            }
            
            // Down
            dpadButton(icon: "chevron.down", dir: .down)
        }
    }
    
    private func dpadButton(icon: String, dir: Direction) -> some View {
        Button {
            changeDirection(dir)
        } label: {
            Image(systemName: icon)
                .font(.title2.bold())
                .foregroundStyle(Color.toxicLime)
                .frame(width: 50, height: 50)
                .background(Color.carbonGrey.opacity(0.6))
                .clipShape(Circle())
        }
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
    
    // MARK: - Game Logic
    
    private func changeDirection(_ newDir: Direction) {
        guard newDir != direction.opposite else { return }
        nextDirection = newDir
        Haptics.shared.play(.light)
    }
    
    private func startGame() {
        if isGameOver {
            resetGame()
        }
        isPlaying = true
        spawnFood()
        timer = Timer.scheduledTimer(withTimeInterval: speed, repeats: true) { _ in
            tick()
        }
    }
    
    private func pauseGame() {
        isPlaying = false
        timer?.invalidate()
        timer = nil
    }
    
    private func resetGame() {
        timer?.invalidate()
        timer = nil
        snake = [GridPos(x: 7, y: 7)]
        direction = .right
        nextDirection = .right
        score = 0
        isPlaying = false
        isGameOver = false
        speed = 0.18
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
        if newHead.x < 0 || newHead.x >= gridSize ||
           newHead.y < 0 || newHead.y >= gridSize {
            endGame()
            return
        }
        
        // Self collision
        if snake.contains(where: { $0 == newHead }) {
            endGame()
            return
        }
        
        snake.insert(newHead, at: 0)
        
        // Eat food
        if newHead == food {
            score += 10
            Haptics.shared.notify(.success)
            spawnFood()
            
            // Speed up slightly
            if speed > 0.08 {
                speed -= 0.005
                timer?.invalidate()
                timer = Timer.scheduledTimer(withTimeInterval: speed, repeats: true) { _ in
                    tick()
                }
            }
            
            // Reduce burnout
            if let hero = hero {
                hero.burnoutLevel = max(0, hero.burnoutLevel - 0.02)
                try? modelContext.save()
            }
        } else {
            snake.removeLast()
        }
    }
    
    private func spawnFood() {
        var pos: GridPos
        repeat {
            pos = GridPos(x: Int.random(in: 0..<gridSize), y: Int.random(in: 0..<gridSize))
        } while snake.contains(where: { $0 == pos })
        food = pos
        currentCollectible = collectibles.randomElement() ?? "{}"
    }
    
    private func endGame() {
        timer?.invalidate()
        timer = nil
        isPlaying = false
        
        withAnimation(.spring(response: 0.5)) {
            isGameOver = true
        }
        
        Haptics.shared.notify(.warning)
        
        // Award XP based on score
        if let hero = hero, score > 0 {
            let xp = min(score / 2, 25) // Cap at 25 XP
            hero.addXP(amount: xp)
            try? modelContext.save()
        }
    }
    
    // MARK: - Game Over
    private var gameOverOverlay: some View {
        VStack(spacing: 16) {
            Spacer()
            
            VStack(spacing: 14) {
                Text("💥")
                    .font(.system(size: 50))
                
                Text("STACK OVERFLOW")
                    .font(.system(size: 18, weight: .black, design: .monospaced))
                    .foregroundStyle(.white)
                
                Text("Score: \(score)")
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundStyle(Color.electricCyan)
                
                if score > 0 {
                    Text("+\(min(score / 2, 25)) XP Earned")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.toxicLime)
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
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.toxicLime.opacity(0.2)))
            .padding(.horizontal, 30)
            
            Spacer()
        }
        .background(Color.black.opacity(0.7).ignoresSafeArea())
        .transition(.opacity)
    }
}
