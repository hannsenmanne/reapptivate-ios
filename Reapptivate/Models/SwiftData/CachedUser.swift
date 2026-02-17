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
    var tsiScreeningCompleted: Bool
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
        tsiScreeningCompleted: Bool = false,
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
        self.tsiScreeningCompleted = tsiScreeningCompleted
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
        tsiScreeningCompleted = profile.tsiScreeningCompleted ?? false
        startDate = profile.startDate
        lastSyncedAt = .now
    }
}
