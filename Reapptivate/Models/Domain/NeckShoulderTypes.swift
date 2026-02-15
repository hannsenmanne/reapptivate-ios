import Foundation

// MARK: - Neck-Shoulder Severity

enum NeckShoulderSeverity: String, Codable {
    case mild
    case moderate
    case high

    var displayName: String {
        switch self {
        case .mild: "Leicht"
        case .moderate: "Mittel"
        case .high: "Hoch"
        }
    }
}

// MARK: - Screening Config

// API response from GET /api/neck-shoulder/config
struct NeckShoulderScreeningConfig: Codable {
    let redFlags: RedFlagSection
    let severity: SeveritySection
    let loadProfile: LoadProfileSection

    struct RedFlagSection: Codable {
        let title: String
        let description: String
        let items: [NeckShoulderScreeningItem]
    }

    struct SeveritySection: Codable {
        let title: String
        let items: [NeckShoulderScreeningItem]
    }

    struct LoadProfileSection: Codable {
        let title: String
        let items: [NeckShoulderScreeningItem]
    }
}

struct NeckShoulderScreeningItem: Codable, Identifiable {
    let id: String
    let textDe: String
    let type: String          // "yesno", "scale", "choice"
    let min: Int?
    let max: Int?
    let options: [NeckShoulderScreeningOption]?
}

struct NeckShoulderScreeningOption: Codable {
    let value: String
    let labelDe: String
}

// MARK: - Screening Result

// API response from POST /api/neck-shoulder/screening: { screening: { ... } }
struct NeckShoulderScreeningResult: Codable {
    let id: String?
    let severity: NeckShoulderSeverity
    let redFlagAlert: Bool
    let painScore: Double
    let disabilityScore: Double
    let screenHours: String?
    let stressScore: Double?
    let createdAt: String?
}

// MARK: - Screening Submission

struct NeckShoulderScreeningSubmission: Codable {
    let responses: [String: AnyCodable]
}

// MARK: - Program

struct NeckShoulderProgram: Codable {
    let id: String
    let severity: NeckShoulderSeverity
    let durationWeeks: Int
    let currentWeek: Int
    let strengthFrequency: Int
    let mobilityFrequency: Int
    let microPauseIntervalMinutes: Int
    let progressionHistory: [ProgressionEntry]?
    let createdAt: String?

    struct ProgressionEntry: Codable {
        let week: Int
        let action: String
        let details: String
        let date: String
    }
}

struct NeckShoulderExercise: Codable, Identifiable {
    let id: String
    let name: String
    let targetMuscle: String?
    let sets: Int?
    let reps: String?
    let equipment: String?
    let instructions: String?
    let progressionNotes: String?
    let holdSeconds: Int?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        targetMuscle = try container.decodeIfPresent(String.self, forKey: .targetMuscle)
        sets = try container.decodeIfPresent(Int.self, forKey: .sets)
        equipment = try container.decodeIfPresent(String.self, forKey: .equipment)
        instructions = try container.decodeIfPresent(String.self, forKey: .instructions)
        progressionNotes = try container.decodeIfPresent(String.self, forKey: .progressionNotes)
        holdSeconds = try container.decodeIfPresent(Int.self, forKey: .holdSeconds)
        // reps can be String ("12-15") or Int (3) depending on exercise type
        if let stringVal = try? container.decode(String.self, forKey: .reps) {
            reps = stringVal
        } else if let intVal = try? container.decode(Int.self, forKey: .reps) {
            reps = "\(intVal)"
        } else {
            reps = nil
        }
    }

    /// Formatted detail string e.g. "3 x 12-15" or "30s halten"
    var detail: String {
        if let sets, let reps {
            return "\(sets) x \(reps)"
        } else if let holdSeconds {
            return "\(holdSeconds)s halten"
        } else if let reps {
            return reps
        }
        return name
    }
}

struct NeckShoulderExerciseConfig: Codable {
    let programA: ProgramSection
    let programB: ProgramSection
    let dailyMobility: MobilitySection
    let microPauses: MicroPauseSection

    struct ProgramSection: Codable {
        let name: String
        let durationMinutes: String?
        let exercises: [NeckShoulderExercise]
    }

    struct MobilitySection: Codable {
        let name: String
        let frequencyPerDay: String
        let durationMinutes: String
        let exercises: [NeckShoulderExercise]
    }

    struct MicroPauseSection: Codable {
        let intervalMinutes: String
        let durationMinutes: String
        let exercises: [NeckShoulderExercise]
    }
}

struct NeckShoulderWeeklyPlan: Codable {
    let weekNumber: Int
    let totalWeeks: Int
    let strengthSessions: [StrengthSession]
    let mobilityPerDay: MobilityPerDay
    let microPauses: MicroPausePlan

    struct StrengthSession: Codable {
        let dayLabel: String
        let program: String
        let exercises: [NeckShoulderExercise]
    }

    struct MobilityPerDay: Codable {
        let frequencyPerDay: String
        let durationMinutes: String
        let exercises: [NeckShoulderExercise]
    }

    struct MicroPausePlan: Codable {
        let intervalMinutes: Int
        let exercises: [NeckShoulderExercise]
    }
}

// MARK: - Progression Result

struct NeckShoulderProgressionResult: Codable {
    let canProgress: Bool
    let currentWeek: Int
    let totalWeeks: Int
    let avgPain: Double
    let compliance: Double
    let recommendation: String
    let suggestions: [String]
}

// MARK: - Session Log

struct NeckShoulderSessionLog: Codable, Identifiable {
    let id: String
    let sessionType: String
    let weekNumber: Int
    let painBefore: Double?
    let painAfter: Double?
    let exercisesCompleted: [String]?
    let durationSeconds: Int?
    let notes: String?
    let completedAt: String
}

struct NeckShoulderSessionLogRequest: Codable {
    let sessionType: String
    let painBefore: Double?
    let painAfter: Double?
    let exercisesCompleted: [String]
    let durationSeconds: Int?
    let notes: String?
}

// MARK: - Compliance Stats

struct NeckShoulderComplianceStats: Codable {
    let weekNumber: Int
    let strengthSessionsCompleted: Int
    let strengthSessionsTarget: Int
    let mobilitySessionsCompleted: Int
    let mobilitySessionsTarget: Int
    let microPausesCompleted: Int
    let overallPercent: Double
}

// MARK: - Micro-Pause Stats

struct NstMicroPauseStats: Codable {
    let completed: Int
    let target: Int
}

// MARK: - Plan Adjustments

struct NstPlanAdjustment: Codable, Identifiable {
    let id: String
    let ruleId: String
    let action: String
    let payload: [String: AnyCodable]?
    let applied: Bool
    let appliedAt: String?
    let createdAt: String
}
