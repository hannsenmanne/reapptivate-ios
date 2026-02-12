import SwiftUI

struct NeckQuestionView: View {
    let item: NeckScreeningItem
    let selectedValue: Int?
    let onSelect: (Int) -> Void

    var body: some View {
        VStack(spacing: 24) {
            // Question text
            Text(item.textDe)
                .font(.title3.weight(.medium))
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
                label: "Ja",
                isSelected: selectedValue == 1,
                action: { onSelect(1) }
            )
            OptionButton(
                label: "Nein",
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
                                .font(.subheadline.weight(.bold).monospacedDigit())
                                .frame(width: 28)

                            Text(option.labelDe)
                                .font(.subheadline)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            if selectedValue == option.value {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.accent)
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(selectedValue == option.value ? Color.accent.opacity(0.08) : Color.cardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(selectedValue == option.value ? Color.accent : .clear, lineWidth: 1.5)
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
                .font(.title3.weight(.medium))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(isSelected ? Color.accent.opacity(0.08) : Color.cardBg)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.accent : .clear, lineWidth: 2)
                }
        }
        .buttonStyle(.plain)
        .foregroundStyle(.textPrimary)
    }
}
