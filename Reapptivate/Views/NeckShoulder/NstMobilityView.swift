import SwiftUI

struct NstMobilityView: View {
    let section: NeckShoulderExerciseConfig.MobilitySection
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: "figure.flexibility")
                    .font(.appTitle3)
                    .foregroundStyle(accentColor)
                Text(section.name)
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)
                Spacer()
            }

            // Frequency & duration info
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "repeat")
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                    Text("\(section.frequencyPerDay)x täglich")
                        .font(.appCaptionMedium)
                        .foregroundStyle(.textSecondary)
                }
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                    Text("~\(section.durationMinutes) Min.")
                        .font(.appCaptionMedium)
                        .foregroundStyle(.textSecondary)
                }
            }
            .padding(10)
            .background(accentColor.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.smallRadius, style: .continuous))

            // Exercise list
            if section.exercises.isEmpty {
                Text("Keine Übungen verfügbar")
                    .font(.appSubheadline)
                    .foregroundStyle(.textSecondary)
                    .padding(.vertical, 16)
            } else {
                ForEach(section.exercises) { exercise in
                    NavigationLink {
                        NstExerciseDetailView(exercise: exercise, accentColor: accentColor)
                    } label: {
                        NstMobilityExerciseRow(exercise: exercise, accentColor: accentColor)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Mobility Exercise Row

private struct NstMobilityExerciseRow: View {
    let exercise: NeckShoulderExercise
    let accentColor: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "figure.flexibility")
                .font(.appCaption)
                .foregroundStyle(accentColor)
                .frame(width: 28, height: 28)
                .background(accentColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.smallRadius, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.appSubheadlineMedium)
                    .foregroundStyle(.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(exercise.detail)
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)

                    if let holdSeconds = exercise.holdSeconds {
                        Text("Halten: \(holdSeconds)s")
                            .font(.appCaption)
                            .foregroundStyle(accentColor)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.appCaption2)
                .foregroundStyle(.textSecondary)
        }
        .padding(12)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardRadius, style: .continuous))
        .shadow(
            color: DesignTokens.cardShadowColor,
            radius: DesignTokens.cardShadowRadius / 2,
            y: DesignTokens.cardShadowY / 2
        )
    }
}
