import Foundation

// MARK: - ACL Enums

enum AclAthleteLevel: String, Codable {
    case competitive = "COMPETITIVE"
    case recreational = "RECREATIONAL"

    var displayName: String {
        switch self {
        case .competitive: "Leistungssportler"
        case .recreational: "Freizeitsportler"
        }
    }
}

enum AclGraftType: String, Codable {
    case hamstring = "HAMSTRING"
    case patellarTendon = "PATELLAR_TENDON"
    case quadriceps = "QUADRICEPS"

    var displayName: String {
        switch self {
        case .hamstring: "Hamstring (Semitendinosus)"
        case .patellarTendon: "Patellasehne (BTB)"
        case .quadriceps: "Quadrizepssehne"
        }
    }
}

enum AclConcomitantInjury: String, Codable {
    case none = "NONE"
    case meniscalRepair = "MENISCAL_REPAIR"
    case chondralRepair = "CHONDRAL_REPAIR"
    case lateralExtraArticularTenodesis = "LATERAL_EXTRA_ARTICULAR_TENODESIS"
    case posterolateralCorner = "POSTEROLATERAL_CORNER"

    var displayName: String {
        switch self {
        case .none: "Keine"
        case .meniscalRepair: "Meniskusnaht"
        case .chondralRepair: "Knorpelreparatur"
        case .lateralExtraArticularTenodesis: "Laterale extraartikuläre Tenodese"
        case .posterolateralCorner: "Posterolaterale Ecke Reparatur"
        }
    }
}

enum AclKneeSide: String, Codable {
    case left = "LEFT"
    case right = "RIGHT"

    var displayName: String {
        switch self {
        case .left: "Links"
        case .right: "Rechts"
        }
    }
}

// MARK: - ACL Screening Config

// API response from GET /api/acl/config: { version, title, titleDE, steps, preOpCriteria, ... }

struct AclScreeningStepOption: Codable {
    let value: String
    let label: String
    let labelDE: String
    let description: String?
    let precaution: String?
}

struct AclScreeningStep: Codable, Identifiable {
    let id: String
    let label: String
    let labelDE: String
    let type: String // "date", "radio", "checkbox", "text"
    let required: Bool?
    let options: [AclScreeningStepOption]?
    let placeholder: String?
    let helpText: String?
}

struct AclPreOpCriterion: Codable, Identifiable {
    let id: String
    let labelDE: String
    let icon: String?
}

struct AclScreeningConfig: Codable {
    let version: String
    let title: String?
    let titleDE: String?
    let description: String?
    let descriptionDE: String?
    let steps: [AclScreeningStep]
    let preOpCriteria: [AclPreOpCriterion]?
}

// MARK: - ACL Screening Submission

struct AclScreeningSubmission: Codable {
    let surgeryDate: String
    let graftType: String
    let athleteLevel: String
    let concomitantInjuries: [String]
    let sport: String?
    let kneeSide: String
}

// MARK: - ACL Screening Result

// API response from POST /api/acl/screening: { screening: { id, surgeryDate, graftType, ... } }
// API response from GET /api/acl/screening: { screening: { id, surgeryDate, graftType, ... } }

struct AclScreeningResult: Codable {
    let id: String?
    let surgeryDate: String?
    let graftType: String?
    let athleteLevel: String?
    let concomitantInjuries: [String]?
    let sport: String?
    let kneeSide: String?
    let initialMilestone: Int?
    let currentMilestone: Int?
    let createdAt: String?
}

// MARK: - ACL Streams

// API response from GET /api/acl/streams: { streams: [...], currentMilestone, weeksPostSurgery }

struct AclStreamsResponse: Codable {
    let streams: [AclStream]
    let currentMilestone: Int
    let weeksPostSurgery: Int
}

struct AclStream: Codable, Identifiable {
    let id: String
    let name: String
    let nameDE: String?
    let description: String?
    let descriptionDE: String?
    let unlockMilestone: Int?
    let milestone: Int?
    let isUnlocked: Bool?
    let locked: Bool?
    let exerciseCount: Int?
}

