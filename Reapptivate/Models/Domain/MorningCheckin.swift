import Foundation

// MARK: - Morning Check-In

struct MorningCheckin: Codable, Identifiable {
    let id: String
    let userId: String
    let date: String
    let painLevel: Int
    let sleepQuality: Int?
    let stiffnessLevel: Int?
    let mood: Int?
    let notes: String?
    let createdAt: Date
}

struct MorningCheckinRequest: Codable {
    let painLevel: Int
    let sleepQuality: Int?
    let stiffnessLevel: Int?
    let mood: Int?
    let notes: String?
}

struct CheckinTodayResponse: Codable {
    let checkedIn: Bool
    let checkin: MorningCheckin?
}

// MARK: - Smart Day

struct SmartDayResponse: Codable {
    let checkedIn: Bool
    let morningCheckin: MorningCheckinSummary?
    let isTrainingDay: Bool
    let dayMessage: String
    let exerciseOrder: [String]
    let educationSuggestions: [String]
    let dayInsight: String
    let progressHint: String?
    let aclContext: AclDayContext?
    let streakInfo: StreakInfo
}

struct MorningCheckinSummary: Codable {
    let painLevel: Int
    let sleepQuality: Int?
    let stiffness: Int?
    let mood: Int?
}

struct AclDayContext: Codable {
    let weeksPostSurgery: Int
    let currentMilestone: Int
    let nextMilestoneHint: String?
}

struct StreakInfo: Codable {
    let current: Int
    let longest: Int
}
