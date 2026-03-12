import SwiftUI

struct AclKpiHistoryView: View {
    @Environment(AppState.self) private var appState
    @Environment(APIClient.self) private var apiClient
    @AppStorage("appLanguage") private var appLanguage = "de"

    @State private var selectedTab = 0
    @State private var dailyVM: AclDailyKpiViewModel?
    @State private var weeklyVM: AclWeeklyKpiViewModel?
    @State private var labVM: AclLabAssessmentViewModel?

    var body: some View {
        VStack(spacing: 16) {
            // Segmented Control
            Picker(appLanguage == "en" ? "KPI Category" : "KPI-Kategorie", selection: $selectedTab) {
                Text(appLanguage == "en" ? "Daily" : "Täglich").tag(0)
                Text(appLanguage == "en" ? "Weekly" : "Wöchentlich").tag(1)
                Text(appLanguage == "en" ? "Lab" : "Labor").tag(2)
            }
            .pickerStyle(.segmented)

            // Content
            switch selectedTab {
            case 0:
                dailyTabContent
            case 1:
                weeklyTabContent
            default:
                labTabContent
            }
        }
        .task {
            let dvm = AclDailyKpiViewModel(apiClient: apiClient)
            dailyVM = dvm
            let wvm = AclWeeklyKpiViewModel(apiClient: apiClient)
            weeklyVM = wvm
            let lvm = AclLabAssessmentViewModel(apiClient: apiClient)
            labVM = lvm
            async let d: Void = dvm.loadHistory()
            async let w: Void = wvm.loadHistory()
            async let l: Void = lvm.loadAssessments()
            _ = await (d, w, l)
        }
    }

    // MARK: - Daily Tab

    @ViewBuilder
    private var dailyTabContent: some View {
        if let vm = dailyVM {
            if vm.isLoadingHistory {
                ProgressView(appLanguage == "en" ? "Loading daily KPIs..." : "Lade Tages-KPIs...")
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else if let error = vm.errorMessage {
                InlineErrorView(message: error, onRetry: {
                    Task<Void, Never> { await vm.loadHistory() }
                })
            } else if vm.dailyKpis.isEmpty {
                EmptyStateView(
                    icon: "chart.line.downtrend.xyaxis",
                    title: appLanguage == "en" ? "No Daily KPIs" : "Keine Tages-KPIs",
                    message: appLanguage == "en" ? "Record your first daily values." : "Erfassen Sie Ihre ersten täglichen Werte."
                )
                .frame(minHeight: 200)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(vm.dailyKpis) { kpi in
                        DailyKpiCard(kpi: kpi)
                    }
                }
            }
        } else {
            ProgressView()
        }
    }

    // MARK: - Weekly Tab

    @ViewBuilder
    private var weeklyTabContent: some View {
        if let vm = weeklyVM {
            if vm.isLoadingHistory {
                ProgressView(appLanguage == "en" ? "Loading weekly KPIs..." : "Lade Wochen-KPIs...")
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else if let error = vm.errorMessage {
                InlineErrorView(message: error, onRetry: {
                    Task<Void, Never> { await vm.loadHistory() }
                })
            } else if vm.weeklyKpis.isEmpty {
                EmptyStateView(
                    icon: "calendar.badge.clock",
                    title: appLanguage == "en" ? "No Weekly KPIs" : "Keine Wochen-KPIs",
                    message: appLanguage == "en" ? "Record your first weekly values." : "Erfassen Sie Ihre ersten wöchentlichen Werte."
                )
                .frame(minHeight: 200)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(vm.weeklyKpis) { kpi in
                        WeeklyKpiCard(kpi: kpi)
                    }
                }
            }
        } else {
            ProgressView()
        }
    }

    // MARK: - Lab Tab

