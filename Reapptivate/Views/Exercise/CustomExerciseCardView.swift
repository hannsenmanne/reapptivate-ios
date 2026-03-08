import SwiftUI

struct CustomExerciseCardView: View {
    let exercise: CustomExercise
    let index: Int
    let isCompleted: Bool
    let onLog: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(alignment: .top) {
                // Number badge (blue to distinguish from protocol exercises)
                Text(String(format: "%02d", index + 1))
                    .font(.appCaptionBold.monospacedDigit())
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(isCompleted ? Color.painGreen : Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.smallRadius, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.name)
                        .font(.appSubheadlineSemibold)
                        .foregroundStyle(.textPrimary)

                    Text("Therapeuten-Übung")
                        .font(.appCaption)
                        .foregroundStyle(.blue)
                }

                Spacer()

                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.painGreen)
                        .font(.appTitle3)
                }
            }

            // Description
            if !exercise.description.isEmpty {
                Text(exercise.description)
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
                    .lineLimit(3)
            }

            // Parameter pills
            FlowLayout(spacing: 6) {
                ParameterPill(label: "\(exercise.sets) x \(exercise.reps)", icon: "repeat")

                if let pauseSeconds = exercise.pauseSeconds, pauseSeconds > 0 {
                    ParameterPill(label: "\(pauseSeconds)s Pause", icon: "pause.circle")
                }

                if let extra = exercise.extra, !extra.isEmpty {
                    ParameterPill(label: extra, icon: "dumbbell")
                }
            }

            // Action Button
            if isCompleted {
                Button {
                    onLog()
                } label: {
                    Text("Erneut")
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                }
                .buttonStyle(.secondary)
            } else {
                Button {
                    onLog()
                } label: {
                    Text("Eintragen")
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                }
                .buttonStyle(.accentFilled)
            }
        }
        .cardStyle()
    }
}