// API response from GET /api/acl/streams/:streamId: { stream: { ... }, exercises: [...] }

struct AclStreamDetailResponse: Codable {
    let stream: AclStreamDetail
    let exercises: [AclStreamExercise]
}

struct AclStreamDetail: Codable, Identifiable {
    let id: String
    let name: String
    let nameDE: String?
    let description: String?
    let descriptionDE: String?
    let milestone: Int?
    let exercises: [AclStreamExercise]?
}

struct AclStreamExercise: Codable, Identifiable {
    let id: String
    let name: String
    let nameDE: String?
    let description: String?
    let descriptionDE: String?
    let sets: Int?
    let reps: String?
    let holdTime: Int?
    let tempo: String?
    let intensity: String?
    let milestoneRange: [Int]?
    let weekRange: [Int]?
    let graftModifier: [String: String]?
    let concomitantPrecaution: [String: String]?
}

// MARK: - ACL Milestone Status

// API response from GET /api/acl/milestone-status: { currentMilestone, weeksPostSurgery, ... }

struct AclMilestoneStatus: Codable {
    let currentMilestone: Int
    let weeksPostSurgery: Int
    let isPreOp: Bool
    let athleteLevel: String?
    let graftType: String?
    let surgeryDate: String?
    let concomitantInjuries: [String]?
    let nextCriteria: [AclMilestoneCriterion]?
    let isReadyForLab: Bool?
}

struct AclMilestoneCriterion: Codable, Identifiable {
    let id: String
    let label: String?
    let labelDE: String?
    let field: String?
    let threshold: Double?
    let unit: String?
    let met: Bool?
    let currentValue: Double?

    // Operator is a keyword, use backticks
    let `operator`: String?
}

// MARK: - ACL Daily KPIs

// API response from POST /api/acl/daily-kpi: { kpi: { ... } }
// API response from GET /api/acl/daily-kpi: { kpis: [...], entries: [...] }

struct AclDailyKpi: Codable, Identifiable {
    let id: String
    let date: String
    let painNrs: Int
    let painLocation: String?
    let painActivity: String?
    let kneeFlexionDeg: Int?
    let extensionDeficitDeg: Int?
    let swellingGrade: Int?
    let quadsLag: Bool?
    let notes: String?
}

struct AclDailyKpiRequest: Codable {
    let date: String?
    let painNrs: Int
    let painLocation: String?
    let painActivity: String?
    let kneeFlexionDeg: Int?
    let extensionDeficitDeg: Int?
    let swellingGrade: Int?
    let quadsLag: Bool?
    let notes: String?
}

// MARK: - ACL Weekly KPIs

// API response from POST /api/acl/weekly-kpi: { kpi: { ... }, tampaAlert }
// API response from GET /api/acl/weekly-kpi: { kpis: [...], entries: [...] }

struct AclWeeklyKpi: Codable, Identifiable {
    let id: String
    let weekDate: String
    let ikdcScore: Int?
    let tampaScore: Int?
    let thighCirc5cm: Double?
    let thighCirc10cm: Double?
}

struct AclWeeklyKpiRequest: Codable {
    let weekDate: String?
    let ikdcScore: Int?
    let tampaScore: Int?
    let thighCirc5cm: Double?
    let thighCirc10cm: Double?
}

struct AclWeeklyKpiResponse: Codable {
    let kpi: AclWeeklyKpi
    let tampaAlert: Bool?
}

// MARK: - ACL Lab Assessments

// API response from GET /api/acl/lab-assessment: { assessments: [...] }

struct AclLabAssessment: Codable, Identifiable {
    let id: String
    let milestone: Int
    let assessmentDate: String?
    let quadLsi: Double?
    let hamstringLsi: Double?
    let hipAbdLsi: Double?
    let hipAddLsi: Double?
    let hipErLsi: Double?
    let calfLsi: Double?
    let dlCmjConcentricLsi: Double?
    let dlCmjEccentricLsi: Double?
    let slCmjHeightLsi: Double?
    let dlDjRsi: Double?
    let slDjRsi: Double?
    let slDjContactTimeLsi: Double?
    let runningSpeedKmh: Double?
    let ikdcScore: Double?
    let tampaScore: Double?
    let kneeFlexionDeg: Double?
    let extensionDeficitDeg: Double?
    let swellingGrade: Int?
    let notes: String?
    let createdAt: String?
}

