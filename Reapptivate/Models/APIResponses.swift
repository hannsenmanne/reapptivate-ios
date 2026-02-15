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

// MARK: - Neck-Shoulder Screening Wrappers

struct NeckShoulderScreeningResponse: Codable {
    let screening: NeckShoulderScreeningResult
}

// MARK: - Neck-Shoulder Program Wrappers

struct NeckShoulderProgramResponse: Codable {
    let program: NeckShoulderProgram
    let weeklySchedule: NeckShoulderWeeklyPlan?
}

struct NeckShoulderExercisesResponse: Codable {
    let programA: NeckShoulderExerciseConfig.ProgramSection
    let programB: NeckShoulderExerciseConfig.ProgramSection
    let dailyMobility: NeckShoulderExerciseConfig.MobilitySection
    let microPauses: NeckShoulderExerciseConfig.MicroPauseSection
}

struct NeckShoulderProgressionResponse: Codable {
    let progression: NeckShoulderProgressionResult
}

// MARK: - Neck-Shoulder Tracking Wrappers

struct NstSessionLogResponse: Codable {
    let session: NeckShoulderSessionLog
    let triggerEvaluation: NstTriggerEvaluation?
}

struct NstTriggerEvaluation: Codable {
    let matchedRules: [NstMatchedRule]?
    let adjustmentsCreated: Int?
    let modulesRecommended: [String]?

    struct NstMatchedRule: Codable {
        let ruleId: String
        let ruleName: String
        let reason: String
    }
}

struct NstSessionsResponse: Codable {
    let sessions: [NeckShoulderSessionLog]
}

struct NstComplianceResponse: Codable {
    let compliance: NeckShoulderComplianceStats
}

struct NstMicroPauseLogResponse: Codable {
    let microPause: NstMicroPauseEntry

    struct NstMicroPauseEntry: Codable {
        let id: String
        let completedAt: String
    }
}

struct NstMicroPauseStatsResponse: Codable {
    let microPauseStats: NstMicroPauseStats
}

// MARK: - Neck-Shoulder Adjustment Wrappers

struct NstAdjustmentsResponse: Codable {
    let adjustments: [NstPlanAdjustment]
}

// MARK: - Custom Exercise Wrappers

struct CustomExercisesResponse: Codable {
    let exercises: [CustomExercise]
}
