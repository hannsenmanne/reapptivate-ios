import SwiftUI

enum DashboardTab: String, CaseIterable {
    case overview = "Ubersicht"
    case program = "Programm"
    case edukation = "Edukation"
    case progress = "Fortschritt"
    case insights = "Insights"
}

@Observable
@MainActor
final class DashboardViewModel {
    var selectedTab: DashboardTab = .overview
    var phaseStatus: AdaptivePhaseStatus?
    var progressStats: ProgressStats?
    var completedToday: [ProgressEntry] = []
    var isLoading = false
    var error: String?

    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    var availableTabs: [DashboardTab] {
        DashboardTab.allCases.filter { tab in
            if tab == .insights {
                return false // LBP-only, checked at view level
            }
            return true
        }
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
