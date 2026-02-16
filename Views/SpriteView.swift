import SwiftUI
import UIKit // Required for UIImage check

struct SpriteView: View {
    var imageName: String
    var frameCount: Int
    var width: CGFloat
    var height: CGFloat
    
    @State private var currentFrame = 0
    @State private var timer: Timer?
    
    var body: some View {
        if let _ = UIImage(named: imageName) {
            GeometryReader { geometry in
                Image(imageName)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFill() // Fill height, overflow width
                    .frame(width: geometry.size.width * CGFloat(frameCount), height: geometry.size.height)
                    .offset(x: -geometry.size.width * CGFloat(currentFrame))
            }
            .frame(width: width, height: height)
            .clipped() // Clip to showing only one frame
            .onAppear {
                startAnimation()
            }
            .onChange(of: imageName) { _, _ in
                currentFrame = 0 // Reset on state change
            }
            .onDisappear {
                stopAnimation()
            }
        } else {
            // Fallback
            VStack {
                Image(systemName: "questionmark.square.dashed")
                    .resizable()
                    .scaledToFit()
                    .frame(width: width * 0.5, height: height * 0.5)
                    .foregroundStyle(.gray)
                Text(imageName)
                    .font(.caption2)
                    .foregroundStyle(.gray)
            }
            .frame(width: width, height: height)
            .background(Color.black.opacity(0.2))
        }
    }
    
    private func startAnimation() {
        stopAnimation()
        // animate at ~10 fps (0.1s)
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if frameCount > 1 {
                currentFrame = (currentFrame + 1) % frameCount
            }
        }
    }
    
    private func stopAnimation() {
        timer?.invalidate()
        timer = nil
    }
}
