import SwiftUI

enum DashboardTab: String, CaseIterable {
    case overview = "Übersicht"
    case program = "Programm"
    case edukation = "Edukation"
    case progress = "Fortschritt"
    case insights = "Analyse"
}

@Observable
@MainActor
final class DashboardViewModel {
    var phaseStatus: AdaptivePhaseStatus?
    var progressStats: ProgressStats?
    var streakData: StreakData?
    var completedToday: [ProgressEntry] = []
    var recentEntries: [ProgressEntry] = []
    var userSchedule: UserSchedule?
    var isLoading = false
    var isFreezing = false
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

        async let streakResult: StreakData? = loadSafely { [apiClient] in
            try await apiClient.request(APIEndpoints.getStreak())
        }

        async let scheduleResult: UserSchedule? = loadSafely { [apiClient] in
            try await apiClient.request(APIEndpoints.getSchedule())
        }

        async let entriesResult: EntriesResponse? = loadSafely { [apiClient] in
            try await apiClient.request(APIEndpoints.getProgress(limit: 100))
        }

        let (phase, stats, today, streak, schedule, entries) = await (phaseResult, statsResult, todayResult, streakResult, scheduleResult, entriesResult)

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

        // Populate neckShoulderSeverity from screening result
        if appState?.isNeckShoulderTension == true, appState?.currentUser?.neckShoulderSeverity == nil {
            let nstResult: NeckShoulderScreeningResponse? = await loadSafely { [apiClient] in
                try await apiClient.request(APIEndpoints.neckShoulderResult())
            }
            if let result = nstResult?.screening {
                appState?.currentUser?.neckShoulderSeverity = result.severity
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
        streakData = streak
        userSchedule = schedule

        // Schedule streak-ending notification if active streak
        if let streakInfo = streak, streakInfo.currentStreak > 0 {
            if let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) {
                await NotificationService.shared.scheduleStreakEndingAlert(
                    streakCount: streakInfo.currentStreak,
                    for: tomorrow
                )
            }
        }

        isLoading = false
    }

    func refresh() async {
        await loadDashboard()
    }

    // MARK: - Streak

    func useFreezeToken() async {
        guard !isFreezing else { return }
        isFreezing = true
        do {
            try await apiClient.requestVoid(APIEndpoints.useFreezeToken())
        } catch {
            self.error = "Frost-Token konnte nicht verwendet werden."
            Log.api.error("Freeze token error: \(error.localizedDescription)")
        }
        await loadDashboard()
        isFreezing = false
    }

    // MARK: - Helpers

    var isRestDay: Bool {
        guard let schedule = userSchedule else { return false }
        let todayWeekday = Calendar.current.component(.weekday, from: Date())
        return !schedule.availableDays.contains(todayWeekday)
    }

    func isExerciseCompletedToday(_ exerciseId: String) -> Bool {
        completedToday.contains { $0.exerciseId == exerciseId }
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
