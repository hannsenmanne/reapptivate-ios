import SwiftUI

struct NstDashboardOverview: View {
    @Environment(AppState.self) private var appState
    @Environment(APIClient.self) private var apiClient

    let dashboardVM: DashboardViewModel?
    let severity: NeckShoulderSeverity
    var onNavigateToProgram: (() -> Void)?

    @State private var trackingVM: NstTrackingViewModel?
    @State private var programVM: NeckShoulderProgramViewModel?
    @State private var microPauseSuccessTrigger = false

    var accentColor: Color {
        switch severity {
        case .mild: .painGreen
        case .moderate: .painAmber
        case .high: .painRed
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            // Stats Row
            if let user = appState.currentUser {
                NstStatsRow(user: user, severity: severity, program: programVM?.program)
            }

            // Streak
            if let streak = dashboardVM?.streakData, (dashboardVM?.progressStats?.totalSessions ?? 0) > 0 {
                StreakCard(streak: streak, isFreezing: dashboardVM?.isFreezing ?? false) {
                    Task { await dashboardVM?.useFreezeToken() }
                }
            }

            // Welcome card (no sessions yet)
            if dashboardVM?.progressStats?.totalSessions == 0 {
                WelcomeCard()
            }

            // Micro-Pause quick log
            NstMicroPauseButton(
                stats: trackingVM?.microPauseStats,
                accentColor: accentColor,
                isLogging: trackingVM?.isLoggingMicroPause ?? false
            ) {
                Task {
                    if await trackingVM?.logMicroPause() == true {
                        microPauseSuccessTrigger.toggle()
                    }
                }
            }

            // Compliance
            NstComplianceView(
                compliance: trackingVM?.compliance,
                accentColor: accentColor
            )

            // Program link
            NstProgramLinkCard(
                program: programVM?.program,
                accentColor: accentColor,
                onTap: { onNavigateToProgram?() }
            )

            // Profile card
            NstProfileView(severity: severity, program: programVM?.program)
        }
        .padding(.bottom, 32)
        .task {
            if trackingVM == nil {
                trackingVM = NstTrackingViewModel(apiClient: apiClient)
            }
            if programVM == nil {
                programVM = NeckShoulderProgramViewModel(apiClient: apiClient)
            }
            async let trackLoad: () = trackingVM?.loadAll() ?? ()
            async let progLoad: () = programVM?.loadProgram() ?? ()
            _ = await (trackLoad, progLoad)
        }
        .sensoryFeedback(.success, trigger: microPauseSuccessTrigger)
    }
}

// MARK: - Stats Row

private struct NstStatsRow: View {
    let user: UserProfile
    let severity: NeckShoulderSeverity
    let program: NeckShoulderProgram?

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
        ], spacing: 12) {
            StatCard(label: "Diagnose", value: "Nacken/Schulter", isCompact: true)
            StatCard(label: "Training seit", value: "\(user.daysSinceStart) Tage")
            StatCard(
                label: "Woche",
                value: program != nil ? "\(program!.currentWeek)/\(program!.durationWeeks)" : "—"
            )
        }
    }
}

// MARK: - Program Link Card

private struct NstProgramLinkCard: View {
    let program: NeckShoulderProgram?
    let accentColor: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: DesignTokens.badgeRadius, style: .continuous)
                    .fill(accentColor)
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.appBody)
                            .foregroundStyle(.white)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Ubungsprogramm")
                        .font(.appSubheadlineSemibold)
                        .foregroundStyle(.textPrimary)

                    if let program {
                        Text("Kraft \(program.strengthFrequency)x/Wo · Mobilitat \(program.mobilityFrequency)x/Tag")
                            .font(.appCaption)
                            .foregroundStyle(.textSecondary)
                    } else {
                        Text("Programm erstellen und Ubungen anzeigen")
                            .font(.appCaption)
                            .foregroundStyle(.textSecondary)
                    }
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
