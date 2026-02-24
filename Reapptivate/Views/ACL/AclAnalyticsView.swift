import SwiftUI
import Charts

struct AclAnalyticsView: View {
    @Environment(APIClient.self) private var apiClient

    @State private var analytics: AclAnalytics?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            if isLoading {
                ProgressView("Analyse laden...")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
            } else if let error = errorMessage {
                InlineErrorView(
                    message: error,
                    errorType: .network,
                    onRetry: {
                        Task { await loadAnalytics() }
                    }
                )
            } else if let analytics {
                // Summary header
                summaryHeader(analytics)

                // Pain trend
                if let painTrend = analytics.painTrend, !painTrend.isEmpty {
                    painChart(painTrend)
                }

                // ROM trend
                if let romTrend = analytics.romTrend, !romTrend.isEmpty {
                    romChart(romTrend)
                }

                // Swelling trend
                if let swellingTrend = analytics.swellingTrend,
                   !swellingTrend.compactMap(\.swellingGrade).isEmpty {
                    swellingChart(swellingTrend)
                }

                // IKDC trend
                if let ikdcTrend = analytics.ikdcTrend, !ikdcTrend.isEmpty {
                    ikdcChart(ikdcTrend)
                }

                // Tampa trend
                if let tampaTrend = analytics.tampaTrend, !tampaTrend.isEmpty {
                    tampaChart(tampaTrend)
                }

                // Thigh circumference trend
                if let thighTrend = analytics.thighCircTrend, !thighTrend.isEmpty {
                    thighCircChart(thighTrend)
                }

                // Lab LSI bar chart
                if let labs = analytics.labAssessments, !labs.isEmpty {
                    labLsiChart(labs)
                }
            } else {
                EmptyStateView(
                    icon: "chart.bar.xaxis",
                    title: "Noch keine Daten",
                    message: "Analyse wird nach einigen KPI-Einträgen verfügbar."
                )
            }
        }
        .padding(.bottom, 32)
        .task {
            await loadAnalytics()
        }
    }

    private func loadAnalytics() async {
        isLoading = true
        errorMessage = nil
        do {
            analytics = try await apiClient.request(APIEndpoints.aclAnalytics())
        } catch {
            errorMessage = "Analyse konnte nicht geladen werden."
        }
        isLoading = false
    }

    // MARK: - Summary Header

    private func summaryHeader(_ data: AclAnalytics) -> some View {
        HStack(spacing: 12) {
            MetricCard(
                title: "Meilenstein",
                value: "\(data.currentMilestone)",
                color: .accent
            )
            MetricCard(
                title: "Wochen post-OP",
                value: "\(data.weeksPostSurgery)",
                color: .farBlue
            )
        }
    }

    // MARK: - Pain Chart

    private func painChart(_ data: [AclPainTrendPoint]) -> some View {
        chartCard(title: "Schmerzentwicklung", icon: "waveform.path.ecg") {
            Chart(data) { point in
                if let date = parseDateOnly(point.date) {
                    LineMark(
                        x: .value("Datum", date),
                        y: .value("NRS", point.painNrs)
                    )
                    .foregroundStyle(Color.accent)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Datum", date),
                        y: .value("NRS", point.painNrs)
                    )
                    .foregroundStyle(Color.painColor(for: point.painNrs))
                    .symbolSize(20)
                }
            }
            .chartYScale(domain: 0...10)
            .chartYAxisLabel("NRS")
            .frame(height: 180)
        }
    }

    // MARK: - ROM Chart

    private func romChart(_ data: [AclRomTrendPoint]) -> some View {
        chartCard(title: "Beweglichkeit", icon: "arrow.up.and.down") {
            Chart {
                ForEach(data) { point in
                    if let date = parseDateOnly(point.date) {
                        if let flexion = point.flexion {
                            LineMark(
                                x: .value("Datum", date),
                                y: .value("Grad", flexion),
                                series: .value("Typ", "Flexion")
                            )
                            .foregroundStyle(Color.accent)
                            .interpolationMethod(.catmullRom)
                        }
                        if let extDeficit = point.extensionDeficit {
                            LineMark(
                                x: .value("Datum", date),
                                y: .value("Grad", extDeficit),
                                series: .value("Typ", "Ext.-Defizit")
                            )
                            .foregroundStyle(Color.painAmber)
                            .interpolationMethod(.catmullRom)
                        }
                    }
                }
            }
            .chartForegroundStyleScale([
                "Flexion": Color.accent,
                "Ext.-Defizit": Color.painAmber
            ])
            .chartYAxisLabel("Grad")
            .frame(height: 180)
        }
    }

    // MARK: - Swelling Chart

    private func swellingChart(_ data: [AclSwellingTrendPoint]) -> some View {
        let filtered = data.filter { $0.swellingGrade != nil }
        return chartCard(title: "Schwellung", icon: "drop.fill") {
            Chart(filtered) { point in
                if let date = parseDateOnly(point.date), let grade = point.swellingGrade {
                    LineMark(
                        x: .value("Datum", date),
                        y: .value("Grad", grade)
                    )
                    .foregroundStyle(Color.farBlue)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Datum", date),
                        y: .value("Grad", grade)
                    )
                    .foregroundStyle(swellingColor(for: grade))
                    .symbolSize(20)
                }
            }
            .chartYScale(domain: 0...4)
            .chartYAxisLabel("Grad")
            .frame(height: 180)
        }
    }

    // MARK: - IKDC Chart

    private func ikdcChart(_ data: [AclScoreTrendPoint]) -> some View {
        chartCard(title: "IKDC-Score", icon: "chart.line.uptrend.xyaxis") {
            Chart {
                ForEach(data) { point in
                    if let date = parseDateOnly(point.weekDate), let score = point.score {
                        LineMark(
                            x: .value("Datum", date),
                            y: .value("Score", score)
                        )
                        .foregroundStyle(Color.accent)
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Datum", date),
                            y: .value("Score", score)
                        )
                        .foregroundStyle(Color.accent)
                        .symbolSize(20)
                    }
                }

                // Target line at 85%
                RuleMark(y: .value("Ziel", 85))
                    .foregroundStyle(Color.painGreen.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Ziel: 85")
                            .font(.appCaption2)
                            .foregroundStyle(.painGreen)
                    }
            }
            .chartYScale(domain: 0...100)
            .chartYAxisLabel("Score")
            .frame(height: 180)
        }
    }

    // MARK: - Tampa Chart

    private func tampaChart(_ data: [AclScoreTrendPoint]) -> some View {
        chartCard(title: "Tampa-Skala", icon: "brain.head.profile") {
            Chart {
                ForEach(data) { point in
                    if let date = parseDateOnly(point.weekDate), let score = point.score {
                        LineMark(
                            x: .value("Datum", date),
                            y: .value("Score", score)
                        )
                        .foregroundStyle(Color.farBlue)
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Datum", date),
                            y: .value("Score", score)
                        )
                        .foregroundStyle(score >= 37 ? Color.painRed : Color.farBlue)
                        .symbolSize(20)
                    }
                }

                // Warning line at 37
                RuleMark(y: .value("Warnung", 37))
                    .foregroundStyle(Color.painRed.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Warnung: 37")
                            .font(.appCaption2)
                            .foregroundStyle(.painRed)
                    }
            }
            .chartYScale(domain: 17...68)
            .chartYAxisLabel("Score")
            .frame(height: 180)
        }
    }

    // MARK: - Thigh Circumference Chart

    private func thighCircChart(_ data: [AclThighCircTrendPoint]) -> some View {
        chartCard(title: "Oberschenkelumfang", icon: "ruler") {
            Chart {
                ForEach(data) { point in
                    if let date = parseDateOnly(point.weekDate) {
                        if let circ5 = point.circ5cm {
                            LineMark(
                                x: .value("Datum", date),
                                y: .value("cm", circ5),
                                series: .value("Messstelle", "5 cm")
                            )
                            .foregroundStyle(Color.accent)
                            .interpolationMethod(.catmullRom)
                        }
                        if let circ10 = point.circ10cm {
                            LineMark(
                                x: .value("Datum", date),
                                y: .value("cm", circ10),
                                series: .value("Messstelle", "10 cm")
                            )
                            .foregroundStyle(Color.farBlue)
                            .interpolationMethod(.catmullRom)
                        }
                    }
                }
            }
            .chartForegroundStyleScale([
                "5 cm": Color.accent,
                "10 cm": Color.farBlue
            ])
            .chartYAxisLabel("cm")
            .frame(height: 180)
        }
    }

    // MARK: - Lab LSI Bar Chart

    private func labLsiChart(_ data: [AclLabSummaryPoint]) -> some View {
        // Show the latest assessment
        guard let latest = data.last else { return AnyView(EmptyView()) }
        let bars: [(String, Double)] = [
            ("Quad", latest.quadLsi ?? 0),
            ("Hamstring", latest.hamstringLsi ?? 0)
        ].filter { $0.1 > 0 }

        guard !bars.isEmpty else { return AnyView(EmptyView()) }

        return AnyView(
            chartCard(title: "Kraft-LSI (Meilenstein \(latest.milestone))", icon: "figure.strengthtraining.traditional") {
                Chart(bars, id: \.0) { item in
                    BarMark(
                        x: .value("Muskelgruppe", item.0),
                        y: .value("LSI %", item.1)
                    )
                    .foregroundStyle(lsiColor(for: item.1))
                    .cornerRadius(4)
                }
                .chartYScale(domain: 0...110)
                .chartYAxisLabel("LSI %")
                .chartOverlay { _ in
                    // Target line overlay
                    GeometryReader { geo in
                        let yRatio = 90.0 / 110.0
                        let yPos = geo.size.height * (1 - yRatio)
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: yPos))
                            path.addLine(to: CGPoint(x: geo.size.width, y: yPos))
                        }
                        .stroke(Color.painGreen.opacity(0.6), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    }
                }
                .frame(height: 180)
            }
        )
    }

    // MARK: - Chart Card Container

    private func chartCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(.accent)
                    .font(.appSubheadline)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)
                Spacer()
            }
            content()
        }
        .cardStyle()
    }

    // MARK: - Helpers

    private func parseDateOnly(_ dateString: String) -> Date? {
        DateFormatters.dateOnly.date(from: dateString)
    }

    private func lsiColor(for value: Double) -> Color {
        if value >= 85 { return .painGreen }
        if value >= 70 { return .painAmber }
        return .painRed
    }

    private func swellingColor(for grade: Int) -> Color {
        switch grade {
        case 0: return .painGreen
        case 1: return .painGreen
        case 2: return .painAmber
        default: return .painRed
        }
    }
}

