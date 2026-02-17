import Foundation

/// Response from GET/PUT /patient/schedule
/// Backend uses JS getDay() convention: 0=Sun, 1=Mon, ..., 6=Sat
struct ScheduleResponse: Codable, Sendable {
    let trainingDays: [Int]
    let isTrainingDay: Bool

    /// Training days converted to iOS Calendar.component(.weekday) convention (1=Sun, 2=Mon, ..., 7=Sat)
    var iosWeekdays: [Int] {
        trainingDays.map { $0 + 1 }
    }
}

/// Request body for PUT /patient/schedule (upsert)
/// Backend expects JS getDay() convention: 0=Sun, 1=Mon, ..., 6=Sat
struct ScheduleUpdateRequest: Codable, Sendable {
    let trainingDays: [Int]

    /// Create from iOS weekday convention (1-7) — converts to JS convention (0-6) for encoding
    static func fromIOSWeekdays(_ days: [Int]) -> ScheduleUpdateRequest {
        ScheduleUpdateRequest(trainingDays: days.map { $0 - 1 }.sorted())
    }
}
