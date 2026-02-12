import Foundation

// MARK: - Cognitive Cues

struct CognitiveCues: Codable {
    let FAR: String?
    let DER: String?
    let EER: String?
    let AR: String?

    func cue(for subtype: AemSubtype) -> String? {
        switch subtype {
        case .FAR: FAR
        case .DER: DER
        case .EER: EER
        case .AR: AR ?? FAR ?? DER ?? EER
        }
    }
}

// MARK: - Exercise

struct Exercise: Codable, Identifiable {
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
    let visualIndicator: VisualIndicator?

    var estimatedDurationMinutes: Int {
        let setDuration: Int
        if let holdTime {
            setDuration = holdTime
        } else {
            let tempoParts = tempo?.split(separator: "-").compactMap { Int($0) } ?? []
            let repDuration = tempoParts.reduce(0, +)
            setDuration = reps * max(repDuration, 3)
        }
        let totalWork = sets * setDuration
        let totalRest = max(0, sets - 1) * restBetweenSets
        return max(1, (totalWork + totalRest) / 60)
    }
}

// MARK: - Exercise with Phase (extended for display)

struct ExerciseWithPhase: Codable, Identifiable {
    let exercise: Exercise
    let phase: Int
    let phaseTitle: String
    let weeksRange: String
    let phaseGoal: String
    let ndiSeverity: NdiSeverityGrade?
    let dosageModifier: DosageModifier?

    var id: String { exercise.id }
    var name: String { exercise.name }

    enum CodingKeys: String, CodingKey {
        case exercise, phase, phaseTitle, weeksRange, phaseGoal
        case ndiSeverity, dosageModifier
    }
}

// MARK: - Dosage Modifier (neck severity adjustments)

struct DosageModifier: Codable {
    let sets: Int?
    let reps: Int?
    let holdTime: Int?
    let restBetweenSets: Int?
    let intensity: String?
}

// MARK: - AEM Progression Rules

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

// MARK: - Exercise Protocol (renamed from "Protocol" to avoid Swift keyword)

struct ExerciseProtocol: Codable, Identifiable {
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
    let maxPainLevel: Int?
    let phaseEducation: [String: String]?
    let progressionRules: AemProgressionRules?

    var effectiveMaxPhase: Int {
        maxPhase ?? 3
    }

    var effectiveMaxPainLevel: Int {
        maxPainLevel ?? 3
    }
}
