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

    // Tension (Neck-Shoulder)
    var tensionScreeningCompleted: Bool?
    var tsiSeverity: TsiSeverityGrade?

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
        if tendinopathyType.isNeck || tendinopathyType.isTension { return 4 }
        return 3
    }
}
