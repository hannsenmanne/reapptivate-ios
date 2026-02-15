import SwiftUI

struct NstProgressView: View {
    @Environment(APIClient.self) private var apiClient

    let severity: NeckShoulderSeverity
    let dashboardVM: DashboardViewModel?
    let phaseVM: PhaseViewModel?

    @State private var trackingVM: NstTrackingViewModel?

    var accentColor: Color {
        switch severity {
        case .mild: .painGreen
        case .moderate: .painAmber
        case .high: .painRed
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            // Streak highlight
            if let streak = dashboardVM?.streakData, streak.currentStreak > 0 {
                ProgressStatCard(
                    label: "Trainingsserie",
                    value: "\(streak.currentStreak) Tage",
                    icon: "flame.fill",
                    valueColor: .accent
                )
            }

            // General stats
            if let stats = dashboardVM?.progressStats, stats.totalSessions > 0 {
                ProgressStatsGrid(stats: stats)
            } else {
                EmptyStateView(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Noch keine Daten",
                    message: "Schliessen Sie Ihr erstes Training ab, um Ihren Fortschritt hier zu sehen."
                )
            }

            // NST Compliance
            NstComplianceView(
                compliance: trackingVM?.compliance,
                accentColor: accentColor
            )

            // Pain trend from sessions
            if let sessions = trackingVM?.sessions, !sessions.isEmpty {
                NstPainTrendCard(sessions: sessions, accentColor: accentColor)
            }

            // Session history
            if let sessions = trackingVM?.sessions, !sessions.isEmpty {
                NstSessionHistoryCard(sessions: Array(sessions.prefix(10)), accentColor: accentColor)
            }

            // Plan adjustments
            NstAdjustmentHistoryView(accentColor: accentColor)

            // Phase timeline
            if let phaseVM {
                if phaseVM.isLoading {
                    ProgressView("Fortschritt laden...")
                        .frame(maxWidth: .infinity)
                        .padding(20)
                } else {
                    PhaseTimelineView(records: phaseVM.phaseHistory)
                }
            }
        }
        .padding(.bottom, 32)
        .task {
            if trackingVM == nil {
                trackingVM = NstTrackingViewModel(apiClient: apiClient)
            }
            await trackingVM?.loadAll()
        }
    }
}

// MARK: - Pain Trend Card

private struct NstPainTrendCard: View {
    let sessions: [NeckShoulderSessionLog]
    let accentColor: Color

    private var painPoints: [(label: String, value: Double)] {
        sessions
            .filter { $0.painAfter != nil }
            .prefix(14)
            .reversed()
            .map { session in
                let dateStr = String(session.completedAt.prefix(10))
                return (label: dateStr, value: session.painAfter ?? 0)
            }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "chart.xyaxis.line")
                    .foregroundStyle(accentColor)
                Text("Schmerzentwicklung")
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)
                Spacer()
            }

            if painPoints.isEmpty {
                Text("Noch keine Schmerzdaten verfugbar")
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
                    .padding(.vertical, 8)
            } else {
                // Simple bar chart
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(Array(painPoints.enumerated()), id: \.offset) { _, point in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(painBarColor(point.value))
                                .frame(height: max(4, CGFloat(point.value) / 10.0 * 60))

                            Text(String(format: "%.0f", point.value))
                                .font(.system(size: 8))
                                .foregroundStyle(.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 80)
            }
        }
        .cardStyle()
    }

    private func painBarColor(_ value: Double) -> Color {
        if value <= 3 { return .painGreen }
        if value <= 5 { return .painAmber }
        return .painRed
    }
}

// MARK: - Session History Card

private struct NstSessionHistoryCard: View {
    let sessions: [NeckShoulderSessionLog]
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundStyle(accentColor)
                Text("Letzte Sitzungen")
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)
                Spacer()
                Text("\(sessions.count)")
                    .font(.appCaptionMedium)
                    .foregroundStyle(.textSecondary)
            }

            ForEach(sessions) { session in
                HStack(spacing: 10) {
                    Image(systemName: sessionIcon(session.sessionType))
                        .font(.appCaption)
                        .foregroundStyle(accentColor)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(sessionLabel(session.sessionType))
                            .font(.appSubheadlineMedium)
                            .foregroundStyle(.textPrimary)
                        Text("Woche \(session.weekNumber)")
                            .font(.appCaption)
                            .foregroundStyle(.textSecondary)
                    }

                    Spacer()

                    if let pain = session.painAfter {
                        Text("\(Int(pain))/10")
                            .font(.appCaptionBold)
                            .foregroundStyle(painColor(pain))
                    }
                }
                .padding(.vertical, 4)

                if session.id != sessions.last?.id {
                    Divider()
                }
            }
        }
        .cardStyle()
    }

    private func sessionIcon(_ type: String) -> String {
        switch type {
        case "strength_a", "strength_b": "figure.strengthtraining.traditional"
        case "mobility": "figure.flexibility"
        case "micro_pause": "timer"
        default: "circle"
        }
    }

    private func sessionLabel(_ type: String) -> String {
        switch type {
        case "strength_a": "Kraft A"
        case "strength_b": "Kraft B"
        case "mobility": "Mobilitat"
        case "micro_pause": "Mikro-Pause"
        default: type
        }
    }

    private func painColor(_ value: Double) -> Color {
        if value <= 3 { return .painGreen }
        if value <= 5 { return .painAmber }
        return .painRed
    }
}
