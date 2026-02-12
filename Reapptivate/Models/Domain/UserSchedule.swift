import Foundation

struct UserSchedule: Codable {
    let userId: String?
    let availableDays: [Int]
    let preferredTimes: [String]
    let notificationsEnabled: Bool

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case availableDays = "available_days"
        case preferredTimes = "preferred_times"
        case notificationsEnabled = "notifications_enabled"
    }
}

struct ScheduleRequest: Codable {
    let availableDays: [Int]
    let preferredTimes: [String]
    let notificationsEnabled: Bool
}
