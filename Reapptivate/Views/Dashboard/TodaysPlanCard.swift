import SwiftUI

struct TodaysPlanCard: View {
    let completedCount: Int
    let totalCount: Int
    let onTap: () -> Void

    @ScaledMetric(relativeTo: .body) private var ringSize: CGFloat = 52

    private var progress: Double {
        totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0
    }

    private var allDone: Bool {
        totalCount > 0 && completedCount >= totalCount
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Progress ring
                ZStack {
                    Circle()
                        .stroke(Color.textSecondary.opacity(0.15), lineWidth: 4)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            allDone ? Color.painGreen : Color.accent,
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(duration: 0.4), value: progress)

                    if allDone {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.painGreen)
                    } else {
                        Text("\(completedCount)")
                            .font(.appSubheadlineSemibold)
                            .foregroundStyle(.textPrimary)
                    }
                }
                .frame(width: ringSize, height: ringSize)
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Heutiges Programm")
                        .font(.appHeadline)
                        .foregroundStyle(.textPrimary)

                    if allDone {
                        Text("Alle Übungen abgeschlossen")
                            .font(.appCaptionMedium)
                            .foregroundStyle(.painGreen)
                    } else if totalCount > 0 {
                        Text("\(completedCount) von \(totalCount) Übungen erledigt")
                            .font(.appCaptionMedium)
                            .foregroundStyle(.accent)
                    } else {
                        Text("Programm starten")
                            .font(.appCaptionMedium)
                            .foregroundStyle(.accent)
                    }
                }

                Spacer()

                if !allDone {
                    Image(systemName: "chevron.right")
                        .font(.appSubheadline)
                        .foregroundStyle(.textSecondary)
                        .accessibilityHidden(true)
                }
            }
            .cardStyle()
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Heutiges Programm")
        .accessibilityValue(
            allDone
                ? "Alle \(totalCount) Übungen abgeschlossen"
                : "\(completedCount) von \(totalCount) Übungen erledigt"
        )
        .accessibilityHint("Antippen, um zum Trainingsprogramm zu gelangen")
    }
}
