import SwiftUI

struct ExerciseDetailView: View {
    @Environment(AppState.self) private var appState
    let exercise: ExerciseWithPhase
    let onLog: () -> Void
    let onStartSession: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(exercise.exercise.type.displayName)
                        .font(.appCaptionMedium)
                        .foregroundStyle(.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accent.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.badgeRadius, style: .continuous))

                    Text(exercise.exercise.name)
                        .font(.appTitle2)
                        .foregroundStyle(.textPrimary)

                    Text(exercise.phaseTitle)
                        .font(.appSubheadline)
                        .foregroundStyle(.textSecondary)
                }

                // Cognitive Cue
                if let subtype = appState.currentUser?.aemSubtype,
                   let cue = exercise.exercise.cognitiveCues?.cue(for: subtype) {
                    CognitiveCueBadge(subtype: subtype, cue: cue)
                }

                // Description
                Text(exercise.exercise.description)
                    .font(.appBody)
                    .foregroundStyle(.textPrimary)

                // Parameters Card
                VStack(spacing: 12) {
                    ParameterRow(label: "Satze", value: "\(exercise.exercise.sets)")
                    ParameterRow(label: "Wiederholungen", value: "\(exercise.exercise.reps)")

                    if let holdTime = exercise.exercise.holdTime {
                        ParameterRow(label: "Haltezeit", value: "\(holdTime) Sek.")
                    }

                    if let tempo = exercise.exercise.tempo {
                        ParameterRow(label: "Tempo", value: tempo)
                    }

                    ParameterRow(label: "Intensitat", value: exercise.exercise.intensity)
                    ParameterRow(label: "Pause zwischen Satzen", value: "\(exercise.exercise.restBetweenSets) Sek.")
                }
                .cardStyle()

                // Action Buttons
                VStack(spacing: 12) {
                    Button {
                        onStartSession()
                    } label: {
                        Label("Training starten", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                    }
                    .buttonStyle(.accentFilled)

                    Button {
                        onLog()
                    } label: {
                        Label("Schnell protokollieren", systemImage: "checkmark.circle")
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    }
                    .buttonStyle(.secondary)
                }
            }
            .padding(16)
        }
        .background(Color.appBg)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ParameterRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.appSubheadline)
                .foregroundStyle(.textSecondary)
            Spacer()
            Text(value)
                .font(.appSubheadlineMedium)
                .foregroundStyle(.textPrimary)
        }
    }
}
