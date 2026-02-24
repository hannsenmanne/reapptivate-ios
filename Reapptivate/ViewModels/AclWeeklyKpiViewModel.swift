import Foundation

@Observable
@MainActor
final class AclWeeklyKpiViewModel {
    // Form state
    var ikdcScoreText: String = ""
    var tampaScoreText: String = ""
    var thighCirc5cmText: String = ""
    var thighCirc10cmText: String = ""

    // Submission state
    var isSubmitting = false
    var errorMessage: String?
    var didSubmit = false
    var showTampaAlert = false

    // History state
    var weeklyKpis: [AclWeeklyKpi] = []
    var isLoadingHistory = false

    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    // MARK: - Parsed Values

    var ikdcScore: Int? {
        Int(ikdcScoreText)
    }

    var tampaScore: Int? {
        Int(tampaScoreText)
    }

    var thighCirc5cm: Double? {
        Double(thighCirc5cmText.replacingOccurrences(of: ",", with: "."))
    }

    var thighCirc10cm: Double? {
        Double(thighCirc10cmText.replacingOccurrences(of: ",", with: "."))
    }

    // MARK: - Validation

    var hasAnyValue: Bool {
        ikdcScore != nil || tampaScore != nil || thighCirc5cm != nil || thighCirc10cm != nil
    }

    var validationError: String? {
        if let score = ikdcScore, (score < 0 || score > 100) {
            return "IKDC-Score muss zwischen 0 und 100 liegen."
        }
        if let score = tampaScore, (score < 11 || score > 44) {
            return "Tampa-Score muss zwischen 11 und 44 liegen."
        }
        if let circ = thighCirc5cm, (circ < 20 || circ > 80) {
            return "Oberschenkelumfang 5 cm muss zwischen 20 und 80 cm liegen."
        }
        if let circ = thighCirc10cm, (circ < 20 || circ > 80) {
            return "Oberschenkelumfang 10 cm muss zwischen 20 und 80 cm liegen."
        }
        return nil
    }

    // MARK: - Tampa Alert

    var isTampaElevated: Bool {
        if let score = tampaScore {
            return score > 37
        }
        return false
    }

    // MARK: - Submit

    func submit() async -> Bool {
        guard hasAnyValue else {
            errorMessage = "Bitte mindestens ein Feld ausfüllen."
            return false
        }

        if let error = validationError {
            errorMessage = error
            return false
        }

        isSubmitting = true
        errorMessage = nil

        let request = AclWeeklyKpiRequest(
            weekDate: nil,
            ikdcScore: ikdcScore,
            tampaScore: tampaScore,
            thighCirc5cm: thighCirc5cm,
            thighCirc10cm: thighCirc10cm
        )

        do {
            let response: AclWeeklyKpiResponse = try await apiClient.request(
                APIEndpoints.submitAclWeeklyKpi(body: request)
            )
            didSubmit = true
            showTampaAlert = response.tampaAlert ?? false
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
            let response: AclWeeklyKpiListResponse = try await apiClient.request(
                APIEndpoints.aclWeeklyKpiHistory()
            )
            weeklyKpis = (response.kpis ?? response.entries ?? [])
                .sorted { $0.weekDate > $1.weekDate }
            isLoadingHistory = false
        } catch {
            errorMessage = "Wochen-KPIs konnten nicht geladen werden."
            isLoadingHistory = false
        }
    }
}
