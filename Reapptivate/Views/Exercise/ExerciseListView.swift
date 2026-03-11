import SwiftUI

struct ExerciseListView: View {
    @Environment(AppState.self) private var appState
    let exercises: [ExerciseWithPhase]
    let completedToday: Set<String>
    let onTap: (ExerciseWithPhase) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Heutige Übungen")
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)

                Spacer()

                let completed = exercises.filter { completedToday.contains($0.id) }.count
                Text("\(completed)/\(exercises.count)")
                    .font(.appSubheadlineMedium)
                    .foregroundStyle(.textSecondary)

                let totalMinutes = exercises.reduce(0) { $0 + $1.exercise.estimatedDurationMinutes }
                Text(UserDefaults.standard.string(forKey: "appLanguage") == "en"
                    ? "~\(totalMinutes) min"
                    : "~\(totalMinutes) Min.")
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
            }

            // Exercise Cards
            ForEach(exercises, id: \.id) { exercise in
                ExerciseCardView(
                    exercise: exercise,
                    isCompleted: completedToday.contains(exercise.id),
                    userSubtype: appState.currentUser?.aemSubtype,
                    onTap: { onTap(exercise) }
                )
            }
        }
    }
}
