import SwiftUI

struct AclDashboardView: View {
    @Environment(AppState.self) private var appState
    @Environment(APIClient.self) private var apiClient

    @State private var viewModel: AclDashboardViewModel?
    @State private var showDailyKpi = false
    @State private var showWeeklyKpi = false
    @State private var showTodayProgram = false
    @State private var todayProgramStreams: [String] = []
    @State private var showMilestoneCelebration = false
    @State private var celebrationHaptic = false
    var onNavigateToProgram: (() -> Void)?

    var body: some View {
        ZStack(alignment: .top) {
            Group {
                if let vm = viewModel, !vm.isLoading || vm.milestoneStatus != nil {
                    dashboardContent(vm: vm)
                } else {
                    AclDashboardSkeletonView()
                }
            }

            // Milestone Celebration Overlay
            if showMilestoneCelebration, let milestone = viewModel?.newMilestoneReached {
                AclMilestoneCelebrationView(
                    milestone: milestone,
                    onDismiss: {
                        withAnimation(.easeIn(duration: 0.2)) {
                            showMilestoneCelebration = false
                        }
                        viewModel?.milestoneAdvanced = false
                    }
                )
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(100)
            }
        }
        .sheet(isPresented: $showDailyKpi) {
            AclDailyKpiLoggerView(onSuccess: {
                Task { await viewModel?.loadAll() }
            })
            .glassSheet()
        }
        .sheet(isPresented: $showWeeklyKpi) {
            AclWeeklyKpiLoggerView(onSuccess: {
                Task { await viewModel?.loadAll() }
            })
            .glassSheet()
        }
        .fullScreenCover(isPresented: $showTodayProgram) {
            AclTodayProgramView(
                streamIds: todayProgramStreams,
                dayLabel: viewModel?.todaySchedule?.label ?? "",
                onComplete: {
                    Task { await viewModel?.loadAll() }
                }
            )
        }
        .conditionalHaptic(.success, trigger: celebrationHaptic)
        .task {
            if viewModel == nil {
                let vm = AclDashboardViewModel(apiClient: apiClient)
                viewModel = vm
                await vm.loadAll()
            }
        }
        .onChange(of: viewModel?.milestoneAdvanced) { _, newValue in
            if newValue == true {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    showMilestoneCelebration = true
                }
                celebrationHaptic.toggle()
            }
        }
    }

    @ViewBuilder
    private func dashboardContent(vm: AclDashboardViewModel) -> some View {
        VStack(spacing: 20) {
            // Error
            if let error = vm.errorMessage {
                InlineErrorView(
                    message: error,
                    errorType: .network,
                    onRetry: { Task { await vm.loadAll() } },
                    onDismiss: { vm.errorMessage = nil }
                )
                .cardEntryAnimation(index: 0)
            }

            // ACL Profile Card
            if let user = appState.currentUser {
                AclProfileQuickCard(
                    milestone: vm.currentMilestone,
                    weeksPostSurgery: vm.weeksPostSurgery,
                    graftType: user.aclGraftType
                )
                .cardEntryAnimation(index: 0)
            }

            // Streak
            if let streak = vm.streak, streak.currentStreak > 0 || streak.longestStreak > 0 {
                StreakCard(streak: streak)
                    .cardEntryAnimation(index: 1)
            }

            // Today's Program Card
            AclTodayProgramCard(
                todayLabel: vm.todaySchedule?.label ?? "",
                streamIds: vm.todayStreamIds,
                completedCount: vm.todayCompletedCount,
                totalCount: vm.todayTotalCount,
                isRestDay: vm.isRestDay,
                onTap: {
                    todayProgramStreams = vm.todayStreamIds
                    showTodayProgram = true
                }
            )
            .cardEntryAnimation(index: 2)

            // Weekly Schedule Card
            AclWeeklyScheduleCard(
                weeksPostSurgery: vm.weeksPostSurgery,
                onStartTodayProgram: { streams in
                    todayProgramStreams = streams
                    showTodayProgram = true
                }
            )
            .cardEntryAnimation(index: 3)

            // Daily Tip
            if let tip = vm.dailyTip {
                AclDailyTipCard(tip: tip)
                    .cardEntryAnimation(index: 4)
            }

            // KPI Quick Actions
            AclKpiQuickActionsCard(
                onDailyKpi: { showDailyKpi = true },
                onWeeklyKpi: { showWeeklyKpi = true }
            )
            .cardEntryAnimation(index: 5)

            // Milestone Timeline
            AclMilestoneTimelineView(
                currentMilestone: vm.currentMilestone,
                weeksPostSurgery: vm.weeksPostSurgery
            )
            .cardEntryAnimation(index: 6)

            // Milestone Criteria (next targets)
            if let criteria = vm.milestoneStatus?.nextCriteria, !criteria.isEmpty {
                AclNextCriteriaCard(
                    milestone: vm.currentMilestone,
                    criteria: criteria
                )
                .cardEntryAnimation(index: 7)
            }

            // Active Streams Quick Access
            if !vm.unlockedStreams.isEmpty {
                AclActiveStreamsCard(
                    streams: vm.unlockedStreams,
                    onViewAll: { onNavigateToProgram?() }
                )
                .cardEntryAnimation(index: 8)
            }

            // Discharge Progress (milestone 4+)
            if vm.currentMilestone >= 4, let discharge = vm.dischargeProgress {
                AclDischargeQuickCard(progress: discharge)
                    .cardEntryAnimation(index: 9)
            }
        }
        .padding(.bottom, 32)
    }
}

