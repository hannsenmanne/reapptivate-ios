import Foundation

@Observable
@MainActor
final class AclTodayProgramViewModel {
    struct StreamGroup: Identifiable {
        let streamId: String
        let streamName: String
        var exercises: [AclStreamExercise]
        var id: String { streamId }
    }

    var streamGroups: [StreamGroup] = []
    var completedExerciseIds: Set<String> = []
    var submittingExerciseIds: Set<String> = []
    var isLoading = false
    var errorMessage: String?

    let userGraftType: String?
    let userConcomitantInjuries: Set<String>

    private let apiClient: APIClient
    private let streamIds: [String]

    init(apiClient: APIClient, streamIds: [String],
         userGraftType: String?, userConcomitantInjuries: Set<String>) {
        self.apiClient = apiClient
        self.streamIds = streamIds
        self.userGraftType = userGraftType
        self.userConcomitantInjuries = userConcomitantInjuries
    }

    // MARK: - Computed

    var totalCount: Int {
        streamGroups.reduce(0) { $0 + $1.exercises.count }
    }

    var completedCount: Int {
        streamGroups.reduce(0) { sum, group in
            sum + group.exercises.filter { completedExerciseIds.contains($0.id) }.count
        }
    }

    var allDone: Bool {
        totalCount > 0 && completedCount >= totalCount
    }

    var progress: Double {
        totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0
    }

    func isCompleted(_ exerciseId: String) -> Bool {
        completedExerciseIds.contains(exerciseId)
    }

    func isSubmitting(_ exerciseId: String) -> Bool {
        submittingExerciseIds.contains(exerciseId)
    }

    func globalIndex(for exercise: AclStreamExercise) -> Int {
        var index = 0
        for group in streamGroups {
            for ex in group.exercises {
                if ex.id == exercise.id { return index }
                index += 1
            }
        }
        return index
    }

    // MARK: - Loading

    func loadAll() async {
        isLoading = true
        errorMessage = nil

        do {
            async let streamsResult = loadStreams()
            async let todayResult: TodayProgressResponse = apiClient.request(
                APIEndpoints.getTodayProgress()
            )

            streamGroups = try await streamsResult
            let today = try await todayResult
            completedExerciseIds = Set(today.completedExercises.map(\.exerciseId))
        } catch {
            Log.api.error("ACL today program load error: \(error.localizedDescription)")
            errorMessage = "Programm konnte nicht geladen werden."
        }

        isLoading = false
    }

    private func loadStreams() async throws -> [StreamGroup] {
        try await withThrowingTaskGroup(of: (String, AclStreamDetailResponse).self) { group in
            for streamId in streamIds {
                group.addTask { [apiClient] in
                    let response: AclStreamDetailResponse = try await apiClient.request(
                        APIEndpoints.aclStreamDetail(streamId: streamId)
                    )
                    return (streamId, response)
                }
            }

            var groups: [StreamGroup] = []
            for try await (_, response) in group {
                let exercises = response.exercises.isEmpty
                    ? (response.stream.exercises ?? [])
                    : response.exercises
                groups.append(StreamGroup(
                    streamId: response.stream.id,
                    streamName: response.stream.nameDE ?? response.stream.name,
                    exercises: exercises
                ))
            }
            // Maintain original stream order
            return streamIds.compactMap { id in groups.first { $0.streamId == id } }
        }
    }

    // MARK: - Exercise Toggle

    func toggleExercise(_ exercise: AclStreamExercise) async {
        let exerciseId = exercise.id
        let wasCompleted = completedExerciseIds.contains(exerciseId)

        submittingExerciseIds.insert(exerciseId)

        if wasCompleted {
            // Unchecking — just remove locally (no server undo endpoint)
            completedExerciseIds.remove(exerciseId)
            submittingExerciseIds.remove(exerciseId)
            return
        }

        // Optimistic: mark as completed immediately
        completedExerciseIds.insert(exerciseId)

        do {
            let setsValue = exercise.sets ?? 3
            let repsValue: Int
            if let repsStr = exercise.reps, let parsed = Int(repsStr) {
                repsValue = parsed
            } else {
                repsValue = 10
            }

            let request = ProgressLogRequest(
                exerciseId: exerciseId,
                painLevel: 0,
                setsCompleted: setsValue,
                repsCompleted: repsValue,
                notes: nil,
                symptomResponse: nil
            )

            let _: ProgressLogResponse = try await apiClient.request(
                APIEndpoints.logProgress(body: request)
            )
        } catch {
            // Revert on failure
            completedExerciseIds.remove(exerciseId)
            Log.api.error("Failed to log exercise \(exerciseId): \(error.localizedDescription)")
        }

        submittingExerciseIds.remove(exerciseId)
    }
}
