import Foundation

// MARK: - Neck Screening Config

struct NeckScreeningOption: Codable {
    let value: Int
    let labelDe: String
}

struct NeckScreeningItem: Codable, Identifiable {
    let id: String
    let part: String  // "A" or "B"
    let textDe: String
    let type: String  // "yesno", "scale", "likert"
    let options: [NeckScreeningOption]?
}

struct NeckScreeningConfig: Codable {
    let version: String
    let items: [NeckScreeningItem]
}

// MARK: - Neck Screening Submission

struct NeckScreeningSubmission: Codable {
    let responses: [String: Int]
}

// MARK: - Neck Screening Result

struct NeckScreeningResult: Codable {
    let userId: String
    let subtypeResult: NeckSubtype
    let ndiScore: Int
    let ndiCategory: String
    let completedAt: String
}

// MARK: - NDI Focus Area

struct NdiFocusArea: Codable, Identifiable {
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

// MARK: - NDI History Entry

struct NdiHistoryEntry: Codable, Identifiable {
    let id: String
    let ndiScore: Int
    let ndiCategory: String
    let severityGrade: NdiSeverityGrade
    let createdAt: String

    var createdAtDate: Date? {
        Date.fromISO8601(createdAt)
    }
}
