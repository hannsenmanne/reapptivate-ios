import SwiftUI

@Observable
@MainActor
final class PhaseViewModel {
    var phaseStatus: AdaptivePhaseStatus?
    var phaseHistory: [PhaseAdaptationRecord] = []
    var isLoading = false
    var error: String?

    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func loadPhaseStatus() async {
        do {
            let response: PhaseStatusResponse = try await apiClient.request(APIEndpoints.phaseStatus())
            phaseStatus = response.phaseStatus
        } catch {
            self.error = "Phasenstatus konnte nicht geladen werden."
            Log.api.error("Failed to load phase status: \(error)")
        }
    }

    func loadPhaseHistory() async {
        isLoading = true
        do {
            let response: PhaseHistoryResponse = try await apiClient.request(APIEndpoints.phaseHistory())
            phaseHistory = response.history
        } catch {
            self.error = "Phasenverlauf konnte nicht geladen werden."
            Log.api.error("Failed to load phase history: \(error)")
        }
        isLoading = false
    }
}
