import SwiftUI

struct ProgressTab: View {
    let viewModel: DashboardViewModel?

    var body: some View {
        VStack(spacing: 20) {
            // Stats Section
            if let stats = viewModel?.progressStats, stats.totalSessions > 0 {
                ProgressStatsGrid(stats: stats)
            } else {
                EmptyStateView(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Noch keine Daten",
                    message: "Schliessen Sie Ihr erstes Training ab, um Ihren Fortschritt hier zu sehen."
                )
            }

            // Pain Sparkline - M6 will add full chart
            if viewModel?.progressStats?.totalSessions ?? 0 > 0 {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Schmerztrend (30 Tage)")
                        .font(.headline)
                        .foregroundStyle(.textPrimary)

                    Text("Schmerzverlauf kommt in M6")
                        .font(.subheadline)
                        .foregroundStyle(.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                        .background(Color.cardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            // Phase Timeline - M6 will add
            VStack(alignment: .leading, spacing: 8) {
                Text("Phasen-Verlauf")
                    .font(.headline)
                    .foregroundStyle(.textPrimary)

                Text("Phase Timeline kommt in M6")
                    .font(.subheadline)
                    .foregroundStyle(.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .background(Color.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.bottom, 32)
    }
}

// MARK: - Progress Stats Grid

struct ProgressStatsGrid: View {
    let stats: ProgressStats

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
        ], spacing: 12) {
            ProgressStatCard(
                label: "Trainings gesamt",
                value: "\(stats.totalSessions)",
                icon: "figure.strengthtraining.traditional"
            )

            ProgressStatCard(
                label: "Letzte 7 Tage",
                value: "\(stats.lastSevenDays)",
                icon: "calendar"
            )

            ProgressStatCard(
                label: "Compliance",
                value: "\(Int(stats.compliancePercent))%",
                icon: "checkmark.circle",
                valueColor: stats.compliancePercent >= 66 ? .painGreen : .painAmber
            )

            ProgressStatCard(
                label: "Schmerz",
                value: String(format: "%.1f/10", stats.averagePain),
                icon: "waveform.path.ecg",
                valueColor: painColor(for: stats.averagePain)
            )
        }
    }

    func painColor(for avg: Double) -> Color {
        if avg <= 3 { return .textPrimary }
        if avg <= 5 { return .painAmber }
        return .painRed
    }
}

struct ProgressStatCard: View {
    let label: String
    let value: String
    let icon: String
    var valueColor: Color = .textPrimary

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.textSecondary)

            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(valueColor)

            Text(label)
                .font(.caption)
                .foregroundStyle(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
