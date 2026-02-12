import SwiftUI

struct InsightsTab: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 20) {
            Text("Ihre Fortschritts-Insights (30 Tage)")
                .font(.headline)
                .foregroundStyle(.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // M10 will implement the full analytics dashboard
            VStack(spacing: 12) {
                Text("Analytics Dashboard kommt in M10")
                    .font(.subheadline)
                    .foregroundStyle(.textSecondary)

                if let subtype = appState.currentUser?.aemSubtype {
                    Text("Subtype: \(subtype.displayName)")
                        .font(.caption)
                        .foregroundStyle(Color.subtypeColor(for: subtype))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(Color.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.bottom, 32)
    }
}