// MARK: - ACL Profile Quick Card

struct AclProfileQuickCard: View {
    let milestone: Int
    let weeksPostSurgery: Int
    let graftType: AclGraftType?
    @AppStorage("appLanguage") private var appLanguage = "de"

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
        ], spacing: 12) {
            StatCard(
                label: "Meilenstein",
                value: "\(milestone)/5"
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Meilenstein \(milestone) von 5")

            StatCard(
                label: "Wochen post-OP",
                value: "\(weeksPostSurgery)"
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(appLanguage == "en"
                ? "\(weeksPostSurgery) week\(weeksPostSurgery == 1 ? "" : "s") post surgery"
                : "\(weeksPostSurgery) Wochen nach Operation")

            StatCard(
                label: "Transplantat",
                value: graftType?.shortName ?? "---",
                isCompact: true
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Transplantat: \(graftType?.displayName ?? "nicht angegeben")")
        }
    }
}

// MARK: - Next Criteria Card

struct AclNextCriteriaCard: View {
    let milestone: Int
    let criteria: [AclMilestoneCriterion]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Nächste Ziele")
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)

                Spacer()

                Text("M\(milestone + 1)")
                    .font(.appCaptionMedium)
                    .foregroundStyle(.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accent.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.badgeRadius, style: .continuous))
            }

            ForEach(criteria) { criterion in
                HStack(spacing: 10) {
                    Image(systemName: criterion.met == true ? "checkmark.circle.fill" : "circle")
                        .font(.appSubheadline)
                        .foregroundStyle(criterion.met == true ? .painGreen : .textSecondary)

                    Text(criterion.labelDE ?? criterion.label ?? criterion.id)
                        .font(.appSubheadline)
                        .foregroundStyle(.textPrimary)

                    Spacer()

                    if let current = criterion.currentValue, let threshold = criterion.threshold {
                        Text("\(Int(current))/\(Int(threshold))\(criterion.unit ?? "")")
                            .font(.appCaptionMedium)
                            .foregroundStyle(criterion.met == true ? .painGreen : .textSecondary)
                    }
                }
            }
        }
        .cardStyle()
    }
}

// MARK: - Active Streams Card

struct AclActiveStreamsCard: View {
    let streams: [AclStream]
    let onViewAll: () -> Void
    @AppStorage("appLanguage") private var appLanguage = "de"

    @ScaledMetric(relativeTo: .body) private var streamIconSize: CGFloat = 32

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Aktive Streams")
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)

                Spacer()

                Button(action: onViewAll) {
                    Text("Alle anzeigen")
                        .font(.appCaptionMedium)
                        .foregroundStyle(.accent)
                }
                .accessibilityLabel("Alle Streams anzeigen")
            }

            ForEach(streams.prefix(4)) { stream in
                HStack(spacing: 12) {
                    Image(systemName: aclStreamIcon(for: stream.id))
                        .font(.appSubheadline)
                        .foregroundStyle(.accent)
                        .frame(width: streamIconSize, height: streamIconSize)
                        .background(Color.accent.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.iconRadius, style: .continuous))
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(stream.nameDE ?? stream.name)
                            .font(.appSubheadlineMedium)
                            .foregroundStyle(.textPrimary)
                        Text(appLanguage == "en"
                            ? "\(stream.exerciseCount ?? 0) exercise\((stream.exerciseCount ?? 0) == 1 ? "" : "s")"
                            : "\(stream.exerciseCount ?? 0) Übungen")
                            .font(.appCaption)
                            .foregroundStyle(.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                        .accessibilityHidden(true)
                }
            }
        }
        .cardStyle()
    }
}

