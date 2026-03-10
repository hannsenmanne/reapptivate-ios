import Foundation

struct EducationCard: Codable, Identifiable {
    let id: String
    let phase: Int
    let title: String
    let body: String
    let icon: String
    let source: String?
    let condition: String? // nil = generic tendinopathy, "LBP_NONSPECIFIC" = LBP, "NECK_PAIN" = Neck
}

final class EducationCardLoader: @unchecked Sendable {
    static let shared = EducationCardLoader()

    private var cache: [EducationCard]?
    private let lock = NSLock()

    private init() {}

    func allCards() -> [EducationCard] {
        lock.lock()
        defer { lock.unlock() }

        if let cache {
            return cache
        }

        guard let url = Bundle.main.url(forResource: "education-cards", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let cards = try? JSONDecoder().decode([EducationCard].self, from: data) else {
            return []
        }

        cache = cards
        return cards
    }

    func cardsForPhase(_ phase: Int, isLbp: Bool, isNeck: Bool = false, isTension: Bool = false, isShoulder: Bool = false) -> [EducationCard] {
        allCards().filter { card in
            card.phase == phase && {
                if isLbp { return card.condition == "LBP_NONSPECIFIC" }
                if isNeck { return card.condition == "NECK_PAIN" }
                if isTension { return card.condition == "NECK_SHOULDER_TENSION" }
                if isShoulder { return card.condition == nil }
                return card.condition == nil
            }()
        }
    }

    func todaysCard(phase: Int, isLbp: Bool, isNeck: Bool = false, isTension: Bool = false, isShoulder: Bool = false) -> EducationCard? {
        let phaseCards = cardsForPhase(phase, isLbp: isLbp, isNeck: isNeck, isTension: isTension, isShoulder: isShoulder)
        guard !phaseCards.isEmpty else { return nil }

        let startOfYear = Calendar.current.date(from: Calendar.current.dateComponents([.year], from: .now)) ?? .now
        let dayOfYear = Calendar.current.dateComponents([.day], from: startOfYear, to: .now).day ?? 0
        return phaseCards[dayOfYear % phaseCards.count]
    }
}
