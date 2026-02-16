import SwiftUI
import AVFoundation

struct SettingsView: View {
    // MARK: - Timer Settings
    @AppStorage("focusDuration") private var focusDuration: Int = 25
    @AppStorage("shortBreakDuration") private var shortBreakDuration: Int = 5
    @AppStorage("longBreakDuration") private var longBreakDuration: Int = 15
    @AppStorage("autoStartBreak") private var autoStartBreak: Bool = true
    @AppStorage("selectedSoundID") private var selectedSoundID: Int = 1005
    
    // MARK: - Available System Sounds
    private let systemSounds: [(name: String, id: Int)] = [
        ("Tri-tone (Default)", 1005),
        ("Alert", 1007),
        ("Glass", 1006),
        ("Horn", 1033),
        ("Bell", 1013),
        ("Electronic", 1014),
        ("Chime", 1008),
        ("Descent", 1024),
        ("Fanfare", 1025),
        ("Ladder", 1026),
        ("Minuet", 1027),
        ("Sherwood Forest", 1030),
        ("Anticipate", 1320),
        ("Bloom", 1321),
        ("Calypso", 1322),
        ("Input", 1327),
        ("Keys", 1328),
        ("Noir", 1329),
        ("Pulse", 1331),
        ("Update", 1336),
    ]
    
    @State private var previewingSound: Int? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.voidBlack.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // MARK: - Timer Configuration
                        settingsSection(title: "REACTOR CALIBRATION", icon: "timer") {
                            // Focus Duration
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Focus Duration")
                                        .font(.system(.subheadline, design: .monospaced))
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Text("\(focusDuration) min")
                                        .font(.system(.subheadline, design: .monospaced)).bold()
                                        .foregroundStyle(Color.electricCyan)
                                }
                                Slider(value: Binding(
                                    get: { Double(focusDuration) },
                                    set: { focusDuration = Int($0) }
                                ), in: 5...120, step: 5)
                                .tint(Color.electricCyan)
                            }
                            
                            Divider().overlay(Color.white.opacity(0.05))
                            
                            // Short Break
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Short Break")
                                        .font(.system(.subheadline, design: .monospaced))
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Text("\(shortBreakDuration) min")
                                        .font(.system(.subheadline, design: .monospaced)).bold()
                                        .foregroundStyle(Color.toxicLime)
                                }
                                Slider(value: Binding(
                                    get: { Double(shortBreakDuration) },
                                    set: { shortBreakDuration = Int($0) }
                                ), in: 1...30, step: 1)
                                .tint(Color.toxicLime)
                            }
                            
                            Divider().overlay(Color.white.opacity(0.05))
                            
                            // Long Break
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Long Break (every 4 sessions)")
                                        .font(.system(.subheadline, design: .monospaced))
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Text("\(longBreakDuration) min")
                                        .font(.system(.subheadline, design: .monospaced)).bold()
                                        .foregroundStyle(Color.ballisticOrange)
                                }
                                Slider(value: Binding(
                                    get: { Double(longBreakDuration) },
                                    set: { longBreakDuration = Int($0) }
                                ), in: 5...45, step: 5)
                                .tint(Color.ballisticOrange)
                            }
                            
                            Divider().overlay(Color.white.opacity(0.05))
                            
                            // Auto-start break
                            Toggle(isOn: $autoStartBreak) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Auto-start Break")
                                        .font(.system(.subheadline, design: .monospaced))
                                        .foregroundStyle(.white)
                                    Text("Automatically begins break after focus ends")
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundStyle(Color.ashGrey)
                                }
                            }
                            .tint(Color.toxicLime)
                        }
                        
                        // MARK: - Notification Sound
                        settingsSection(title: "ALERT SIGNAL", icon: "speaker.wave.3.fill") {
                            ForEach(systemSounds, id: \.id) { sound in
                                Button {
                                    selectedSoundID = sound.id
                                    AudioServicesPlaySystemSound(SystemSoundID(sound.id))
                                    previewingSound = sound.id
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        if previewingSound == sound.id {
                                            previewingSound = nil
                                        }
                                    }
                                    Haptics.shared.play(.light)
                                } label: {
                                    HStack {
                                        Image(systemName: selectedSoundID == sound.id ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(selectedSoundID == sound.id ? Color.toxicLime : Color.ashGrey)
                                            .font(.body)
                                        
                                        Text(sound.name)
                                            .font(.system(.subheadline, design: .monospaced))
                                            .foregroundStyle(selectedSoundID == sound.id ? .white : Color.smokeWhite.opacity(0.7))
                                        
                                        Spacer()
                                        
                                        if previewingSound == sound.id {
                                            Image(systemName: "speaker.wave.2.fill")
                                                .font(.caption)
                                                .foregroundStyle(Color.electricCyan)
                                                .transition(.scale.combined(with: .opacity))
                                        }
                                    }
                                    .padding(.vertical, 6)
                                }
                                .buttonStyle(.plain)
                                
                                if sound.id != systemSounds.last?.id {
                                    Divider().overlay(Color.white.opacity(0.03))
                                }
                            }
                        }
                        
                        // MARK: - Theme Engine
                        settingsSection(title: "VISUAL MATRIX", icon: "paintbrush.fill") {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Active Theme")
                                        .font(.system(.subheadline, design: .monospaced))
                                        .foregroundStyle(.white)
                                    Spacer()
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(ThemeManager.shared.currentAccent)
                                            .frame(width: 12, height: 12)
                                        Text(ThemeManager.shared.activeThemeID.replacingOccurrences(of: "theme_", with: "").uppercased())
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                            .foregroundStyle(ThemeManager.shared.currentAccent)
                                    }
                                    .padding(.horizontal, 10).padding(.vertical, 5)
                                    .background(ThemeManager.shared.currentAccent.opacity(0.12))
                                    .clipShape(Capsule())
                                }
                                
                                Text("Manage themes in the Armory ⚡")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundStyle(Color.ashGrey)
                            }
                        }
                        
                        // MARK: - About
                        settingsSection(title: "SYSTEM INFO", icon: "info.circle") {
                            infoRow(label: "Version", value: "1.0.0")
                            Divider().overlay(Color.white.opacity(0.03))
                            infoRow(label: "Engine", value: "ForgeFlow Core")
                            Divider().overlay(Color.white.opacity(0.03))
                            infoRow(label: "Framework", value: "SwiftUI + SwiftData")
                        }
                    }
                    .padding()
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Helpers
    
    private func settingsSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(title, systemImage: icon)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.ashGrey)
            
            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding(16)
            .background(Color.carbonGrey.opacity(0.5))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
        }
    }
    
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(.subheadline, design: .monospaced))
                .foregroundStyle(Color.smokeWhite.opacity(0.7))
            Spacer()
            Text(value)
                .font(.system(.subheadline, design: .monospaced))
                .foregroundStyle(Color.ashGrey)
        }
    }
}
