import SwiftUI

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @Environment(APIClient.self) private var apiClient
    @State private var viewModel: DashboardViewModel?
    @State private var exerciseVM: ExerciseViewModel?
    @State private var phaseVM: PhaseViewModel?
    @State private var messagingVM: MessagingViewModel?
    @State private var selectedTab: DashboardTab = .overview
    @State private var showSettings = false
    @State private var showLogoutConfirmation = false
    @State private var milestoneService = MilestoneService()
    @State private var activeMilestone: Milestone?
    @State private var ratingService = RatingService()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab Bar
                DashboardTabBar(
                    selectedTab: $selectedTab,
                    showInsights: appState.isLbp || appState.isNeck || appState.isTension || appState.isAcl || appState.isShoulder || appState.isFrozenShoulder || appState.isLateralAnkleSprain,
                    unreadCount: messagingVM?.unreadCount ?? 0
                )

                // Tab Content
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
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    }
                }
                .refreshable {
                    await loadAll()
                }
            }
            .background(Color.appBg)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text(brandWordmark)
                        .font(.outfit(.bold, size: 18))
                        .fixedSize()
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                                .font(.appBody)
                        }
                        .accessibilityLabel("Einstellungen")

                        Menu {
                            if let user = appState.currentUser {
                                Text(user.name)
                                Text(user.tendinopathyType.displayName)
                                Divider()
                            }
                            Button("Abmelden", role: .destructive) {
                                showLogoutConfirmation = true
                            }
                        } label: {
                            Image(systemName: "person.circle")
                                .font(.appTitle3)
                        }
                        .accessibilityLabel("Profil und Abmelden")
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
            }
            .alert("Abmelden?", isPresented: $showLogoutConfirmation) {
                Button("Abbrechen", role: .cancel) { }
                Button("Abmelden", role: .destructive) {
                    appState.performLogout(apiClient: apiClient)
                }
            } message: {
                Text("Sie werden ausgeloggt und müssen sich erneut anmelden.")
            }
        }
        .task {
            await loadAll()
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
            if let messagingVM {
                MessagesTab(viewModel: messagingVM)
            } else {
                ProgressView("Nachrichten laden...")
                    .frame(maxWidth: .infinity, minHeight: 200)
            }
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

// MARK: - Tab Bar

struct DashboardTabBar: View {
    @Binding var selectedTab: DashboardTab
    let showInsights: Bool
    var unreadCount: Int = 0

    var tabs: [DashboardTab] {
        var result: [DashboardTab] = [.overview, .program, .edukation, .progress]
        if showInsights {
            result.append(.insights)
        }
        result.append(.messages)
        return result
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(tabs, id: \.self) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    } label: {
                        VStack(spacing: 8) {
                            HStack(spacing: 4) {
                                Text(tab.rawValue.uppercased())
                                    .font(.appCaptionMedium)
                                    .tracking(0.8)
                                    .foregroundStyle(selectedTab == tab ? .textPrimary : .textSecondary)

                                // Unread badge on messages tab
                                if tab == .messages && unreadCount > 0 {
                                    Text("\(unreadCount)")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.white)
                                        .frame(minWidth: 16, minHeight: 16)
                                        .background(Color.red)
                                        .clipShape(Circle())
                                }
                            }

                            Rectangle()
                                .frame(height: 2)
                                .foregroundStyle(selectedTab == tab ? .textPrimary : .clear)
                        }
                        .padding(.horizontal, 16)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
                }
            }
            .padding(.horizontal, 8)
        }
        .padding(.top, 8)
        .background(Color.appBg)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.gray200)
                .frame(height: 1)
        }
        .conditionalHaptic(.selection, trigger: selectedTab)
    }
}