// API response from POST /api/acl/lab-assessment: { assessment: { ... }, criteria, allCriteriaMet, milestoneAdvanced, newMilestone }

struct AclLabAssessmentResponse: Codable {
    let assessment: AclLabAssessmentBrief
    let criteria: [AclCriterionResult]?
    let allCriteriaMet: Bool
    let milestoneAdvanced: Bool
    let newMilestone: Int

    struct AclLabAssessmentBrief: Codable {
        let id: String
        let milestone: Int
        let assessmentDate: String?
    }

    struct AclCriterionResult: Codable, Identifiable {
        let id: String
        let label: String?
        let labelDE: String?
        let field: String?
        let threshold: Double?
        let unit: String?
        let met: Bool
        let currentValue: Double?
        let `operator`: String?
    }
}

// MARK: - ACL Discharge Progress

// API response from GET /api/acl/discharge-progress: { athleteLevel, criteria, overallPercent, metCount, totalCount }

struct AclDischargeProgress: Codable {
    let athleteLevel: String
    let criteria: [AclDischargeCriterion]
    let overallPercent: Int
    let metCount: Int
    let totalCount: Int
}

struct AclDischargeCriterion: Codable, Identifiable {
    let id: String
    let category: String?
    let test: String?
    let field: String?
    let threshold: Double?
    let unit: String?
    let met: Bool?
    let currentValue: Double?
    let `operator`: String?
}

// MARK: - ACL Analytics

// API response from GET /api/acl/analytics: { currentMilestone, weeksPostSurgery, painTrend, ... }

struct AclAnalytics: Codable {
    let currentMilestone: Int
    let weeksPostSurgery: Int
    let athleteLevel: String?
    let painTrend: [AclPainTrendPoint]?
    let swellingTrend: [AclSwellingTrendPoint]?
    let romTrend: [AclRomTrendPoint]?
    let ikdcTrend: [AclScoreTrendPoint]?
    let tampaTrend: [AclScoreTrendPoint]?
    let thighCircTrend: [AclThighCircTrendPoint]?
    let labAssessments: [AclLabSummaryPoint]?
}

struct AclPainTrendPoint: Codable, Identifiable {
    let date: String
    let painNrs: Int

    var id: String { date }
}

struct AclSwellingTrendPoint: Codable, Identifiable {
    let date: String
    let swellingGrade: Int?

    var id: String { date }
}

struct AclRomTrendPoint: Codable, Identifiable {
    let date: String
    let flexion: Int?
    let extensionDeficit: Int?

    var id: String { date }
}

struct AclScoreTrendPoint: Codable, Identifiable {
    let weekDate: String
    let score: Int?

    var id: String { weekDate }
}

struct AclThighCircTrendPoint: Codable, Identifiable {
    let weekDate: String
    let circ5cm: Double?
    let circ10cm: Double?

    var id: String { weekDate }
}

struct AclLabSummaryPoint: Codable {
    let milestone: Int
    let date: String?
    let quadLsi: Double?
    let hamstringLsi: Double?
}

// MARK: - ACL Micro-Modules

// API response from GET /api/acl/micro-modules: { modules: [...] }
// Uses the same MicroModule type from LbpTypes.swift (same structure)
// Uses the same MicroModuleCompletion type from LbpTypes.swift

// ACL module has additional optional field targetMilestone: [Int]
struct AclMicroModule: Codable, Identifiable {
    let key: String
    let title: String
    let content: String
    let takeHome: String?
    let taskType: String?
    let targetCondition: String?
    let targetMilestone: [Int]?

    var id: String { key }

    private enum CodingKeys: String, CodingKey {
        case key, title, takeHome, taskType, targetCondition, targetMilestone
        case content = "bodyMarkdown"
    }
}
