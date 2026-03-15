import SwiftUI

@Observable
@MainActor
final class SmartDayViewModel {
    var smartDayData: SmartDayResponse?
    var hasCheckedIn = false
    var isLoading = true
    var errorMessage: String?
    var isApiAvailable = true

    private let apiClient: APIClient
    private weak var appState: AppState?

    init(apiClient: APIClient, appState: AppState) {
        self.apiClient = apiClient
        self.appState = appState
        // Preserve check-in state from AppState so tab switches don't re-show the check-in
        self.hasCheckedIn = appState.hasCheckedInToday
    }

    func checkTodayStatus() async {
        isLoading = true
        errorMessage = nil

        // Already checked in this session — skip the check-in API, load smart day directly
        if hasCheckedIn {
            await loadSmartDay()
            return
        }

        do {
            let response: CheckinTodayResponse = try await apiClient.request(
                APIEndpoints.morningCheckinToday()
            )
            hasCheckedIn = response.checkedIn
            appState?.hasCheckedInToday = response.checkedIn

            if response.checkedIn {
                await loadSmartDay()
            } else {
                isLoading = false
            }
        } catch {
            Log.api.error("Check-in today status failed: \(error.localizedDescription)")
            isApiAvailable = false
            isLoading = false
        }
    }

    func loadSmartDay() async {
        do {
            let response: SmartDayResponse = try await apiClient.request(
                APIEndpoints.smartDay()
            )
            smartDayData = response
            isLoading = false
        } catch {
            Log.api.error("Smart day load failed: \(error.localizedDescription)")
            isApiAvailable = false
            isLoading = false
        }
    }

    func onCheckinComplete() async {
        hasCheckedIn = true
        appState?.hasCheckedInToday = true
        await loadSmartDay()
    }
}
