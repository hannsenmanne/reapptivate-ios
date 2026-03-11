import SwiftUI

struct AclTodayProgramCard: View {
    let todayLabel: String
    let streamIds: [String]
    let completedCount: Int
    let totalCount: Int
    let isRestDay: Bool
    let onTap: () -> Void

    @ScaledMetric(relativeTo: .body) private var ringSize: CGFloat = 52

    private var progress: Double {
        totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0
    }

    private var allDone: Bool {
        totalCount > 0 && completedCount >= totalCount
    }

    var body: some View {
        if isRestDay {
            restDayCard
        } else if !streamIds.isEmpty {
            trainingCard
        }
    }

    // MARK: - Training Day

    private var trainingCard: some View {
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

                    Text(todayLabel)
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)

                    if allDone {
                        Text("Alle Übungen abgeschlossen")
                            .font(.appCaptionMedium)
                            .foregroundStyle(.painGreen)
                    } else if totalCount > 0 {
                        Text(UserDefaults.standard.string(forKey: "appLanguage") == "en"
                            ? "\(completedCount) of \(totalCount) exercises completed"
                            : "\(completedCount) von \(totalCount) Übungen erledigt")
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
                }
            }
        }
        .buttonStyle(.plain)
        .cardStyle()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Heutiges Programm: \(todayLabel)")
        .accessibilityValue(
            allDone
                ? (UserDefaults.standard.string(forKey: "appLanguage") == "en"
                    ? "All \(totalCount) exercises completed"
                    : "Alle \(totalCount) Übungen abgeschlossen")
                : (UserDefaults.standard.string(forKey: "appLanguage") == "en"
                    ? "\(completedCount) of \(totalCount) exercises completed"
                    : "\(completedCount) von \(totalCount) Übungen erledigt")
        )
        .accessibilityHint("Antippen, um das Programm zu öffnen")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Rest Day

    private var restDayCard: some View {
        HStack(spacing: 16) {
            Image(systemName: "bed.double.fill")
                .font(.system(size: 20))
                .foregroundStyle(.textSecondary)
                .frame(width: ringSize, height: ringSize)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text("Heutiges Programm")
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)

                Text("Ruhetag — Erholung genießen")
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
            }

            Spacer()
        }
        .cardStyle()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Heutiges Programm: Ruhetag")
    }
}
