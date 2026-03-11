import SwiftUI

@Observable
@MainActor
final class ExerciseViewModel {
    var exercises: [ExerciseWithPhase] = []
    var customExercises: [CustomExercise] = []
    var completedToday: Set<String> = []
    var selectedExercise: ExerciseWithPhase?
    var showProgressLog = false
    var showExerciseSession = false

    private let protocolLoader = ProtocolLoader.shared
    private var apiClient: APIClient?

    init(apiClient: APIClient? = nil) {
        self.apiClient = apiClient
    }

    // MARK: - Loading

    func loadExercises(for user: UserProfile, trainingDays: [Int]? = nil) {
        guard let proto = protocolLoader.protocolFor(
            type: user.tendinopathyType,
            aemSubtype: user.aemSubtype,
            tsiSeverity: user.tsiSeverity,
            siSeverity: user.siSeverity,
            fsSeverity: user.fsSeverity,
            lasSeverity: user.lasSeverity
        ) else {
            Log.exercise.error("No protocol found for \(user.tendinopathyType.rawValue)")
            return
        }

        var loaded = protocolLoader.exercisesForPhase(
            protocol: proto,
            phase: user.currentPhase,
            trainingDays: trainingDays
        )

        // Apply dosage modifiers for Frozen Shoulder based on severity
        if user.tendinopathyType.isFrozenShoulder, let severity = user.fsSeverity, severity != .unknown {
            loaded = loaded.map { $0.applyingDosageModifier(severityKey: severity.rawValue) }
        }

        exercises = loaded
    }

    func updateCompletedToday(from exerciseIds: [String]) {
        completedToday = Set(exerciseIds)
    }

    func markCompleted(_ exerciseId: String) {
        completedToday.insert(exerciseId)
    }

    func isCompleted(_ exerciseId: String) -> Bool {
        completedToday.contains(exerciseId)
    }

    func loadCustomExercises() async {
        guard let apiClient else { return }
        do {
            let response: CustomExercisesResponse = try await apiClient.request(
                APIEndpoints.customExercises()
            )
            customExercises = response.exercises
        } catch {
            Log.exercise.error("Failed to load custom exercises: \(error)")
        }
    }

    func isCustomExerciseCompleted(_ exercise: CustomExercise) -> Bool {
        completedToday.contains("custom_\(exercise.id)")
    }

    func markCustomExerciseCompleted(_ exercise: CustomExercise) {
        completedToday.insert("custom_\(exercise.id)")
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
