import Foundation

// MARK: - Neck Screening Config

// API response from GET /api/neck/config: { version, partA, partB }
// partA has radiculopathy classification items, partB has NDI items

struct NeckScreeningOption: Codable {
    let value: Int
    let labelDe: String
    let labelEn: String?
}

struct NeckScreeningItem: Codable, Identifiable {
    let id: String
    let part: String?  // "A" or "B" (added by client for flat access)
    let textDe: String
    let textEn: String?
    let type: String?  // "yesno", "scale", "likert"
    let options: [NeckScreeningOption]?
}

struct NeckScreeningPartConfig: Codable {
    let title: String?
    let description: String?
    let items: [NeckScreeningItem]
}

struct NeckScreeningConfig: Codable {
    let version: String
    let partA: NeckScreeningPartConfig?
    let partB: NeckScreeningPartConfig?

    // Convenience: flatten items with part tags for the VM
    var items: [NeckScreeningItem] {
        let aItems = (partA?.items ?? []).map { item in
            NeckScreeningItem(id: item.id, part: "A", textDe: item.textDe, textEn: item.textEn, type: item.type, options: item.options)
        }
        let bItems = (partB?.items ?? []).map { item in
            NeckScreeningItem(id: item.id, part: "B", textDe: item.textDe, textEn: item.textEn, type: item.type, options: item.options)
        }
        return aItems + bItems
    }
}

// MARK: - Neck Screening Submission

struct NeckScreeningSubmission: Codable {
    let responses: [String: Int]
}

// MARK: - Neck Screening Result

// API response from POST /api/neck/screening: { screening: { id, subtype, subtypeScore, ndiScore, ndiCategory, createdAt } }
// API response from GET /api/neck/result: { screening: { id, subtype, ndiScore, ndiCategory, ... } }
struct NeckScreeningResult: Codable {
    let id: String?
    let subtype: String?
    let subtypeScore: Int?
    let ndiScore: Int
    let ndiCategory: String
    let createdAt: String?
}

// MARK: - NDI Focus Area

// API response from GET /api/neck/focus-areas: { focusAreas: [...] }
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

// API response from GET /api/neck/history: { history: [...] }
struct NdiHistoryEntry: Codable, Identifiable {
    let id: String
    let ndiScore: Int
    let ndiCategory: String?
    let severityGrade: NdiSeverityGrade?
    let createdAt: String

    var createdAtDate: Date? {
        Date.fromISO8601(createdAt)
    }
}
