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
        case .AR, .unknown: AR ?? FAR ?? DER ?? EER
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

    func applying(setsMultiplier: Double?, repsMultiplier: Double?, holdTimeMultiplier: Double?) -> Exercise {
        Exercise(
            id: id, name: name, type: type, description: description,
            sets: setsMultiplier.map { max(1, Int((Double(sets) * $0).rounded())) } ?? sets,
            reps: repsMultiplier.map { max(1, Int((Double(reps) * $0).rounded())) } ?? reps,
            holdTime: holdTimeMultiplier.flatMap { m in holdTime.map { max(1, Int((Double($0) * m).rounded())) } } ?? holdTime,
            restBetweenSets: restBetweenSets, tempo: tempo, videoUrl: videoUrl, gifUrl: gifUrl,
            intensity: intensity, cognitiveCues: cognitiveCues,
            aemSubtypeSpecific: aemSubtypeSpecific, visualIndicator: visualIndicator
        )
    }

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
    let exerciseGroup: String?

    var id: String { exercise.id }
    var name: String { exercise.name }

    // Manual init for constructing from code
    init(exercise: Exercise, phase: Int, phaseTitle: String, weeksRange: String, phaseGoal: String, ndiSeverity: NdiSeverityGrade? = nil, dosageModifier: DosageModifier? = nil, exerciseGroup: String? = nil) {
        self.exercise = exercise
        self.phase = phase
        self.phaseTitle = phaseTitle
        self.weeksRange = weeksRange
        self.phaseGoal = phaseGoal
        self.ndiSeverity = ndiSeverity
        self.dosageModifier = dosageModifier
        self.exerciseGroup = exerciseGroup
    }

    // Custom decoder: handles both nested {"exercise": {...}, "phase": 1}
    // and flat {"id": "...", "name": "...", "phase": 1} JSON formats
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Try nested Exercise first, fall back to flat
        if let nested = try? container.decode(Exercise.self, forKey: .exercise) {
            exercise = nested
        } else {
            exercise = try Exercise(from: decoder)
        }

        phase = try container.decode(Int.self, forKey: .phase)
        phaseTitle = try container.decodeIfPresent(String.self, forKey: .phaseTitle) ?? ""
        weeksRange = try container.decodeIfPresent(String.self, forKey: .weeksRange) ?? ""
        phaseGoal = try container.decodeIfPresent(String.self, forKey: .phaseGoal) ?? ""
        ndiSeverity = try container.decodeIfPresent(NdiSeverityGrade.self, forKey: .ndiSeverity)
        dosageModifier = try container.decodeIfPresent(DosageModifier.self, forKey: .dosageModifier)
        exerciseGroup = try container.decodeIfPresent(String.self, forKey: .exerciseGroup)
    }

    enum CodingKeys: String, CodingKey {
        case exercise, phase, phaseTitle, weeksRange, phaseGoal
        case ndiSeverity, dosageModifier, exerciseGroup
    }

    /// Returns a copy of this exercise with the dosage modifier for the given severity key applied.
    /// If no modifier exists for the key, returns self unchanged.
    func applyingDosageModifier(severityKey: String) -> ExerciseWithPhase {
        guard let multipliers = dosageModifier?[severityKey] else { return self }
        let modified = exercise.applying(
            setsMultiplier: multipliers.setsMultiplier,
            repsMultiplier: multipliers.repsMultiplier,
            holdTimeMultiplier: multipliers.holdTimeMultiplier
        )
        return ExerciseWithPhase(
            exercise: modified, phase: phase, phaseTitle: phaseTitle,
            weeksRange: weeksRange, phaseGoal: phaseGoal, ndiSeverity: ndiSeverity,
            dosageModifier: dosageModifier, exerciseGroup: exerciseGroup
        )
    }
}

// MARK: - Dosage Modifier (neck severity adjustments)
// JSON format: { "SCHWER": { "sets_multiplier": 0.7, "hold_time_multiplier": 0.6 } }

struct DosageMultipliers: Codable {
    let setsMultiplier: Double?
    let repsMultiplier: Double?
    let holdTimeMultiplier: Double?
}

typealias DosageModifier = [String: DosageMultipliers]

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
    let exercises: [ExerciseWithPhase]
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
