import SwiftUI
import UserNotifications

@Observable
@MainActor
final class AppState {
    var isAuthenticated = false
    var currentUser: UserProfile?
    var isCheckingAuth = true
    var isLoading = false
    var unreadMessageCount = 0

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

    var isAcl: Bool {
        currentUser?.tendinopathyType == .aclReconstruction
    }

    var isShoulder: Bool {
        currentUser?.tendinopathyType == .shoulderImpingement
    }

    var isFrozenShoulder: Bool {
        currentUser?.tendinopathyType == .frozenShoulder
    }

    var isLateralAnkleSprain: Bool {
        currentUser?.tendinopathyType == .lateralAnkleSprain
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

    var needsAclScreening: Bool {
        isAcl && currentUser?.aclScreeningCompleted != true
    }

    var needsShoulderScreening: Bool {
        isShoulder && currentUser?.siScreeningCompleted != true
    }

    var needsFsScreening: Bool {
        isFrozenShoulder && currentUser?.fsScreeningCompleted != true
    }

    var needsLasScreening: Bool {
        isLateralAnkleSprain && currentUser?.lasScreeningCompleted != true
    }

    func handleLogin(user: UserProfile) {
        currentUser = user
        isAuthenticated = true
    }

    func handleLogout() {
        currentUser = nil
        isAuthenticated = false
        unreadMessageCount = 0
        WorkTimerViewModel.clearPersistedState()
        ExerciseVideoStore.shared.deleteAllVideos()
        clearUserScopedDefaults()
        NotificationDelegate.shared.onBreakComplete = nil
        NotificationDelegate.shared.onBreakSnooze = nil
        NotificationDelegate.shared.onBreakSkip = nil
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
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
