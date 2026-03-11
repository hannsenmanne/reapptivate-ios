import Foundation
import SwiftData

@Model
final class CachedUser {
    @Attribute(.unique) var userId: String
    var email: String
    var name: String
    var tendinopathyType: String
    var adaptivePhase: Int
    var aemSubtype: String?
    var ndiSeverity: String?
    var tsiSeverity: String?
    var protocolId: String?
    var aemScreeningCompleted: Bool
    var neckScreeningCompleted: Bool
    var tensionScreeningCompleted: Bool
    var aclScreeningCompleted: Bool
    var aclAthleteLevel: String?
    var aclGraftType: String?
    var aclSurgeryDate: String?
    var aclCurrentMilestone: Int?
    var aclConcomitantInjuries: String?
    var siScreeningCompleted: Bool
    var siSeverity: String?
    var fsScreeningCompleted: Bool
    var fsSeverity: String?
    var lasScreeningCompleted: Bool
    var lasSeverity: String?
    var startDate: String
    var lastSyncedAt: Date

    init(
        userId: String,
        email: String,
        name: String,
        tendinopathyType: String,
        adaptivePhase: Int = 1,
        aemSubtype: String? = nil,
        ndiSeverity: String? = nil,
        tsiSeverity: String? = nil,
        protocolId: String? = nil,
        aemScreeningCompleted: Bool = false,
        neckScreeningCompleted: Bool = false,
        tensionScreeningCompleted: Bool = false,
        aclScreeningCompleted: Bool = false,
        aclAthleteLevel: String? = nil,
        aclGraftType: String? = nil,
        aclSurgeryDate: String? = nil,
        aclCurrentMilestone: Int? = nil,
        aclConcomitantInjuries: String? = nil,
        siScreeningCompleted: Bool = false,
        siSeverity: String? = nil,
        fsScreeningCompleted: Bool = false,
        fsSeverity: String? = nil,
        lasScreeningCompleted: Bool = false,
        lasSeverity: String? = nil,
        startDate: String,
        lastSyncedAt: Date = .now
    ) {
        self.userId = userId
        self.email = email
        self.name = name
        self.tendinopathyType = tendinopathyType
        self.adaptivePhase = adaptivePhase
        self.aemSubtype = aemSubtype
        self.ndiSeverity = ndiSeverity
        self.tsiSeverity = tsiSeverity
        self.protocolId = protocolId
        self.aemScreeningCompleted = aemScreeningCompleted
        self.neckScreeningCompleted = neckScreeningCompleted
        self.tensionScreeningCompleted = tensionScreeningCompleted
        self.aclScreeningCompleted = aclScreeningCompleted
        self.aclAthleteLevel = aclAthleteLevel
        self.aclGraftType = aclGraftType
        self.aclSurgeryDate = aclSurgeryDate
        self.aclCurrentMilestone = aclCurrentMilestone
        self.aclConcomitantInjuries = aclConcomitantInjuries
        self.siScreeningCompleted = siScreeningCompleted
        self.siSeverity = siSeverity
        self.fsScreeningCompleted = fsScreeningCompleted
        self.fsSeverity = fsSeverity
        self.lasScreeningCompleted = lasScreeningCompleted
        self.lasSeverity = lasSeverity
        self.startDate = startDate
        self.lastSyncedAt = lastSyncedAt
    }

    func update(from profile: UserProfile) {
        email = profile.email
        name = profile.name
        tendinopathyType = profile.tendinopathyType.rawValue
        adaptivePhase = profile.currentPhase
        aemSubtype = profile.aemSubtype?.rawValue
        ndiSeverity = profile.ndiSeverity?.rawValue
        tsiSeverity = profile.tsiSeverity?.rawValue
        protocolId = profile.protocolId
        aemScreeningCompleted = profile.aemScreeningCompleted ?? false
        neckScreeningCompleted = profile.neckScreeningCompleted ?? false
        tensionScreeningCompleted = profile.tensionScreeningCompleted ?? false
        aclScreeningCompleted = profile.aclScreeningCompleted ?? false
        aclAthleteLevel = profile.aclAthleteLevel?.rawValue
        aclGraftType = profile.aclGraftType?.rawValue
        aclSurgeryDate = profile.aclSurgeryDate
        aclCurrentMilestone = profile.aclCurrentMilestone
        aclConcomitantInjuries = profile.aclConcomitantInjuries?.map(\.rawValue).joined(separator: ",")
        siScreeningCompleted = profile.siScreeningCompleted ?? false
        siSeverity = profile.siSeverity?.rawValue
        fsScreeningCompleted = profile.fsScreeningCompleted ?? false
        fsSeverity = profile.fsSeverity?.rawValue
        lasScreeningCompleted = profile.lasScreeningCompleted ?? false
        lasSeverity = profile.lasSeverity?.rawValue
        startDate = profile.startDate
        lastSyncedAt = .now
    }
}
