import UIKit

enum TerminalTheme: String, CaseIterable, Identifiable {
    case dark
    case light
    case solarizedDark
    case solarizedLight

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dark: return "Dark"
        case .light: return "Light"
        case .solarizedDark: return "Solarized Dark"
        case .solarizedLight: return "Solarized Light"
        }
    }

    var backgroundColor: UIColor {
        switch self {
        case .dark:
            return .black
        case .light:
            return UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        case .solarizedDark:
            return UIColor(red: 0.0, green: 0.169, blue: 0.212, alpha: 1.0) // #002b36
        case .solarizedLight:
            return UIColor(red: 0.992, green: 0.965, blue: 0.890, alpha: 1.0) // #fdf6e3
        }
    }

    var foregroundColor: UIColor {
        switch self {
        case .dark:
            return .white
        case .light:
            return .black
        case .solarizedDark:
            return UIColor(red: 0.514, green: 0.580, blue: 0.588, alpha: 1.0) // #839496
        case .solarizedLight:
            return UIColor(red: 0.396, green: 0.482, blue: 0.514, alpha: 1.0) // #657b83
        }
    }

    var cursorColor: UIColor {
        switch self {
        case .dark:
            return .white
        case .light:
            return .black
        case .solarizedDark:
            return UIColor(red: 0.514, green: 0.580, blue: 0.588, alpha: 1.0) // #839496
        case .solarizedLight:
            return UIColor(red: 0.396, green: 0.482, blue: 0.514, alpha: 1.0) // #657b83
        }
    }
}
