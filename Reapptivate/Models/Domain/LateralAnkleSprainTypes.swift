import Foundation

// MARK: - CAIT Screening Config

// API response from GET /api/lateral-ankle-sprain/config

struct LasScreeningOption: Codable {
    let value: Int
    let labelDe: String
    var labelEn: String? = nil
}

struct LasScreeningItem: Codable, Identifiable {
    let id: String
    let textDe: String
    var textEn: String? = nil
    let options: [LasScreeningOption]?
}

struct LasScreeningConfig: Codable {
    let version: String
    let items: [LasScreeningItem]
}

// MARK: - CAIT Screening Submission

struct LasScreeningSubmission: Codable {
    let responses: [String: Int]
}

// MARK: - CAIT Screening Result

// API response from POST /api/lateral-ankle-sprain/screening: { screening: { id, caitScore, severityLabel, severityGrade, createdAt } }
// API response from GET /api/lateral-ankle-sprain/result: { screening: { id, caitScore, severityLabel, severityGrade, createdAt } }
struct LasScreeningResult: Codable {
    let id: String?
    let caitScore: Int
    let severityLabel: String?
    let severityGrade: LasSeverityGrade
    let createdAt: String?
}

// MARK: - LAS Focus Area

// API response from GET /api/lateral-ankle-sprain/focus-areas: { focusAreas: [...] }
struct LasFocusArea: Codable, Identifiable, FocusAreaProtocol {
    let domainId: String
    let domainLabel: String
    let score: Int
    let maxScore: Int
    let dailyTips: [String]?

    var id: String { domainId }

    var percentage: Double {
        guard maxScore > 0 else { return 0 }
        // CAIT: lower score = MORE problematic (inverted scale)
        // Show inverted percentage for visual clarity (high bar = more problematic)
        return (1.0 - Double(score) / Double(maxScore)) * 100
    }
}

// MARK: - LAS History Entry

// API response from GET /api/lateral-ankle-sprain/history: { history: [...] }
struct LasHistoryEntry: Codable, Identifiable {
    let id: String
    let caitScore: Int
    let severityLabel: String?
    let severityGrade: LasSeverityGrade?
    let createdAt: String

    var createdAtDate: Date? {
        Date.fromISO8601(createdAt)
    }
}
