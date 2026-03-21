import SwiftUI

enum DashboardTab: String, CaseIterable {
    case overview = "Übersicht"
    case program = "Programm"
    case edukation = "Edukation"
    case progress = "Fortschritt"
    case insights = "Analyse"
    case messages = "Nachrichten"

    var displayName: String {
        let isEn = UserDefaults.standard.string(forKey: "appLanguage") == "en"
        switch self {
        case .overview: return isEn ? "Overview" : "Übersicht"
        case .program: return isEn ? "Program" : "Programm"
        case .edukation: return isEn ? "Education" : "Edukation"
        case .progress: return isEn ? "Progress" : "Fortschritt"
        case .insights: return isEn ? "Insights" : "Analyse"
        case .messages: return isEn ? "Messages" : "Nachrichten"
        }
    }

    var icon: String {
        switch self {
        case .overview: return "house"
        case .program: return "figure.run"
        case .edukation: return "book"
        case .progress: return "chart.bar"
        case .insights: return "lightbulb"
        case .messages: return "message"
        }
    }

    var iconFilled: String {
        switch self {
        case .overview: return "house.fill"
        case .program: return "figure.run" // no .fill variant in SF Symbols
        case .edukation: return "book.fill"
        case .progress: return "chart.bar.fill"
        case .insights: return "lightbulb.fill"
        case .messages: return "message.fill"
        }
    }
}

@Observable
@MainActor
final class DashboardViewModel {
    var phaseStatus: AdaptivePhaseStatus?
    var progressStats: ProgressStats?
    var completedToday: [String] = []
    var recentEntries: [ProgressEntry] = []
    var scheduleResponse: ScheduleResponse?
    var streak: StreakResponse?
    var isLoading = false
    var error: String?

    private let apiClient: APIClient
    private weak var appState: AppState?

    init(apiClient: APIClient, appState: AppState) {
        self.apiClient = apiClient
        self.appState = appState
    }

    // MARK: - Data Loading

    // Determines which severity fetch (if any) is needed for the current user's condition.
    // At most one condition applies per user, so at most one fetch runs.
    private enum SeverityFetchKind: Sendable {
        case neck, tension, shoulder, frozenShoulder, lateralAnkleSprain
    }

    private func neededSeverityFetch() -> SeverityFetchKind? {
        guard let appState else { return nil }
        if appState.isNeck, appState.currentUser?.ndiSeverity == nil { return .neck }
        if appState.isTension, appState.currentUser?.tsiSeverity == nil { return .tension }
        if appState.isShoulder, appState.currentUser?.siSeverity == nil { return .shoulder }
        if appState.isFrozenShoulder, appState.currentUser?.fsSeverity == nil { return .frozenShoulder }
        if appState.isLateralAnkleSprain, appState.currentUser?.lasSeverity == nil { return .lateralAnkleSprain }
        return nil
    }

    func loadDashboard() async {
        isLoading = true
        error = nil

        // Determine needed severity fetch before entering parallel block
        let severityKind = neededSeverityFetch()

        async let phaseResult: PhaseStatusResponse? = loadSafely { [apiClient] in
            try await apiClient.request(APIEndpoints.phaseStatus())
        }

        async let statsResult: StatsResponse? = loadSafely { [apiClient] in
            try await apiClient.request(APIEndpoints.getProgressStats())
        }

        async let todayResult: TodayProgressResponse? = loadSafely { [apiClient] in
            try await apiClient.request(APIEndpoints.getTodayProgress())
        }

        async let scheduleResult: ScheduleResponse? = loadSafely { [apiClient] in
            try await apiClient.request(APIEndpoints.getSchedule())
        }

        async let entriesResult: EntriesResponse? = loadSafely { [apiClient] in
            try await apiClient.request(APIEndpoints.getProgress(limit: 100))
        }

        async let streakResult: StreakResponse? = loadSafely { [apiClient] in
            try await apiClient.request(APIEndpoints.streak())
        }

        // Severity fetch runs in parallel with all other calls (at most one fires)
        async let severityResult: SeverityFetchResult = loadSeverity(severityKind)

        let (phase, stats, today, schedule, entries, streakResp, severity) = await (
            phaseResult, statsResult, todayResult, scheduleResult, entriesResult, streakResult, severityResult
        )

        phaseStatus = phase?.phaseStatus
        if let phaseData = phase?.phaseStatus {
            appState?.currentUser?.adaptivePhase = phaseData.currentPhase
        }
        streak = streakResp

        // Apply severity result to appState
        applySeverityResult(severity)

        if let s = stats?.stats {
            progressStats = ProgressStats(
                totalSessions: s.totalSessions,
                lastSevenDays: s.lastSevenDays,
                averagePain: s.averagePainLevel,
                compliancePercent: s.currentWeekCompliance,
                recentPainLevels: s.recentPainLevels
            )
        }
        completedToday = today?.completedExercises ?? []
        recentEntries = entries?.entries ?? []
        scheduleResponse = schedule

        isLoading = false
    }

