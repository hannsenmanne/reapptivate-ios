import SwiftUI

struct SymptomResponsePicker: View {
    @Binding var selection: SymptomResponse?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Symptomreaktion")
                .font(.appHeadline)
                .foregroundStyle(.textPrimary)

            Text("Wie haben sich Ihre Symptome wahrend der Ubung verandert?")
                .font(.appCaption)
                .foregroundStyle(.textSecondary)

            VStack(spacing: 8) {
                SymptomOption(
                    response: .centralized,
                    isSelected: selection == .centralized,
                    icon: "arrow.up.to.line",
                    description: "Symptome haben sich zentralisiert (naher zur Wirbelsaule)"
                ) {
                    selection = .centralized
                }

                SymptomOption(
                    response: .unchanged,
                    isSelected: selection == .unchanged,
                    icon: "equal",
                    description: "Symptome sind unverandert geblieben"
                ) {
                    selection = .unchanged
                }

                SymptomOption(
                    response: .peripheralized,
                    isSelected: selection == .peripheralized,
                    icon: "arrow.down.to.line",
                    description: "Symptome haben sich peripheralisiert (weiter in den Arm)"
                ) {
                    selection = .peripheralized
                }
            }
        }
    }
}

struct SymptomOption: View {
    let response: SymptomResponse
    let isSelected: Bool
    let icon: String
    let description: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.appBody)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(response.displayName)
                        .font(.appSubheadlineMedium)
                    Text(description)
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .accent : .textSecondary)
            }
            .padding(12)
            .background(isSelected ? Color.accent.opacity(0.05) : Color.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.inputRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: DesignTokens.inputRadius, style: .continuous)
                    .stroke(isSelected ? Color.accent : Color.gray200, lineWidth: isSelected ? 1.5 : 1)
            }
        }
        .buttonStyle(.plain)
    }
}
