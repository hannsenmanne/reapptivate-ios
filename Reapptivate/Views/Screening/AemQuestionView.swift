import SwiftUI

private var isEnglishLocale: Bool {
    UserDefaults.standard.string(forKey: "appLanguage") == "en"
}

struct AemQuestionView: View {
    let item: AemScreeningItem
    let selectedValue: Int?
    let onSelect: (Int) -> Void

    private let likertLabelsDe = [
        "Trifft gar nicht zu",
        "Trifft kaum zu",
        "Trifft etwas zu",
        "Trifft teilweise zu",
        "Trifft überwiegend zu",
        "Trifft stark zu",
        "Trifft völlig zu",
    ]

    private let likertLabelsEn = [
        "Does not apply at all",
        "Hardly applies",
        "Applies somewhat",
        "Partially applies",
        "Mostly applies",
        "Strongly applies",
        "Completely applies",
    ]

    private var likertLabels: [String] {
        isEnglishLocale ? likertLabelsEn : likertLabelsDe
    }

    var body: some View {
        VStack(spacing: 24) {
            // Question text
            Text(isEnglishLocale ? item.textEn ?? item.textDe : item.textDe)
                .font(.appTitle3)
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
                                .font(.appSubheadlineSemibold.monospacedDigit())
                                .frame(width: 28)

                            Text(likertLabels[value])
                                .font(.appSubheadline)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            if selectedValue == value {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.accent)
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(selectedValue == value ? Color.accent.opacity(0.08) : Color.cardBg)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.inputRadius, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: DesignTokens.inputRadius, style: .continuous)
                                .stroke(selectedValue == value ? Color.accent : Color.gray200, lineWidth: selectedValue == value ? 1.5 : 1)
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.textPrimary)
                    .accessibilityAddTraits(selectedValue == value ? .isSelected : [])
                }
            }
            .padding(.horizontal, 24)
        }
    }
}
