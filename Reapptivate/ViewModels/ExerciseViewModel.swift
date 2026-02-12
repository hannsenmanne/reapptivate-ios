import SwiftUI

@Observable
@MainActor
final class ExerciseViewModel {
    var exercises: [ExerciseWithPhase] = []
    var completedToday: Set<String> = []
    var selectedExercise: ExerciseWithPhase?
    var showProgressLog = false
    var showExerciseSession = false

    private let protocolLoader = ProtocolLoader.shared

    // MARK: - Loading

    func loadExercises(for user: UserProfile) {
        guard let proto = protocolLoader.protocolFor(
            type: user.tendinopathyType,
            aemSubtype: user.aemSubtype,
            ndiSeverity: user.ndiSeverity
        ) else {
            Log.exercise.error("No protocol found for \(user.tendinopathyType.rawValue)")
            return
        }

        exercises = protocolLoader.exercisesForPhase(
            protocol: proto,
            phase: user.currentPhase,
            ndiSeverity: user.ndiSeverity
        )
    }

    func updateCompletedToday(from entries: [ProgressEntry]) {
        completedToday = Set(entries.map(\.exerciseId))
    }

    func markCompleted(_ exerciseId: String) {
        completedToday.insert(exerciseId)
    }

    func isCompleted(_ exerciseId: String) -> Bool {
        completedToday.contains(exerciseId)
    }

    // MARK: - Actions

    func openProgressLog(for exercise: ExerciseWithPhase) {
        selectedExercise = exercise
        showProgressLog = true
    }

    func openSession(for exercise: ExerciseWithPhase) {
        selectedExercise = exercise
        showExerciseSession = true
    }

    // MARK: - Helpers

    var totalEstimatedMinutes: Int {
        exercises.reduce(0) { $0 + $1.exercise.estimatedDurationMinutes }
    }

    var completedCount: Int {
        exercises.filter { isCompleted($0.id) }.count
    }

    var totalCount: Int {
        exercises.count
    }
}
