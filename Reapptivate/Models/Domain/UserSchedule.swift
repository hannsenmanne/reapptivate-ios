import Foundation

struct UserSchedule: Codable {
    let userId: String?
    let availableDays: [Int]
    let preferredTimes: [String]
    let notificationsEnabled: Bool
}

struct ScheduleRequest: Codable {
    let availableDays: [Int]
    let preferredTimes: [String]
    let notificationsEnabled: Bool

    enum CodingKeys: String, CodingKey {
        case availableDays = "available_days"
        case preferredTimes = "preferred_times"
        case notificationsEnabled = "notifications_enabled"
    }
}
