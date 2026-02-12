import SwiftUI
import SwiftData

@main
struct ReapptivateApp: App {
    @State private var appState = AppState()
    @State private var apiClient = APIClient()
    @State private var networkMonitor = NetworkMonitor()

    var body: some Scene {
        WindowGroup {
            RootView(apiClient: apiClient)
                .environment(appState)
                .environment(apiClient)
                .environment(networkMonitor)
                .onAppear {
                    apiClient.onTokenExpired = {
                        appState.handleLogout()
                    }
                }
        }
        .modelContainer(for: [
            CachedUser.self,
            CachedProgress.self,
            PendingSync.self
        ])
    }
}

struct RootView: View {
    @Environment(AppState.self) private var appState
    let apiClient: APIClient

    @State private var authViewModel: AuthViewModel?

    var body: some View {
        Group {
            if appState.isCheckingAuth {
                LoadingView(message: "Laden...")
            } else if appState.isAuthenticated {
                DashboardView()
            } else {
                LoginView(apiClient: apiClient)
            }
        }
        .task {
            let vm = AuthViewModel(apiClient: apiClient)
            authViewModel = vm
            await vm.checkExistingAuth(appState: appState)
        }
    }
}
