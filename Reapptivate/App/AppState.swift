import SwiftUI

@Observable
final class AppState {
    var isAuthenticated = false
    var currentUser: UserProfile?
    var isCheckingAuth = true
    var isLoading = false

    var isLbp: Bool {
        currentUser?.tendinopathyType == .lbpNonspecific
    }

    var isNeck: Bool {
        currentUser?.tendinopathyType == .neckPain
    }

    var needsAemScreening: Bool {
        isLbp && currentUser?.aemScreeningCompleted != true
    }

    var needsNeckScreening: Bool {
        isNeck && currentUser?.neckScreeningCompleted != true
    }

    func handleLogin(user: UserProfile) {
        currentUser = user
        isAuthenticated = true
    }

    func handleLogout() {
        currentUser = nil
        isAuthenticated = false
    }
}
