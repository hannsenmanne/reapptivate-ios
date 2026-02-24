import Foundation

// MARK: - Core API Response Wrappers
// The backend wraps most responses in container objects.

struct UserResponse: Codable {
    let user: UserProfile
}

struct EntriesResponse: Codable {
    let entries: [ProgressEntry]
}

struct StatsResponse: Codable {
    let stats: StatsPayload

    struct StatsPayload: Codable {
        let totalSessions: Int
        let averagePainLevel: Double
        let lastSevenDays: Int
        let currentWeekCompliance: Double
        let recentPainLevels: [RecentPain]?
    }

    struct RecentPain: Codable {
        let date: String
        let avgPain: Double
    }
}

struct TodayProgressResponse: Codable {
    let completedExercises: [ProgressEntry]
    let count: Int
}

struct PhaseStatusResponse: Codable {
    let phaseStatus: AdaptivePhaseStatus
}

struct PhaseHistoryResponse: Codable {
    let history: [PhaseAdaptationRecord]
}

struct ProgressLogResponse: Codable {
    let entry: ProgressEntry
    let adaptation: AdaptationResult?
}

// MARK: - LBP Fear Hierarchy Wrappers

struct FearHierarchyResponse: Codable {
    let hierarchy: FearHierarchy
}

struct ExposureLogResponse: Codable {
    let log: ExposureLog
}

struct ExposureLogsResponse: Codable {
    let logs: [ExposureLog]
}

// MARK: - LBP Pacing Wrappers

struct PacingPlanResponse: Codable {
    let plan: PacingPlan
    let message: String?
}

struct PacingTemplateResponse: Codable {
    let template: PacingTemplate
}

struct PacingLogFullResponse: Codable {
    let log: PacingLog
    let evaluation: PacingEvaluation?

    struct PacingEvaluation: Codable {
        let matchedRules: [String]?
        let adjustmentsCreated: Int?
        let modulesRecommended: [String]?
    }
}

struct PacingLogsResponse: Codable {
    let logs: [PacingLog]
}

// MARK: - LBP Micro-Module Wrappers

struct MicroModulesResponse: Codable {
    let modules: [MicroModule]
}

struct CompletedModulesResponse: Codable {
    let completedModules: [String]
}

struct ModuleCompletionResponse: Codable {
    let completion: MicroModuleCompletion
}

// MARK: - LBP Plan Adjustments Wrapper

struct PlanAdjustmentsResponse: Codable {
    let adjustments: [PlanAdjustment]
}

// MARK: - AEM Screening Wrappers

struct AemScreeningResponse: Codable {
    let screening: AemScreeningResult
}

// MARK: - Neck Screening Wrappers

struct NeckScreeningResponse: Codable {
    let screening: NeckScreeningResult
}

struct NeckHistoryResponse: Codable {
    let history: [NdiHistoryEntry]
}

struct NeckFocusAreasResponse: Codable {
    let focusAreas: [NdiFocusArea]
}

// MARK: - Tension Screening Wrappers

struct TsiScreeningResponse: Codable {
    let screening: TsiScreeningResult
}

struct TsiHistoryResponse: Codable {
    let history: [TsiHistoryEntry]
}

struct TsiFocusAreasResponse: Codable {
    let focusAreas: [TsiFocusArea]
}

// MARK: - Work Timer Wrappers

struct WorkTimerSettingsResponse: Codable {
    let settings: WorkTimerSettings
}

struct WorkTimerExercisesResponse: Codable {
    let exercises: [WorkTimerBreakExercise]
}

struct WorkTimerSummaryResponse: Codable {
    let summary: WorkTimerDaySummary
}

struct WorkTimerHistoryResponse: Codable {
    let history: [WorkTimerDaySummary]
}

// MARK: - ACL Screening Wrappers

struct AclScreeningResponse: Codable {
    let screening: AclScreeningResult
}

// MARK: - ACL Daily KPI Wrappers

struct AclDailyKpiSingleResponse: Codable {
    let kpi: AclDailyKpi
}

struct AclDailyKpiListResponse: Codable {
    let kpis: [AclDailyKpi]?
    let entries: [AclDailyKpi]?
}

// MARK: - ACL Weekly KPI Wrappers

struct AclWeeklyKpiListResponse: Codable {
    let kpis: [AclWeeklyKpi]?
    let entries: [AclWeeklyKpi]?
}

// MARK: - ACL Lab Assessment Wrappers

struct AclLabAssessmentListResponse: Codable {
    let assessments: [AclLabAssessment]
}

// MARK: - ACL Micro-Module Wrappers

struct AclMicroModulesResponse: Codable {
    let modules: [AclMicroModule]
}

struct AclCompletedModulesResponse: Codable {
    let completions: [String]?
    let completedModules: [String]?
}

// MARK: - Custom Exercise Wrappers

struct CustomExercisesResponse: Codable {
    let exercises: [CustomExercise]
}
