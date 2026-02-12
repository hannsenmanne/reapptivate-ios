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
                .font(.title3.bold())
                .foregroundStyle(.textPrimary)

            Text(message)
                .font(.body)
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if let actionLabel, let action {
                Button(actionLabel, action: action)
                    .buttonStyle(.borderedProminent)
                    .tint(.accent)
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
