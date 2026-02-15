import SwiftUI
import SwiftData

@main
struct ReapptivateApp: App {
    @State private var appState = AppState()
    @State private var apiClient = APIClient()
    @State private var networkMonitor = NetworkMonitor()
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true

    var body: some Scene {
        WindowGroup {
            RootView(apiClient: apiClient)
                .environment(appState)
                .environment(apiClient)
                .environment(networkMonitor)
                .environment(\.hapticsEnabled, hapticsEnabled)
                .preferredColorScheme(appearanceMode.colorScheme)
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
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false
    @AppStorage("hasSeenWalkthrough") private var hasSeenWalkthrough = false

    var body: some View {
        Group {
            if appState.isCheckingAuth {
                LoadingView(message: "Laden...")
            } else if appState.isAuthenticated {
                if appState.needsAemScreening {
                    AemScreeningView(isEmbedded: true)
                } else if appState.needsNeckScreening {
                    NeckScreeningView(isRescreening: false, isEmbedded: true)
                } else if appState.needsNeckShoulderScreening {
                    NeckShoulderScreeningView(isEmbedded: true)
                } else if !hasSeenWelcome {
                    ScreeningCompleteView()
                } else if !hasSeenWalkthrough {
                    FeatureWalkthroughView()
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
                appState.onLogout = { [self] in
                    service.clearAllData()
                    hasSeenWelcome = false
                    hasSeenWalkthrough = false

                    // Clear all user-specific AppStorage keys
                    let defaults = UserDefaults.standard
                    defaults.removeObject(forKey: "hasCompletedFirstExercise")
                    defaults.removeObject(forKey: "milestones_shown")
                    defaults.removeObject(forKey: "milestones_dates")

                    // Clear all coachmark keys (dynamically keyed)
                    for key in defaults.dictionaryRepresentation().keys where key.hasPrefix("coachmark_") {
                        defaults.removeObject(forKey: key)
                    }
                }
            }

            if authViewModel == nil {
                authViewModel = AuthViewModel(apiClient: apiClient)
            }
            apiClient.resetLogoutGuard()
            await authViewModel?.checkExistingAuth(appState: appState)
        }
        .onChange(of: networkMonitor.isConnected) { _, isConnected in
            if isConnected {
                Task { await syncService?.drainQueue() }
            }
        }
    }
}

// MARK: - Appearance Mode

enum AppearanceMode: String, CaseIterable {
    case system, light, dark

    var label: String {
        switch self {
        case .system: "System"
        case .light: "Hell"
        case .dark: "Dunkel"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
