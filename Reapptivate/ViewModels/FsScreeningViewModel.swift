import SwiftUI

@Observable
@MainActor
final class FsScreeningViewModel {
    var config: FsScreeningConfig?
    var responses: [String: Int] = [:]
    var currentItemIndex = 0
    var isLoading = false
    var isSubmitting = false
    var errorMessage: String?
    var result: FsScreeningResult?
    var isRescreening = false

    private let apiClient: APIClient
    private var autoAdvanceTask: Task<Void, Never>?

    init(apiClient: APIClient, isRescreening: Bool = false) {
        self.apiClient = apiClient
        self.isRescreening = isRescreening
    }

    var items: [FsScreeningItem] {
        config?.items ?? []
    }

    var currentItem: FsScreeningItem? {
        guard currentItemIndex < items.count else { return nil }
        return items[currentItemIndex]
    }

    var progress: Double {
        guard !items.isEmpty else { return 0 }
        return Double(responses.count) / Double(items.count)
    }

    var canSubmit: Bool {
        items.allSatisfy { responses[$0.id] != nil }
    }

    // MARK: - Loading

    func loadConfig() async {
        isLoading = true
        do {
            config = try await apiClient.request(APIEndpoints.fsConfig())
        } catch {
            errorMessage = "SPADI-Fragebogen konnte nicht geladen werden."
        }
        isLoading = false
    }

    // MARK: - Response

    func selectResponse(itemId: String, value: Int) {
        responses[itemId] = value
        autoAdvanceTask?.cancel()

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
        guard currentItemIndex > 0 else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentItemIndex -= 1
        }
    }

    // MARK: - Submission

    func submit() async -> Bool {
        guard canSubmit else { return false }
        isSubmitting = true
        errorMessage = nil

        let submission = FsScreeningSubmission(responses: responses)
        let endpoint = isRescreening
            ? APIEndpoints.submitFsRescreening(body: submission)
            : APIEndpoints.submitFsScreening(body: submission)

        do {
            let response: FsScreeningResponse = try await apiClient.request(endpoint)
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
