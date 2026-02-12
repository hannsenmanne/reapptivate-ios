import SwiftUI

enum DashboardTab: String, CaseIterable {
    case overview = "Ubersicht"
    case program = "Programm"
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

        async let phaseResult: AdaptivePhaseStatus? = loadSafely { [apiClient] in
            try await apiClient.request(APIEndpoints.phaseStatus())
        }

        async let statsResult: ProgressStats? = loadSafely { [apiClient] in
            try await apiClient.request(APIEndpoints.getProgressStats())
        }

        async let todayResult: [ProgressEntry]? = loadSafely { [apiClient] in
            try await apiClient.request(APIEndpoints.getTodayProgress())
        }

        let (phase, stats, today) = await (phaseResult, statsResult, todayResult)

        phaseStatus = phase
        progressStats = stats
        completedToday = today ?? []

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
