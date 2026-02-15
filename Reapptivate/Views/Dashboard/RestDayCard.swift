import SwiftUI

struct RestDayCard: View {
    @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 44

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: DesignTokens.badgeRadius, style: .continuous)
                .fill(Color.painGreen.opacity(0.12))
                .frame(width: iconSize, height: iconSize)
                .overlay {
                    Image(systemName: "bed.double.fill")
                        .font(.appBody)
                        .foregroundStyle(.painGreen)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text("Ruhetag")
                    .font(.appSubheadlineSemibold)
                    .foregroundStyle(.textPrimary)

                Text("Heute ist Ihr Ruhetag. Erholung ist ein wichtiger Teil Ihrer Rehabilitation.")
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .cardStyle()
    }
}
