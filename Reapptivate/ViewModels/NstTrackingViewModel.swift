import SwiftUI

@Observable
@MainActor
final class NstTrackingViewModel {
    // Session log state
    var sessions: [NeckShoulderSessionLog] = []
    var compliance: NeckShoulderComplianceStats?
    var microPauseStats: NstMicroPauseStats?

    // Loading
    var isLoading = false
    var isLoggingSession = false
    var isLoggingMicroPause = false
    var errorMessage: String?

    // Trigger evaluation result (shown after session log)
    var lastTriggerEvaluation: NstTriggerEvaluation?

    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    // MARK: - Load All

    func loadAll() async {
        isLoading = true
        errorMessage = nil
        async let sessionsTask: () = loadSessions()
        async let complianceTask: () = loadCompliance()
        async let microPauseTask: () = loadMicroPauseStats()
        _ = await (sessionsTask, complianceTask, microPauseTask)
        isLoading = false
    }

    // MARK: - Sessions

    func loadSessions() async {
        do {
            let response: NstSessionsResponse = try await apiClient.request(APIEndpoints.nstSessions())
            sessions = response.sessions
        } catch {
            if errorMessage == nil {
                errorMessage = "Sitzungen konnten nicht geladen werden."
            }
        }
    }

    // MARK: - Compliance

    func loadCompliance() async {
        do {
            let response: NstComplianceResponse = try await apiClient.request(APIEndpoints.nstCompliance())
            compliance = response.compliance
        } catch {
            // Non-critical — compliance may not exist before first session
        }
    }

    // MARK: - Micro-Pause Stats

    func loadMicroPauseStats() async {
        do {
            let response: NstMicroPauseStatsResponse = try await apiClient.request(APIEndpoints.nstMicroPauseStats())
            microPauseStats = response.microPauseStats
        } catch {
            // Non-critical
        }
    }

    // MARK: - Log Session

    func logSession(
        sessionType: String,
        painBefore: Int?,
        painAfter: Int?,
        exercisesCompleted: [String],
        durationSeconds: Int?,
        notes: String?
    ) async -> Bool {
        isLoggingSession = true
        errorMessage = nil
        lastTriggerEvaluation = nil

        let request = NeckShoulderSessionLogRequest(
            sessionType: sessionType,
            painBefore: painBefore.map(Double.init),
            painAfter: painAfter.map(Double.init),
            exercisesCompleted: exercisesCompleted,
            durationSeconds: durationSeconds,
            notes: notes
        )

        do {
            let response: NstSessionLogResponse = try await apiClient.request(APIEndpoints.logNstSession(body: request))
            sessions.insert(response.session, at: 0)
            lastTriggerEvaluation = response.triggerEvaluation

            // Reload compliance after logging
            await loadCompliance()

            isLoggingSession = false
            return true
        } catch {
            errorMessage = "Sitzung konnte nicht gespeichert werden."
            isLoggingSession = false
            return false
        }
    }

    // MARK: - Log Micro-Pause

    func logMicroPause() async -> Bool {
        isLoggingMicroPause = true
        do {
            let _: NstMicroPauseLogResponse = try await apiClient.request(APIEndpoints.logNstMicroPause())
            // Update stats
            if var stats = microPauseStats {
                microPauseStats = NstMicroPauseStats(completed: stats.completed + 1, target: stats.target)
            }
            await loadMicroPauseStats()
            isLoggingMicroPause = false
            return true
        } catch {
            isLoggingMicroPause = false
            return false
        }
    }
}
