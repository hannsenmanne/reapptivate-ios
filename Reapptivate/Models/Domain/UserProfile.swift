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

    // ACL
    var aclScreeningCompleted: Bool?
    var aclAthleteLevel: AclAthleteLevel?
    var aclGraftType: AclGraftType?
    var aclSurgeryDate: String?
    var aclCurrentMilestone: Int?
    var aclConcomitantInjuries: [AclConcomitantInjury]?

    // Shoulder Impingement
    var siScreeningCompleted: Bool?
    var siSeverity: SiSeverityGrade?

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

    var isAcl: Bool { tendinopathyType.isAcl }

    var maxPhase: Int {
        if tendinopathyType.isAcl { return 5 }
        if tendinopathyType.isNeck || tendinopathyType.isTension || tendinopathyType.isShoulder { return 4 }
        return 3
    }
}
