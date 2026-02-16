import SwiftUI
import Observation

// MARK: - Theme Manager (Single Source of Truth with Preview Mode)
@Observable
class ThemeManager {
    static let shared = ThemeManager()
    
    // Persistent State
    var activeAccentColor: Color = Color(hex: "00F2FF")
    var activeThemeID: String = "default"
    
    // Temporary Preview State
    var previewColor: Color?
    var previewThemeID: String?
    var isPreviewing: Bool = false
    
    // The "Live" color used by all Views
    var currentAccent: Color {
        isPreviewing ? (previewColor ?? activeAccentColor) : activeAccentColor
    }
    
    var isHackerMode: Bool {
        let id = isPreviewing ? (previewThemeID ?? activeThemeID) : activeThemeID
        return id == "theme_hacker"
    }
    
    func applyTheme(_ id: String, color: Color) {
        cancelPreview()
        withAnimation(.easeInOut(duration: 0.5)) {
            self.activeThemeID = id
            self.activeAccentColor = color
        }
    }
    
    func startPreview(id: String, color: Color) {
        withAnimation(.easeInOut(duration: 0.3)) {
            self.previewThemeID = id
            self.previewColor = color
            self.isPreviewing = true
        }
    }
    
    func cancelPreview() {
        withAnimation(.easeInOut(duration: 0.3)) {
            self.isPreviewing = false
            self.previewColor = nil
            self.previewThemeID = nil
        }
    }
}

extension Color {
    // MARK: - 1. Base Palette (Static Constants)
    static let voidBlack = Color(hex: "0B0D10")  // Background
    static let carbonGrey = Color(hex: "1A1F2B") // Cards
    static let surfaceGrey = Color(hex: "141821") // Elements
    static let alertRed = Color(hex: "FF3B30")   // Thermal Overload
    static let smokeWhite = Color(hex: "F5F5F5") // Text
    static let ashGrey = Color(hex: "B0B3B8")    // Sub-text
    
    // MARK: - 2. Tactical Accents (Theme Aware)
    
    static var toxicLime: Color {
        ThemeManager.shared.isHackerMode ? Color(hex: "00FF41") : Color(hex: "00F2FF")
    }
    
    static var ballisticOrange: Color {
        ThemeManager.shared.isHackerMode ? Color(hex: "ADFF2F") : Color(hex: "FF9500")
    }
    
    static var electricCyan: Color {
        ThemeManager.shared.isHackerMode ? Color(hex: "008F11") : Color(hex: "00F2FF")
    }
    
    static var radarBlue: Color { electricCyan }
    static var tacticalTeal: Color { electricCyan }
    static var targetGreen: Color { toxicLime }
    static var creditsGold: Color { Color(hex: "FFD700") }
    static var hotPink: Color { Color(hex: "BC00FF") }

    // MARK: - 3. Gradients
    static var primaryGradient: LinearGradient {
        LinearGradient(colors: [toxicLime, ballisticOrange], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
    static var flowGradient: LinearGradient {
        LinearGradient(colors: [toxicLime, electricCyan], startPoint: .top, endPoint: .bottom)
    }

    // MARK: - 4. Hex Initializer (The Engine)
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

// MARK: - View Helpers
extension View {
    /// Adds a neon glow effect to any SwiftUI view.
    func neonGlow(color: Color, radius: CGFloat = 10) -> some View {
        self.shadow(color: color.opacity(0.6), radius: radius)
            .shadow(color: color.opacity(0.3), radius: radius * 2)
    }
}