    func refresh() async {
        await loadDashboard()
    }

    func fetchTodayCheckin() async {
        let response: CheckinTodayResponse? = await loadSafely { [apiClient] in
            try await apiClient.request(APIEndpoints.morningCheckinToday())
        }
        appState?.hasCheckedInToday = response?.checkedIn ?? false
    }

    // MARK: - Helpers

    var isRestDay: Bool {
        guard let schedule = scheduleResponse else { return false }
        let todayWeekday = Calendar.current.component(.weekday, from: Date())
        return !schedule.iosWeekdays.contains(todayWeekday)
    }

    func isExerciseCompletedToday(_ exerciseId: String) -> Bool {
        completedToday.contains(exerciseId)
    }

    // MARK: - Severity Fetching

    private enum SeverityFetchResult: Sendable {
        case none
        case ndiSeverity(NdiSeverityGrade)
        case tsiSeverity(TsiSeverityGrade)
        case siSeverity(SiSeverityGrade)
        case fsSeverity(FsSeverityGrade)
        case lasSeverity(LasSeverityGrade)
    }

    private func loadSeverity(_ kind: SeverityFetchKind?) async -> SeverityFetchResult {
        guard let kind else { return .none }
        switch kind {
        case .neck:
            let result: NeckScreeningResponse? = await loadSafely { [apiClient] in
                try await apiClient.request(APIEndpoints.neckResult())
            }
            if let screening = result?.screening {
                return .ndiSeverity(NdiSeverityGrade.from(ndiScore: screening.ndiScore))
            }
        case .tension:
            let result: TsiScreeningResponse? = await loadSafely { [apiClient] in
                try await apiClient.request(APIEndpoints.tensionResult())
            }
            if let screening = result?.screening {
                return .tsiSeverity(TsiSeverityGrade.from(tsiScore: screening.tsiScore))
            }
        case .shoulder:
            let result: SiScreeningResponse? = await loadSafely { [apiClient] in
                try await apiClient.request(APIEndpoints.siResult())
            }
            if let screening = result?.screening {
                return .siSeverity(SiSeverityGrade.from(quickDashScore: screening.quickDashScore))
            }
        case .frozenShoulder:
            let result: FsScreeningResponse? = await loadSafely { [apiClient] in
                try await apiClient.request(APIEndpoints.fsResult())
            }
            if let screening = result?.screening {
                let backendSeverity = screening.severityGrade
                let severity = (backendSeverity != .unknown)
                    ? backendSeverity
                    : FsSeverityGrade.from(spadiScore: screening.spadiTotalScore)
                return .fsSeverity(severity)
            }
        case .lateralAnkleSprain:
            let result: LasScreeningResponse? = await loadSafely { [apiClient] in
                try await apiClient.request(APIEndpoints.lasResult())
            }
            if let screening = result?.screening {
                let backendSeverity = screening.severityGrade
                let severity = (backendSeverity != .unknown)
                    ? backendSeverity
                    : LasSeverityGrade.from(caitScore: screening.caitScore)
                return .lasSeverity(severity)
            }
        }
        return .none
    }

    private func applySeverityResult(_ result: SeverityFetchResult) {
        switch result {
        case .none:
            break
        case .ndiSeverity(let grade):
            appState?.currentUser?.ndiSeverity = grade
        case .tsiSeverity(let grade):
            appState?.currentUser?.tsiSeverity = grade
        case .siSeverity(let grade):
            appState?.currentUser?.siSeverity = grade
        case .fsSeverity(let grade):
            appState?.currentUser?.fsSeverity = grade
        case .lasSeverity(let grade):
            appState?.currentUser?.lasSeverity = grade
        }
    }

    private func loadSafely<T: Sendable>(_ work: @Sendable () async throws -> T) async -> T? {
        do {
            return try await work()
        } catch is CancellationError {
            return nil
        } catch let urlError as URLError where urlError.code == .cancelled {
            return nil
        } catch {
            Log.api.error("Dashboard load error: \(error.localizedDescription)")
            if self.error == nil {
                let isEn = UserDefaults.standard.string(forKey: "appLanguage") == "en"
                self.error = isEn ? "Data could not be loaded." : "Daten konnten nicht geladen werden."
            }
            return nil
        }
    }
}
