import SwiftUI

struct WissenCardView: View {
    let phase: Int
    let isLbp: Bool
    let isNeck: Bool
    let isTension: Bool
    @AppStorage("appLanguage") private var appLanguage = "de"

    init(phase: Int, isLbp: Bool, isNeck: Bool = false, isTension: Bool = false) {
        self.phase = phase
        self.isLbp = isLbp
        self.isNeck = isNeck
        self.isTension = isTension
    }

    private var phaseCards: [EducationCard] {
        EducationCardLoader.shared.cardsForPhase(phase, isLbp: isLbp, isNeck: isNeck, isTension: isTension)
    }

    private var todaysCard: EducationCard? {
        EducationCardLoader.shared.todaysCard(phase: phase, isLbp: isLbp, isNeck: isNeck, isTension: isTension)
    }

    private var activeIndex: Int {
        guard !phaseCards.isEmpty else { return 0 }
        let startOfYear = Calendar.current.date(from: Calendar.current.dateComponents([.year], from: .now)) ?? .now
        let dayOfYear = Calendar.current.dateComponents([.day], from: startOfYear, to: .now).day ?? 0
        return dayOfYear % phaseCards.count
    }

    var body: some View {
        if let card = todaysCard {
            VStack(spacing: 0) {
                // Header
                HStack {
                    HStack(spacing: 10) {
                        Image(systemName: "book.fill")
                            .font(.appCaption)
                            .foregroundStyle(.accent)
                            .frame(width: 28, height: 28)
                            .background(Color.accent.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.badgeRadius, style: .continuous))
                            .accessibilityHidden(true)

                        Text(appLanguage == "en" ? "KNOWLEDGE" : "WISSEN")
                            .font(.appCaption2)
                            .tracking(1.2)
                            .foregroundStyle(.textSecondary)
                    }

                    Spacer()

                    // Pagination dots
                    HStack(spacing: 4) {
                        ForEach(0..<phaseCards.count, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(i == activeIndex ? Color.accent : Color.gray200)
                                .frame(width: i == activeIndex ? 14 : 5, height: 3)
                        }
                    }
                    .accessibilityLabel(appLanguage == "en" ? "Card \(activeIndex + 1) of \(phaseCards.count)" : "Karte \(activeIndex + 1) von \(phaseCards.count)")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                Divider()
                    .foregroundStyle(Color.gray200)

                // Content
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: iconName(for: card.icon))
                        .font(.appBody)
                        .foregroundStyle(.accent)
                        .frame(width: 36, height: 36)
                        .background(Color.accent.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.badgeRadius, style: .continuous))

                    VStack(alignment: .leading, spacing: 6) {
                        Text(card.title)
                            .font(.appSubheadlineSemibold)
                            .foregroundStyle(.textPrimary)

                        Text(card.body)
                            .font(.appCaption)
                            .foregroundStyle(.textSecondary)
                            .lineSpacing(3)

                        if let source = card.source {
                            Text(appLanguage == "en" ? "Source: \(source)" : "Quelle: \(source)")
                                .font(.appCaption2)
                                .foregroundStyle(.textSecondary.opacity(0.7))
                                .padding(.top, 2)
                        }
                    }
                }
                .padding(16)
            }
            .cardStyle(padding: 0)
        }
    }

    private func iconName(for icon: String) -> String {
        switch icon {
        case "biology": "flask"
        case "pain": "lightbulb"
        case "loading": "bolt"
        case "recovery": "arrow.2.circlepath"
        case "progress": "chart.line.uptrend.xyaxis"
        default: "book"
        }
    }
}
