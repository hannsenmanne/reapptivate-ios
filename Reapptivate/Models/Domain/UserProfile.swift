import Foundation

struct UserProfile: Codable, Identifiable {
    let id: String
    let email: String
    let name: String
    let tendinopathyType: TendinopathyType
    let protocolId: String?
    let startDate: String
    let createdAt: String?

    // AEM (LBP)
    var aemScreeningCompleted: Bool?
    var aemSubtype: AemSubtype?

    // Neck
    var neckScreeningCompleted: Bool?
    let neckSubtype: String?

    // Neck-Shoulder Tension
    var neckShoulderScreeningCompleted: Bool?
    var neckShoulderSeverity: NeckShoulderSeverity?

    // Populated from phase-status endpoint, not from /me
    var adaptivePhase: Int?
    var ndiSeverity: NdiSeverityGrade?

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
}
