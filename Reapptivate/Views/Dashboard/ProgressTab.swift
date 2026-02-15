import SwiftUI
import Charts

struct ProgressTab: View {
    let viewModel: DashboardViewModel?
    let phaseVM: PhaseViewModel?

    var body: some View {
        VStack(spacing: 20) {
            // Stats Section
            if let stats = viewModel?.progressStats, stats.totalSessions > 0 {
                ProgressStatsGrid(stats: stats)
                    .cardEntryAnimation(index: 1)
            } else {
                EmptyStateView(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Noch keine Daten",
                    message: "Schliessen Sie Ihr erstes Training ab, um Ihren Fortschritt hier zu sehen."
                )
            }

            // Pain Trend Chart
            if let painLevels = viewModel?.progressStats?.recentPainLevels, !painLevels.isEmpty {
                PainTrendChart(painLevels: painLevels)
                    .cardEntryAnimation(index: 2)
            }

            // Phase Timeline
            if let phaseVM {
                if phaseVM.isLoading {
                    SkeletonView(variant: .card(height: 140))
                } else {
                    PhaseTimelineView(records: phaseVM.phaseHistory)
                        .cardEntryAnimation(index: 3)
                }
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
                .font(.appTitle3)
                .foregroundStyle(.textSecondary)

            Text(value)
                .font(.appTitle2)
                .foregroundStyle(valueColor)

            Text(label)
                .font(.appCaption)
                .foregroundStyle(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .cardStyle(padding: 0)
    }
}
