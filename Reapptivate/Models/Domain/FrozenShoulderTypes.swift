import Foundation

// MARK: - SPADI Screening Config

// API response from GET /api/frozen-shoulder/config: { version, title, description, items, scoring, severityGrades }

struct FsScreeningOption: Codable {
    let value: Int
    let labelDe: String
    var labelEn: String? = nil
}

struct FsScreeningItem: Codable, Identifiable {
    let id: String
    let textDe: String
    var textEn: String? = nil
    let options: [FsScreeningOption]?
}

struct FsScreeningConfig: Codable {
    let version: String
    let items: [FsScreeningItem]
}

// MARK: - SPADI Screening Submission

struct FsScreeningSubmission: Codable {
    let responses: [String: Int]
}

// MARK: - SPADI Screening Result

// API response from POST /api/frozen-shoulder/screening: { screening: { id, spadiTotalScore, spadiPainScore, spadiDisabilityScore, severityLabel, severityGrade, createdAt } }
// API response from GET /api/frozen-shoulder/result: { screening: { id, spadiTotalScore, spadiPainScore, spadiDisabilityScore, severityLabel, severityGrade, createdAt } }
struct FsScreeningResult: Codable {
    let id: String?
    let spadiTotalScore: Double
    let spadiPainScore: Double?
    let spadiDisabilityScore: Double?
    let severityLabel: String?
    let severityGrade: FsSeverityGrade
    let createdAt: String?
}

// MARK: - FS Focus Area

// API response from GET /api/frozen-shoulder/focus-areas: { focusAreas: [...] }
struct FsFocusArea: Codable, Identifiable, FocusAreaProtocol {
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

// MARK: - FS History Entry

// API response from GET /api/frozen-shoulder/history: { history: [...] }
struct FsHistoryEntry: Codable, Identifiable {
    let id: String
    let spadiTotalScore: Double
    let severityLabel: String?
    let severityGrade: FsSeverityGrade?
    let createdAt: String

    var createdAtDate: Date? {
        Date.fromISO8601(createdAt)
    }
}
