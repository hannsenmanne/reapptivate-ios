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

    func loadDashboard() async {
        isLoading = true
        error = nil

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

        let (phase, stats, today, schedule, entries, streakResp) = await (phaseResult, statsResult, todayResult, scheduleResult, entriesResult, streakResult)

        phaseStatus = phase?.phaseStatus
        if let phaseData = phase?.phaseStatus {
            appState?.currentUser?.adaptivePhase = phaseData.currentPhase
        }
        streak = streakResp

        // Populate ndiSeverity for neck patients from screening result
        if appState?.isNeck == true, appState?.currentUser?.ndiSeverity == nil {
            let neckResult: NeckScreeningResponse? = await loadSafely { [apiClient] in
                try await apiClient.request(APIEndpoints.neckResult())
            }
            if let result = neckResult?.screening {
                appState?.currentUser?.ndiSeverity = NdiSeverityGrade.from(ndiScore: result.ndiScore)
            }
        }

        // Populate tsiSeverity for tension patients from screening result
        if appState?.isTension == true, appState?.currentUser?.tsiSeverity == nil {
            let tsiResult: TsiScreeningResponse? = await loadSafely { [apiClient] in
                try await apiClient.request(APIEndpoints.tensionResult())
            }
            if let result = tsiResult?.screening {
                appState?.currentUser?.tsiSeverity = TsiSeverityGrade.from(tsiScore: result.tsiScore)
            }
        }

        // Populate siSeverity for shoulder patients from screening result
        if appState?.isShoulder == true, appState?.currentUser?.siSeverity == nil {
            let siResult: SiScreeningResponse? = await loadSafely { [apiClient] in
                try await apiClient.request(APIEndpoints.siResult())
            }
            if let result = siResult?.screening {
                appState?.currentUser?.siSeverity = SiSeverityGrade.from(quickDashScore: result.quickDashScore)
            }
        }

        // Populate fsSeverity for frozen shoulder patients from screening result
        if appState?.isFrozenShoulder == true, appState?.currentUser?.fsSeverity == nil {
            let fsResult: FsScreeningResponse? = await loadSafely { [apiClient] in
                try await apiClient.request(APIEndpoints.fsResult())
            }
            if let result = fsResult?.screening {
                // Prefer backend-assigned severity; fall back to client-derived if nil/unknown
                let backendSeverity = result.severityGrade
                appState?.currentUser?.fsSeverity = (backendSeverity != nil && backendSeverity != .unknown)
                    ? backendSeverity
                    : FsSeverityGrade.from(spadiScore: result.spadiTotalScore)
            }
        }

        // Populate lasSeverity for lateral ankle sprain patients from screening result
        if appState?.isLateralAnkleSprain == true, appState?.currentUser?.lasSeverity == nil {
            let lasResult: LasScreeningResponse? = await loadSafely { [apiClient] in
                try await apiClient.request(APIEndpoints.lasResult())
            }
            if let result = lasResult?.screening {
                let backendSeverity = result.severityGrade
                appState?.currentUser?.lasSeverity = (backendSeverity != .unknown)
                    ? backendSeverity
                    : LasSeverityGrade.from(caitScore: result.caitScore)
            }
        }

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
        return !schedule.isTrainingDay
    }

    func isExerciseCompletedToday(_ exerciseId: String) -> Bool {
        completedToday.contains(exerciseId)
    }

    private func loadSafely<T: Sendable>(_ work: @Sendable () async throws -> T) async -> T? {
        do {
            return try await work()
        } catch {
            Log.api.error("Dashboard load error: \(error.localizedDescription)")
            if self.error == nil {
                self.error = "Daten konnten nicht geladen werden."
            }
            return nil
        }
    }
}
