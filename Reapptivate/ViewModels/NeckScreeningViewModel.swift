import SwiftUI

@Observable
@MainActor
final class NeckScreeningViewModel {
    var config: NeckScreeningConfig?
    var responses: [String: Int] = [:]
    var currentItemIndex = 0
    var currentPart: String = "A"
    var showPartTransition = false
    var isLoading = false
    var isSubmitting = false
    var errorMessage: String?
    var result: NeckScreeningResult?
    var isRescreening = false

    private let apiClient: APIClient

    init(apiClient: APIClient, isRescreening: Bool = false) {
        self.apiClient = apiClient
        self.isRescreening = isRescreening
        if isRescreening {
            currentPart = "B" // Rescreening skips Part A
        }
    }

    var items: [NeckScreeningItem] {
        config?.items.filter { $0.part == currentPart } ?? []
    }

    var allItems: [NeckScreeningItem] {
        config?.items ?? []
    }

    var currentItem: NeckScreeningItem? {
        let partItems = items
        guard currentItemIndex < partItems.count else { return nil }
        return partItems[currentItemIndex]
    }

    var progress: Double {
        let totalItems = isRescreening
            ? allItems.filter { $0.part == "B" }.count
            : allItems.count
        guard totalItems > 0 else { return 0 }
        return Double(responses.count) / Double(totalItems)
    }

    var canSubmit: Bool {
        let requiredItems = isRescreening
            ? allItems.filter { $0.part == "B" }
            : allItems
        return requiredItems.allSatisfy { responses[$0.id] != nil }
    }

    // MARK: - Loading

    func loadConfig() async {
        isLoading = true
        do {
            config = try await apiClient.request(APIEndpoints.neckConfig())
        } catch {
            errorMessage = "NDI-Fragebogen konnte nicht geladen werden."
        }
        isLoading = false
    }

    // MARK: - Response

    func selectResponse(itemId: String, value: Int) {
        responses[itemId] = value

        let partItems = items
        if currentItemIndex < partItems.count - 1 {
            Task {
                try? await Task.sleep(for: .milliseconds(500))
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentItemIndex += 1
                }
            }
        } else if currentPart == "A" && !isRescreening {
            // Transition from Part A to Part B
            Task {
                try? await Task.sleep(for: .milliseconds(500))
                withAnimation {
                    showPartTransition = true
                }
            }
        }
    }

    func continueToPartB() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentPart = "B"
            currentItemIndex = 0
            showPartTransition = false
        }
    }

    func goBack() {
        if currentItemIndex > 0 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentItemIndex -= 1
            }
        } else if currentPart == "B" && !isRescreening {
            // Go back to Part A
            withAnimation(.easeInOut(duration: 0.3)) {
                currentPart = "A"
                let partAItems = allItems.filter { $0.part == "A" }
                currentItemIndex = max(0, partAItems.count - 1)
            }
        }
    }

    // MARK: - Submission

    func submit() async -> Bool {
        guard canSubmit else { return false }
        isSubmitting = true
        errorMessage = nil

        let submission = NeckScreeningSubmission(responses: responses)
        let endpoint = isRescreening
            ? APIEndpoints.submitNeckRescreening(body: submission)
            : APIEndpoints.submitNeckScreening(body: submission)

        do {
            result = try await apiClient.request(endpoint)
            isSubmitting = false
            return true
        } catch {
            errorMessage = "Screening konnte nicht gespeichert werden."
            isSubmitting = false
            return false
        }
    }
}
