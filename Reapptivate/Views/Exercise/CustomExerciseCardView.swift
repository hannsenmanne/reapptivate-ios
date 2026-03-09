import SwiftUI

struct CustomExerciseCardView: View {
    let exercise: CustomExercise
    let isCompleted: Bool
    let onLog: () -> Void

    @ScaledMetric(relativeTo: .body) private var thumbnailSize: CGFloat = 56

    var body: some View {
        Button {
            onLog()
        } label: {
            HStack(spacing: 14) {
                // Thumbnail placeholder (blue to distinguish from protocol exercises)
                RoundedRectangle(cornerRadius: DesignTokens.smallRadius, style: .continuous)
                    .fill(isCompleted ? Color.painGreen.opacity(0.15) : Color.blue.opacity(0.12))
                    .frame(width: thumbnailSize, height: thumbnailSize)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.appTitle3)
                            .foregroundStyle(isCompleted ? .painGreen : .blue)
                    }

                VStack(alignment: .leading, spacing: 3) {
                    Text(exercise.name)
                        .font(.appSubheadlineSemibold)
                        .foregroundStyle(.textPrimary)
                        .lineLimit(1)

                    Text(exerciseSummary)
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.painGreen)
                        .font(.appTitle2)
                        .accessibilityLabel("Abgeschlossen")
                } else {
                    Image(systemName: "play.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.appTitle2)
                        .accessibilityHidden(true)
                }
            }
            .padding(12)
            .background(Color.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardRadius, style: .continuous))
            .shadow(
                color: DesignTokens.cardShadowColor,
                radius: DesignTokens.cardShadowRadius,
                y: DesignTokens.cardShadowY
            )
        }
        .buttonStyle(.plain)
    }

    private var exerciseSummary: String {
        var parts: [String] = []
        parts.append("\(exercise.sets) × \(exercise.reps)")
        if let pauseSeconds = exercise.pauseSeconds, pauseSeconds > 0 {
            parts.append("\(pauseSeconds)s Pause")
        }
        parts.append("Therapeuten-Übung")
        return parts.joined(separator: " · ")
    }
}
