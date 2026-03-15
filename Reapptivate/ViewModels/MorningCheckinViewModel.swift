import SwiftUI

@Observable
@MainActor
final class MorningCheckinViewModel {
    var painLevel: Int = 5
    var sleepQuality: Int? = nil
    var stiffnessLevel: Int? = nil
    var mood: Int? = nil
    var notes: String = ""
    var isSubmitting = false
    var errorMessage: String?

    private let apiClient: APIClient
    private weak var appState: AppState?

    init(apiClient: APIClient, appState: AppState) {
        self.apiClient = apiClient
        self.appState = appState
    }

    func submitCheckin() async -> Bool {
        isSubmitting = true
        errorMessage = nil

        let request = MorningCheckinRequest(
            painLevel: painLevel,
            sleepQuality: sleepQuality,
            stiffnessLevel: stiffnessLevel,
            mood: mood,
            notes: notes.isEmpty ? nil : notes
        )

        do {
            let _: MorningCheckin = try await apiClient.request(
                APIEndpoints.submitMorningCheckin(body: request)
            )
            appState?.hasCheckedInToday = true
            isSubmitting = false
            return true
        } catch {
            Log.api.error("Morning check-in failed: \(error.localizedDescription)")
            errorMessage = "Check-In fehlgeschlagen. Bitte versuche es erneut."
            isSubmitting = false
            return false
        }
    }
}
