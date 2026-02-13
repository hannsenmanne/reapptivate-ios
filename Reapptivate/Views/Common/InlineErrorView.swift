import SwiftUI

struct InlineErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.painAmber)

            Text(message)
                .font(.appCaption)
                .foregroundStyle(.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onRetry) {
                Text("Erneut")
                    .font(.appCaptionMedium)
                    .foregroundStyle(.accent)
            }
        }
        .padding(12)
        .background(Color.painAmber.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.smallRadius, style: .continuous))
    }
}
