import Foundation

// MARK: - Fear Hierarchy

// API response: { hierarchy: { id, createdAt, items: [...] } }
struct FearHierarchy: Codable, Identifiable {
    let id: String
    let createdAt: String
    let items: [FearHierarchyItem]
}

// DB columns: id, hierarchy_id, label, context, fear_rating_0_to_10,
//   difficulty_0_to_10, status, steps, sort_order, created_at, updated_at
struct FearHierarchyItem: Codable, Identifiable {
    let id: String
    let hierarchyId: String
    let label: String
    let context: String?
    let fearRating0To10: Int
    let difficulty0To10: Int?
    let status: String?
    let steps: [FearHierarchyItemStep]?
    let sortOrder: Int
    let createdAt: String?
    let updatedAt: String?
}

struct FearHierarchyItemStep: Codable {
    let stepNum: Int
    let dose: String
    let description: String
}

// Request sent to POST /api/lbp-enhancements/fear-hierarchy
// Controller reads: items[].label, items[].context, items[].fearRating, items[].steps
struct FearHierarchyCreateRequest: Codable {
    let items: [FearHierarchyItemInput]
}

struct FearHierarchyItemInput: Codable {
    let label: String
    let context: String?
    let fearRating: Int
    let sortOrder: Int?
    let steps: [FearHierarchyItemStep]?
}

// MARK: - Exposure Logs

// DB columns: id, patient_id, hierarchy_item_id, plan_week, plan_session,
//   predicted_harm_0_to_100, predicted_fear_0_to_10, pre_fear_0_to_10,
//   pre_pain_0_to_10, performed_dose, post_fear_0_to_10, post_pain_0_to_10,
//   outcome_notes, did_avoid, created_at
struct ExposureLog: Codable, Identifiable {
    let id: String
    let patientId: String?
    let hierarchyItemId: String?
    let planWeek: Int?
    let planSession: Int?
    let predictedHarm0To100: Int?
    let predictedFear0To10: Int?
    let preFear0To10: Int
    let prePain0To10: Int
    let performedDose: AnyCodable?
    let postFear0To10: Int
    let postPain0To10: Int
    let outcomeNotes: String?
    let didAvoid: Bool
    let createdAt: String?

    var createdAtDate: Date? {
        guard let createdAt else { return nil }
        return Date.fromISO8601(createdAt)
    }

    var fearReduction: Int {
        preFear0To10 - postFear0To10
    }
}

// Controller reads: predictedHarm, predictedFear, preFear, prePain,
//   performedDose, postFear, postPain, didAvoid, outcomeNotes
struct ExposureLogRequest: Codable {
    let predictedHarm: Int?
    let predictedFear: Int?
    let preFear: Int
    let prePain: Int
    let performedDose: String?
    let postFear: Int
    let postPain: Int
    let didAvoid: Bool
    let outcomeNotes: String?
}

// MARK: - AnyCodable helper (for JSON objects like performed_dose)

struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            value = NSNull()
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else {
            value = NSNull()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let string as String: try container.encode(string)
        case let int as Int: try container.encode(int)
        case let double as Double: try container.encode(double)
        case let bool as Bool: try container.encode(bool)
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case is NSNull: try container.encodeNil()
        default: try container.encodeNil()
        }
    }
}

// MARK: - Pacing Plan

// DB columns: id, patient_id, target_activities (JSONB), rules (JSONB),
//   baseline_mode, baseline_started_at, baseline_logs (JSONB),
//   baseline_calculated, created_at, updated_at
struct PacingPlan: Codable, Identifiable {
    let id: String
    let patientId: String
    let targetActivities: [TargetActivity]
    let rules: PacingRules
    let baselineMode: Bool
    let baselineStartedAt: String?
    let baselineLogs: [BaselineLog]?
    let baselineCalculated: Bool
    let createdAt: String?
}

struct TargetActivity: Codable, Identifiable {
    let key: String
    let label: String
    let baseline: Int?
    let quota: Int?
    let unit: String?

    var id: String { key }
}

