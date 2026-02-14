import Foundation

struct StreakData: Codable, Sendable {
    let currentStreak: Int
    let longestStreak: Int
    let freezeTokens: Int
    let lastTrainingDate: String?
}
