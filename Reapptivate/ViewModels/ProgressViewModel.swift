import SwiftUI

@Observable
@MainActor
final class ProgressViewModel {
    // Form state
    var painLevel: Int = 0
    var setsCompleted: Int = 0
    var repsCompleted: Int = 0
    var notes: String = ""
    var symptomResponse: SymptomResponse?

    // Submission state
    var isSubmitting = false
    var errorMessage: String?
    var adaptationResult: AdaptationResult?
    var showPhaseChange = false

    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    // MARK: - Setup

    func configure(for exercise: Exercise) {
        setsCompleted = exercise.sets
        repsCompleted = exercise.reps
        painLevel = 0
        notes = ""
        symptomResponse = nil
        errorMessage = nil
        adaptationResult = nil
    }

    // MARK: - Submission

    func logProgress(exerciseId: String) async -> Bool {
        isSubmitting = true
        errorMessage = nil

        let request = ProgressLogRequest(
            exerciseId: exerciseId,
            painLevel: painLevel,
            setsCompleted: setsCompleted,
            repsCompleted: repsCompleted,
            notes: notes.isEmpty ? nil : notes,
            symptomResponse: symptomResponse
        )

        do {
            let response: ProgressLogResponse = try await apiClient.request(
                APIEndpoints.logProgress(body: request)
            )

            if let adaptation = response.adaptation, adaptation.phaseChanged {
                adaptationResult = adaptation
                showPhaseChange = true
            }

            isSubmitting = false
            return true
        } catch let error as APIError {
            errorMessage = error.localizedDescription
            isSubmitting = false
            return false
        } catch {
            errorMessage = "Fortschritt konnte nicht gespeichert werden."
            isSubmitting = false
            return false
        }
    }
}
