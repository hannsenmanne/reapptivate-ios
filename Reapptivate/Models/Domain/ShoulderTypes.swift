import Foundation

// MARK: - QuickDASH Screening Config

// API response from GET /api/shoulder-impingement/config: { version, title, description, items, scoring, severityGrades }

struct SiScreeningOption: Codable {
    let value: Int
    let labelDe: String
    var labelEn: String? = nil
}

struct SiScreeningItem: Codable, Identifiable {
    let id: String
    let textDe: String
    var textEn: String? = nil
    let options: [SiScreeningOption]?
}

struct SiScreeningConfig: Codable {
    let version: String
    let items: [SiScreeningItem]
}

// MARK: - QuickDASH Screening Submission

struct SiScreeningSubmission: Codable {
    let responses: [String: Int]
}

// MARK: - QuickDASH Screening Result

// API response from POST /api/shoulder-impingement/screening: { screening: { id, quickDashScore, severityLabel, severityGrade, focusAreas, createdAt } }
// API response from GET /api/shoulder-impingement/result: { screening: { id, quickDashScore, severityLabel, severityGrade, createdAt } }
struct SiScreeningResult: Codable {
    let id: String?
    let quickDashScore: Double
    let severityLabel: String?
    let severityGrade: SiSeverityGrade
    let createdAt: String?
}

// MARK: - SI Focus Area

// API response from GET /api/shoulder-impingement/focus-areas: { focusAreas: [...] }
struct SiFocusArea: Codable, Identifiable {
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

// MARK: - SI History Entry

// API response from GET /api/shoulder-impingement/history: { history: [...] }
struct SiHistoryEntry: Codable, Identifiable {
    let id: String
    let quickDashScore: Double
    let severityLabel: String?
    let severityGrade: SiSeverityGrade?
    let createdAt: String

    var createdAtDate: Date? {
        Date.fromISO8601(createdAt)
    }
}
