import Foundation

struct UserProfile: Codable, Identifiable {
    let id: String
    let email: String
    let name: String
    let tendinopathyType: TendinopathyType
    let protocolId: String?
    let startDate: String
    let createdAt: String

    // Adaptive phase
    let adaptivePhase: Int?
    let phaseStartedAt: String?
    let adaptationEnabled: Bool?

    // AEM (LBP)
    let aemScreeningCompleted: Bool?
    let aemSubtype: AemSubtype?

    // Neck
    let neckScreeningCompleted: Bool?
    let ndiSeverity: NdiSeverityGrade?

    var startDateParsed: Date? {
        Date.fromISO8601(startDate)
    }

    var daysSinceStart: Int {
        startDateParsed?.daysSinceNow ?? 0
    }

    var currentPhase: Int {
        adaptivePhase ?? 1
    }

    var maxPhase: Int {
        tendinopathyType.isNeck ? 4 : 3
    }

    enum CodingKeys: String, CodingKey {
        case id, email, name
        case tendinopathyType = "tendinopathy_type"
        case protocolId = "protocol_id"
        case startDate = "start_date"
        case createdAt = "created_at"
        case adaptivePhase = "adaptive_phase"
        case phaseStartedAt = "phase_started_at"
        case adaptationEnabled = "adaptation_enabled"
        case aemScreeningCompleted = "aem_screening_completed"
        case aemSubtype = "aem_subtype"
        case neckScreeningCompleted = "neck_screening_completed"
        case ndiSeverity = "ndi_severity"
    }
}
