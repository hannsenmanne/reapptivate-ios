import SwiftUI
import Charts

struct AclAnalyticsView: View {
    @Environment(AppState.self) private var appState
    @Environment(APIClient.self) private var apiClient
    @AppStorage("appLanguage") private var appLanguage = "de"

    @State private var analytics: AclAnalytics?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            if isLoading {
                ProgressView(appLanguage == "en" ? "Loading analytics..." : "Analyse laden...")
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
                    title: appLanguage == "en" ? "No data yet" : "Noch keine Daten",
                    message: appLanguage == "en" ? "Analytics will be available after a few KPI entries." : "Analyse wird nach einigen KPI-Einträgen verfügbar."
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
            errorMessage = appLanguage == "en" ? "Could not load analytics." : "Analyse konnte nicht geladen werden."
        }
        isLoading = false
    }

    // MARK: - Summary Header

    private func summaryHeader(_ data: AclAnalytics) -> some View {
        HStack(spacing: 12) {
            MetricCard(
                title: appLanguage == "en" ? "Milestone" : "Meilenstein",
                value: "\(data.currentMilestone)",
                color: .accent
            )
            MetricCard(
                title: appLanguage == "en" ? "Weeks post-op" : "Wochen post-OP",
                value: "\(data.weeksPostSurgery)",
                color: .farBlue
            )
        }
    }

    // MARK: - Pain Chart

    private func painChart(_ data: [AclPainTrendPoint]) -> some View {
        chartCard(title: appLanguage == "en" ? "Pain Trend" : "Schmerzentwicklung", icon: "waveform.path.ecg") {
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
        chartCard(title: appLanguage == "en" ? "Range of Motion" : "Beweglichkeit", icon: "arrow.up.and.down") {
            Chart {
                ForEach(data) { point in
                    if let date = parseDateOnly(point.date) {
                        if let flexion = point.flexion {
                            LineMark(
                                x: .value(appLanguage == "en" ? "Date" : "Datum", date),
                                y: .value(appLanguage == "en" ? "Degrees" : "Grad", flexion),
                                series: .value(appLanguage == "en" ? "Type" : "Typ", appLanguage == "en" ? "Flexion" : "Flexion")
                            )
                            .foregroundStyle(Color.accent)
                            .interpolationMethod(.catmullRom)
                        }
                        if let extDeficit = point.extensionDeficit {
                            LineMark(
                                x: .value(appLanguage == "en" ? "Date" : "Datum", date),
                                y: .value(appLanguage == "en" ? "Degrees" : "Grad", extDeficit),
                                series: .value(appLanguage == "en" ? "Type" : "Typ", appLanguage == "en" ? "Ext. deficit" : "Ext.-Defizit")
                            )
                            .foregroundStyle(Color.painAmber)
                            .interpolationMethod(.catmullRom)
                        }
                    }
                }
            }
            .chartForegroundStyleScale([
                (appLanguage == "en" ? "Flexion" : "Flexion"): Color.accent,
                (appLanguage == "en" ? "Ext. deficit" : "Ext.-Defizit"): Color.painAmber
            ])
            .chartYAxisLabel("Grad")
            .frame(height: 180)
        }
    }

    // MARK: - Swelling Chart

    private func swellingChart(_ data: [AclSwellingTrendPoint]) -> some View {
        let filtered = data.filter { $0.swellingGrade != nil }
        return chartCard(title: appLanguage == "en" ? "Swelling" : "Schwellung", icon: "drop.fill") {
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
                RuleMark(y: .value(appLanguage == "en" ? "Target" : "Ziel", 85))
                    .foregroundStyle(Color.painGreen.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text(appLanguage == "en" ? "Target: 85" : "Ziel: 85")
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
        chartCard(title: appLanguage == "en" ? "Tampa Scale" : "Tampa-Skala", icon: "brain.head.profile") {
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
                RuleMark(y: .value(appLanguage == "en" ? "Warning" : "Warnung", 37))
                    .foregroundStyle(Color.painRed.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text(appLanguage == "en" ? "Warning: 37" : "Warnung: 37")
                            .font(.appCaption2)
                            .foregroundStyle(.painRed)
                    }
            }
            .chartYScale(domain: 11...44)
            .chartYAxisLabel("Score")
            .frame(height: 180)
        }
    }

    // MARK: - Thigh Circumference Chart

    private func thighCircChart(_ data: [AclThighCircTrendPoint]) -> some View {
        chartCard(title: appLanguage == "en" ? "Thigh Circumference" : "Oberschenkelumfang", icon: "ruler") {
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
            chartCard(title: appLanguage == "en" ? "Strength LSI (Milestone \(latest.milestone))" : "Kraft-LSI (Meilenstein \(latest.milestone))", icon: "figure.strengthtraining.traditional") {
                Chart(bars, id: \.0) { item in
                    BarMark(
                        x: .value("Muskelgruppe", item.0),
                        y: .value("LSI %", item.1)
                    )
                    .foregroundStyle(lsiColor(for: item.1, milestone: latest.milestone))
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
        .accessibilityElement(children: .contain)
        .accessibilityLabel(appLanguage == "en" ? "Chart: \(title)" : "Diagramm: \(title)")
    }

    // MARK: - Helpers

    private func parseDateOnly(_ dateString: String) -> Date? {
        DateFormatters.dateOnly.date(from: dateString)
    }

    private func lsiColor(for value: Double, milestone: Int? = nil) -> Color {
        let athleteLevel = appState.currentUser?.aclAthleteLevel
        let greenThreshold: Double = (milestone ?? 0) >= 4 && athleteLevel == .competitive ? 90 : 85
        let amberThreshold: Double = (milestone ?? 0) >= 4 && athleteLevel == .competitive ? 75 : 70
        if value >= greenThreshold { return .painGreen }
        if value >= amberThreshold { return .painAmber }
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

