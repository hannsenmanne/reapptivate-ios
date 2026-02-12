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
        startDate = profile.startDate
        lastSyncedAt = .now
    }
}
