import SwiftUI

@Observable
@MainActor
final class AppState {
    var isAuthenticated = false
    var currentUser: UserProfile?
    var isCheckingAuth = true
    var isLoading = false

    /// Called during logout to clear caches (set by ReapptivateApp)
    var onLogout: (() -> Void)?

    var isLbp: Bool {
        currentUser?.tendinopathyType == .lbpNonspecific
    }

    var isNeck: Bool {
        currentUser?.tendinopathyType == .neckPain
    }

    var isTension: Bool {
        currentUser?.tendinopathyType == .neckShoulderTension
    }

    var needsAemScreening: Bool {
        isLbp && currentUser?.aemScreeningCompleted != true
    }

    var needsNeckScreening: Bool {
        isNeck && currentUser?.neckScreeningCompleted != true
    }

    var needsTsiScreening: Bool {
        isTension && currentUser?.tensionScreeningCompleted != true
    }

    func handleLogin(user: UserProfile) {
        currentUser = user
        isAuthenticated = true
    }

    func handleLogout() {
        currentUser = nil
        isAuthenticated = false
        WorkTimerViewModel.clearPersistedState()
        clearUserScopedDefaults()
        onLogout?()
    }

    /// Clears @AppStorage keys that are not scoped per user to prevent state bleeding between accounts.
    private func clearUserScopedDefaults() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "readEducationCardIds")
        defaults.removeObject(forKey: "rating_prompt_count")
        defaults.removeObject(forKey: "rating_last_prompt_date")
        defaults.removeObject(forKey: "hasCompletedFirstExercise")
    }

    /// Single consolidated logout path — clears tokens, resets API guard, and updates state.
    func performLogout(apiClient: APIClient) {
        TokenManager.shared.clearAll()
        apiClient.resetLogoutGuard()
        handleLogout()
    }
}
