import SwiftUI

struct WorkTimerCard: View {
    @Environment(AppState.self) private var appState
    @Environment(APIClient.self) private var apiClient
    @Environment(\.scenePhase) private var scenePhase

    @State private var viewModel: WorkTimerViewModel?
    @State private var hapticStart = false
    @ScaledMetric(relativeTo: .title2) private var ringSize: CGFloat = 80

    var body: some View {
        if appState.isLbp || appState.isNeck || appState.isTension {
            Group {
                if let vm = viewModel {
                    if vm.isRunning {
                        activeTimerView(vm)
                    } else {
                        inactiveTimerView(vm)
                    }
                } else {
                    loadingView
                }
            }
            .conditionalHaptic(.impact(weight: .medium), trigger: hapticStart)
            .onChange(of: scenePhase) { _, phase in
                if phase == .active, let vm = viewModel {
                    vm.handleForegroundReturn()
                }
            }
            .onDisappear {
                NotificationDelegate.shared.onBreakComplete = nil
                NotificationDelegate.shared.onBreakSnooze = nil
                NotificationDelegate.shared.onBreakSkip = nil
            }
            .task {
                let vm = WorkTimerViewModel(apiClient: apiClient)
                viewModel = vm

                NotificationDelegate.shared.onBreakComplete = { [weak vm] in
                    guard let vm else { return }
                    if vm.isOnBreak {
                        Task { await vm.completeBreak() }
                    } else {
                        vm.triggerBreak()
                    }
                }
                NotificationDelegate.shared.onBreakSnooze = { [weak vm] in
                    guard let vm else { return }
                    if vm.isOnBreak {
                        vm.snoozeBreak()
                    }
                }
                NotificationDelegate.shared.onBreakSkip = { [weak vm] in
                    guard let vm else { return }
                    if vm.isOnBreak {
                        Task { await vm.skipBreak() }
                    }
                }

                vm.requestNotificationPermission()
                await vm.loadSettings()
                vm.restoreTimerState()
                await vm.loadExercises()
                vm.checkAutoStart()
            }
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        HStack(spacing: 12) {
            ProgressView()
            Text("Arbeits-Timer laden...")
                .font(.appSubheadline)
                .foregroundStyle(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
    }

    // MARK: - Inactive Timer

    private func inactiveTimerView(_ vm: WorkTimerViewModel) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "clock.badge.checkmark")
                    .font(.appTitle3)
                    .foregroundStyle(.accent)
                    .accessibilityHidden(true)

                Text("Arbeits-Timer")
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)

                Spacer()

                Button {
                    vm.showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.appBody)
                        .foregroundStyle(.textSecondary)
                }
                .accessibilityLabel("Einstellungen")
            }

            Text("Regelmäßige Pausen für weniger Beschwerden")
                .font(.appSubheadline)
                .foregroundStyle(.textSecondary)

            Button {
                vm.startWorkday()
                hapticStart.toggle()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                    Text("Arbeitstag starten")
                }
            }
            .buttonStyle(.accentFilled)
        }
        .cardStyle()
        .sheet(isPresented: Bindable(vm).showingSettings) {
            WorkTimerSettingsSheet(viewModel: vm)
        }
        .sheet(isPresented: Bindable(vm).showingSummary) {
            WorkTimerSummarySheet(viewModel: vm)
        }
    }

    // MARK: - Active Timer

    private func activeTimerView(_ vm: WorkTimerViewModel) -> some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "clock.badge.checkmark")
                    .font(.appTitle3)
                    .foregroundStyle(.accent)
                    .accessibilityHidden(true)

                Text("Arbeits-Timer")
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)

                Spacer()

                Button {
                    vm.showingHistory = true
                } label: {
                    Image(systemName: "chart.bar.fill")
                        .font(.appBody)
                        .foregroundStyle(.textSecondary)
                }
                .accessibilityLabel("Wochenverlauf")

                Text(vm.formattedWorkTime)
                    .font(.appCaptionMedium)
                    .foregroundStyle(.textSecondary)
            }

            // Countdown ring
            ZStack {
                Circle()
                    .stroke(Color.gray200, lineWidth: 6)
                    .frame(width: ringSize, height: ringSize)

                Circle()
                    .trim(from: 0, to: vm.progress)
                    .stroke(Color.accent, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: ringSize, height: ringSize)
                    .animation(.linear(duration: 1), value: vm.progress)

                VStack(spacing: 2) {
                    Text(vm.formattedTimeUntilBreak)
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundStyle(.textPrimary)
                    Text("bis zur Pause")
                        .font(.appCaption2)
                        .foregroundStyle(.textSecondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Nächste Pause in \(vm.formattedTimeUntilBreak)")
            }

            // Break count badge
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.painGreen)
                    .font(.appCaption)
                    .accessibilityHidden(true)
                Text("\(vm.breaksTakenToday) Pause\(vm.breaksTakenToday == 1 ? "" : "n") erledigt")
                    .font(.appCaptionMedium)
                    .foregroundStyle(.textSecondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.painGreen.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.badgeRadius, style: .continuous))

            Button {
                Task { await vm.stopWorkday() }
            } label: {
                Text("Arbeitstag beenden")
            }
            .buttonStyle(.secondary)
        }
        .accentCardStyle()
        .sheet(isPresented: Bindable(vm).showingBreak) {
            WorkTimerBreakView(viewModel: vm)
                .interactiveDismissDisabled()
        }
        .sheet(isPresented: Bindable(vm).showingSummary) {
            WorkTimerSummarySheet(viewModel: vm)
        }
        .sheet(isPresented: Bindable(vm).showingSettings) {
            WorkTimerSettingsSheet(viewModel: vm)
        }
        .sheet(isPresented: Bindable(vm).showingHistory) {
            WorkTimerHistoryView(viewModel: vm)
        }
    }
}
