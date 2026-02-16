import SwiftUI

struct LevelUpAlert: View {
    let newLevel: Int
    let rewards: [String]
    var onDismiss: () -> Void = {}
    
    @State private var animateIcon = false
    @State private var animateContent = false
    @State private var animateGlow = false
    
    var body: some View {
        ZStack {
            // Dimmed backdrop
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }
            
            VStack(spacing: 20) {
                // Animated Icon
                ZStack {
                    // Glow ring
                    Circle()
                        .stroke(Color.toxicLime.opacity(0.3), lineWidth: 3)
                        .frame(width: 100, height: 100)
                        .scaleEffect(animateGlow ? 1.5 : 1.0)
                        .opacity(animateGlow ? 0.0 : 0.6)
                    
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(Color.toxicLime)
                        .scaleEffect(animateIcon ? 1.0 : 0.3)
                        .rotationEffect(.degrees(animateIcon ? 0 : -180))
                }
                
                Text("SYSTEM OPTIMIZED")
                    .font(.headline.bold())
                    .foregroundStyle(Color.ashGrey)
                    .tracking(3)
                
                Text("LEVEL \(newLevel)")
                    .font(.system(size: 38, weight: .black, design: .monospaced))
                    .foregroundStyle(.white)
                
                // Rewards list
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(rewards, id: \.self) { reward in
                        Label(reward, systemImage: "checkmark.shield.fill")
                            .font(.caption.bold())
                            .foregroundStyle(Color.toxicLime)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                
                Button {
                    onDismiss()
                } label: {
                    Text("CONTINUE")
                        .font(.headline.bold())
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.toxicLime)
                        .cornerRadius(16)
                }
                .padding(.top, 8)
            }
            .padding(32)
            .background(Color.carbonGrey)
            .clipShape(RoundedRectangle(cornerRadius: 30))
            .overlay(
                RoundedRectangle(cornerRadius: 30)
                    .stroke(Color.toxicLime.opacity(0.6), lineWidth: 2)
            )
            .shadow(color: Color.toxicLime.opacity(0.3), radius: 30)
            .padding(40)
            .scaleEffect(animateContent ? 1.0 : 0.8)
            .opacity(animateContent ? 1.0 : 0.0)
        }
        .onAppear {
            Haptics.shared.notify(.success)
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                animateIcon = true
                animateContent = true
            }
            withAnimation(.easeOut(duration: 1.2).repeatForever(autoreverses: false)) {
                animateGlow = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Level up! You reached level \(newLevel)")
    }
}
