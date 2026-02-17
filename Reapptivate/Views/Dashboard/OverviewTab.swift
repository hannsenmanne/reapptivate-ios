import SwiftUI

struct OverviewTab: View {
    @Environment(AppState.self) private var appState
    @Environment(APIClient.self) private var apiClient
    let viewModel: DashboardViewModel?
    var completedTodayCount: Int = 0
    var totalExerciseCount: Int = 0
    var onNavigateToProgram: (() -> Void)?

    @State private var todaysQuote: MotivationalQuote?

    var body: some View {
        VStack(spacing: 20) {
            // Stats Row
            if let user = appState.currentUser {
                StatsRow(user: user, phaseStatus: viewModel?.phaseStatus, stats: viewModel?.progressStats)
                    .cardEntryAnimation(index: 0)
            }

            // Motivational Quote
            if let quote = todaysQuote {
                MotivationalQuoteCard(quote: quote)
                    .cardEntryAnimation(index: 1)
            }

            // Welcome Card (new patients)
            if viewModel?.progressStats?.totalSessions == 0 {
                WelcomeCard()
                    .cardEntryAnimation(index: 2)
            }

            // Today's Plan
            if viewModel?.isRestDay != true && totalExerciseCount > 0 {
                TodaysPlanCard(
                    completedCount: completedTodayCount,
                    totalCount: totalExerciseCount,
                    onTap: { onNavigateToProgram?() }
                )
                .cardEntryAnimation(index: 3)
            }

            // Rest Day Card
            if viewModel?.isRestDay == true {
                RestDayCard()
                    .cardEntryAnimation(index: 3)
            }

            // Phase Status
            if let phaseStatus = viewModel?.phaseStatus {
                PhaseStatusQuickCard(status: phaseStatus)
                    .cardEntryAnimation(index: 4)
            }

            // Exercise Link
            ExerciseLinkCard(onTap: { onNavigateToProgram?() })
                .cardEntryAnimation(index: 5)

            // Training Schedule
            TrainingScheduleCard()
                .cardEntryAnimation(index: 6)

            // Compliance Calendar
            if let entries = viewModel?.recentEntries, !entries.isEmpty {
                ComplianceCalendarCard(entries: entries)
                    .cardEntryAnimation(index: 7)
            }

            // Wissen
            if let user = appState.currentUser {
                WissenCardView(
                    phase: user.currentPhase,
                    isLbp: appState.isLbp,
                    isNeck: appState.isNeck,
                    isTension: appState.isTension
                )
                .cardEntryAnimation(index: 8)
            }

        }
        .padding(.bottom, 32)
        .task {
            todaysQuote = QuoteLoader.shared.todaysQuote()
        }
    }
}

// MARK: - Exercise Link Card

struct ExerciseLinkCard: View {
    let onTap: () -> Void
    @ScaledMetric(relativeTo: .body) private var iconContainerSize: CGFloat = 44

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: DesignTokens.badgeRadius, style: .continuous)
                    .fill(Color.accent)
                    .frame(width: iconContainerSize, height: iconContainerSize)
                    .overlay {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.appBody)
                            .foregroundStyle(.white)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Übungsprogramm")
                        .font(.appSubheadlineSemibold)
                        .foregroundStyle(.textPrimary)
                    Text("Übungen anzeigen und protokollieren")
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
            }
            .cardStyle()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Stats Row

struct StatsRow: View {
    let user: UserProfile
    let phaseStatus: AdaptivePhaseStatus?
    let stats: ProgressStats?

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
        ], spacing: 12) {
            StatCard(
                label: "Diagnose",
                value: user.tendinopathyType.displayName,
                isCompact: true
            )

            StatCard(
                label: "Training seit",
                value: "\(user.daysSinceStart) Tage"
            )

            StatCard(
                label: "Phase",
                value: "\(user.currentPhase)/\(user.maxPhase)"
            )
        }
    }
}

struct StatCard: View {
    let label: String
    let value: String
    var isCompact: Bool = false

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.appCaption2)
                .foregroundStyle(.textSecondary)
            Text(value)
                .font(isCompact ? .appCaptionBold : .appSubheadlineSemibold)
                .foregroundStyle(.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .cardStyle(padding: 0)
    }
}

// MARK: - Welcome Card

struct WelcomeCard: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.run")
                .font(.system(size: 32))
                .foregroundStyle(.accent)

            Text("Willkommen bei Reapptivate!")
                .font(.appHeadline)
                .foregroundStyle(.textPrimary)

            Text("Starten Sie Ihr erstes Training, um Ihren Fortschritt zu verfolgen.")
                .font(.appSubheadline)
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .accentCardStyle(padding: 0)
    }
}

// MARK: - Phase Status Quick Card

struct PhaseStatusQuickCard: View {
    let status: AdaptivePhaseStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(status.phaseName)
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)

                Spacer()

                DecisionBadge(decision: status.lastDecision)
            }

            // Readiness Progress
            HStack(spacing: 4) {
                ForEach(0..<4, id: \.self) { index in
                    Rectangle()
                        .fill(index < status.progressionReadiness.criteriaMetCount ? Color.painGreen : Color.textSecondary.opacity(0.2))
                        .frame(height: 4)
                }
            }

            Text(status.nextEvaluationHint)
                .font(.appCaption)
                .foregroundStyle(.textSecondary)
        }
        .cardStyle()
    }
}

struct DecisionBadge: View {
    let decision: AdaptationDecision

    var color: Color {
        switch decision {
        case .progress: .phaseProgress
        case .hold: .phaseHold
        case .regress: .phaseRegress
        case .initial: .phaseInitial
        }
    }

    var body: some View {
        Text(decision.displayName)
            .font(.appCaptionMedium)
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.badgeRadius, style: .continuous))
    }
}
