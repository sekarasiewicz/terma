import SwiftUI

@Observable
class AppSettings {
    static let shared = AppSettings()

    var terminalThemeRawValue: String {
        didSet {
            UserDefaults.standard.set(terminalThemeRawValue, forKey: "terminalTheme")
        }
    }

    var biometricEnabled: Bool {
        didSet {
            UserDefaults.standard.set(biometricEnabled, forKey: "biometricEnabled")
        }
    }

    var terminalTheme: TerminalTheme {
        get {
            TerminalTheme(rawValue: terminalThemeRawValue) ?? .dark
        }
        set {
            terminalThemeRawValue = newValue.rawValue
        }
    }

    private init() {
        self.terminalThemeRawValue = UserDefaults.standard.string(forKey: "terminalTheme") ?? "dark"
        self.biometricEnabled = UserDefaults.standard.bool(forKey: "biometricEnabled")
    }
}
