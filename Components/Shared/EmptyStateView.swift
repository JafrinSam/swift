import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    
    @State private var pulse = false
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.toxicLime.opacity(0.15), lineWidth: 1)
                    .frame(width: 100, height: 100)
                    .scaleEffect(pulse ? 1.2 : 1.0)
                    .opacity(pulse ? 0.0 : 0.5)
                
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundStyle(Color.ashGrey.opacity(0.6))
            }
            
            Text(title)
                .font(.headline.bold())
                .foregroundStyle(.white)
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(Color.ashGrey)
                .multilineTextAlignment(.center)
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.caption.bold())
                        .foregroundStyle(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.toxicLime)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle)")
        .onAppear {
            withAnimation(.easeOut(duration: 2.0).repeatForever(autoreverses: false)) {
                pulse = true
            }
        }
    }
}
