import SwiftUI

struct StreakCard: View {
    let streak: StreakData
    let onUseFreezeToken: () -> Void

    @State private var hapticTrigger = false
    @ScaledMetric(relativeTo: .title2) private var flameSize: CGFloat = 32

    /// Whether the streak is at risk (last training was not today)
    private var isStreakAtRisk: Bool {
        guard streak.currentStreak > 0, let last = streak.lastTrainingDate else { return false }
        let today = DateFormatter.yyyyMMdd.string(from: Date())
        return last != today
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                // Flame + streak count
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: flameSize))
                        .foregroundStyle(.accent)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(streak.currentStreak)")
                                .font(.appTitle)
                                .foregroundStyle(.textPrimary)
                            Text(streak.currentStreak == 1 ? "Tag" : "Tage")
                                .font(.appSubheadline)
                                .foregroundStyle(.textSecondary)
                        }
                        Text("Trainingsserie")
                            .font(.appCaption)
                            .foregroundStyle(.textSecondary)
                    }
                }

                Spacer()

                // Freeze tokens
                if streak.freezeTokens > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "snowflake")
                            .foregroundStyle(.farBlue)
                        Text("\(streak.freezeTokens)")
                            .font(.appSubheadlineSemibold)
                            .foregroundStyle(.farBlue)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.farBlue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.badgeRadius, style: .continuous))
                    .accessibilityLabel("\(streak.freezeTokens) Frost-Token")
                }
            }

            // Longest streak footer
            if streak.longestStreak > streak.currentStreak {
                HStack {
                    Image(systemName: "trophy")
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                    Text("Beste Serie: \(streak.longestStreak) Tage")
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                    Spacer()
                }
            }

            // "Save streak" button when at risk
            if isStreakAtRisk && streak.freezeTokens > 0 {
                Button {
                    hapticTrigger.toggle()
                    onUseFreezeToken()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "snowflake")
                        Text("Serie retten")
                    }
                    .font(.appSubheadlineSemibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.farBlue)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.buttonRadius, style: .continuous))
                }
                .sensoryFeedback(.success, trigger: hapticTrigger)
            }
        }
        .cardStyle()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Trainingsserie: \(streak.currentStreak) Tage")
    }
}

private extension DateFormatter {
    static let yyyyMMdd: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
}
