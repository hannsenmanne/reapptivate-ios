import SwiftUI

enum DashboardTab: String, CaseIterable {
    case overview = "Übersicht"
    case program = "Programm"
    case edukation = "Edukation"
    case progress = "Fortschritt"
    case insights = "Analyse"
    case messages = "Nachrichten"
}

@Observable
@MainActor
final class DashboardViewModel {
    var phaseStatus: AdaptivePhaseStatus?
    var progressStats: ProgressStats?
    var completedToday: [String] = []
    var recentEntries: [ProgressEntry] = []
    var scheduleResponse: ScheduleResponse?
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

        let (phase, stats, today, schedule, entries) = await (phaseResult, statsResult, todayResult, scheduleResult, entriesResult)

        phaseStatus = phase?.phaseStatus
        if let phaseData = phase?.phaseStatus {
            appState?.currentUser?.adaptivePhase = phaseData.currentPhase
        }

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
            return nil
        }
    }
}
