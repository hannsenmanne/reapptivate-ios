import SwiftUI

struct AnalyticsDashboardView: View {
    @Environment(APIClient.self) private var apiClient
    let subtype: AemSubtype

    @State private var summary: AnalyticsSummary?
    @State private var fearAnalytics: FearReductionAnalytics?
    @State private var pacingAnalytics: PacingComplianceAnalytics?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if isLoading {
                    ProgressSkeletonView()
                        .padding(.vertical, 8)
                } else if let summary {
                    // Overview metrics
                    overviewSection(summary)

                    // Subtype-specific
                    switch subtype {
                    case .FAR:
                        if let fear = fearAnalytics {
                            fearSection(fear)
                        }
                    case .DER, .EER:
                        if let pacing = pacingAnalytics {
                            pacingSection(pacing)
                        }
                    case .AR:
                        arSection(summary)
                    }

                    // Trigger fires
                    if !summary.triggerFires.isEmpty {
                        triggerSection(summary.triggerFires)
                    }
                } else if let error = errorMessage {
                    InlineErrorView(
                        message: error,
                        errorType: .network,
                        onRetry: {
                            Task { await loadAnalytics() }
                        }
                    )
                    .padding(.vertical, 20)
                } else {
                    EmptyStateView(
                        icon: "chart.bar.xaxis",
                        title: "Noch keine Daten",
                        message: "Analytics werden nach einigen Trainingseinheiten verfügbar."
                    )
                }
            }
            .padding(16)
        }
        .background(Color.appBg)
        .task {
            await loadAnalytics()
        }
    }

    // MARK: - Overview Section

    private func overviewSection(_ summary: AnalyticsSummary) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(.farBlue)
                Text("30-Tage Übersicht")
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)
                Spacer()
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                MetricCard(
                    title: "Compliance",
                    value: "\(Int(summary.complianceRate))%",
                    color: summary.complianceRate >= 66 ? .painGreen : .painAmber
                )

                MetricCard(
                    title: "Anpassungen",
                    value: "\(summary.appliedAdjustments)/\(summary.totalAdjustments)",
                    color: .farBlue
                )
            }

            // Pain trend sparkline
            if !summary.painTrend.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Schmerztrend")
                        .font(.appCaptionMedium)
                        .foregroundStyle(.textSecondary)

                    PainSparklineView(dataPoints: summary.painTrend)
                        .frame(height: 60)
                }
                .cardStyle(padding: 12)
            }
        }
    }

    // MARK: - FAR Section

    private func fearSection(_ analytics: FearReductionAnalytics) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "target")
                    .foregroundStyle(.farBlue)
                Text("Expositions-Analyse")
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)
                Spacer()
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                MetricCard(
                    title: "Expositionen",
                    value: "\(analytics.totalExposures)",
                    color: .farBlue
                )

                MetricCard(
                    title: "Angst-Reduktion",
                    value: String(format: "%.1f", analytics.fearReduction),
                    color: analytics.fearReduction > 0 ? .painGreen : .textSecondary
                )
            }

            // Fear trend
            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("Frühe Exp.")
                        .font(.appCaption2)
                        .foregroundStyle(.textSecondary)
                    Text(String(format: "%.1f", analytics.earlyAvgFear))
                        .font(.appTitle3.monospacedDigit())
                        .foregroundStyle(.painAmber)
                }

                Image(systemName: "arrow.right")
                    .foregroundStyle(.painGreen)

                VStack(spacing: 4) {
                    Text("Späte Exp.")
                        .font(.appCaption2)
                        .foregroundStyle(.textSecondary)
                    Text(String(format: "%.1f", analytics.lateAvgFear))
                        .font(.appTitle3.monospacedDigit())
                        .foregroundStyle(.painGreen)
                }
            }
            .frame(maxWidth: .infinity)
            .cardStyle()

            if analytics.avoidanceDetected {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.painAmber)
                    Text("Vermeidungsverhalten erkannt. Versuchen Sie, auch hohe Angst-Items zu bearbeiten.")
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                }
                .infoBoxStyle(color: .painAmber)
            }
        }
    }

    // MARK: - Pacing Section

    private func pacingSection(_ analytics: PacingComplianceAnalytics) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "gauge.with.dots.needle.bottom.50percent")
                    .foregroundStyle(Color.subtypeColor(for: subtype))
                Text("Pacing-Analyse")
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)
                Spacer()
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                MetricCard(
                    title: "Überschreitungsrate",
                    value: "\(Int(analytics.breachRate))%",
                    color: analytics.breachRate <= 20 ? .painGreen : .painAmber
                )

                MetricCard(
                    title: "Pausen-Adhärenz",
                    value: "\(Int(analytics.pauseAdherence))%",
                    color: analytics.pauseAdherence >= 80 ? .painGreen : .painAmber
                )
            }

            // Weekly volume
            if !analytics.weeklySessionVolume.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Wochentliches Volumen")
                        .font(.appCaptionMedium)
                        .foregroundStyle(.textSecondary)

                    WeeklyBarChart(data: analytics.weeklySessionVolume)
                        .frame(height: 80)
                }
                .cardStyle(padding: 12)
            }
        }
    }

    // MARK: - AR Section

    private func arSection(_ summary: AnalyticsSummary) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(.arGray)
                Text("Ausgeglichene Übersicht")
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)
                Spacer()
            }

            Text("Als Adaptive Responder zeigen Sie ein ausgeglichenes Belastungsmuster. Halten Sie Ihre aktuelle Routine bei.")
                .font(.appSubheadline)
                .foregroundStyle(.textSecondary)
        }
        .cardStyle()
    }

    // MARK: - Trigger Section

    private func triggerSection(_ fires: [TriggerFireCount]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ausgelöste Regeln")
                .font(.appSubheadlineMedium)
                .foregroundStyle(.textPrimary)

            ForEach(fires) { fire in
                HStack {
                    Text(ruleDisplayName(fire.ruleId))
                        .font(.appCaption)
                        .foregroundStyle(.textPrimary)
                    Spacer()
                    Text("\(fire.count)x")
                        .font(.appCaptionBold.monospacedDigit())
                        .foregroundStyle(.painAmber)
                }
            }
        }
        .cardStyle(padding: 12)
    }

    // MARK: - Load Data

    private func loadAnalytics() async {
        isLoading = true
        errorMessage = nil
        do {
            summary = try await apiClient.request(APIEndpoints.analyticsSummary())

            switch subtype {
            case .FAR:
                fearAnalytics = try? await apiClient.request(APIEndpoints.fearReductionAnalytics())
            case .DER, .EER:
                pacingAnalytics = try? await apiClient.request(APIEndpoints.pacingComplianceAnalytics())
            case .AR:
                break
            }
        } catch {
            summary = nil
            errorMessage = "Analytics konnten nicht geladen werden."
        }
        isLoading = false
    }

    private func ruleDisplayName(_ ruleId: String) -> String {
        switch ruleId {
        case "FLARE_RULE": return "Schmerz-Schub"
        case "LOW_ADHERENCE_RULE": return "Niedrige Adhärenz"
        case "OVERDOING_RULE_DER": return "Überbelastung"
        case "FEAR_STUCK_RULE": return "Vermeidung"
        default: return ruleId
        }
    }
}