    @ViewBuilder
    private var labTabContent: some View {
        if let vm = labVM {
            if vm.isLoading {
                ProgressView(appLanguage == "en" ? "Loading lab values..." : "Lade Laborwerte...")
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else if let error = vm.errorMessage {
                InlineErrorView(message: error, onRetry: {
                    Task<Void, Never> { await vm.loadAssessments() }
                })
            } else if vm.assessments.isEmpty {
                EmptyStateView(
                    icon: "flask",
                    title: appLanguage == "en" ? "No Lab Values" : "Keine Laborwerte",
                    message: appLanguage == "en" ? "Lab values are recorded by your therapist." : "Laborwerte werden von Ihrem Therapeuten erfasst."
                )
                .frame(minHeight: 200)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(vm.assessments) { assessment in
                        LabAssessmentCard(assessment: assessment, athleteLevel: appState.currentUser?.aclAthleteLevel)
                    }
                }
            }
        } else {
            ProgressView()
        }
    }
}

// MARK: - Daily KPI Card

private struct DailyKpiCard: View {
    let kpi: AclDailyKpi
    @AppStorage("appLanguage") private var appLanguage = "de"
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header row
            HStack {
                Text(formattedDate(kpi.date, locale: appLanguage))
                    .font(.appSubheadlineMedium)
                    .foregroundStyle(.textPrimary)

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                }
                .accessibilityLabel(isExpanded ? (appLanguage == "en" ? "Hide details" : "Details ausblenden") : (appLanguage == "en" ? "Show details" : "Details anzeigen"))
            }

            // Summary row
            HStack(spacing: 16) {
                KpiPill(label: appLanguage == "en" ? "Pain" : "Schmerz", value: "\(kpi.painNrs)/10", color: dailyPainColor(kpi.painNrs))

                if let flexion = kpi.kneeFlexionDeg {
                    KpiPill(label: appLanguage == "en" ? "Flexion" : "Flexion", value: "\(flexion)\u{00B0}", color: .textPrimary)
                }

                if let ext = kpi.extensionDeficitDeg {
                    KpiPill(label: appLanguage == "en" ? "Ext. def." : "Ext.def.", value: "\(ext)\u{00B0}", color: .textPrimary)
                }

                if let swelling = kpi.swellingGrade {
                    KpiPill(label: appLanguage == "en" ? "Effusion" : "Erguss", value: appLanguage == "en" ? "Grade \(swelling)" : "Grad \(swelling)", color: swellingColor(swelling))
                }
            }

            // Expanded details
            if isExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    if let location = kpi.painLocation, !location.isEmpty {
                        detailRow(label: appLanguage == "en" ? "Location" : "Lokalisation", value: location)
                    }
                    if let activity = kpi.painActivity, !activity.isEmpty {
                        detailRow(label: appLanguage == "en" ? "Activity" : "Aktivität", value: activity)
                    }
                    if let quadsLag = kpi.quadsLag {
                        detailRow(label: "Quad-Lag", value: quadsLag ? (appLanguage == "en" ? "Yes" : "Ja") : (appLanguage == "en" ? "No" : "Nein"))
                    }
                    if let notes = kpi.notes, !notes.isEmpty {
                        detailRow(label: appLanguage == "en" ? "Notes" : "Notizen", value: notes)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .cardStyle()
    }

    @ViewBuilder
    private func detailRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.appCaption)
                .foregroundStyle(.textSecondary)
                .frame(width: 90, alignment: .leading)
            Text(value)
                .font(.appCaption)
                .foregroundStyle(.textPrimary)
        }
    }

    private func dailyPainColor(_ level: Int) -> Color {
        if level <= 3 { return .painGreen }
        if level <= 6 { return .painAmber }
        return .painRed
    }

    private func swellingColor(_ grade: Int) -> Color {
        switch grade {
        case 0: .painGreen
        case 1: .painAmber
        default: .painRed
        }
    }
}

// MARK: - Weekly KPI Card

private struct WeeklyKpiCard: View {
    let kpi: AclWeeklyKpi
    @AppStorage("appLanguage") private var appLanguage = "de"

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(formattedDate(kpi.weekDate, locale: appLanguage))
                .font(.appSubheadlineMedium)
                .foregroundStyle(.textPrimary)

