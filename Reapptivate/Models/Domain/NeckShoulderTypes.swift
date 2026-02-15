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
