import Foundation

// MARK: - Progress Entry (from API)

struct ProgressEntry: Codable, Identifiable {
    let id: String
    let userId: String
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

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case exerciseId = "exercise_id"
        case completedAt = "completed_at"
        case setsCompleted = "sets_completed"
        case repsCompleted = "reps_completed"
        case painLevel = "pain_level"
        case notes
        case symptomResponse = "symptom_response"
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

// MARK: - Progress Stats (from /progress/stats)

struct ProgressStats: Codable {
    let totalSessions: Int
    let lastSevenDays: Int
    let averagePain: Double
    let compliancePercent: Double

    enum CodingKeys: String, CodingKey {
        case totalSessions = "total_sessions"
        case lastSevenDays = "last_seven_days"
        case averagePain = "average_pain"
        case compliancePercent = "compliance_percent"
    }
}

// MARK: - Progress Log Response (includes adaptation)

struct ProgressLogResponse: Codable {
    let entry: ProgressEntry
    let adaptation: AdaptationResult?
}
