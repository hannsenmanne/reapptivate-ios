import SwiftUI

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @Environment(APIClient.self) private var apiClient
    @State private var viewModel: DashboardViewModel?
    @State private var exerciseVM: ExerciseViewModel?
    @State private var phaseVM: PhaseViewModel?
    @State private var selectedTab: DashboardTab = .overview
    @State private var showSettings = false
    @State private var showLogoutConfirmation = false
    @State private var milestoneService = MilestoneService()
    @State private var activeMilestone: Milestone?
    @State private var ratingService = RatingService()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab Bar
                DashboardTabBar(
                    selectedTab: $selectedTab,
                    showInsights: true
                )

                // Tab Content
                ScrollView {
                    VStack(spacing: 0) {
                        if let error = viewModel?.error {
                            InlineErrorView(message: error) {
                                Task { await loadAll() }
                            }
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
    }

    // MARK: - Default Tab Content

    @ViewBuilder
    private var defaultTabContent: some View {
        switch selectedTab {
        case .overview:
            if viewModel == nil || (viewModel?.isLoading == true && viewModel?.progressStats == nil) {
                OverviewSkeletonView()
            } else {
                OverviewTab(
                    viewModel: viewModel,
                    completedTodayCount: viewModel?.completedToday.count ?? 0,
                    totalExerciseCount: exerciseVM?.exercises.count ?? 0,
                    onNavigateToProgram: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = .program
                        }
                    }
                )
            }
        case .program:
            ProgramTab(exerciseVM: exerciseVM, onExerciseLogged: {
                Task { await viewModel?.refresh() }
            })
        case .edukation:
            EdukationTab()
        case .progress:
            ProgressTab(
                viewModel: viewModel,
                phaseVM: phaseVM
            )
        case .insights:
            InsightsTab(viewModel: viewModel, phaseVM: phaseVM)
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
            exerciseVM?.loadExercises(for: user)
            exerciseVM?.updateCompletedToday(from: viewModel?.completedToday ?? [])
        }

        async let exerciseLoad: () = exerciseVM?.loadCustomExercises() ?? ()
        async let phaseLoad: () = phaseVM?.loadPhaseHistory() ?? ()
        _ = await (exerciseLoad, phaseLoad)

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

    var tabs: [DashboardTab] {
        var result: [DashboardTab] = [.overview, .program, .edukation, .progress]
        if showInsights {
            result.append(.insights)
        }
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
                            Text(tab.rawValue.uppercased())
                                .font(.appCaptionMedium)
                                .tracking(0.8)
                                .foregroundStyle(selectedTab == tab ? .textPrimary : .textSecondary)

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
