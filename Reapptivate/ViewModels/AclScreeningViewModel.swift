import SwiftUI

@Observable
@MainActor
final class AclScreeningViewModel {
    var config: AclScreeningConfig?
    var steps: [AclScreeningStep] { config?.steps ?? [] }
    var currentStepIndex = 0
    var isLoading = false
    var isSubmitting = false
    var errorMessage: String?
    var result: AclScreeningResult?

    // Form state — keyed by step id
    var surgeryDate: Date = Date()
    var surgeryDateSet = false
    var graftType: String?
    var athleteLevel: String?
    var concomitantInjuries: Set<String> = []
    var sport: String = ""
    var kneeSide: String?

    private let apiClient: APIClient
    private var autoAdvanceTask: Task<Void, Never>?

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    // MARK: - Computed

    var currentStep: AclScreeningStep? {
        guard currentStepIndex < steps.count else { return nil }
        return steps[currentStepIndex]
    }

    var progress: Double {
        guard !steps.isEmpty else { return 0 }
        let completed = steps.prefix(steps.count).filter { isStepComplete($0) }.count
        return Double(completed) / Double(steps.count)
    }

    var canSubmit: Bool {
        steps.allSatisfy { step in
            if step.required == true {
                return isStepComplete(step)
            }
            return true
        }
    }

    var isOnLastStep: Bool {
        currentStepIndex == steps.count - 1
    }

    var canAdvance: Bool {
        guard let step = currentStep else { return false }
        if step.required == true {
            return isStepComplete(step)
        }
        return true
    }

    func isStepComplete(_ step: AclScreeningStep) -> Bool {
        switch step.id {
        case "surgery_date":
            return surgeryDateSet
        case "graft_type":
            return graftType != nil
        case "athlete_level":
            return athleteLevel != nil
        case "concomitant_injuries":
            // Checkbox step is optional per config, always "complete"
            return true
        case "sport":
            // Optional text field — always complete
            return true
        case "knee_side":
            return kneeSide != nil
        default:
            return false
        }
    }

    // MARK: - Loading

    func loadConfig() async {
        isLoading = true
        errorMessage = nil
        do {
            config = try await apiClient.request(APIEndpoints.aclConfig())
        } catch {
            errorMessage = "Screening konnte nicht geladen werden."
        }
        isLoading = false
    }

    // MARK: - Selection

    func selectRadio(stepId: String, value: String) {
        switch stepId {
        case "graft_type":
            graftType = value
        case "athlete_level":
            athleteLevel = value
        case "knee_side":
            kneeSide = value
        default:
            break
        }

        // Auto-advance after radio selection
        autoAdvanceTask?.cancel()
        if currentStepIndex < steps.count - 1 {
            autoAdvanceTask = Task {
                try? await Task.sleep(for: .milliseconds(500))
                guard !Task.isCancelled else { return }
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentStepIndex += 1
                }
            }
        }
    }

    func toggleCheckbox(value: String) {
        if value == "NONE" {
            // NONE is mutually exclusive — selecting it clears everything else
            concomitantInjuries = ["NONE"]
        } else {
            // Remove NONE if selecting a real injury
            concomitantInjuries.remove("NONE")

            if concomitantInjuries.contains(value) {
                concomitantInjuries.remove(value)
            } else {
                concomitantInjuries.insert(value)
            }
        }
    }

    func setSurgeryDate(_ date: Date) {
        surgeryDate = date
        surgeryDateSet = true
    }

    // MARK: - Navigation

    func goForward() {
        autoAdvanceTask?.cancel()
        guard currentStepIndex < steps.count - 1, canAdvance else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStepIndex += 1
        }
    }

    func goBack() {
        autoAdvanceTask?.cancel()
        guard currentStepIndex > 0 else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStepIndex -= 1
        }
    }

    // MARK: - Submission

    func submit() async -> Bool {
        guard canSubmit else { return false }
        isSubmitting = true
        errorMessage = nil

        // Format surgery date as yyyy-MM-dd
        let dateString = DateFormatters.dateOnly.string(from: surgeryDate)

        let submission = AclScreeningSubmission(
            surgeryDate: dateString,
            graftType: graftType ?? "",
            athleteLevel: athleteLevel ?? "",
            concomitantInjuries: concomitantInjuries.isEmpty ? ["NONE"] : Array(concomitantInjuries),
            sport: sport.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : sport.trimmingCharacters(in: .whitespacesAndNewlines),
            kneeSide: kneeSide ?? ""
        )

        do {
            let response: AclScreeningResponse = try await apiClient.request(
                APIEndpoints.submitAclScreening(body: submission)
            )
            result = response.screening
            isSubmitting = false
            return true
        } catch {
            errorMessage = "Screening konnte nicht gespeichert werden."
            isSubmitting = false
            return false
        }
    }
}
