import SwiftUI

/// Program tab wrapper for neck-shoulder tension patients.
/// Shows NST profile card, program view with session player integration, and micro-modules.
struct NstProgramTab: View {
    @Environment(AppState.self) private var appState
    @Environment(APIClient.self) private var apiClient

    let severity: NeckShoulderSeverity
    var onSessionLogged: (() -> Void)?

    @State private var programVM: NeckShoulderProgramViewModel?
    @State private var showSessionPlayer: SessionPlayerSheet?

    enum SessionPlayerSheet: Identifiable {
        case player(type: String, exercises: [NeckShoulderExercise])

        var id: String {
            switch self {
            case .player(let type, _): "player-\(type)"
            }
        }
    }

    var accentColor: Color {
        switch severity {
        case .mild: .painGreen
        case .moderate: .painAmber
        case .high: .painRed
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            // Profile quick card
            NstProfileQuickCard(severity: severity)

            // Program view
            NstProgramView(severity: severity)

            // Session player buttons
            if let exercises = programVM?.exercises {
                VStack(spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "play.circle.fill")
                            .foregroundStyle(accentColor)
                        Text("Training starten")
                            .font(.appHeadline)
                            .foregroundStyle(.textPrimary)
                        Spacer()
                    }

                    SessionStartButton(
                        label: "Kraft A",
                        icon: "figure.strengthtraining.traditional",
                        accentColor: accentColor
                    ) {
                        showSessionPlayer = .player(
                            type: "strength_a",
                            exercises: exercises.programA.exercises
                        )
                    }

                    SessionStartButton(
                        label: "Kraft B",
                        icon: "figure.strengthtraining.traditional",
                        accentColor: accentColor
                    ) {
                        showSessionPlayer = .player(
                            type: "strength_b",
                            exercises: exercises.programB.exercises
                        )
                    }

                    SessionStartButton(
                        label: "Mobilitat",
                        icon: "figure.flexibility",
                        accentColor: accentColor
                    ) {
                        showSessionPlayer = .player(
                            type: "mobility",
                            exercises: exercises.dailyMobility.exercises
                        )
                    }
                }
            }
        }
        .padding(.bottom, 32)
        .task {
            if programVM == nil {
                programVM = NeckShoulderProgramViewModel(apiClient: apiClient)
                await programVM?.loadAll()
            }
        }
        .sheet(item: $showSessionPlayer) { sheet in
            switch sheet {
            case .player(let type, let exercises):
                NstSessionPlayerView(
                    sessionType: type,
                    exercises: exercises,
                    accentColor: accentColor,
                    onComplete: { onSessionLogged?() }
                )
            }
        }
    }
}

// MARK: - Session Start Button

private struct SessionStartButton: View {
    let label: String
    let icon: String
    let accentColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.appBody)
                    .foregroundStyle(accentColor)
                    .frame(width: 32)

                Text(label)
                    .font(.appSubheadlineMedium)
                    .foregroundStyle(.textPrimary)

                Spacer()

                Image(systemName: "play.fill")
                    .font(.appCaption)
                    .foregroundStyle(accentColor)
            }
            .cardStyle(padding: 14)
        }
        .buttonStyle(.plain)
    }
}
