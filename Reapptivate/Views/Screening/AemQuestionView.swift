import SwiftUI

struct AemQuestionView: View {
    let item: AemScreeningItem
    let selectedValue: Int?
    let onSelect: (Int) -> Void

    private let likertLabels = [
        "Trifft gar nicht zu",
        "Trifft kaum zu",
        "Trifft etwas zu",
        "Trifft teilweise zu",
        "Trifft uberwiegend zu",
        "Trifft stark zu",
        "Trifft vollig zu",
    ]

    var body: some View {
        VStack(spacing: 24) {
            // Question text
            Text(item.textDe)
                .font(.title3.weight(.medium))
                .foregroundStyle(.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.top, 32)

            // Likert scale options (0-6)
            VStack(spacing: 8) {
                ForEach(0..<7, id: \.self) { value in
                    Button {
                        onSelect(value)
                    } label: {
                        HStack(spacing: 12) {
                            Text("\(value)")
                                .font(.subheadline.weight(.bold).monospacedDigit())
                                .frame(width: 28)

                            Text(likertLabels[value])
                                .font(.subheadline)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            if selectedValue == value {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.accent)
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(selectedValue == value ? Color.accent.opacity(0.08) : Color.cardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(selectedValue == value ? Color.accent : .clear, lineWidth: 1.5)
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.textPrimary)
                }
            }
            .padding(.horizontal, 24)
        }
    }
}