// MARK: - Metric Card

struct MetricCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.appTitle2.monospacedDigit())
                .foregroundStyle(color)
            Text(title)
                .font(.appCaption)
                .foregroundStyle(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .cardStyle(padding: 12)
    }
}

// MARK: - Pain Sparkline

struct PainSparklineView: View {
    let dataPoints: [PainDataPoint]

    var body: some View {
        GeometryReader { geo in
            let maxPain = max(10.0, dataPoints.map(\.avgPain).max() ?? 10)
            let width = geo.size.width
            let height = geo.size.height

            Path { path in
                guard dataPoints.count > 1 else { return }
                let stepX = width / CGFloat(dataPoints.count - 1)

                for (index, point) in dataPoints.enumerated() {
                    let x = CGFloat(index) * stepX
                    let y = height - (CGFloat(point.avgPain) / CGFloat(maxPain) * height)

                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(Color.farBlue, lineWidth: 2)
        }
    }
}

// MARK: - Weekly Bar Chart

struct WeeklyBarChart: View {
    let data: [WeeklyVolume]

    var body: some View {
        GeometryReader { geo in
            let maxSessions = max(1, data.map(\.sessions).max() ?? 1)
            let barWidth = max(12, (geo.size.width - CGFloat(data.count - 1) * 4) / CGFloat(data.count))

            HStack(alignment: .bottom, spacing: 4) {
                ForEach(data) { week in
                    VStack(spacing: 2) {
                        Text("\(week.sessions)")
                            .font(.appCaption2.monospacedDigit())
                            .foregroundStyle(.textSecondary)

                        Rectangle()
                            .fill(Color.farBlue)
                            .frame(
                                width: barWidth,
                                height: max(4, geo.size.height * 0.8 * CGFloat(week.sessions) / CGFloat(maxSessions))
                            )
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}
