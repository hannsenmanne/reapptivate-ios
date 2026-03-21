import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case german = "de"
    case english = "en"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .german: return "Deutsch"
        case .english: return "English"
        }
    }

    var locale: Locale { Locale(identifier: rawValue) }
}

@Observable @MainActor final class LanguageManager {
    // Tracked stored property — @Observable synthesizes observation for this,
    // so mutations trigger immediate SwiftUI view updates.
    private var trackedLanguage: AppLanguage

    var language: AppLanguage {
        get { trackedLanguage }
        set {
            trackedLanguage = newValue
            UserDefaults.standard.set(newValue.rawValue, forKey: "appLanguage")
            ProtocolLoader.shared.clearCache()
        }
    }

    init() {
        let raw = UserDefaults.standard.string(forKey: "appLanguage") ?? AppLanguage.german.rawValue
        trackedLanguage = AppLanguage(rawValue: raw) ?? .german
    }

    var isEnglish: Bool { language == .english }
}
