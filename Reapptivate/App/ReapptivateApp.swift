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
    @Environment(NetworkMonitor.self) private var networkMonitor
    @Environment(\.modelContext) private var modelContext
    let apiClient: APIClient

    @State private var authViewModel: AuthViewModel?
    @State private var syncService: SyncService?

    var body: some View {
        Group {
            if appState.isCheckingAuth {
                LoadingView(message: "Laden...")
            } else if appState.isAuthenticated {
                if appState.needsAemScreening {
                    AemScreeningView(isEmbedded: true)
                } else if appState.needsNeckScreening {
                    NeckScreeningView(isRescreening: false, isEmbedded: true)
                } else {
                    DashboardView()
                }
            } else {
                LoginView(apiClient: apiClient)
            }
        }
        .task {
            // Initialize SyncService with ModelContext from environment
            if syncService == nil {
                let service = SyncService(apiClient: apiClient, networkMonitor: networkMonitor)
                service.setModelContext(modelContext)
                syncService = service
                appState.onLogout = {
                    service.clearAllData()
                }
            }

            let vm = AuthViewModel(apiClient: apiClient)
            authViewModel = vm
            apiClient.resetLogoutGuard()
            await vm.checkExistingAuth(appState: appState)
        }
        .onChange(of: networkMonitor.isConnected) { _, isConnected in
            if isConnected {
                Task { await syncService?.drainQueue() }
            }
        }
    }
}
