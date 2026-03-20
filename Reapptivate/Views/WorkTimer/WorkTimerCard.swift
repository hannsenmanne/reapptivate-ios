import SwiftUI

struct WorkTimerCard: View {
    @Environment(AppState.self) private var appState
    @Environment(APIClient.self) private var apiClient
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("appLanguage") private var appLanguage = "de"

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
            .task {
                let vm = WorkTimerViewModel(apiClient: apiClient)
                viewModel = vm

                NotificationDelegate.shared.onBreakComplete = { [weak vm] in
                    guard let vm, vm.isRunning else { return }
                    if !vm.isOnBreak { vm.triggerBreak(silent: true) }
                    Task { await vm.completeBreak() }
                }
                NotificationDelegate.shared.onBreakSnooze = { [weak vm] in
                    guard let vm, vm.isRunning else { return }
                    if !vm.isOnBreak { vm.triggerBreak(silent: true) }
                    vm.snoozeBreak()
                }
                NotificationDelegate.shared.onBreakSkip = { [weak vm] in
                    guard let vm, vm.isRunning else { return }
                    if !vm.isOnBreak { vm.triggerBreak(silent: true) }
                    Task { await vm.skipBreak() }
                }

                vm.patientCondition = appState.currentUser?.tendinopathyType.rawValue
                vm.patientPhase = appState.currentUser?.currentPhase ?? 1
                vm.requestNotificationPermission()
                await vm.loadSettings()
                vm.restoreTimerState()
                await vm.loadExercises()
                vm.checkAutoStart()
            }
        }
    }

    private var isEn: Bool { appLanguage == "en" }

    // MARK: - Loading

    private var loadingView: some View {
        HStack(spacing: 12) {
            ProgressView()
            Text(isEn ? "Loading work timer..." : "Arbeits-Timer laden...")
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

                Text(isEn ? "Work Timer" : "Arbeits-Timer")
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
                .accessibilityLabel(isEn ? "Settings" : "Einstellungen")
            }

            Text(isEn ? "Regular breaks for fewer symptoms" : "Regelmäßige Pausen für weniger Beschwerden")
                .font(.appSubheadline)
                .foregroundStyle(.textSecondary)

            Button {
                vm.startWorkday()
                hapticStart.toggle()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                    Text(isEn ? "Start workday" : "Arbeitstag starten")
                }
            }
            .buttonStyle(.accentFilled)
        }
        .cardStyle()
        .sheet(isPresented: Bindable(vm).showingSettings) {
            WorkTimerSettingsSheet(viewModel: vm)
                .glassSheet()
        }
        .sheet(isPresented: Bindable(vm).showingSummary) {
            WorkTimerSummarySheet(viewModel: vm)
                .glassSheet()
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

                Text(isEn ? "Work Timer" : "Arbeits-Timer")
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
                .accessibilityLabel(isEn ? "Weekly overview" : "Wochenverlauf")

                Text(vm.formattedWorkTime)
                    .font(.appCaptionMedium)
                    .foregroundStyle(.textSecondary)
            }

            // Countdown ring
            ZStack {
                Circle()
                    .stroke(Color.textSecondary.opacity(0.1), lineWidth: 6)
                    .frame(width: ringSize, height: ringSize)

                Circle()
                    .trim(from: 0, to: vm.progress)
                    .stroke(Color.accent.opacity(0.3), style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: ringSize, height: ringSize)
                    .blur(radius: 6)

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
                    Text(isEn ? "until break" : "bis zur Pause")
                        .font(.appCaption2)
                        .foregroundStyle(.textSecondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(isEn
                    ? "Next break in \(vm.formattedTimeUntilBreak)"
                    : "Nächste Pause in \(vm.formattedTimeUntilBreak)")
            }

            // Break count badge
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.painGreen)
                    .font(.appCaption)
                    .accessibilityHidden(true)
                Text(isEn
                    ? "\(vm.breaksTakenToday) break\(vm.breaksTakenToday == 1 ? "" : "s") completed"
                    : "\(vm.breaksTakenToday) Pause\(vm.breaksTakenToday == 1 ? "" : "n") erledigt")
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
                Text(isEn ? "End workday" : "Arbeitstag beenden")
            }
            .buttonStyle(.secondary)
        }
        .accentCardStyle()
        .sheet(isPresented: Bindable(vm).showingBreak) {
            WorkTimerBreakView(viewModel: vm)
                .interactiveDismissDisabled()
                .glassSheet()
                .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: Bindable(vm).showingSummary) {
            WorkTimerSummarySheet(viewModel: vm)
                .glassSheet()
        }
        .sheet(isPresented: Bindable(vm).showingSettings) {
            WorkTimerSettingsSheet(viewModel: vm)
                .glassSheet()
        }
        .sheet(isPresented: Bindable(vm).showingHistory) {
            WorkTimerHistoryView(viewModel: vm)
                .glassSheet()
        }
    }
}
