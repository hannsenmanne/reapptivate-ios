import Foundation

// MARK: - Progression Readiness

struct ProgressionReadiness: Codable {
    let minDaysMet: Bool
    let minSessionsMet: Bool
    let painCriteriaMet: Bool
    let complianceCriteriaMet: Bool

    var criteriaMetCount: Int {
        [minDaysMet, minSessionsMet, painCriteriaMet, complianceCriteriaMet]
            .filter { $0 }.count
    }
}

// MARK: - Adaptive Phase Status

struct AdaptivePhaseStatus: Codable {
    let currentPhase: Int
    let phaseName: String
    let daysInPhase: Int
    let sessionsInPhase: Int
    let lastDecision: AdaptationDecision
    let lastDecisionReason: String
    let lastDecisionDate: String?
    let currentPainAvg: Double
    let currentCompliance: Double
    let progressionReadiness: ProgressionReadiness
    let nextEvaluationHint: String
}

// MARK: - Adaptation Result (returned from progress logging)

struct AdaptationResult: Codable {
    let currentPhase: Int
    let previousPhase: Int
    let decision: AdaptationDecision
    let reason: String
    let reasonKey: String
    let avgPainLevel: Double
    let compliancePct: Double
    let sessionsInPhase: Int
    let daysInPhase: Int

    var phaseChanged: Bool {
        decision == .progress || decision == .regress
    }
}

// MARK: - Phase Adaptation Record (history)

struct PhaseAdaptationRecord: Codable, Identifiable {
    let id: String
    let userId: String
    let currentPhase: Int
    let previousPhase: Int?
    let decision: AdaptationDecision
    let reason: String
    let avgPainLevel: Double?
    let compliancePct: Double?
    let sessionsInPhase: Int
    let daysInPhase: Int
    let decidedAt: String
    let therapistOverride: Bool

    var decidedAtDate: Date? {
        Date.fromISO8601(decidedAt)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case currentPhase = "current_phase"
        case previousPhase = "previous_phase"
        case decision, reason
        case avgPainLevel = "avg_pain_level"
        case compliancePct = "compliance_pct"
        case sessionsInPhase = "sessions_in_phase"
        case daysInPhase = "days_in_phase"
        case decidedAt = "decided_at"
        case therapistOverride = "therapist_override"
    }
}
