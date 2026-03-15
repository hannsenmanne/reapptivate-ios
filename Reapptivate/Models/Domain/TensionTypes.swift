import Foundation

// MARK: - TSI Screening Config

// API response from GET /api/tension/config: { version, items }
// Single-part screening (no Part A/B like Neck)

struct TsiScreeningOption: Codable {
    let value: Int
    let labelDe: String
    var labelEn: String? = nil
}

struct TsiScreeningItem: Codable, Identifiable {
    let id: String
    let textDe: String
    var textEn: String? = nil
    let options: [TsiScreeningOption]?
}

struct TsiScreeningConfig: Codable {
    let version: String
    let items: [TsiScreeningItem]
}

// MARK: - TSI Screening Submission

struct TsiScreeningSubmission: Codable {
    let responses: [String: Int]
}

// MARK: - TSI Screening Result

// API response from POST /api/tension/screening: { screening: { id, tsiScore, tsiCategory, createdAt } }
// API response from GET /api/tension/result: { screening: { id, tsiScore, tsiCategory, ... } }
struct TsiScreeningResult: Codable {
    let id: String?
    let tsiScore: Int
    let tsiCategory: String
    let createdAt: String?
}

// MARK: - TSI Focus Area

// API response from GET /api/tension/focus-areas: { focusAreas: [...] }
struct TsiFocusArea: Codable, Identifiable, FocusAreaProtocol {
    let domainId: String
    let domainLabel: String
    let score: Int
    let maxScore: Int
    let dailyTips: [String]?

    var id: String { domainId }

    var percentage: Double {
        guard maxScore > 0 else { return 0 }
        return Double(score) / Double(maxScore) * 100
    }
}

// MARK: - TSI History Entry

// API response from GET /api/tension/history: { history: [...] }
struct TsiHistoryEntry: Codable, Identifiable {
    let id: String
    let tsiScore: Int
    let tsiCategory: String?
    let severityGrade: TsiSeverityGrade?
    let createdAt: String

    var createdAtDate: Date? {
        Date.fromISO8601(createdAt)
    }
}
