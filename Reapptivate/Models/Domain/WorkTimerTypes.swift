import Foundation

// MARK: - Work Timer Settings

struct WorkTimerSettings: Codable {
    let startTime: String      // "HH:mm"
    let endTime: String
    let breakIntervalMinutes: Int
    let breakDurationMinutes: Int
    let isEnabled: Bool
}

// MARK: - Work Timer Break Exercise

struct WorkTimerBreakExercise: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let durationSeconds: Int
    let targetConditions: [String]?
    let minPhase: Int?
    let category: String
}

// MARK: - Work Timer Break Log (POST body)

struct WorkTimerBreakLog: Codable {
    let breakNumber: Int
    let completed: Bool
    let skipped: Bool
    let exercisesShown: [String]
}

// MARK: - Work Timer Day Summary

struct WorkTimerDaySummary: Codable {
    let date: String
    let totalWorkMinutes: Int
    let breaksOffered: Int
    let breaksCompleted: Int
    let breaksSkipped: Int
    let adherencePercent: Double
}
