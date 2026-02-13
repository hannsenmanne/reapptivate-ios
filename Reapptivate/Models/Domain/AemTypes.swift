import Foundation

// MARK: - AEM Screening Config

// API response from GET /api/aem/config: { version, items, likertScale }
struct AemCutoff: Codable {
    let low: Double
    let high: Double
}

struct AemLikertScale: Codable {
    let min: Int
    let max: Int
    let labels: [String: [String]]?
}

struct AemScreeningItem: Codable, Identifiable {
    let id: String
    let textDe: String
    let textEn: String?
    let subscale: String
    let reverse: Bool
}

struct AemScreeningConfig: Codable {
    let version: String
    let items: [AemScreeningItem]
    let likertScale: AemLikertScale?
    let cutoffs: [String: AemCutoff]?
}

// MARK: - AEM Screening Result

// API response from POST /api/aem/screening: { screening: { id, subscaleScores, subtype, completedAt } }
// API response from GET /api/aem/result: { screening: { id, subscaleScores, subtype, completedAt } }
struct AemSubscaleScores: Codable {
    let fearAvoidance: Double
    let distressEndurance: Double
    let eustressEndurance: Double
}

struct AemScreeningResult: Codable {
    let id: String?
    let subscaleScores: AemSubscaleScores
    let subtype: AemSubtype
    let completedAt: String?
}

// MARK: - AEM Screening Submission

struct AemScreeningSubmission: Codable {
    let responses: [String: Int]
}
