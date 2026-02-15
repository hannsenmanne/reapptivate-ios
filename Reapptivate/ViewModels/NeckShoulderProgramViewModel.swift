import SwiftUI

@Observable
@MainActor
final class NeckShoulderProgramViewModel {
    var program: NeckShoulderProgram?
    var exercises: NeckShoulderExerciseConfig?
    var isLoading = false
    var isGenerating = false
    var isEvaluating = false
    var errorMessage: String?
    var progressionMessage: String?

    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    // MARK: - Computed

    var severityColor: Color {
        guard let severity = program?.severity else { return .accent }
        switch severity {
        case .mild: return .painGreen
        case .moderate: return .painAmber
        case .high: return .painRed
        }
    }

    var hasProgram: Bool {
        program != nil
    }

    // MARK: - Loading

    func loadProgram() async {
        isLoading = true
        errorMessage = nil
        do {
            let response: NeckShoulderProgramResponse = try await apiClient.request(APIEndpoints.neckShoulderProgram())
            program = response.program
        } catch {
            errorMessage = "Programm konnte nicht geladen werden."
        }
        isLoading = false
    }

    func loadExercises() async {
        do {
            let response: NeckShoulderExercisesResponse = try await apiClient.request(APIEndpoints.neckShoulderExercises())
            exercises = NeckShoulderExerciseConfig(
                programA: response.programA,
                programB: response.programB,
                dailyMobility: response.dailyMobility,
                microPauses: response.microPauses
            )
        } catch {
            if errorMessage == nil {
                errorMessage = "Übungen konnten nicht geladen werden."
            }
        }
    }

    func loadAll() async {
        isLoading = true
        errorMessage = nil
        async let programTask: () = loadProgram()
        async let exercisesTask: () = loadExercises()
        _ = await (programTask, exercisesTask)
        isLoading = false
    }

    // MARK: - Generate Program

    func generateProgram() async {
        isGenerating = true
        errorMessage = nil
        do {
            let response: NeckShoulderProgramResponse = try await apiClient.request(APIEndpoints.generateNstProgram())
            program = response.program
            await loadExercises()
        } catch {
            errorMessage = "Programm konnte nicht erstellt werden."
        }
        isGenerating = false
    }

    // MARK: - Evaluate Progression

    func evaluateProgression() async {
        isEvaluating = true
        progressionMessage = nil
        do {
            let response: NeckShoulderProgressionResponse = try await apiClient.request(APIEndpoints.evaluateNstProgression())
            let result = response.progression
            progressionMessage = result.recommendation
            if result.canProgress {
                // Reload program to get updated week
                await loadProgram()
            }
        } catch {
            // Silent fail — progression evaluation is optional
        }
        isEvaluating = false
    }
}
