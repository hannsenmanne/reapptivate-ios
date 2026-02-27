import SwiftUI

struct SmartDayGateView<Fallback: View>: View {
    @Environment(APIClient.self) private var apiClient
    @Environment(AppState.self) private var appState
    @State private var viewModel: SmartDayViewModel?

    let fallback: () -> Fallback

    init(@ViewBuilder fallback: @escaping () -> Fallback) {
        self.fallback = fallback
    }

    var body: some View {
        Group {
            if let vm = viewModel {
                if !vm.isApiAvailable {
                    // API not available — show existing overview content
                    fallback()
                } else if vm.isLoading {
                    ProgressView("Tagesstatus laden...")
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if !vm.hasCheckedIn {
                    MorningCheckinView {
                        Task { await vm.onCheckinComplete() }
                    }
                } else {
                    SmartDayView(smartDay: vm.smartDayData)
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
