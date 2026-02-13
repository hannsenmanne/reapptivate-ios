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
    var completedToday: [ProgressEntry] = []
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

        let (phase, stats, today) = await (phaseResult, statsResult, todayResult)

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
        if let s = stats?.stats {
            progressStats = ProgressStats(
                totalSessions: s.totalSessions,
                lastSevenDays: s.lastSevenDays,
                averagePain: s.averagePainLevel,
                compliancePercent: s.currentWeekCompliance
            )
        }
        completedToday = today?.completedExercises ?? []

        isLoading = false
    }

    func refresh() async {
        await loadDashboard()
    }

    // MARK: - Helpers

    func isExerciseCompletedToday(_ exerciseId: String) -> Bool {
        completedToday.contains { $0.exerciseId == exerciseId }
    }

    private func loadSafely<T>(_ work: @Sendable () async throws -> T) async -> T? {
        do {
            return try await work()
        } catch {
            Log.api.error("Dashboard load error: \(error.localizedDescription)")
            return nil
        }
    }
}
