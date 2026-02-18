import SwiftUI

struct MotivationalQuoteCard: View {
    let quote: MotivationalQuote

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
        .accessibilityLabel("Motivationszitat: \(quote.text)")
    }
}
