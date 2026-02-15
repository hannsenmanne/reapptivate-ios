import SwiftUI

struct TodaysPlanCard: View {
    let completedCount: Int
    let totalCount: Int
    let onTap: () -> Void

    private var remaining: Int { max(0, totalCount - completedCount) }
    private var progress: Double {
        totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Progress ring
                ZStack {
                    Circle()
                        .stroke(Color.textSecondary.opacity(0.15), lineWidth: 6)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.accent, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(duration: 0.5), value: progress)

                    Text("\(completedCount)/\(totalCount)")
                        .font(.appCaptionBold)
                        .foregroundStyle(.accent)
                }
                .frame(width: 52, height: 52)

                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text("Heutiger Plan")
                        .font(.appSubheadlineSemibold)
                        .foregroundStyle(.textPrimary)

                    if remaining > 0 {
                        Text("Noch \(remaining) Übung\(remaining == 1 ? "" : "en") übrig")
                            .font(.appCaption)
                            .foregroundStyle(.textSecondary)
                    } else {
                        Text("Alle Übungen abgeschlossen!")
                            .font(.appCaption)
                            .foregroundStyle(.painGreen)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
            }
            .cardStyle()
        }
        .buttonStyle(.plain)
    }
}
