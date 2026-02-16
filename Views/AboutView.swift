import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.voidBlack.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 28) {
                        // App Identity
                        VStack(spacing: 12) {
                            Image(systemName: "bolt.shield.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(Color.toxicLime)
                            
                            Text("FORGEFLOW")
                                .font(.system(size: 28, weight: .black, design: .monospaced))
                                .foregroundStyle(.white)
                            
                            Text("v1.0 • Swift Student Challenge 2025")
                                .font(.caption)
                                .foregroundStyle(Color.ashGrey)
                        }
                        .padding(.top, 20)
                        
                        // Why I Built This
                        sectionCard(
                            title: "WHY I BUILT THIS",
                            icon: "brain.head.profile",
                            content: """
                            As a student, I struggled with maintaining focus during long study sessions. \
                            Traditional productivity apps felt clinical and uninspiring. I wanted to create \
                            a system that treats deep work as an engaging experience — where every minute of \
                            focus earns tangible rewards and your progress feels alive.
                            
                            ForgeFlow transforms productivity into a cyberpunk command center where you're \
                            the operator of your own cognitive engine. The burnout detection system is inspired \
                            by real research on sustainable work patterns, ensuring you push hard but never crash.
                            """
                        )
                        
                        // Technologies
                        sectionCard(
                            title: "TECH STACK",
                            icon: "cpu",
                            content: nil,
                            customContent: AnyView(techStack)
                        )
                        
                        // Features
                        sectionCard(
                            title: "KEY INNOVATIONS",
                            icon: "sparkles",
                            content: nil,
                            customContent: AnyView(innovations)
                        )
                    }
                    .padding()
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.toxicLime)
                }
            }
        }
    }
    
    private var techStack: some View {
        VStack(alignment: .leading, spacing: 12) {
            techRow(name: "SwiftUI", desc: "Declarative UI framework")
            techRow(name: "SwiftData", desc: "Persistent data layer")
            techRow(name: "Swift Charts", desc: "Data visualization")
            techRow(name: "AVFoundation", desc: "Audio recording engine")
            techRow(name: "UIKit Haptics", desc: "Tactile feedback system")
        }
    }
    
    private var innovations: some View {
        VStack(alignment: .leading, spacing: 12) {
            innovationRow(icon: "flame.fill", text: "Burnout Detection Engine — monitors focus sustainability")
            innovationRow(icon: "chart.bar.fill", text: "Temporal Analysis — precision second-level tracking")
            innovationRow(icon: "gamecontroller.fill", text: "Gamified XP System — makes productivity engaging")
            innovationRow(icon: "mic.fill", text: "Voice Notes — audio context linked to missions")
            innovationRow(icon: "accessibility", text: "Built for Everyone — VoiceOver & Dynamic Type ready")
        }
    }
    
    // MARK: - Helpers
    
    private func sectionCard(title: String, icon: String, content: String?, customContent: AnyView? = nil) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(Color.toxicLime)
                Text(title)
                    .font(.caption.bold())
                    .foregroundStyle(Color.ashGrey)
                    .tracking(2)
            }
            
            if let content = content {
                Text(content)
                    .font(.subheadline)
                    .foregroundStyle(Color.smokeWhite.opacity(0.85))
                    .lineSpacing(4)
            }
            
            if let customContent = customContent {
                customContent
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.carbonGrey)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
    
    private func techRow(name: String, desc: String) -> some View {
        HStack(spacing: 12) {
            Text(name)
                .font(.caption.bold())
                .foregroundStyle(Color.toxicLime)
                .frame(width: 100, alignment: .leading)
            Text(desc)
                .font(.caption)
                .foregroundStyle(Color.ashGrey)
        }
    }
    
    private func innovationRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.toxicLime)
                .frame(width: 20)
            Text(text)
                .font(.caption)
                .foregroundStyle(Color.smokeWhite.opacity(0.85))
        }
    }
}