            HStack(spacing: 16) {
                if let ikdc = kpi.ikdcScore {
                    KpiPill(label: "IKDC", value: "\(ikdc)%", color: .textPrimary)
                }

                if let tampa = kpi.tampaScore {
                    KpiPill(
                        label: "Tampa",
                        value: "\(tampa)/44",
                        color: tampa > 37 ? .painRed : .textPrimary
                    )
                }

                if let circ5 = kpi.thighCirc5cm {
                    KpiPill(label: "OS 5cm", value: String(format: "%.1f cm", circ5), color: .textPrimary)
                }

                if let circ10 = kpi.thighCirc10cm {
                    KpiPill(label: "OS 10cm", value: String(format: "%.1f cm", circ10), color: .textPrimary)
                }
            }

            // Tampa warning
            if let tampa = kpi.tampaScore, tampa > 37 {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.appCaption)
                        .foregroundStyle(.painAmber)
                    Text(appLanguage == "en" ? "Elevated fear of movement" : "Erhöhte Bewegungsangst")
                        .font(.appCaption)
                        .foregroundStyle(.painAmber)
                }
            }
        }
        .cardStyle()
    }
}

// MARK: - Lab Assessment Card

private struct LabAssessmentCard: View {
    let assessment: AclLabAssessment
    var athleteLevel: AclAthleteLevel?
    @AppStorage("appLanguage") private var appLanguage = "de"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(appLanguage == "en" ? "Milestone \(assessment.milestone)" : "Meilenstein \(assessment.milestone)")
                    .font(.appSubheadlineMedium)
                    .foregroundStyle(.textPrimary)
                Spacer()
                if let date = assessment.assessmentDate {
                    Text(formattedDate(date, locale: appLanguage))
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                }
            }

            // Kraft-LSI Section
            if hasStrengthData {
                sectionHeader(appLanguage == "en" ? "Strength LSI" : "Kraft-LSI")
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    lsiRow(appLanguage == "en" ? "Quadriceps" : "Quadrizeps", value: assessment.quadLsi)
                    lsiRow("Hamstring", value: assessment.hamstringLsi)
                    lsiRow(appLanguage == "en" ? "Hip abd." : "Hüft-Abd.", value: assessment.hipAbdLsi)
                    lsiRow(appLanguage == "en" ? "Hip add." : "Hüft-Add.", value: assessment.hipAddLsi)
                    lsiRow(appLanguage == "en" ? "Hip ER" : "Hüft-ER", value: assessment.hipErLsi)
                    lsiRow(appLanguage == "en" ? "Calf" : "Wade", value: assessment.calfLsi)
                }
            }

            // Explosivität Section
            if hasCmjData {
                sectionHeader(appLanguage == "en" ? "Explosiveness" : "Explosivität")
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    lsiRow(appLanguage == "en" ? "DL CMJ conc." : "DL CMJ konz.", value: assessment.dlCmjConcentricLsi)
                    lsiRow(appLanguage == "en" ? "DL CMJ ecc." : "DL CMJ exz.", value: assessment.dlCmjEccentricLsi)
                    lsiRow(appLanguage == "en" ? "SL CMJ height" : "SL CMJ Höhe", value: assessment.slCmjHeightLsi)
                }
            }

            // Reaktivkraft Section
            if hasReactiveData {
                sectionHeader(appLanguage == "en" ? "Reactive Strength" : "Reaktivkraft")
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    lsiRow("DL DJ RSI", value: assessment.dlDjRsi)
                    lsiRow("SL DJ RSI", value: assessment.slDjRsi)
                    lsiRow(appLanguage == "en" ? "SL DJ contact" : "SL DJ Kontakt", value: assessment.slDjContactTimeLsi)
                }
            }

            // Running
            if let speed = assessment.runningSpeedKmh {
                sectionHeader(appLanguage == "en" ? "Running" : "Laufen")
                HStack {
                    Text(appLanguage == "en" ? "Speed" : "Geschwindigkeit")
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                    Spacer()
                    Text(String(format: "%.1f km/h", speed))
                        .font(.appCaptionMedium)
                        .foregroundStyle(.textPrimary)
                }
            }

            // Clinical
            if hasClinicalData {
                sectionHeader(appLanguage == "en" ? "Clinical" : "Klinisch")
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    if let ikdc = assessment.ikdcScore {
                        clinicalRow("IKDC", value: String(format: "%.0f%%", ikdc))
                    }
                    if let tampa = assessment.tampaScore {
                        clinicalRow("Tampa", value: String(format: "%.0f/44", tampa))
                    }
                    if let flexion = assessment.kneeFlexionDeg {
                        clinicalRow("Flexion", value: String(format: "%.0f\u{00B0}", flexion))
                    }
                    if let ext = assessment.extensionDeficitDeg {
                        clinicalRow("Ext.def.", value: String(format: "%.0f\u{00B0}", ext))
                    }
                    if let swelling = assessment.swellingGrade {
                        clinicalRow(appLanguage == "en" ? "Effusion" : "Erguss", value: appLanguage == "en" ? "Grade \(swelling)" : "Grad \(swelling)")
                    }
                }
            }

            // Notes
            if let notes = assessment.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text(appLanguage == "en" ? "Notes" : "Notizen")
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                    Text(notes)
                        .font(.appCaption)
                        .foregroundStyle(.textPrimary)
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Section Header

    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.appCaptionMedium)
            .foregroundStyle(.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
    }

    // MARK: - LSI Row

    @ViewBuilder
    private func lsiRow(_ label: String, value: Double?) -> some View {
        if let value {
            HStack {
                Text(label)
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
                Spacer()
                Text(String(format: "%.0f%%", value))
                    .font(.appCaptionMedium)
                    .foregroundStyle(lsiColor(for: value, milestone: assessment.milestone, athleteLevel: athleteLevel))
            }
        }
    }

    @ViewBuilder
    private func clinicalRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.appCaption)
                .foregroundStyle(.textSecondary)
            Spacer()
            Text(value)
                .font(.appCaptionMedium)
                .foregroundStyle(.textPrimary)
        }
    }

    // MARK: - Helpers

    private func lsiColor(for value: Double, milestone: Int? = nil, athleteLevel: AclAthleteLevel? = nil) -> Color {
        let greenThreshold: Double = (milestone ?? 0) >= 4 && athleteLevel == .competitive ? 90 : 85
        let amberThreshold: Double = (milestone ?? 0) >= 4 && athleteLevel == .competitive ? 75 : 70
        if value < amberThreshold { return .painRed }
        if value < greenThreshold { return .painAmber }
        return .painGreen
    }

    private var hasStrengthData: Bool {
        assessment.quadLsi != nil || assessment.hamstringLsi != nil
            || assessment.hipAbdLsi != nil || assessment.hipAddLsi != nil
            || assessment.hipErLsi != nil || assessment.calfLsi != nil
    }

    private var hasCmjData: Bool {
        assessment.dlCmjConcentricLsi != nil || assessment.dlCmjEccentricLsi != nil
            || assessment.slCmjHeightLsi != nil
    }

    private var hasReactiveData: Bool {
        assessment.dlDjRsi != nil || assessment.slDjRsi != nil
            || assessment.slDjContactTimeLsi != nil
    }

    private var hasClinicalData: Bool {
        assessment.ikdcScore != nil || assessment.tampaScore != nil
            || assessment.kneeFlexionDeg != nil || assessment.extensionDeficitDeg != nil
            || assessment.swellingGrade != nil
    }
}

// MARK: - KPI Pill

private struct KpiPill: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.appCaptionMedium)
                .foregroundStyle(color)
            Text(label)
                .font(.appCaption2)
                .foregroundStyle(.textSecondary)
        }
    }
}

// MARK: - Date Formatting

private enum KpiDateFormatters {
    nonisolated(unsafe) static let iso: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withFullDate]
        return f
    }()

    static let displayDE: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.dateStyle = .medium
        return f
    }()

    static let displayEN: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateStyle = .medium
        return f
    }()

    static let fallback: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f
    }()
}

private func formattedDate(_ dateString: String, locale: String = "de") -> String {
    let formatter = locale == "en" ? KpiDateFormatters.displayEN : KpiDateFormatters.displayDE
    if let date = KpiDateFormatters.iso.date(from: dateString) {
        return formatter.string(from: date)
    }
    if let date = KpiDateFormatters.fallback.date(from: dateString) {
        return formatter.string(from: date)
    }
    return dateString
}
