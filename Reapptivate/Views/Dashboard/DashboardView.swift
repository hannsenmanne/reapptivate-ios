import SwiftUI

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @Environment(APIClient.self) private var apiClient
    @Environment(LanguageManager.self) private var languageManager
    @AppStorage("appLanguage") private var appLanguage = "de"
    @State private var viewModel: DashboardViewModel?
    @State private var exerciseVM: ExerciseViewModel?
    @State private var phaseVM: PhaseViewModel?
    @State private var messagingVM: MessagingViewModel?
    @State private var selectedTab: DashboardTab = .overview
    @State private var showSettings = false
    @State private var showMessages = false
    @State private var showLogoutConfirmation = false
    @State private var milestoneService = MilestoneService()
    @State private var activeMilestone: Milestone?
    @State private var ratingService = RatingService()
    @Environment(\.scenePhase) private var scenePhase

    private var isEn: Bool { appLanguage == "en" }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    if let error = viewModel?.error {
                        InlineErrorView(
                            message: error,
                            errorType: .network,
                            onRetry: {
                                Task { await loadAll() }
                            },
                            onDismiss: {
                                viewModel?.error = nil
                            }
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                    }

                    Group {
                        defaultTabContent
                    }
                    .animation(.easeOut(duration: 0.15), value: selectedTab)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            }
            .refreshable {
                await loadAll()
            }
            .safeAreaInset(edge: .bottom) {
                FloatingTabBar(
                    selectedTab: $selectedTab,
                    showInsights: appState.isLbp || appState.isNeck || appState.isTension || appState.isAcl || appState.isShoulder || appState.isFrozenShoulder || appState.isLateralAnkleSprain
                )
                .padding(.bottom, 4)
            }
            .appBackground()
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text(brandWordmark)
                        .font(.outfit(.bold, size: 18))
                        .fixedSize()
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            guard messagingVM != nil else { return }
                            showMessages = true
                        } label: {
                            Image(systemName: "bubble.left.and.bubble.right")
                                .font(.appBody)
                                .overlay(alignment: .topTrailing) {
                                    if appState.unreadMessageCount > 0 {
                                        Text("\(min(appState.unreadMessageCount, 99))")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundStyle(.white)
                                            .frame(minWidth: 15, minHeight: 15)
                                            .background(Color.red)
                                            .clipShape(Circle())
                                            .offset(x: 8, y: -8)
                                    }
                                }
                        }
                        .accessibilityLabel(isEn ? "Messages" : "Nachrichten")
                        .accessibilityValue(
                            appState.unreadMessageCount > 0
                                ? "\(appState.unreadMessageCount) \(isEn ? "unread" : "ungelesen")"
                                : ""
                        )

                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                                .font(.appBody)
                        }
                        .accessibilityLabel(isEn ? "Settings" : "Einstellungen")

                        Menu {
                            if let user = appState.currentUser {
                                Text(user.name)
                                Text(user.tendinopathyType.displayName)
                                Divider()
                            }
                            Button(isEn ? "Log out" : "Abmelden", role: .destructive) {
                                showLogoutConfirmation = true
                            }
                        } label: {
                            Image(systemName: "person.circle")
                                .font(.appTitle3)
                        }
                        .accessibilityLabel(isEn ? "Profile and log out" : "Profil und Abmelden")
                    }
                }
            }
            .overlay {
                if let milestone = activeMilestone {
                    MilestoneAlert(milestone: milestone) {
                        milestoneService.markShown(milestone)
                        activeMilestone = nil
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environment(languageManager)
                    .glassSheet()
            }
            .fullScreenCover(isPresented: $showMessages) {
                if let messagingVM {
                    MessagesTab(viewModel: messagingVM)
                        .environment(appState)
                        .environment(apiClient)
                        .environment(languageManager)
                } else {
                    ProgressView(isEn ? "Loading messages..." : "Nachrichten laden...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.appBg)
                }
            }
            .alert(isEn ? "Log out?" : "Abmelden?", isPresented: $showLogoutConfirmation) {
                Button(isEn ? "Cancel" : "Abbrechen", role: .cancel) { }
                Button(isEn ? "Log out" : "Abmelden", role: .destructive) {
                    appState.performLogout(apiClient: apiClient)
                }
            } message: {
                Text(isEn ? "You will be logged out and need to sign in again." : "Sie werden ausgeloggt und müssen sich erneut anmelden.")
            }
        }
        .task {
            await loadAll()
        }
        .onChange(of: languageManager.language) { _, _ in
            // Only exercise data needs reloading — protocol JSON files have language variants.
            // View strings use @AppStorage ternaries and update reactively.
            // API data (phase status, progress stats, schedule) is language-independent.
            if let user = appState.currentUser {
                exerciseVM?.loadExercises(for: user, trainingDays: viewModel?.scheduleResponse?.iosWeekdays)
            }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                messagingVM?.startUnreadPolling()
            case .background, .inactive:
                messagingVM?.stopPolling()
            @unknown default:
                break
            }
        }
    }

    // MARK: - Default Tab Content

    @ViewBuilder
    private var defaultTabContent: some View {
        switch selectedTab {
        case .overview:
            if appState.isAcl {
                AclDashboardView(
                    onNavigateToProgram: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = .program
                        }
                    }
                )
            } else if viewModel == nil || (viewModel?.isLoading == true && viewModel?.progressStats == nil) {
                OverviewSkeletonView()
            } else {
                OverviewTab(
                    viewModel: viewModel,
                    exerciseVM: exerciseVM,
                    streak: viewModel?.streak,
                    onNavigateToProgram: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = .program
                        }
                    }
                )
            }
        case .program:
            if appState.isAcl {
                AclStreamOverviewView()
            } else {
                ProgramTab(exerciseVM: exerciseVM, onExerciseLogged: {
                    Task { await viewModel?.refresh() }
                })
            }
        case .edukation:
            EdukationTab()
        case .progress:
            if appState.isAcl {
                VStack(spacing: 20) {
                    AclDischargeProgressView()
                    AclKpiHistoryView()
                }
            } else {
                ProgressTab(
                    viewModel: viewModel,
                    phaseVM: phaseVM
                )
            }
        case .insights:
            InsightsTab(viewModel: viewModel, phaseVM: phaseVM)
        case .messages:
            EmptyView()
        }
    }

    private var brandWordmark: AttributedString {
        var re = AttributedString("re")
        re.foregroundColor = UIColor(.textPrimary)
        var app = AttributedString("app")
        app.foregroundColor = UIColor(.accent)
        var tivate = AttributedString("tivate")
        tivate.foregroundColor = UIColor(.textPrimary)
        return re + app + tivate
    }

    private func loadAll() async {
        // Messaging VM (available for all conditions)
        if messagingVM == nil {
            messagingVM = MessagingViewModel(apiClient: apiClient, appState: appState)
            messagingVM?.startUnreadPolling()
        }

        // ACL patients use their own dashboard views with separate data loading
        guard !appState.isAcl else { return }

        // Dashboard VM (must load first — provides completedToday for exerciseVM)
        if viewModel == nil {
            viewModel = DashboardViewModel(apiClient: apiClient, appState: appState)
        }
        await viewModel?.loadDashboard()

        // Exercise + Phase VMs can load in parallel
        if exerciseVM == nil {
            exerciseVM = ExerciseViewModel(apiClient: apiClient)
        }
        if phaseVM == nil {
            phaseVM = PhaseViewModel(apiClient: apiClient)
        }

        if let user = appState.currentUser {
            exerciseVM?.loadExercises(for: user, trainingDays: viewModel?.scheduleResponse?.iosWeekdays)
            exerciseVM?.updateCompletedToday(from: viewModel?.completedToday ?? [])
        }

        async let exerciseLoad: () = exerciseVM?.loadCustomExercises() ?? ()
        async let phaseLoad: () = phaseVM?.loadPhaseHistory() ?? ()
        _ = await (exerciseLoad, phaseLoad)

        // Configure milestone service with current user ID
        if let user = appState.currentUser {
            milestoneService.configure(userId: user.id)
            milestoneService.seedExistingIfNeeded(
                totalSessions: viewModel?.progressStats?.totalSessions ?? 0,
                currentPhase: viewModel?.phaseStatus?.currentPhase ?? 1,
                maxPhase: user.maxPhase
            )
        }

        // Check milestones
        checkMilestones()

        // Check App Store rating prompt
        ratingService.checkAndPrompt(
            totalSessions: viewModel?.progressStats?.totalSessions ?? 0,
            compliancePercent: viewModel?.progressStats?.compliancePercent ?? 0
        )
    }

    private func checkMilestones() {
        guard activeMilestone == nil else { return }
        activeMilestone = milestoneService.check(
            totalSessions: viewModel?.progressStats?.totalSessions ?? 0,
            currentPhase: viewModel?.phaseStatus?.currentPhase ?? 1,
            maxPhase: appState.currentUser?.maxPhase ?? 3
        )
    }
}

