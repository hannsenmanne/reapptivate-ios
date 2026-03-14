import SwiftUI

struct TodaysPlanCard: View {
    let completedCount: Int
    let totalCount: Int
    let onTap: () -> Void
    @AppStorage("appLanguage") private var appLanguage = "de"

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
                        .stroke(Color.textSecondary.opacity(0.1), lineWidth: 5)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            allDone ? Color.painGreen.opacity(0.3) : Color.accent.opacity(0.3),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .blur(radius: 6)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            allDone ? Color.painGreen : Color.accent,
                            style: StrokeStyle(lineWidth: 5, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(duration: 0.6), value: progress)

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
                    Text(appLanguage == "en"
                        ? "Today's Program"
                        : "Heutiges Programm")
                        .font(.appHeadline)
                        .foregroundStyle(.textPrimary)

                    if allDone {
                        Text(appLanguage == "en"
                            ? "All exercises completed"
                            : "Alle Übungen abgeschlossen")
                            .font(.appCaptionMedium)
                            .foregroundStyle(.painGreen)
                    } else if totalCount > 0 {
                        Text(appLanguage == "en"
                            ? "\(completedCount) of \(totalCount) exercises completed"
                            : "\(completedCount) von \(totalCount) Übungen erledigt")
                            .font(.appCaptionMedium)
                            .foregroundStyle(.accent)
                    } else {
                        Text(appLanguage == "en"
                            ? "Start program"
                            : "Programm starten")
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
        .accessibilityLabel(appLanguage == "en"
            ? "Today's Program"
            : "Heutiges Programm")
        .accessibilityValue(
            allDone
                ? (appLanguage == "en"
                    ? "All \(totalCount) exercises completed"
                    : "Alle \(totalCount) Übungen abgeschlossen")
                : (appLanguage == "en"
                    ? "\(completedCount) of \(totalCount) exercises completed"
                    : "\(completedCount) von \(totalCount) Übungen erledigt")
        )
        .accessibilityHint(appLanguage == "en"
            ? "Tap to go to the training program"
            : "Antippen, um zum Trainingsprogramm zu gelangen")
    }
}
