import Foundation

// MARK: - AEM Screening Config

struct AemCutoff: Codable {
    let low: Double
    let high: Double
}

struct AemScreeningItem: Codable, Identifiable {
    let id: String
    let textDe: String
    let textEn: String
    let subscale: AemSubscale
    let reverse: Bool
}

struct AemScreeningConfig: Codable {
    let version: String
    let items: [AemScreeningItem]
    let cutoffs: [String: AemCutoff]
}

// MARK: - AEM Screening Result

struct AemSubscaleScores: Codable {
    let fearAvoidance: Double
    let distressEndurance: Double
    let eustressEndurance: Double

    enum CodingKeys: String, CodingKey {
        case fearAvoidance = "fear_avoidance"
        case distressEndurance = "distress_endurance"
        case eustressEndurance = "eustress_endurance"
    }
}

struct AemScreeningResult: Codable {
    let userId: Int
    let responses: [String: Int]
    let subscaleScores: AemSubscaleScores
    let subtype: AemSubtype
    let completedAt: String
}

// MARK: - AEM Screening Submission

struct AemScreeningSubmission: Codable {
    let responses: [String: Int]
}
