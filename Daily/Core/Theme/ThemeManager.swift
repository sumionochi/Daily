import SwiftUI
import Combine

// MARK: - Enums

enum UIStyle: String, CaseIterable, Codable {
    case mono
    case liquidGlass
    
    var displayName: String {
        switch self {
        case .mono: return "Mono"
        case .liquidGlass: return "Liquid Glass"
        }
    }
}

enum ColorSchemePreference: String, CaseIterable, Codable {
    case light
    case dark
    case system
    
    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}

enum AccentColor: String, CaseIterable, Codable {
    case mono
    case blue
    case purple
    case pink
    case orange
    case green
    case teal

    var color: Color {
        switch self {
        case .mono:
            // Explicit mono accent: black in light mode, white in dark mode
            return Color(light: .black, dark: .white)

        case .blue:   return Color(red: 0.4, green: 0.6, blue: 1.0)
        case .purple: return Color(red: 0.7, green: 0.5, blue: 1.0)
        case .pink:   return Color(red: 1.0, green: 0.5, blue: 0.7)
        case .orange: return Color(red: 1.0, green: 0.6, blue: 0.4)
        case .green:  return Color(red: 0.5, green: 0.9, blue: 0.6)
        case .teal:   return Color(red: 0.4, green: 0.8, blue: 0.9)
        }
    }
}


// MARK: - ThemeManager

class ThemeManager: ObservableObject {
    @Published var uiStyle: UIStyle {
        didSet {
            UserDefaults.standard.set(uiStyle.rawValue, forKey: "uiStyle")
        }
    }
    
    @Published var colorSchemePreference: ColorSchemePreference {
        didSet {
            UserDefaults.standard.set(colorSchemePreference.rawValue, forKey: "colorSchemePreference")
        }
    }
    
    @Published var accentColor: AccentColor {
        didSet {
            UserDefaults.standard.set(accentColor.rawValue, forKey: "accentColor")
        }
    }
    
    init() {
        // Load saved preferences
        if let savedStyle = UserDefaults.standard.string(forKey: "uiStyle"),
           let style = UIStyle(rawValue: savedStyle) {
            self.uiStyle = style
        } else {
            self.uiStyle = .mono
        }
        
        if let savedScheme = UserDefaults.standard.string(forKey: "colorSchemePreference"),
           let scheme = ColorSchemePreference(rawValue: savedScheme) {
            self.colorSchemePreference = scheme
        } else {
            self.colorSchemePreference = .system
        }
        
        if let savedAccent = UserDefaults.standard.string(forKey: "accentColor"),
           let accent = AccentColor(rawValue: savedAccent) {
            self.accentColor = accent
        } else {
            self.accentColor = .mono
        }
    }
    
    // MARK: - Design Tokens
    
    // Colors
    var backgroundColor: Color {
        switch uiStyle {
        case .mono:
            // #f0eef7 in light mode, #000000 in dark mode
            return Color(light: Color(red: 240/255, green: 238/255, blue: 247/255),
                        dark: Color(red: 0/255, green: 0/255, blue: 0/255))
        case .liquidGlass:
            return Color.black.opacity(0.85)
        }
    }
    
    var secondaryBackgroundColor: Color {
        switch uiStyle {
        case .mono:
            // #fefeff in light mode, #1c1c1e in dark mode
            return Color(light: Color(red: 254/255, green: 254/255, blue: 255/255),
                        dark: Color(red: 28/255, green: 28/255, blue: 30/255))
        case .liquidGlass:
            return Color.white.opacity(0.05)
        }
    }
    
    var cardBackgroundColor: Color {
        switch uiStyle {
        case .mono:
            // #fefeff in light mode, #1c1c1e in dark mode
            return Color(light: Color(red: 254/255, green: 254/255, blue: 255/255),
                        dark: Color(red: 28/255, green: 28/255, blue: 30/255))
        case .liquidGlass:
            return Color.white.opacity(0.08)
        }
    }
    
    var borderColor: Color {
        switch uiStyle {
        case .mono:
            return Color(uiColor: UIColor.separator)
        case .liquidGlass:
            return Color.white.opacity(0.15)
        }
    }
    
    var textPrimaryColor: Color {
        switch uiStyle {
        case .mono:
            return Color(uiColor: UIColor.label)
        case .liquidGlass:
            return Color.white
        }
    }
    
    var textSecondaryColor: Color {
        switch uiStyle {
        case .mono:
            return Color(uiColor: UIColor.secondaryLabel)
        case .liquidGlass:
            return Color.white.opacity(0.7)
        }
    }
    
    var textTertiaryColor: Color {
        switch uiStyle {
        case .mono:
            return Color(uiColor: UIColor.tertiaryLabel)
        case .liquidGlass:
            return Color.white.opacity(0.5)
        }
    }
    
    var accent: Color {
        accentColor.color
    }
    
    // Typography
    var titleFont: Font {
        .system(size: 28, weight: .bold, design: .rounded)
    }
    
    var subtitleFont: Font {
        .system(size: 20, weight: .semibold, design: .rounded)
    }
    
    var bodyFont: Font {
        .system(size: 16, weight: .regular, design: .default)
    }
    
    var captionFont: Font {
        .system(size: 13, weight: .medium, design: .default)
    }
    
    var buttonFont: Font {
        .system(size: 16, weight: .semibold, design: .rounded)
    }
    
    // Corner Radius
    var cornerRadiusSmall: CGFloat { 8 }
    var cornerRadiusMedium: CGFloat { 12 }
    var cornerRadiusLarge: CGFloat { 20 }
    
    // Shadows
    var shadowRadius: CGFloat {
        switch uiStyle {
        case .mono: return 8
        case .liquidGlass: return 16
        }
    }
    
    var shadowOpacity: Double {
        switch uiStyle {
        case .mono: return 0.1
        case .liquidGlass: return 0.3
        }
    }
    
    // Blur (LiquidGlass only)
    var blurAmount: CGFloat {
        switch uiStyle {
        case .mono: return 0
        case .liquidGlass: return 20
        }
    }
    
    // Text color when drawn on top of `accent`
    var textOnAccentColor: Color {
        // Special handling for Mono accent (which is dynamic: black in light, white in dark)
        if accentColor == .mono {
            switch colorSchemePreference {
            case .light:
                // Accent ~ black → use white text
                return .white
            case .dark:
                // Accent ~ white → use black text
                return .black
            case .system:
                // Follow system: white in light, black in dark
                return Color(light: .white, dark: .black)
            }
        } else {
            // Colored accents → always white text
            return .white
        }
    }

}

// MARK: - Color Extension for Light/Dark Mode

extension Color {
    init(light: Color, dark: Color) {
        self.init(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
    }
}
