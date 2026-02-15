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
}

// MARK: - Progress Stats (convenience, populated from StatsResponse)

struct ProgressStats {
    let totalSessions: Int
    let lastSevenDays: Int
    let averagePain: Double
    let compliancePercent: Double
    let recentPainLevels: [StatsResponse.RecentPain]?
}
