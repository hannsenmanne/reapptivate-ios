import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionLabel: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.textSecondary)

            Text(title)
                .font(.appTitle3)
                .foregroundStyle(.textPrimary)

            Text(message)
                .font(.appBody)
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if let actionLabel, let action {
                Button(actionLabel, action: action)
                    .buttonStyle(.accentFilled)
                    .padding(.horizontal, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBg)
    }
}

#Preview {
    EmptyStateView(
        icon: "figure.run",
        title: "Noch keine Trainings",
        message: "Starten Sie Ihr erstes Training, um Ihren Fortschritt zu verfolgen.",
        actionLabel: "Training starten"
    ) {
        // action
    }
}
