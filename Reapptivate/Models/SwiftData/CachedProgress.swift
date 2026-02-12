import Foundation
import SwiftData

@Model
final class CachedProgress {
    @Attribute(.unique) var entryId: String
    var userId: String
    var exerciseId: String
    var completedAt: String
    var setsCompleted: Int
    var repsCompleted: Int
    var painLevel: Int
    var notes: String?

    init(
        entryId: String,
        userId: String,
        exerciseId: String,
        completedAt: String,
        setsCompleted: Int,
        repsCompleted: Int,
        painLevel: Int,
        notes: String? = nil
    ) {
        self.entryId = entryId
        self.userId = userId
        self.exerciseId = exerciseId
        self.completedAt = completedAt
        self.setsCompleted = setsCompleted
        self.repsCompleted = repsCompleted
        self.painLevel = painLevel
        self.notes = notes
    }

    convenience init(from entry: ProgressEntry) {
        self.init(
            entryId: entry.id,
            userId: entry.userId,
            exerciseId: entry.exerciseId,
            completedAt: entry.completedAt,
            setsCompleted: entry.setsCompleted,
            repsCompleted: entry.repsCompleted,
            painLevel: entry.painLevel,
            notes: entry.notes
        )
    }
}
