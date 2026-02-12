// SharedTypes.swift
// Auto-generated from TypeScript types
// DO NOT EDIT MANUALLY - Run scripts/translate-protocols.js to regenerate

import Foundation

// MARK: - Enums

enum TendinopathyType: String, Codable {
    case tennisElbow = "TENNIS_ELBOW"
    case golfersElbow = "GOLFERS_ELBOW"
    case achilles = "ACHILLES"
    case patellar = "PATELLAR"
    case rotatorCuff = "ROTATOR_CUFF"
    case gluteal = "GLUTEAL"
    case proximalHamstring = "PROXIMAL_HAMSTRING"
    case plantarFascia = "PLANTAR_FASCIA"
    case lbpNonspecific = "LBP_NONSPECIFIC"
    case neckPain = "NECK_PAIN"
}

enum ExerciseType: String, Codable {
    case isometric = "ISOMETRIC"
    case hsr = "HSR"
    case eccentric = "ECCENTRIC"
    case concentric = "CONCENTRIC"
    case motorControl = "MOTOR_CONTROL"
    case bodyAwareness = "BODY_AWARENESS"
    case pacing = "PACING"
    case gradedActivity = "GRADED_ACTIVITY"
}

// MARK: - Type Aliases

// MARK: - Models

struct CognitiveCues: Codable {
    let FAR: String?
    let DER: String?
    let EER: String?
    let AR: String?
}

struct Exercise: Codable {
    let id: String
    let name: String
    let type: ExerciseType
    let description: String
    let sets: Int
    let reps: Int
    let holdTime: Int?
    let restBetweenSets: Int
    let tempo: String?
    let videoUrl: String?
    let gifUrl: String?
    let intensity: String
    let cognitiveCues: CognitiveCues?
    let aemSubtypeSpecific: Bool?
    let visualIndicator: String?
}

struct AemProgressionRules: Codable {
    let regressPainSpike: Int
    let regressAvgPain: Int
    let holdMinDays: Int
    let holdMinSessions: Int
    let holdMaxCompliance: Int?
    let progressAvgPain: Int
    let progressMinCompliance: Int
    let progressMaxCompliance: Int?
}

struct Protocol: Codable {
    let id: String
    let tendinopathyType: TendinopathyType
    let name: String
    let description: String
    let durationWeeks: Int
    let exercises: [Exercise]
    let frequencyPerWeek: Int
    let evidenceBase: [String]
    let maxPhase: Int?
    let painRule: String?
    let progressionCriteria: [String]?
    let redFlags: [String]?
    let createdAt: Date
    let updatedAt: Date
    let maxPainLevel: Int?
    let phaseEducation: [String: Any]?
    let progressionRules: AemProgressionRules?
}

struct UserSchedule: Codable {
    let userId: String
    let availableDays: [Int]
    let preferredTimes: [String]
    let notificationsEnabled: Bool
}

struct ProgressEntry: Codable {
    let id: String
    let userId: String
    let exerciseId: String
    let completedAt: Date
    let setsCompleted: Int
    let repsCompleted: Int
    let painLevel: Int
    let notes: String?
}

struct User: Codable {
    let id: String
    let email: String
    let name: String
    let tendinopathyType: TendinopathyType
    let protocolId: String
    let startDate: Date
    let createdAt: Date
}

struct AdaptivePhaseStatus: Codable {
    let currentPhase: Int
    let phaseName: String
    let daysInPhase: Int
    let sessionsInPhase: Int
    let lastDecision: AdaptationDecision
    let lastDecisionReason: String
    let lastDecisionDate: string | null
    let currentPainAvg: Int
    let currentCompliance: Int
    let progressionReadiness: [String: Any]
    let minDaysMet: Bool
    let minSessionsMet: Bool
    let painCriteriaMet: Bool
    let complianceCriteriaMet: Bool
    let nextEvaluationHint: String
}

struct AdaptationResult: Codable {
    let currentPhase: Int
    let previousPhase: Int
    let decision: AdaptationDecision
    let reason: String
    let reasonKey: String
    let avgPainLevel: Int
    let compliancePct: Int
    let sessionsInPhase: Int
    let daysInPhase: Int
}

struct PhaseAdaptationRecord: Codable {
    let id: String
    let userId: String
    let currentPhase: Int
    let previousPhase: number | null
    let decision: AdaptationDecision
    let reason: String
    let avgPainLevel: number | null
    let compliancePct: number | null
    let sessionsInPhase: Int
    let daysInPhase: Int
    let decidedAt: String
    let therapistOverride: Bool
}

struct AemScreeningItem: Codable {
    let id: String
    let textDe: String
    let textEn: String
    let subscale: AemSubscale
    let reverse: Bool
}

struct AemScreeningConfig: Codable {
    let version: String
    let items: [AemScreeningItem]
    let cutoffs: [String: Any]
}

struct AemSubscaleScores: Codable {
    let fear_avoidance: Int
    let distress_endurance: Int
    let eustress_endurance: Int
}

struct AemScreeningResult: Codable {
    let userId: Int
    let responses: [String: Int]
    let subscaleScores: AemSubscaleScores
    let subtype: AemSubtype
    let completedAt: String
}

struct AemScreeningSubmission: Codable {
    let responses: [String: Int]
}

struct NeckScreeningItem: Codable {
    let id: String
    let part: String
    let textDe: String
    let type: String
    let options: [String: Any]?
}

struct NeckScreeningResult: Codable {
    let userId: String
    let subtypeResult: NeckSubtype
    let ndiScore: Int
    let ndiCategory: String
    let completedAt: String
}

struct NdiFocusArea: Codable {
    let domainId: String
    let domainLabel: String
    let score: Int
    let maxScore: Int
    let dailyTips: [String]?
}

struct NdiHistoryEntry: Codable {
    let id: String
    let ndiScore: Int
    let ndiCategory: String
    let severityGrade: NdiSeverityGrade
    let createdAt: String
}

