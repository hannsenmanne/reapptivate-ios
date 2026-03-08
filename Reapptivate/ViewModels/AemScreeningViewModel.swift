import SwiftUI

@Observable
@MainActor
final class AemScreeningViewModel {
    var config: AemScreeningConfig?
    var responses: [String: Int] = [:]
    var currentItemIndex = 0
    var isLoading = false
    var isSubmitting = false
    var errorMessage: String?
    var result: AemScreeningResult?

    private let apiClient: APIClient
    private var autoAdvanceTask: Task<Void, Never>?

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    var items: [AemScreeningItem] {
        config?.items ?? []
    }

    var currentItem: AemScreeningItem? {
        guard currentItemIndex < items.count else { return nil }
        return items[currentItemIndex]
    }

    var progress: Double {
        guard !items.isEmpty else { return 0 }
        return Double(responses.count) / Double(items.count)
    }

    var canSubmit: Bool {
        responses.count == items.count
    }

    var isOnLastItem: Bool {
        currentItemIndex == items.count - 1
    }

    // MARK: - Loading

    func loadConfig() async {
        isLoading = true
        do {
            config = try await apiClient.request(APIEndpoints.aemConfig())
        } catch {
            errorMessage = "Fragebogen konnte nicht geladen werden."
        }
        isLoading = false
    }

    // MARK: - Response

    func selectResponse(itemId: String, value: Int) {
        responses[itemId] = value
        autoAdvanceTask?.cancel()

        // Auto-advance after brief delay
        if currentItemIndex < items.count - 1 {
            autoAdvanceTask = Task {
                try? await Task.sleep(for: .milliseconds(500))
                guard !Task.isCancelled else { return }
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentItemIndex += 1
                }
            }
        }
    }

    func goBack() {
        autoAdvanceTask?.cancel()
        if currentItemIndex > 0 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentItemIndex -= 1
            }
        }
    }

    // MARK: - Submission

    func submit() async -> Bool {
        guard canSubmit else { return false }
        isSubmitting = true
        errorMessage = nil

        do {
            let submission = AemScreeningSubmission(responses: responses)
            let response: AemScreeningResponse = try await apiClient.request(
                APIEndpoints.submitAemScreening(body: submission)
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
