import SwiftUI

struct AclDashboardView: View {
    @Environment(AppState.self) private var appState
    @Environment(APIClient.self) private var apiClient

    @State private var viewModel: AclDashboardViewModel?
    var onNavigateToProgram: (() -> Void)?

    var body: some View {
        Group {
            if let vm = viewModel, !vm.isLoading || vm.milestoneStatus != nil {
                dashboardContent(vm: vm)
            } else {
                AclDashboardSkeletonView()
            }
        }
        .task {
            if viewModel == nil {
                let vm = AclDashboardViewModel(apiClient: apiClient)
                viewModel = vm
                await vm.loadAll()
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

            // Milestone Timeline
            AclMilestoneTimelineView(
                currentMilestone: vm.currentMilestone,
                weeksPostSurgery: vm.weeksPostSurgery
            )
            .cardEntryAnimation(index: 1)

            // Milestone Criteria (next targets)
            if let criteria = vm.milestoneStatus?.nextCriteria, !criteria.isEmpty {
                AclNextCriteriaCard(
                    milestone: vm.currentMilestone,
                    criteria: criteria
                )
                .cardEntryAnimation(index: 2)
            }

            // Active Streams Quick Access
            if !vm.unlockedStreams.isEmpty {
                AclActiveStreamsCard(
                    streams: vm.unlockedStreams,
                    onViewAll: { onNavigateToProgram?() }
                )
                .cardEntryAnimation(index: 3)
            }

            // Discharge Progress (milestone 4+)
            if vm.currentMilestone >= 4, let discharge = vm.dischargeProgress {
                AclDischargeQuickCard(progress: discharge)
                    .cardEntryAnimation(index: 4)
            }

            // Training Schedule
            TrainingScheduleCard()
                .cardEntryAnimation(index: 5)
        }
        .padding(.bottom, 32)
    }
}

// MARK: - ACL Profile Quick Card

struct AclProfileQuickCard: View {
    let milestone: Int
    let weeksPostSurgery: Int
    let graftType: AclGraftType?

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

            StatCard(
                label: "Wochen post-OP",
                value: "\(weeksPostSurgery)"
            )

            StatCard(
                label: "Transplantat",
                value: graftType?.shortName ?? "---",
                isCompact: true
            )
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
            }

            ForEach(streams.prefix(4)) { stream in
                HStack(spacing: 12) {
                    Image(systemName: streamIcon(for: stream.id))
                        .font(.appSubheadline)
                        .foregroundStyle(.accent)
                        .frame(width: 32, height: 32)
                        .background(Color.accent.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.iconRadius, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(stream.nameDE ?? stream.name)
                            .font(.appSubheadlineMedium)
                            .foregroundStyle(.textPrimary)
                        Text("\(stream.exerciseCount ?? 0) Übungen")
                            .font(.appCaption)
                            .foregroundStyle(.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
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

            Text("\(progress.metCount) von \(progress.totalCount) Kriterien erfüllt")
                .font(.appCaption)
                .foregroundStyle(.textSecondary)
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

// MARK: - Helpers

private func streamIcon(for streamId: String) -> String {
    switch streamId {
    case let id where id.contains("ROM"), let id where id.contains("CLINICAL"):
        "figure.walk"
    case let id where id.contains("STRENGTH"):
        "figure.strengthtraining.functional"
    case let id where id.contains("RUNNING"):
        "figure.run"
    case let id where id.contains("PLYO"), let id where id.contains("AGILITY"):
        "figure.jumprope"
    case let id where id.contains("BALANCE"), let id where id.contains("NEURO"):
        "figure.cooldown"
    case let id where id.contains("SPORT"):
        "sportscourt"
    default:
        "figure.strengthtraining.traditional"
    }
}

// MARK: - AclGraftType Extension

extension AclGraftType {
    var shortName: String {
        switch self {
        case .hamstring: "Hamstring"
        case .patellarTendon: "BTB"
        case .quadriceps: "Quadrizeps"
        }
    }
}
