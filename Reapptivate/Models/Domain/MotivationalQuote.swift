import Foundation

struct MotivationalQuote: Codable, Identifiable {
    let id: String
    let text: String
    let author: String
}

final class QuoteLoader: @unchecked Sendable {
    static let shared = QuoteLoader()

    private var cache: [MotivationalQuote]?
    private var cachedLocale: String?
    private let lock = NSLock()

    private init() {}

    func allQuotes() -> [MotivationalQuote] {
        lock.lock()
        defer { lock.unlock() }

        let currentLocale = UserDefaults.standard.string(forKey: "appLanguage") ?? "de"
        if let cache, cachedLocale == currentLocale {
            return cache
        }

        let isEnglish = currentLocale == "en"
        let resourceName = isEnglish ? "motivational-quotes_en" : "motivational-quotes"
        let resolvedName = Bundle.main.url(forResource: resourceName, withExtension: "json") != nil
            ? resourceName : "motivational-quotes"
        guard let url = Bundle.main.url(forResource: resolvedName, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let quotes = try? JSONDecoder().decode([MotivationalQuote].self, from: data) else {
            return []
        }

        cache = quotes
        cachedLocale = currentLocale
        return quotes
    }

    func todaysQuote() -> MotivationalQuote? {
        let quotes = allQuotes()
        guard !quotes.isEmpty else { return nil }

        let startOfYear = Calendar.current.date(from: Calendar.current.dateComponents([.year], from: .now)) ?? .now
        let dayOfYear = Calendar.current.dateComponents([.day], from: startOfYear, to: .now).day ?? 0
        return quotes[dayOfYear % quotes.count]
    }
}
