import SwiftUI
import SwiftData
import UserNotifications

@main
struct ReapptivateApp: App {
    @State private var appState = AppState()
    @State private var apiClient = APIClient()
    @State private var networkMonitor = NetworkMonitor()
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true

    init() {
        registerNotificationCategories()
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    var body: some Scene {
        WindowGroup {
            RootView(apiClient: apiClient)
                .environment(appState)
                .environment(apiClient)
                .environment(networkMonitor)
                .environment(\.hapticsEnabled, hapticsEnabled)
                .preferredColorScheme(appearanceMode.colorScheme)
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
                } else if appState.needsTsiScreening {
                    TsiScreeningView(isRescreening: false, isEmbedded: true)
                } else if appState.needsAclScreening {
                    AclScreeningView(isEmbedded: true)
                } else if appState.needsShoulderScreening {
                    SiScreeningView(isRescreening: false, isEmbedded: true)
                } else if appState.needsFsScreening {
                    FsScreeningView(isRescreening: false)
                } else if appState.needsLasScreening {
                    LasScreeningView(isRescreening: false)
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
            // Set up token-expired callback before any API calls to avoid race condition
            apiClient.onTokenExpired = { [apiClient] in
                appState.performLogout(apiClient: apiClient)
            }

            // Initialize SyncService with ModelContext from environment
            if syncService == nil {
                let service = SyncService(
                    apiClient: apiClient,
                    networkMonitor: networkMonitor,
                    modelContext: modelContext
                )
                syncService = service
                appState.onLogout = {
                    service.clearAllData()
                }
            }

            if authViewModel == nil {
                authViewModel = AuthViewModel(apiClient: apiClient)
            }
            apiClient.resetLogoutGuard()
            await authViewModel?.checkExistingAuth(appState: appState)
        }
    }
}

// MARK: - Notification Categories

private extension ReapptivateApp {
    func registerNotificationCategories() {
        let completeAction = UNNotificationAction(
            identifier: "COMPLETE_BREAK",
            title: "Erledigt",
            options: .foreground
        )
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_BREAK",
            title: "Später (5 Min.)",
            options: []
        )
        let skipAction = UNNotificationAction(
            identifier: "SKIP_BREAK",
            title: "Überspringen",
            options: .destructive
        )
        let breakCategory = UNNotificationCategory(
            identifier: "WORK_TIMER_BREAK",
            actions: [completeAction, snoozeAction, skipAction],
            intentIdentifiers: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([breakCategory])
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
