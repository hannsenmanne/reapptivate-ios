import SwiftUI

struct ExerciseListView: View {
    @Environment(AppState.self) private var appState
    let exercises: [ExerciseWithPhase]
    let completedToday: Set<String>
    let onLog: (ExerciseWithPhase) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Heutige Ubungen")
                    .font(.headline)
                    .foregroundStyle(.textPrimary)

                Spacer()

                let completed = exercises.filter { completedToday.contains($0.id) }.count
                Text("\(completed)/\(exercises.count)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.textSecondary)

                let totalMinutes = exercises.reduce(0) { $0 + $1.exercise.estimatedDurationMinutes }
                Text("~\(totalMinutes) Min.")
                    .font(.caption)
                    .foregroundStyle(.textSecondary)
            }

            // Exercise Cards
            ForEach(Array(exercises.enumerated()), id: \.element.id) { index, exercise in
                ExerciseCardView(
                    exercise: exercise,
                    index: index,
                    isCompleted: completedToday.contains(exercise.id),
                    userSubtype: appState.currentUser?.aemSubtype,
                    onLog: { onLog(exercise) }
                )
            }
        }
    }
}
