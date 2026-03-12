import SwiftUI

struct MotivationalQuoteCard: View {
    let quote: MotivationalQuote
    @AppStorage("appLanguage") private var appLanguage = "de"

    private var isEn: Bool { appLanguage == "en" }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "quote.opening")
                .font(.appTitle3)
                .foregroundStyle(.accent.opacity(0.6))
                .accessibilityHidden(true)

            Text(quote.text)
                .font(.appSubheadline)
                .italic()
                .foregroundStyle(.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .cardStyle()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isEn
            ? "Motivational quote: \(quote.text)"
            : "Motivationszitat: \(quote.text)")
    }
}
