import SwiftUI
import Observation

// MARK: - Theme Definition
struct AppTheme {
    let id: String
    let primaryAccent: Color      // Main accent (buttons, highlights, tab tint)
    let secondaryAccent: Color    // Secondary (progress bars, badges)
    let tertiaryAccent: Color     // Tertiary (links, subtle elements)
    let cardBackground: Color     // Card/surface bg
    let baseBackground: Color     // Root background
    let textPrimary: Color        // Primary text
    let textSecondary: Color      // Subdued text
    let gradientStart: Color      // Gradient start
    let gradientEnd: Color        // Gradient end
}

// MARK: - Built-in Theme Palettes
extension AppTheme {
    /// Default ForgeFlow — Cyber Blue
    static let standard = AppTheme(
        id: "default",
        primaryAccent: Color(hex: "00F2FF"),
        secondaryAccent: Color(hex: "FF9500"),
        tertiaryAccent: Color(hex: "00F2FF"),
        cardBackground: Color(hex: "1A1F2B"),
        baseBackground: Color(hex: "0B0D10"),
        textPrimary: Color(hex: "F5F5F5"),
        textSecondary: Color(hex: "B0B3B8"),
        gradientStart: Color(hex: "00F2FF"),
        gradientEnd: Color(hex: "FF9500")
    )
    
    /// Spec-Ops — Warm tactical orange
    static let specOps = AppTheme(
        id: "theme_cyber",
        primaryAccent: Color(hex: "FF9500"),
        secondaryAccent: Color(hex: "FFB84D"),
        tertiaryAccent: Color(hex: "FF6B00"),
        cardBackground: Color(hex: "1C1810"),
        baseBackground: Color(hex: "0D0B08"),
        textPrimary: Color(hex: "FFF0DB"),
        textSecondary: Color(hex: "C4A882"),
        gradientStart: Color(hex: "FF9500"),
        gradientEnd: Color(hex: "FF3B30")
    )
    
    /// Deep Sea — Cold oceanic blue-green
    static let deepSea = AppTheme(
        id: "theme_ocean",
        primaryAccent: Color(hex: "00F2FF"),
        secondaryAccent: Color(hex: "0A84FF"),
        tertiaryAccent: Color(hex: "64D2FF"),
        cardBackground: Color(hex: "0E1A24"),
        baseBackground: Color(hex: "060D14"),
        textPrimary: Color(hex: "D8F0FF"),
        textSecondary: Color(hex: "6BA3C2"),
        gradientStart: Color(hex: "00F2FF"),
        gradientEnd: Color(hex: "0A84FF")
    )
    
    /// Inferno — Aggressive red-fire
    static let inferno = AppTheme(
        id: "theme_fire",
        primaryAccent: Color(hex: "FF3B30"),
        secondaryAccent: Color(hex: "FF6B3D"),
        tertiaryAccent: Color(hex: "FF453A"),
        cardBackground: Color(hex: "1E1210"),
        baseBackground: Color(hex: "100806"),
        textPrimary: Color(hex: "FFE0D6"),
        textSecondary: Color(hex: "C48070"),
        gradientStart: Color(hex: "FF3B30"),
        gradientEnd: Color(hex: "FF9500")
    )
    
    /// Construct (Hacker) — Matrix green
    static let construct = AppTheme(
        id: "theme_hacker",
        primaryAccent: Color(hex: "00FF41"),
        secondaryAccent: Color(hex: "ADFF2F"),
        tertiaryAccent: Color(hex: "008F11"),
        cardBackground: Color(hex: "0A1A0A"),
        baseBackground: Color(hex: "050D05"),
        textPrimary: Color(hex: "C8FFC8"),
        textSecondary: Color(hex: "5A8A5A"),
        gradientStart: Color(hex: "00FF41"),
        gradientEnd: Color(hex: "ADFF2F")
    )
    
    /// Lookup by ID
    static func theme(for id: String) -> AppTheme {
        switch id {
        case "theme_cyber":  return .specOps
        case "theme_ocean":  return .deepSea
        case "theme_fire":   return .inferno
        case "theme_hacker": return .construct
        default:             return .standard
        }
    }
}

// MARK: - Theme Manager (Single Source of Truth)
@Observable
class ThemeManager {
    static let shared = ThemeManager()
    
    // Persistent state
    var activeThemeID: String = "default" {
        didSet { _activeTheme = AppTheme.theme(for: activeThemeID) }
    }
    private var _activeTheme: AppTheme = .standard
    
    // Preview state
    var previewColor: Color?
    var previewThemeID: String?
    var isPreviewing: Bool = false
    private var _previewTheme: AppTheme?
    
    // MARK: - The Live Theme
    var current: AppTheme {
        if isPreviewing, let preview = _previewTheme {
            return preview
        }
        return _activeTheme
    }
    
    var currentAccent: Color { current.primaryAccent }
    
    var isHackerMode: Bool {
        let id = isPreviewing ? (previewThemeID ?? activeThemeID) : activeThemeID
        return id == "theme_hacker"
    }
    
    // MARK: - Actions
    func applyTheme(_ id: String, color: Color) {
        cancelPreview()
        withAnimation(.easeInOut(duration: 0.5)) {
            self.activeThemeID = id
        }
    }
    
    func startPreview(id: String, color: Color) {
        withAnimation(.easeInOut(duration: 0.3)) {
            self.previewThemeID = id
            self.previewColor = color
            self._previewTheme = AppTheme.theme(for: id)
            self.isPreviewing = true
        }
    }
    
    func cancelPreview() {
        withAnimation(.easeInOut(duration: 0.3)) {
            self.isPreviewing = false
            self.previewColor = nil
            self.previewThemeID = nil
            self._previewTheme = nil
        }
    }
}

// MARK: - Color Extension
extension Color {
    // 1. Base Palette — now theme-aware
    static var voidBlack: Color { ThemeManager.shared.current.baseBackground }
    static var carbonGrey: Color { ThemeManager.shared.current.cardBackground }
    static var surfaceGrey: Color { ThemeManager.shared.current.cardBackground }
    static var smokeWhite: Color { ThemeManager.shared.current.textPrimary }
    static var ashGrey: Color { ThemeManager.shared.current.textSecondary }
    
    // Hard-coded — these don't change with theme
    static let alertRed = Color(hex: "FF3B30")
    static let creditsGold = Color(hex: "FFD700")
    static let hotPink = Color(hex: "BC00FF")
    
    // 2. Tactical Accents — from theme
    static var toxicLime: Color { ThemeManager.shared.current.primaryAccent }
    static var ballisticOrange: Color { ThemeManager.shared.current.secondaryAccent }
    static var electricCyan: Color { ThemeManager.shared.current.tertiaryAccent }
    static var radarBlue: Color { electricCyan }
    static var tacticalTeal: Color { electricCyan }
    static var targetGreen: Color { toxicLime }
    
    // 3. Gradients — from theme
    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [ThemeManager.shared.current.gradientStart, ThemeManager.shared.current.gradientEnd],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
    
    static var flowGradient: LinearGradient {
        LinearGradient(
            colors: [ThemeManager.shared.current.gradientStart, ThemeManager.shared.current.tertiaryAccent],
            startPoint: .top, endPoint: .bottom
        )
    }
    
    // 4. Hex Initializer
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
