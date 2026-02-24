import Foundation

@Observable
@MainActor
final class AclLabAssessmentViewModel {
    var assessments: [AclLabAssessment] = []
    var isLoading = false
    var errorMessage: String?

    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    // MARK: - Load

    func loadAssessments() async {
        isLoading = true
        errorMessage = nil

        do {
            let response: AclLabAssessmentListResponse = try await apiClient.request(
                APIEndpoints.aclLabAssessmentHistory()
            )
            assessments = response.assessments.sorted {
                ($0.assessmentDate ?? "") > ($1.assessmentDate ?? "")
            }
            isLoading = false
        } catch {
            errorMessage = "Laborwerte konnten nicht geladen werden."
            isLoading = false
        }
    }

    // MARK: - LSI Color Helpers

    static func lsiColor(for value: Double?) -> LSILevel {
        guard let value else { return .none }
        if value < 70 { return .red }
        if value < 85 { return .amber }
        return .green
    }

    enum LSILevel {
        case red, amber, green, none
    }
}
