import SwiftUI

private var isEnglishLocale: Bool {
    UserDefaults.standard.string(forKey: "appLanguage") == "en"
}

struct NeckQuestionView: View {
    let item: NeckScreeningItem
    let selectedValue: Int?
    let onSelect: (Int) -> Void

    @AppStorage("appLanguage") private var appLanguage = "de"

    var body: some View {
        VStack(spacing: 24) {
            // Question text
            Text(isEnglishLocale ? item.textEn ?? item.textDe : item.textDe)
                .font(.appTitle3)
                .foregroundStyle(.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.top, 32)

            // Options based on type
            switch item.type {
            case "yesno":
                yesNoOptions
            case "likert":
                likertOptions
            default:
                scaleOptions
            }
        }
    }

    // MARK: - Yes/No

    var yesNoOptions: some View {
        HStack(spacing: 12) {
            OptionButton(
                label: isEnglishLocale ? "Yes" : "Ja",
                isSelected: selectedValue == 1,
                action: { onSelect(1) }
            )
            OptionButton(
                label: isEnglishLocale ? "No" : "Nein",
                isSelected: selectedValue == 0,
                action: { onSelect(0) }
            )
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Likert / Scale

    var likertOptions: some View {
        VStack(spacing: 8) {
            if let options = item.options {
                ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                    Button {
                        onSelect(option.value)
                    } label: {
                        HStack(spacing: 12) {
                            Text("\(option.value)")
                                .font(.appSubheadlineSemibold.monospacedDigit())
                                .frame(width: 28)

                            Text(isEnglishLocale ? option.labelEn ?? option.labelDe : option.labelDe)
                                .font(.appSubheadline)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            if selectedValue == option.value {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.accent)
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(selectedValue == option.value ? Color.accent.opacity(0.08) : Color.cardBg)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.inputRadius, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: DesignTokens.inputRadius, style: .continuous)
                                .stroke(selectedValue == option.value ? Color.accent : Color.gray200, lineWidth: selectedValue == option.value ? 1.5 : 1)
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.textPrimary)
                }
            }
        }
        .padding(.horizontal, 24)
    }

    var scaleOptions: some View {
        likertOptions // Same layout for scale type
    }
}

// MARK: - Option Button

struct OptionButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.appTitle3)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(isSelected ? Color.accent.opacity(0.08) : Color.cardBg)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.inputRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: DesignTokens.inputRadius, style: .continuous)
                        .stroke(isSelected ? Color.accent : Color.gray200, lineWidth: isSelected ? 2 : 1)
                }
        }
        .buttonStyle(.plain)
        .foregroundStyle(.textPrimary)
    }
}
