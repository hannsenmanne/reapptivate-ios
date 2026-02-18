import Foundation

// MARK: - Progress Entry (from API)

struct ProgressEntry: Codable, Identifiable {
    let id: String
    let userId: String?
    let exerciseId: String
    let completedAt: String
    let setsCompleted: Int
    let repsCompleted: Int
    let painLevel: Int
    let notes: String?
    let symptomResponse: SymptomResponse?

    var completedAtDate: Date? {
        Date.fromISO8601(completedAt)
    }
}

// MARK: - Progress Log Request (POST body)

struct ProgressLogRequest: Codable {
    let exerciseId: String
    let painLevel: Int
    let setsCompleted: Int
    let repsCompleted: Int
    let notes: String?
    let symptomResponse: SymptomResponse?

    init(exerciseId: String, painLevel: Int, setsCompleted: Int, repsCompleted: Int, notes: String?, symptomResponse: SymptomResponse?) {
        self.exerciseId = exerciseId
        self.painLevel = min(max(painLevel, 0), 10)
        self.setsCompleted = setsCompleted
        self.repsCompleted = repsCompleted
        self.notes = notes
        self.symptomResponse = symptomResponse
    }
}

// MARK: - Progress Stats (convenience, populated from StatsResponse)

struct ProgressStats {
    let totalSessions: Int
    let lastSevenDays: Int
    let averagePain: Double
    let compliancePercent: Double
    let recentPainLevels: [StatsResponse.RecentPain]?
}
