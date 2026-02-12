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
            phaseStatus = try await apiClient.request(APIEndpoints.phaseStatus())
        } catch {
            Log.api.error("Failed to load phase status: \(error)")
        }
    }

    func loadPhaseHistory() async {
        isLoading = true
        do {
            phaseHistory = try await apiClient.request(APIEndpoints.phaseHistory())
        } catch {
            self.error = "Phasenverlauf konnte nicht geladen werden."
            Log.api.error("Failed to load phase history: \(error)")
        }
        isLoading = false
    }
}
