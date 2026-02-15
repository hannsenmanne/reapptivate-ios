import SwiftUI

struct NstExerciseDetailView: View {
    let exercise: NeckShoulderExercise
    let accentColor: Color

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    if let muscle = exercise.targetMuscle {
                        Text(muscle)
                            .font(.appCaptionMedium)
                            .foregroundStyle(accentColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(accentColor.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.badgeRadius, style: .continuous))
                    }

                    Text(exercise.name)
                        .font(.appTitle2)
                        .foregroundStyle(.textPrimary)
                }

                // Parameters Card
                VStack(spacing: 12) {
                    if let sets = exercise.sets {
                        NstParameterRow(label: "Sätze", value: "\(sets)")
                    }
                    if let reps = exercise.reps {
                        NstParameterRow(label: "Wiederholungen", value: reps)
                    }

                    if let holdSeconds = exercise.holdSeconds {
                        NstParameterRow(label: "Haltezeit", value: "\(holdSeconds) Sek.")
                    }

                    if let equipment = exercise.equipment {
                        NstParameterRow(label: "Equipment", value: equipment)
                    }
                }
                .cardStyle()

                // Instructions
                if let instructions = exercise.instructions {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "list.bullet")
                                .foregroundStyle(accentColor)
                            Text("Anleitung")
                                .font(.appHeadline)
                                .foregroundStyle(.textPrimary)
                        }

                        Text(instructions)
                            .font(.appBody)
                            .foregroundStyle(.textSecondary)
                            .lineSpacing(4)
                    }
                    .cardStyle()
                }

                // Progression Notes
                if let notes = exercise.progressionNotes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundStyle(.painGreen)
                            Text("Steigerung")
                                .font(.appHeadline)
                                .foregroundStyle(.textPrimary)
                        }

                        Text(notes)
                            .font(.appCaption)
                            .foregroundStyle(.textSecondary)
                            .lineSpacing(3)
                    }
                    .infoBoxStyle(color: .painGreen)
                }
            }
            .padding(16)
        }
        .background(Color.appBg)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Parameter Row

private struct NstParameterRow: View {
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
