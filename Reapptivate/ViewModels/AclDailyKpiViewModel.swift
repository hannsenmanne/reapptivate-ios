import Foundation

@Observable
@MainActor
final class AclDailyKpiViewModel {
    // Form state
    var painNrs: Int = 0
    var painLocation: String = ""
    var painActivity: String = ""
    var kneeFlexionDeg: Int = 90
    var extensionDeficitDeg: Int = 0
    var swellingGrade: Int = 0
    var quadsLag: Bool = false
    var notes: String = ""

    // Submission state
    var isSubmitting = false
    var errorMessage: String?
    var didSubmit = false

    // History state
    var dailyKpis: [AclDailyKpi] = []
    var isLoadingHistory = false

    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    // MARK: - Validation

    var isValid: Bool {
        painNrs >= 0 && painNrs <= 10
            && kneeFlexionDeg >= 0 && kneeFlexionDeg <= 160
            && extensionDeficitDeg >= 0 && extensionDeficitDeg <= 30
            && swellingGrade >= 0 && swellingGrade <= 3
    }

    // MARK: - Submit

    func submit() async -> Bool {
        guard isValid else {
            errorMessage = "Bitte überprüfen Sie Ihre Eingaben."
            return false
        }

        isSubmitting = true
        errorMessage = nil

        let request = AclDailyKpiRequest(
            date: nil,
            painNrs: painNrs,
            painLocation: painLocation.isEmpty ? nil : painLocation,
            painActivity: painActivity.isEmpty ? nil : painActivity,
            kneeFlexionDeg: kneeFlexionDeg,
            extensionDeficitDeg: extensionDeficitDeg,
            swellingGrade: swellingGrade,
            quadsLag: quadsLag,
            notes: notes.isEmpty ? nil : notes
        )

        do {
            let _: AclDailyKpiSingleResponse = try await apiClient.request(
                APIEndpoints.submitAclDailyKpi(body: request)
            )
            didSubmit = true
            isSubmitting = false
            return true
        } catch let error as APIError {
            errorMessage = error.localizedDescription
            isSubmitting = false
            return false
        } catch {
            errorMessage = "Speichern fehlgeschlagen."
            isSubmitting = false
            return false
        }
    }

    // MARK: - History

    func loadHistory() async {
        isLoadingHistory = true
        errorMessage = nil

        do {
            let response: AclDailyKpiListResponse = try await apiClient.request(
                APIEndpoints.aclDailyKpiHistory()
            )
            dailyKpis = (response.kpis ?? response.entries ?? [])
                .sorted { $0.date > $1.date }
            isLoadingHistory = false
        } catch {
            errorMessage = "Tages-KPIs konnten nicht geladen werden."
            isLoadingHistory = false
        }
    }
}
