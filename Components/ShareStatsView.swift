import SwiftUI

struct ShareStatsView: View {
    let focusMinutes: Int
    let focusSeconds: Int
    let level: Int
    let streak: Int
    let nanobytes: Int
    
    @State private var shareImage: Image?
    
    var body: some View {
        VStack(spacing: 20) {
            // The shareable card
            statsCard
                .padding(.horizontal, 20)
            
            // Share button
            if let shareImage = shareImage {
                ShareLink(item: shareImage, preview: SharePreview("My ForgeFlow Stats", image: shareImage)) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("SHARE STATS")
                            .font(.headline.bold())
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.toxicLime)
                    .cornerRadius(16)
                }
                .padding(.horizontal, 32)
            }
        }
        .onAppear { renderShareImage() }
    }
    
    // The visual card
    private var statsCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "bolt.shield.fill")
                    .font(.title2)
                    .foregroundStyle(Color.toxicLime)
                Text("FORGEFLOW")
                    .font(.system(size: 18, weight: .black, design: .monospaced))
                    .foregroundStyle(.white)
                Spacer()
                Text("LVL \(level)")
                    .font(.caption.bold())
                    .foregroundStyle(Color.toxicLime)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.toxicLime.opacity(0.15))
                    .clipShape(Capsule())
            }
            
            Divider().background(Color.white.opacity(0.1))
            
            HStack(spacing: 20) {
                statItem(title: "FOCUS", value: "\(focusMinutes)m \(focusSeconds)s", icon: "timer")
                statItem(title: "STREAK", value: "\(streak)d", icon: "flame.fill")
                statItem(title: "CREDITS", value: "\(nanobytes)", icon: "cpu")
            }
            
            Text(formattedDate)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(Color.ashGrey)
        }
        .padding(24)
        .background(Color.carbonGrey)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.toxicLime.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func statItem(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(Color.electricCyan)
            Text(value)
                .font(.headline.bold())
                .foregroundStyle(.white)
            Text(title)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(Color.ashGrey)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: Date())
    }
    
    @MainActor
    private func renderShareImage() {
        let renderer = ImageRenderer(content: 
            statsCard
                .frame(width: 340)
                .padding(20)
                .background(Color.voidBlack)
        )
        renderer.scale = 3.0
        if let uiImage = renderer.uiImage {
            shareImage = Image(uiImage: uiImage)
        }
    }
}
