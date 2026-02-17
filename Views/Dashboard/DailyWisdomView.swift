import SwiftUI

struct NeuralSyncView: View {
    @Binding var isVisible: Bool
    
    // Cyber-Wellness & Tactical Tips
    let quotes = [
        "System integrity begins with a rested architect. Log out to recharge.",
        "A clear mind is the most secure firewall. Clear your cache with a 5-minute break.",
        "Code is a marathon, not a sprint. Pace your processors to avoid thermal throttling.",
        "First, secure your peace. Then, secure the network.",
        "Even the most advanced systems require a reboot. Stand up and stretch.",
        "Your focus is the CPU of this mission. Avoid overheating by hydrating."
    ]
    
    @State private var currentQuote = ""
    @State private var tacticalRecommendation = ""
    
    var body: some View {
        ZStack {
            Color.voidBlack.ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Tactical Icon with FIXED Symbol Effects
                ZStack {
                    Circle()
                        .stroke(Color.toxicLime.opacity(0.2), lineWidth: 1)
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 50))
                        .foregroundStyle(Color.toxicLime)
                        // FIXED: Removed .overall and updated options to .repeating
                        .symbolEffect(.pulse, options: .repeating)
                }
                
                VStack(spacing: 8) {
                    Text("NEURAL SYNC INITIALIZED")
                        .font(.system(.caption, design: .monospaced))
                        .tracking(3)
                        .foregroundStyle(Color.ashGrey)
                    Rectangle()
                        .fill(Color.toxicLime.opacity(0.3))
                        .frame(width: 150, height: 1)
                }
                
                VStack(spacing: 15) {
                    Text("\"\(currentQuote)\"")
                        .font(.system(.title3, design: .rounded))
                        .italic()
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 40)
                    
                    if !tacticalRecommendation.isEmpty {
                        Label("RECOMMENDATION: \(tacticalRecommendation)", systemImage: "info.circle.fill")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.electricCyan)
                            .padding(8)
                            .background(Color.electricCyan.opacity(0.1))
                            .cornerRadius(5)
                    }
                }
                .frame(height: 160)
                
                Spacer()
                
                Button {
                    withAnimation(.spring()) {
                        isVisible = false
                    }
                } label: {
                    HStack {
                        Image(systemName: "terminal.fill")
                        Text("ENTER COMMAND CENTER")
                    }
                    .font(.system(.subheadline, design: .monospaced)).bold()
                    .foregroundStyle(.black)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 32)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LinearGradient(colors: [.toxicLime, .electricCyan], startPoint: .leading, endPoint: .trailing))
                    )
                }
            }
            .padding(.vertical, 60)
        }
        .onAppear {
            currentQuote = quotes.randomElement() ?? "Hello Architect"
            tacticalRecommendation = generateTacticalRecommendation(for: currentQuote)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }
    
    private func generateTacticalRecommendation(for quote: String) -> String {
        if quote.contains("firewall") { return "ENABLE 'DO NOT DISTURB' MODE" }
        if quote.contains("reboot") { return "PHYSICAL SYSTEM RESET: STAND UP" }
        if quote.contains("CPU") { return "HYDRATION PACK: DRINK WATER" }
        return "OPTIMIZE MENTAL BANDWIDTH"
    }
}