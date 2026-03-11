import SwiftUI

struct LasQuestionView: View {
    let item: LasScreeningItem
    let selectedValue: Int?
    let onSelect: (Int) -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text(item.textDe)
                .font(.appTitle3)
                .foregroundStyle(.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.top, 32)

            likertOptions
        }
    }

    // MARK: - Likert Options

    var likertOptions: some View {
        VStack(spacing: 8) {
            if let options = item.options {
                ForEach(Array(options.enumerated()), id: \.offset) { _, option in
                    Button {
                        onSelect(option.value)
                    } label: {
                        HStack(spacing: 12) {
                            Text("\(option.value)")
                                .font(.appSubheadlineSemibold.monospacedDigit())
                                .frame(width: 28)

                            Text(option.labelDe)
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
                    .accessibilityAddTraits(selectedValue == option.value ? .isSelected : [])
                }
            }
        }
        .padding(.horizontal, 24)
    }
}
