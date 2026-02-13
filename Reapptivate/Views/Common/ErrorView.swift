import SwiftUI

struct ErrorView: View {
    let message: String
    var retryAction: (() async -> Void)?

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.painAmber)

            Text("Fehler")
                .font(.appTitle2)
                .foregroundStyle(.textPrimary)

            Text(message)
                .font(.appBody)
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if let retryAction {
                Button {
                    Task { await retryAction() }
                } label: {
                    Label("Erneut versuchen", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                }
                .buttonStyle(.accentFilled)
                .padding(.horizontal, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBg)
    }
}

#Preview {
    ErrorView(message: "Verbindung zum Server fehlgeschlagen.") {
        // retry
    }
}