struct PacingRules: Codable {
    let quotaIncrementPercent: Int?
    let mandatoryPauseMinutes: Int?
    let pauseFrequencyMinutes: Int?
    let weeklySessionCap: Int?
}

// JSONB content within baseline_logs (uses camelCase)
struct BaselineLog: Codable {
    let date: String
    let activityKey: String
    let duration: Int
    let painLevel: Int
}

// MARK: - Pacing Template

// API response: { template: { name, targetActivities, rules, ... } }
struct PacingTemplate: Codable {
    let name: String?
    let targetActivities: [PacingTemplateActivity]?
    let rules: PacingRules?
    let description: String?
}

struct PacingTemplateActivity: Codable {
    let key: String
    let label: String
    let defaultBaseline: Int?
    let quotaFromBaseline: Double?
}

// MARK: - Pacing Logs

// DB columns: id, patient_id, activity_key, log_date, planned_quota,
//   done_quota, planned_pauses, done_pauses, notes, created_at
struct PacingLog: Codable, Identifiable {
    let id: String
    let patientId: String?
    let activityKey: String
    let logDate: String?
    let plannedQuota: Int?
    let doneQuota: Int
    let plannedPauses: Int?
    let donePauses: Int?
    let notes: String?
    let createdAt: String?

    var isBreach: Bool {
        guard let plannedQuota, plannedQuota > 0 else { return false }
        return Double(doneQuota) / Double(plannedQuota) > 1.1
    }
}

// Controller reads: activityKey, logDate, plannedQuota, doneQuota,
//   plannedPauses, donePauses, notes
struct PacingLogRequest: Codable {
    let activityKey: String
    let logDate: String?
    let plannedQuota: Int?
    let doneQuota: Int
    let plannedPauses: Int?
    let donePauses: Int?
    let notes: String?
}

// MARK: - Plan Adjustments

// DB columns: id, patient_id, rule_id, action, payload (JSONB), applied, applied_at, created_at
struct PlanAdjustment: Codable, Identifiable {
    let id: String
    let patientId: String?
    let ruleId: String
    let action: String?
    let payload: AnyCodable?
    let applied: Bool
    let appliedAt: String?
    let createdAt: String?
}

// MARK: - Micro-Module

struct MicroModule: Codable, Identifiable {
    let key: String
    let title: String
    let content: String
    let takeHome: String?
    let targetSubtypes: [String]?

    var id: String { key }

    private enum CodingKeys: String, CodingKey {
        case key, title, takeHome, targetSubtypes
        case content = "bodyMarkdown"
    }
}

// DB columns: id, patient_id, module_key, started_at, completed_at
struct MicroModuleCompletion: Codable, Identifiable {
    let id: String
    let moduleKey: String
    let startedAt: String?
    let completedAt: String?
}

// MARK: - Analytics

struct AnalyticsSummary: Codable {
    let painTrend: [PainDataPoint]
    let complianceRate: Double
    let totalAdjustments: Int
    let appliedAdjustments: Int
    let triggerFires: [TriggerFireCount]
}

struct PainDataPoint: Codable, Identifiable {
    let date: String
    let avgPain: Double

    var id: String { date }
}

struct TriggerFireCount: Codable, Identifiable {
    let ruleId: String
    let count: Int

    var id: String { ruleId }
}

struct FearReductionAnalytics: Codable {
    let totalExposures: Int
    let earlyAvgFear: Double
    let lateAvgFear: Double
    let fearReduction: Double
    let avoidanceDetected: Bool
}

struct PacingComplianceAnalytics: Codable {
    let breachRate: Double
    let pauseAdherence: Double
    let weeklySessionVolume: [WeeklyVolume]
}

struct WeeklyVolume: Codable, Identifiable {
    let week: String
    let sessions: Int

    var id: String { week }
}

// MARK: - Quota Progression

struct QuotaProgressionSuggestion: Codable {
    let ready: Bool
    let currentQuotas: [String: Int]?
    let suggestedQuotas: [String: Int]?
    let incrementPercent: Int?
    let reason: String?
}
