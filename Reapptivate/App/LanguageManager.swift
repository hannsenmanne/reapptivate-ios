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
    @ObservationIgnored @AppStorage("appLanguage")
    private var _language: String = AppLanguage.german.rawValue

    var language: AppLanguage {
        get { AppLanguage(rawValue: _language) ?? .german }
        set { _language = newValue.rawValue }
    }

    var isEnglish: Bool { language == .english }
}