// MARK: - Discharge Quick Card

struct AclDischargeQuickCard: View {
    let progress: AclDischargeProgress

    private var progressColor: Color {
        if progress.overallPercent >= 85 { return .painGreen }
        if progress.overallPercent >= 70 { return .painAmber }
        return .painRed
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Entlassungskriterien")
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)

                Spacer()

                Text("\(progress.overallPercent)%")
                    .font(.appTitle2)
                    .foregroundStyle(progressColor)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: DesignTokens.progressBarRadius)
                        .fill(Color.textSecondary.opacity(0.15))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: DesignTokens.progressBarRadius)
                        .fill(progressColor)
                        .frame(
                            width: geo.size.width * CGFloat(min(100, progress.overallPercent)) / 100,
                            height: 6
                        )
                }
            }
            .frame(height: 6)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Fortschritt")
            .accessibilityValue("\(progress.overallPercent) Prozent")

            Text("\(progress.metCount) von \(progress.totalCount) Kriterien erfüllt")
                .font(.appCaption)
                .foregroundStyle(.textSecondary)
        }
        .cardStyle()
    }
}

// MARK: - KPI Quick Actions Card

struct AclKpiQuickActionsCard: View {
    let onDailyKpi: () -> Void
    let onWeeklyKpi: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("KPIs erfassen")
                .font(.appHeadline)
                .foregroundStyle(.textPrimary)

            HStack(spacing: 12) {
                Button(action: onDailyKpi) {
                    HStack(spacing: 8) {
                        Image(systemName: "heart.text.clipboard")
                            .font(.appSubheadline)
                        Text("Tägliche KPIs")
                            .font(.appSubheadlineMedium)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                }
                .buttonStyle(.secondary)
                .accessibilityLabel("Tägliche KPIs erfassen")

                Button(action: onWeeklyKpi) {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.appSubheadline)
                        Text("Wöchentliche KPIs")
                            .font(.appSubheadlineMedium)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                }
                .buttonStyle(.secondary)
                .accessibilityLabel("Wöchentliche KPIs erfassen")
            }
        }
        .cardStyle()
    }
}

// MARK: - Skeleton

struct AclDashboardSkeletonView: View {
    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 12) {
                SkeletonView(variant: .card(height: 60))
                SkeletonView(variant: .card(height: 60))
                SkeletonView(variant: .card(height: 60))
            }
            SkeletonView(variant: .card(height: 100))
            SkeletonView(variant: .card(height: 120))
            SkeletonView(variant: .card(height: 80))
        }
        .padding(.bottom, 32)
    }
}

// AclStreakCard removed — use shared StreakCard from OverviewTab.swift

// MARK: - Daily Tip Card

private struct AclDailyTipCard: View {
    let tip: AclDailyTip

    @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 32

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "lightbulb.fill")
                    .font(.appSubheadline)
                    .foregroundStyle(.painAmber)
                    .frame(width: iconSize, height: iconSize)
                    .background(Color.painAmber.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.iconRadius, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Tipp des Tages")
                        .font(.appSubheadlineMedium)
                        .foregroundStyle(.textPrimary)

                    HStack(spacing: 4) {
                        Image(systemName: aclStreamIcon(for: tip.stream))
                            .font(.appCaption2)
                            .foregroundStyle(.accent)
                        Text(tip.streamLabel)
                            .font(.appCaption)
                            .foregroundStyle(.textSecondary)
                    }
                }

                Spacer()
            }

            Text(tip.tip)
                .font(.appSubheadline)
                .foregroundStyle(.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .cardStyle()
    }
}

// MARK: - AclGraftType Extension

extension AclGraftType {
    var shortName: String {
        switch self {
        case .hamstring: "Hamstring"
        case .patellarTendon: "BTB"
        case .quadriceps: "Quadrizeps"
        case .unknown: "---"
        }
    }
}
