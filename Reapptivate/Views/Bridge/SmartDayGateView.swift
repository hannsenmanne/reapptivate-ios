import SwiftUI

struct SmartDayGateView<Fallback: View>: View {
    @Environment(APIClient.self) private var apiClient
    @Environment(AppState.self) private var appState
    @State private var viewModel: SmartDayViewModel?

    let completedCount: Int
    let totalCount: Int
    let onNavigateToProgram: (() -> Void)?
    let fallback: () -> Fallback

    init(
        completedCount: Int = 0,
        totalCount: Int = 0,
        onNavigateToProgram: (() -> Void)? = nil,
        @ViewBuilder fallback: @escaping () -> Fallback
    ) {
        self.completedCount = completedCount
        self.totalCount = totalCount
        self.onNavigateToProgram = onNavigateToProgram
        self.fallback = fallback
    }

    var body: some View {
        Group {
            if let vm = viewModel {
                if !vm.isApiAvailable {
                    fallback()
                } else if vm.isLoading {
                    ProgressView("Tagesstatus laden...")
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if !vm.hasCheckedIn {
                    MorningCheckinView {
                        Task { await vm.onCheckinComplete() }
                    }
                } else {
                    SmartDayView(
                        smartDay: vm.smartDayData,
                        completedCount: completedCount,
                        totalCount: totalCount,
                        onNavigateToProgram: onNavigateToProgram
                    )
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 200)
            }
        }
        .task {
            if viewModel == nil {
                let vm = SmartDayViewModel(apiClient: apiClient, appState: appState)
                viewModel = vm
                await vm.checkTodayStatus()
            }
        }
    }
}
