import SwiftUI

struct OverviewTab: View {
    @Environment(AppState.self) private var appState
    @Environment(APIClient.self) private var apiClient
    let viewModel: DashboardViewModel?
    let exerciseVM: ExerciseViewModel?
    var streak: StreakResponse?
    var onNavigateToProgram: (() -> Void)?

    var body: some View {
        SmartDayGateView(
            completedCount: viewModel?.completedToday.count ?? 0,
            totalCount: exerciseVM?.exercises.count ?? 0,
            onNavigateToProgram: onNavigateToProgram
        ) {
            overviewFallbackContent
        }
    }

    // MARK: - Fallback Content (shown when Smart Day API is unavailable)

    @ViewBuilder
    private var overviewFallbackContent: some View {
        VStack(spacing: 20) {
            // Stats Row
            if let user = appState.currentUser {
                StatsRow(user: user, phaseStatus: viewModel?.phaseStatus, stats: viewModel?.progressStats)
                    .cardEntryAnimation(index: 0)
            }

            // Welcome Card (new patients)
            if viewModel?.progressStats?.totalSessions == 0 {
                WelcomeCard()
                    .cardEntryAnimation(index: 1)
            }

            // Today's Plan
            let completedTodayCount = viewModel?.completedToday.count ?? 0
            let totalExerciseCount = exerciseVM?.exercises.count ?? 0
            if viewModel?.isRestDay != true && totalExerciseCount > 0 {
                TodaysPlanCard(
                    completedCount: completedTodayCount,
                    totalCount: totalExerciseCount,
                    onTap: { onNavigateToProgram?() }
                )
                .cardEntryAnimation(index: 2)
            }

            // Rest Day Card
            if viewModel?.isRestDay == true {
                RestDayCard()
                    .cardEntryAnimation(index: 2)
            }

            // Streak
            if let s = streak, s.currentStreak > 0 || s.longestStreak > 0 {
                StreakCard(streak: s)
                    .cardEntryAnimation(index: 3)
            }

            // Phase Status
            if let phaseStatus = viewModel?.phaseStatus {
                PhaseStatusQuickCard(status: phaseStatus)
                    .cardEntryAnimation(index: 4)
            }

            // Work Timer (LBP / Neck / Tension only)
            WorkTimerCard()
                .cardEntryAnimation(index: 5)

            // Exercise Link
            ExerciseLinkCard(onTap: { onNavigateToProgram?() })
                .cardEntryAnimation(index: 6)

            // Training Schedule
            TrainingScheduleCard()
                .cardEntryAnimation(index: 7)

            // Compliance Calendar
            if let entries = viewModel?.recentEntries, !entries.isEmpty {
                ComplianceCalendarCard(entries: entries)
                    .cardEntryAnimation(index: 8)
            }

            // Wissen (not for shoulder impingement / frozen shoulder — micro-modules cover education)
            if let user = appState.currentUser, !appState.isShoulder, !appState.isFrozenShoulder, !appState.isAcl, !appState.isLateralAnkleSprain {
                WissenCardView(
                    phase: user.currentPhase,
                    isLbp: appState.isLbp,
                    isNeck: appState.isNeck,
                    isTension: appState.isTension
                )
                .cardEntryAnimation(index: 9)
            }

        }
        .padding(.bottom, 32)
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

    private var diagnosisDisplay: (String, String?) {
        if user.tendinopathyType == .neckShoulderTension {
            return ("Nacken & Schulter", "Verspannung")
        }
        return (user.tendinopathyType.displayName, nil)
    }

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
        ], spacing: 12) {
            StatCard(
                label: "Diagnose",
                value: diagnosisDisplay.0,
                secondLine: diagnosisDisplay.1,
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
    var secondLine: String? = nil
    var isCompact: Bool = false

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.appCaption2)
                .foregroundStyle(.textSecondary)

            if let secondLine = secondLine {
                VStack(spacing: 0) {
                    Text(value)
                        .font(isCompact ? .appCaptionBold : .appSubheadlineSemibold)
                        .foregroundStyle(.textPrimary)
                    Text(secondLine)
                        .font(isCompact ? .appCaptionBold : .appSubheadlineSemibold)
                        .foregroundStyle(.textPrimary)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            } else {
                Text(value)
                    .font(isCompact ? .appCaptionBold : .appSubheadlineSemibold)
                    .foregroundStyle(.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
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

// MARK: - Streak Card

struct StreakCard: View {
    let streak: StreakResponse

    @ScaledMetric(relativeTo: .body) private var flameSize: CGFloat = 36

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "flame.fill")
                .font(.system(size: 24))
                .foregroundStyle(streak.currentStreak > 0 ? Color.painAmber : Color.textSecondary)
                .frame(width: flameSize, height: flameSize)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text("\(streak.currentStreak)")
                        .font(.appTitle2)
                        .foregroundStyle(.textPrimary)
                    Text(streak.currentStreak == 1 ? "Tag Streak" : "Tage Streak")
                        .font(.appSubheadline)
                        .foregroundStyle(.textSecondary)
                }

                HStack(spacing: 12) {
                    if streak.longestStreak > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "trophy.fill")
                                .font(.appCaption2)
                                .foregroundStyle(Color.painAmber)
                                .accessibilityHidden(true)
                            Text("Rekord: \(streak.longestStreak)")
                                .font(.appCaption)
                                .foregroundStyle(.textSecondary)
                        }
                    }

                    if streak.freezeTokens > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "snowflake")
                                .font(.appCaption2)
                                .foregroundStyle(Color.farBlue)
                                .accessibilityHidden(true)
                            Text("\(streak.freezeTokens) Freeze")
                                .font(.appCaption)
                                .foregroundStyle(.textSecondary)
                        }
                    }
                }
            }

            Spacer()
        }
        .cardStyle()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Streak: \(streak.currentStreak) \(streak.currentStreak == 1 ? "Tag" : "Tage"), Rekord: \(streak.longestStreak)")
    }
}

struct DecisionBadge: View {
    let decision: AdaptationDecision

    var color: Color {
        switch decision {
        case .progress: .phaseProgress
        case .hold: .phaseHold
        case .regress: .phaseRegress
        case .initial, .unknown: .phaseInitial
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
