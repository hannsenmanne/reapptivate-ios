import SwiftUI

struct WorkTimerSummarySheet: View {
    @Bindable var viewModel: WorkTimerViewModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appLanguage") private var appLanguage = "de"

    private var isEn: Bool { appLanguage == "en" }

    private var summary: WorkTimerDaySummary? {
        viewModel.todaySummary
    }

    private var motivationalMessage: String {
        let adherence = summary?.adherencePercent ?? 0
        if adherence >= 80 {
            return isEn
                ? "Excellent! Your breaks are doing your body good."
                : "Hervorragend! Ihre Pausen tun Ihrem Körper gut."
        } else if adherence >= 50 {
            return isEn
                ? "Well done! Try to take breaks even more regularly tomorrow."
                : "Gut gemacht! Versuchen Sie morgen noch regelmäßiger Pausen einzulegen."
        } else {
            return isEn
                ? "Every break counts. You'll do more tomorrow!"
                : "Jede Pause zählt. Morgen schaffen Sie mehr!"
        }
    }

    private var motivationalIcon: String {
        let adherence = summary?.adherencePercent ?? 0
        if adherence >= 80 { return "star.fill" }
        if adherence >= 50 { return "hand.thumbsup.fill" }
        return "heart.fill"
    }

    private var motivationalColor: Color {
        let adherence = summary?.adherencePercent ?? 0
        if adherence >= 80 { return .painGreen }
        if adherence >= 50 { return .painAmber }
        return .farBlue
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // Icon
                Image(systemName: motivationalIcon)
                    .font(.system(size: 48))
                    .foregroundStyle(motivationalColor)
                    .accessibilityHidden(true)

                Text(isEn ? "Workday finished" : "Arbeitstag beendet")
                    .font(.appTitle2)
                    .foregroundStyle(.textPrimary)

                // Stats grid
                if let summary {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                    ], spacing: 16) {
                        SummaryStatCard(
                            label: isEn ? "Work time" : "Arbeitszeit",
                            value: formatWorkMinutes(summary.totalWorkMinutes ?? 0)
                        )

                        SummaryStatCard(
                            label: isEn ? "Breaks done" : "Pausen erledigt",
                            value: "\(summary.breaksCompleted) / \(summary.breaksOffered)"
                        )

                        SummaryStatCard(
                            label: isEn ? "Skipped" : "Übersprungen",
                            value: "\(summary.breaksSkipped)"
                        )

                        SummaryStatCard(
                            label: isEn ? "Adherence" : "Adhärenz",
                            value: "\(Int(summary.adherencePercent))%"
                        )
                    }
                    .padding(.horizontal, 4)
                }

                // Motivational message
                Text(motivationalMessage)
                    .font(.appSubheadline)
                    .foregroundStyle(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                // History link
                Button {
                    viewModel.showingHistory = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chart.bar.fill")
                        Text(isEn ? "Show weekly overview" : "Wochenverlauf anzeigen")
                    }
                    .font(.appSubheadlineMedium)
                    .foregroundStyle(.accent)
                }

                Spacer()

                Button(isEn ? "Close" : "Schlie\u{00DF}en") {
                    dismiss()
                }
                .buttonStyle(.primary)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
            .padding(.horizontal, 16)
            .background(Color.appBg)
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
        .sheet(isPresented: $viewModel.showingHistory) {
            WorkTimerHistoryView(viewModel: viewModel)
        }
    }

    private func formatWorkMinutes(_ minutes: Int) -> String {
        let isEn = appLanguage == "en"
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return isEn
                ? "\(hours) hr\(hours == 1 ? "" : "s") \(mins) min"
                : "\(hours) Std. \(mins) Min."
        }
        return isEn ? "\(mins) min" : "\(mins) Min."
    }
}

// MARK: - Summary Stat Card

private struct SummaryStatCard: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.appCaption)
                .foregroundStyle(.textSecondary)

            Text(value)
                .font(.appSubheadlineSemibold)
                .foregroundStyle(.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .cardStyle(padding: 0)
    }
}
