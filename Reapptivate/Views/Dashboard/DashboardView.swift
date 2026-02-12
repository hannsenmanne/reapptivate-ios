import SwiftUI

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @Environment(APIClient.self) private var apiClient
    @State private var viewModel: DashboardViewModel?
    @State private var selectedTab: DashboardTab = .overview

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab Bar
                DashboardTabBar(
                    selectedTab: $selectedTab,
                    showInsights: appState.isLbp
                )

                // Tab Content
                ScrollView {
                    Group {
                        switch selectedTab {
                        case .overview:
                            OverviewTab(viewModel: viewModel)
                        case .program:
                            ProgramTab()
                        case .progress:
                            ProgressTab(viewModel: viewModel)
                        case .insights:
                            InsightsTab()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
                .refreshable {
                    await viewModel?.refresh()
                }
            }
            .background(Color.appBg)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 8) {
                        Text("Reapptivate")
                            .font(.headline.bold())

                        if let user = appState.currentUser {
                            Text("Tag \(user.daysSinceStart)")
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.accent.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        if let user = appState.currentUser {
                            Text(user.name)
                            Text(user.tendinopathyType.displayName)
                            Divider()
                        }
                        Button("Abmelden", role: .destructive) {
                            let vm = AuthViewModel(apiClient: apiClient)
                            vm.logout(appState: appState)
                        }
                    } label: {
                        Image(systemName: "person.circle")
                            .font(.title3)
                    }
                }
            }
        }
        .task {
            let vm = DashboardViewModel(apiClient: apiClient)
            viewModel = vm
            await vm.loadDashboard()
        }
    }
}

// MARK: - Tab Bar

struct DashboardTabBar: View {
    @Binding var selectedTab: DashboardTab
    let showInsights: Bool

    var tabs: [DashboardTab] {
        var result: [DashboardTab] = [.overview, .program, .progress]
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
                            Text(tab.rawValue)
                                .font(.subheadline.weight(selectedTab == tab ? .semibold : .regular))
                                .foregroundStyle(selectedTab == tab ? .textPrimary : .textSecondary)

                            Rectangle()
                                .frame(height: 2)
                                .foregroundStyle(selectedTab == tab ? .accent : .clear)
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.horizontal, 8)
        }
        .padding(.top, 8)
        .background(Color.appBg)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }
}
