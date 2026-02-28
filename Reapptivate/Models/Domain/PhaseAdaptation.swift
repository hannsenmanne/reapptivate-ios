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

    private enum CodingKeys: String, CodingKey {
        case currentPhase, phaseName, daysInPhase, sessionsInPhase
        case lastDecision, lastDecisionReason, lastDecisionDate
        case currentPainAvg, currentCompliance
        case progressionReadiness, nextEvaluationHint
    }

    init(currentPhase: Int, phaseName: String, daysInPhase: Int, sessionsInPhase: Int, lastDecision: AdaptationDecision, lastDecisionReason: String, lastDecisionDate: String?, currentPainAvg: Double, currentCompliance: Double, progressionReadiness: ProgressionReadiness, nextEvaluationHint: String) {
        self.currentPhase = currentPhase
        self.phaseName = phaseName
        self.daysInPhase = daysInPhase
        self.sessionsInPhase = sessionsInPhase
        self.lastDecision = lastDecision
        self.lastDecisionReason = lastDecisionReason
        self.lastDecisionDate = lastDecisionDate
        self.currentPainAvg = currentPainAvg
        self.currentCompliance = currentCompliance
        self.progressionReadiness = progressionReadiness
        self.nextEvaluationHint = nextEvaluationHint
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        currentPhase = try container.decode(Int.self, forKey: .currentPhase)
        phaseName = try container.decode(String.self, forKey: .phaseName)
        daysInPhase = try container.decode(Int.self, forKey: .daysInPhase)
        sessionsInPhase = try container.decode(Int.self, forKey: .sessionsInPhase)
        lastDecision = try container.decode(AdaptationDecision.self, forKey: .lastDecision)
        lastDecisionReason = try container.decode(String.self, forKey: .lastDecisionReason)
        lastDecisionDate = try container.decodeIfPresent(String.self, forKey: .lastDecisionDate)
        if let value = try? container.decode(Double.self, forKey: .currentPainAvg) {
            currentPainAvg = value
        } else if let str = try? container.decode(String.self, forKey: .currentPainAvg) {
            currentPainAvg = Double(str) ?? 0
        } else {
            currentPainAvg = 0
        }
        if let value = try? container.decode(Double.self, forKey: .currentCompliance) {
            currentCompliance = value
        } else if let str = try? container.decode(String.self, forKey: .currentCompliance) {
            currentCompliance = Double(str) ?? 0
        } else {
            currentCompliance = 0
        }
        progressionReadiness = try container.decode(ProgressionReadiness.self, forKey: .progressionReadiness)
        nextEvaluationHint = try container.decode(String.self, forKey: .nextEvaluationHint)
    }
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

    private enum CodingKeys: String, CodingKey {
        case currentPhase, previousPhase, decision, reason, reasonKey
        case avgPainLevel, compliancePct, sessionsInPhase, daysInPhase
    }

    init(currentPhase: Int, previousPhase: Int, decision: AdaptationDecision, reason: String, reasonKey: String, avgPainLevel: Double, compliancePct: Double, sessionsInPhase: Int, daysInPhase: Int) {
        self.currentPhase = currentPhase
        self.previousPhase = previousPhase
        self.decision = decision
        self.reason = reason
        self.reasonKey = reasonKey
        self.avgPainLevel = avgPainLevel
        self.compliancePct = compliancePct
        self.sessionsInPhase = sessionsInPhase
        self.daysInPhase = daysInPhase
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        currentPhase = try container.decode(Int.self, forKey: .currentPhase)
        previousPhase = try container.decode(Int.self, forKey: .previousPhase)
        decision = try container.decode(AdaptationDecision.self, forKey: .decision)
        reason = try container.decode(String.self, forKey: .reason)
        reasonKey = try container.decode(String.self, forKey: .reasonKey)
        if let value = try? container.decode(Double.self, forKey: .avgPainLevel) {
            avgPainLevel = value
        } else if let str = try? container.decode(String.self, forKey: .avgPainLevel) {
            avgPainLevel = Double(str) ?? 0
        } else {
            avgPainLevel = 0
        }
        if let value = try? container.decode(Double.self, forKey: .compliancePct) {
            compliancePct = value
        } else if let str = try? container.decode(String.self, forKey: .compliancePct) {
            compliancePct = Double(str) ?? 0
        } else {
            compliancePct = 0
        }
        sessionsInPhase = try container.decode(Int.self, forKey: .sessionsInPhase)
        daysInPhase = try container.decode(Int.self, forKey: .daysInPhase)
    }
}

// MARK: - Phase Adaptation Record (history)

struct PhaseAdaptationRecord: Codable, Identifiable {
    let id: String
    let currentPhase: Int
    let previousPhase: Int?
    let decision: AdaptationDecision
    let reason: String
    let avgPainLevel: Double?
    let compliancePct: Double?
    let sessionsInPhase: Int
    let daysInPhase: Int
    let decidedAt: String
    let therapistOverride: Bool?

    var decidedAtDate: Date? {
        Date.fromISO8601(decidedAt)
    }

    private enum CodingKeys: String, CodingKey {
        case id, currentPhase, previousPhase, decision, reason
        case avgPainLevel, compliancePct, sessionsInPhase, daysInPhase
        case decidedAt, therapistOverride
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        currentPhase = try container.decode(Int.self, forKey: .currentPhase)
        previousPhase = try container.decodeIfPresent(Int.self, forKey: .previousPhase)
        decision = try container.decode(AdaptationDecision.self, forKey: .decision)
        reason = try container.decode(String.self, forKey: .reason)
        // Handle PostgreSQL returning numeric as string
        if let value = try? container.decode(Double.self, forKey: .avgPainLevel) {
            avgPainLevel = value
        } else if let str = try? container.decode(String.self, forKey: .avgPainLevel) {
            avgPainLevel = Double(str)
        } else {
            avgPainLevel = nil
        }
        if let value = try? container.decode(Double.self, forKey: .compliancePct) {
            compliancePct = value
        } else if let str = try? container.decode(String.self, forKey: .compliancePct) {
            compliancePct = Double(str)
        } else {
            compliancePct = nil
        }
        sessionsInPhase = try container.decode(Int.self, forKey: .sessionsInPhase)
        daysInPhase = try container.decode(Int.self, forKey: .daysInPhase)
        decidedAt = try container.decode(String.self, forKey: .decidedAt)
        therapistOverride = try container.decodeIfPresent(Bool.self, forKey: .therapistOverride)
    }
}
