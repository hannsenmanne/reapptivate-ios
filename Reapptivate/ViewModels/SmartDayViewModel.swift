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
    }

    func checkTodayStatus() async {
        isLoading = true
        errorMessage = nil

        do {
            let response: CheckinTodayResponse = try await apiClient.request(
                APIEndpoints.morningCheckinToday()
            )
            hasCheckedIn = response.checkedIn

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
        await loadSmartDay()
    }
}
