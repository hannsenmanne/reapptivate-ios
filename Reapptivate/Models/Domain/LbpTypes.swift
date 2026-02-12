import Foundation

// MARK: - Fear Hierarchy

struct FearHierarchy: Codable, Identifiable {
    let id: String
    let userId: String
    let items: [FearHierarchyItem]
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case items
        case createdAt = "created_at"
    }
}

struct FearHierarchyItem: Codable, Identifiable {
    let id: String
    let hierarchyId: String
    let activityName: String
    let initialFearRating: Int
    let rank: Int

    enum CodingKeys: String, CodingKey {
        case id
        case hierarchyId = "hierarchy_id"
        case activityName = "activity_name"
        case initialFearRating = "initial_fear_rating"
        case rank
    }
}

struct FearHierarchyCreateRequest: Codable {
    let items: [FearHierarchyItemInput]
}

struct FearHierarchyItemInput: Codable {
    let activityName: String
    let initialFearRating: Int
    let rank: Int
}

// MARK: - Exposure Logs

struct ExposureLog: Codable, Identifiable {
    let id: String
    let itemId: String
    let fearBefore: Int
    let fearAfter: Int
    let notes: String?
    let completedAt: String

    var completedAtDate: Date? {
        Date.fromISO8601(completedAt)
    }

    var fearReduction: Int {
        fearBefore - fearAfter
    }

    enum CodingKeys: String, CodingKey {
        case id
        case itemId = "item_id"
        case fearBefore = "fear_before"
        case fearAfter = "fear_after"
        case notes
        case completedAt = "completed_at"
    }
}

struct ExposureLogRequest: Codable {
    let fearBefore: Int
    let fearAfter: Int
    let notes: String?
}

// MARK: - Pacing Plan

struct PacingPlan: Codable, Identifiable {
    let id: String
    let patientId: String
    let targetActivities: [TargetActivity]
    let rules: PacingRules
    let baselineMode: Bool
    let baselineStartedAt: String?
    let baselineLogs: [BaselineLog]?
    let baselineCalculated: Bool
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case targetActivities = "target_activities"
        case rules
        case baselineMode = "baseline_mode"
        case baselineStartedAt = "baseline_started_at"
        case baselineLogs = "baseline_logs"
        case baselineCalculated = "baseline_calculated"
        case createdAt = "created_at"
    }
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

struct BaselineLog: Codable {
    let date: String
    let activityKey: String
    let duration: Int
    let painLevel: Int
}

// MARK: - Pacing Template

struct PacingTemplate: Codable {
    let subtype: String
    let targetActivities: [TargetActivity]
    let rules: PacingRules
    let description: String?
}

// MARK: - Pacing Logs

struct PacingLog: Codable, Identifiable {
    let id: String
    let planId: String
    let activityKey: String
    let plannedQuota: Int
    let doneQuota: Int
    let plannedPauses: Int?
    let donePauses: Int?
    let notes: String?
    let loggedAt: String

    var isBreach: Bool {
        guard plannedQuota > 0 else { return false }
        return Double(doneQuota) / Double(plannedQuota) > 1.1
    }

    enum CodingKeys: String, CodingKey {
        case id
        case planId = "plan_id"
        case activityKey = "activity_key"
        case plannedQuota = "planned_quota"
        case doneQuota = "done_quota"
        case plannedPauses = "planned_pauses"
        case donePauses = "done_pauses"
        case notes
        case loggedAt = "logged_at"
    }
}

struct PacingLogRequest: Codable {
    let activityKey: String
    let plannedQuota: Int
    let doneQuota: Int
    let plannedPauses: Int?
    let donePauses: Int?
    let notes: String?
}

// MARK: - Plan Adjustments

struct PlanAdjustment: Codable, Identifiable {
    let id: String
    let planId: String
    let ruleId: String
    let triggerReason: String
    let oldValues: [String: String]?
    let newValues: [String: String]?
    let applied: Bool
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case planId = "plan_id"
        case ruleId = "rule_id"
        case triggerReason = "trigger_reason"
        case oldValues = "old_values"
        case newValues = "new_values"
        case applied
        case createdAt = "created_at"
    }
}

// MARK: - Micro-Module

struct MicroModule: Codable, Identifiable {
    let key: String
    let title: String
    let content: String
    let takeHome: String?
    let targetSubtypes: [String]?

    var id: String { key }
}

struct MicroModuleCompletion: Codable, Identifiable {
    let id: String
    let moduleKey: String
    let startedAt: String
    let completedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case moduleKey = "module_key"
        case startedAt = "started_at"
        case completedAt = "completed_at"
    }
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

    enum CodingKeys: String, CodingKey {
        case date
        case avgPain = "avg_pain"
    }
}

struct TriggerFireCount: Codable, Identifiable {
    let ruleId: String
    let count: Int

    var id: String { ruleId }

    enum CodingKeys: String, CodingKey {
        case ruleId = "rule_id"
        case count
    }
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
    let currentQuotas: [String: Int]
    let suggestedQuotas: [String: Int]
    let incrementPercent: Int
    let reason: String
}
