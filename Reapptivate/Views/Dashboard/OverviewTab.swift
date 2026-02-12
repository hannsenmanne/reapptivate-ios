import SwiftUI

struct OverviewTab: View {
    @Environment(AppState.self) private var appState
    let viewModel: DashboardViewModel?

    var body: some View {
        VStack(spacing: 20) {
            // Stats Row
            if let user = appState.currentUser {
                StatsRow(user: user, phaseStatus: viewModel?.phaseStatus, stats: viewModel?.progressStats)
            }

            // Welcome Card (new patients)
            if viewModel?.progressStats?.totalSessions == 0 {
                WelcomeCard()
            }

            // Phase Status
            if let phaseStatus = viewModel?.phaseStatus {
                PhaseStatusQuickCard(status: phaseStatus)
            }

            // Today's Exercises Preview
            TodaysExercisesSection(viewModel: viewModel)
        }
        .padding(.bottom, 32)
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
                .font(.caption2)
                .foregroundStyle(.textSecondary)
            Text(value)
                .font(isCompact ? .caption.weight(.semibold) : .subheadline.weight(.semibold))
                .foregroundStyle(.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 10))
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
                .font(.headline)
                .foregroundStyle(.textPrimary)

            Text("Starten Sie Ihr erstes Training, um Ihren Fortschritt zu verfolgen.")
                .font(.subheadline)
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color.accent.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Phase Status Quick Card

struct PhaseStatusQuickCard: View {
    let status: AdaptivePhaseStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(status.phaseName)
                    .font(.headline)
                    .foregroundStyle(.textPrimary)

                Spacer()

                DecisionBadge(decision: status.lastDecision)
            }

            // Readiness Progress
            HStack(spacing: 4) {
                ForEach(0..<4, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(index < status.progressionReadiness.criteriaMetCount ? Color.painGreen : Color.textSecondary.opacity(0.2))
                        .frame(height: 4)
                }
            }

            Text(status.nextEvaluationHint)
                .font(.caption)
                .foregroundStyle(.textSecondary)
        }
        .padding(16)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
            .font(.caption.weight(.medium))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .clipShape(Capsule())
    }
}

// MARK: - Today's Exercises

struct TodaysExercisesSection: View {
    let viewModel: DashboardViewModel?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Heutige Ubungen")
                .font(.headline)
                .foregroundStyle(.textPrimary)

            // M5 will populate this with actual exercise cards
            Text("Ubungen werden in M5 angezeigt")
                .font(.subheadline)
                .foregroundStyle(.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(Color.cardBg)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}
