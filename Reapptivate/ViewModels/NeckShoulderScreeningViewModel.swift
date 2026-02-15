import SwiftUI

@Observable
@MainActor
final class NeckShoulderScreeningViewModel {
    var config: NeckShoulderScreeningConfig?
    var currentSection: ScreeningSection = .redFlags
    var currentItemIndex = 0
    var showSectionTransition = false
    var transitionTitle = ""
    var transitionDescription = ""
    var isLoading = false
    var isSubmitting = false
    var errorMessage: String?
    var result: NeckShoulderScreeningResult?

    // Responses: yesno → Bool stored as 1/0, scale → Int, choice → String
    var responses: [String: AnyCodable] = [:]

    private let apiClient: APIClient

    enum ScreeningSection: Int, CaseIterable {
        case redFlags = 0
        case severity = 1
        case loadProfile = 2

        var title: String {
            switch self {
            case .redFlags: "Sicherheit"
            case .severity: "Schweregrad"
            case .loadProfile: "Belastung"
            }
        }
    }

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    // MARK: - Computed Properties

    var currentItems: [NeckShoulderScreeningItem] {
        guard let config else { return [] }
        switch currentSection {
        case .redFlags: return config.redFlags.items
        case .severity: return config.severity.items
        case .loadProfile: return config.loadProfile.items
        }
    }

    var currentItem: NeckShoulderScreeningItem? {
        guard currentItemIndex < currentItems.count else { return nil }
        return currentItems[currentItemIndex]
    }

    var allItems: [NeckShoulderScreeningItem] {
        guard let config else { return [] }
        return config.redFlags.items + config.severity.items + config.loadProfile.items
    }

    var progress: Double {
        let total = allItems.count
        guard total > 0 else { return 0 }
        return Double(responses.count) / Double(total)
    }

    var canSubmit: Bool {
        allItems.allSatisfy { responses[$0.id] != nil }
    }

    // MARK: - Loading

    func loadConfig() async {
        isLoading = true
        do {
            config = try await apiClient.request(APIEndpoints.neckShoulderConfig())
        } catch {
            errorMessage = "Screening konnte nicht geladen werden."
        }
        isLoading = false
    }

    // MARK: - Response Handling

    func selectYesNo(itemId: String, value: Bool) {
        responses[itemId] = AnyCodable(value)
        advanceAfterResponse()
    }

    func selectScale(itemId: String, value: Int) {
        responses[itemId] = AnyCodable(value)
        advanceAfterResponse()
    }

    func selectChoice(itemId: String, value: String) {
        responses[itemId] = AnyCodable(value)
        advanceAfterResponse()
    }

    private func advanceAfterResponse() {
        let items = currentItems
        if currentItemIndex < items.count - 1 {
            Task {
                try? await Task.sleep(for: .milliseconds(500))
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentItemIndex += 1
                }
            }
        } else {
            // End of current section — advance to next
            let allSections = ScreeningSection.allCases
            guard let nextIndex = allSections.firstIndex(of: currentSection).map({ $0 + 1 }),
                  nextIndex < allSections.count else {
                return // Already at last section — wait for submit
            }
            let nextSection = allSections[nextIndex]
            Task {
                try? await Task.sleep(for: .milliseconds(500))
                withAnimation {
                    transitionTitle = sectionTransitionTitle(for: nextSection)
                    transitionDescription = sectionTransitionDescription(for: nextSection)
                    showSectionTransition = true
                }
            }
        }
    }

    func continueToNextSection() {
        let allSections = ScreeningSection.allCases
        guard let nextIndex = allSections.firstIndex(of: currentSection).map({ $0 + 1 }),
              nextIndex < allSections.count else { return }

        withAnimation(.easeInOut(duration: 0.3)) {
            currentSection = allSections[nextIndex]
            currentItemIndex = 0
            showSectionTransition = false
        }
    }

    func goBack() {
        if currentItemIndex > 0 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentItemIndex -= 1
            }
        } else {
            // Go back to previous section's last item
            let allSections = ScreeningSection.allCases
            guard let prevIndex = allSections.firstIndex(of: currentSection).map({ $0 - 1 }),
                  prevIndex >= 0 else { return }

            let prevSection = allSections[prevIndex]
            let prevItems: [NeckShoulderScreeningItem]
            switch prevSection {
            case .redFlags: prevItems = config?.redFlags.items ?? []
            case .severity: prevItems = config?.severity.items ?? []
            case .loadProfile: prevItems = config?.loadProfile.items ?? []
            }

            withAnimation(.easeInOut(duration: 0.3)) {
                currentSection = prevSection
                currentItemIndex = max(0, prevItems.count - 1)
            }
        }
    }

    var canGoBack: Bool {
        currentItemIndex > 0 || currentSection.rawValue > 0
    }

    // MARK: - Submission

    func submit() async -> Bool {
        guard canSubmit else { return false }
        isSubmitting = true
        errorMessage = nil

        let submission = NeckShoulderScreeningSubmission(responses: responses)

        do {
            let response: NeckShoulderScreeningResponse = try await apiClient.request(
                APIEndpoints.submitNeckShoulderScreening(body: submission)
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

    // MARK: - Helpers

    private func sectionTransitionTitle(for section: ScreeningSection) -> String {
        switch section {
        case .redFlags: "Sicherheits-Screening"
        case .severity: "Schweregrad-Einschätzung"
        case .loadProfile: "Belastungsprofil"
        }
    }

    private func sectionTransitionDescription(for section: ScreeningSection) -> String {
        switch section {
        case .redFlags:
            "Bitte beantworten Sie einige Sicherheitsfragen."
        case .severity:
            "Jetzt erfassen wir Ihr aktuelles Schmerz- und Einschränkungsniveau."
        case .loadProfile:
            "Abschließend benötigen wir Informationen zu Ihrem Belastungsprofil."
        }
    }
}
