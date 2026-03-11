import Foundation

/// Loads exercise protocols from bundled JSON resources.
/// Protocols are bundled locally so they work offline.
/// The JSON files are generated from the web app's mockProtocols.ts
/// using scripts/translate-protocols.js
final class ProtocolLoader: @unchecked Sendable {
    static let shared = ProtocolLoader()

    private var cache: [String: ExerciseProtocol] = [:]
    private let lock = NSLock()

    private init() {}

    // MARK: - Protocol Loading

    /// Get the correct protocol for a patient based on their condition and subtype
    func protocolFor(
        type: TendinopathyType,
        aemSubtype: AemSubtype? = nil,
        tsiSeverity: TsiSeverityGrade? = nil,
        siSeverity: SiSeverityGrade? = nil,
        fsSeverity: FsSeverityGrade? = nil,
        lasSeverity: LasSeverityGrade? = nil
    ) -> ExerciseProtocol? {
        let key = protocolKey(for: type, aemSubtype: aemSubtype, tsiSeverity: tsiSeverity, siSeverity: siSeverity, fsSeverity: fsSeverity, lasSeverity: lasSeverity)

        lock.lock()
        defer { lock.unlock() }

        if let cached = cache[key] {
            return cached
        }

        guard let proto = loadProtocol(filename: key) else {
            Log.general.error("Failed to load protocol: \(key)")
            return nil
        }

        cache[key] = proto
        return proto
    }

    /// Get exercises for a specific phase.
    /// When exercises have `exerciseGroup` tags, returns a balanced daily subset
    /// (rotating based on training day count) instead of all exercises at once.
    /// - Parameter trainingDays: iOS weekday numbers (1=Sun...7=Sat) the patient trains on.
    func exercisesForPhase(
        protocol proto: ExerciseProtocol,
        phase: Int,
        trainingDays: [Int]? = nil
    ) -> [ExerciseWithPhase] {
        let allExercises = proto.exercises.filter { $0.phase == phase }

        // If no exercises have groups, return all (legacy behavior)
        let hasGroups = allExercises.contains { $0.exerciseGroup != nil }
        guard hasGroups else { return allExercises }

        return dailyRotationSubset(from: allExercises, trainingDays: trainingDays)
    }

    /// Selects a balanced daily subset by picking exercises from each group.
    /// Rotation is based on training day index (how many training days have passed
    /// since start of year), so exercises only rotate on actual training days.
    private func dailyRotationSubset(from exercises: [ExerciseWithPhase], trainingDays: [Int]?) -> [ExerciseWithPhase] {
        // Group exercises by their exerciseGroup (ungrouped exercises always included)
        var alwaysInclude: [ExerciseWithPhase] = []
        var groups: [String: [ExerciseWithPhase]] = [:]

        for exercise in exercises {
            if let group = exercise.exerciseGroup {
                groups[group, default: []].append(exercise)
            } else {
                alwaysInclude.append(exercise)
            }
        }

        let rotationIndex = trainingDayIndex(trainingDays: trainingDays)

        var selected: [ExerciseWithPhase] = alwaysInclude

        // Pick 2 exercises from each group, rotating per training day
        for (_, groupExercises) in groups.sorted(by: { $0.key < $1.key }) {
            let count = groupExercises.count
            guard count > 0 else { continue }

            let pickCount = min(2, count)
            let startIndex = rotationIndex % count

            for i in 0..<pickCount {
                let index = (startIndex + i) % count
                selected.append(groupExercises[index])
            }
        }

        // Preserve original order
        let selectedIds = Set(selected.map(\.id))
        return exercises.filter { selectedIds.contains($0.id) }
    }

    /// Returns the number of training days that have passed since start of year.
    /// If no training days are set, falls back to calendar day-of-year.
    private func trainingDayIndex(trainingDays: [Int]?) -> Int {
        let calendar = Calendar.current
        let today = Date.now

        guard let trainingDays, !trainingDays.isEmpty else {
            // Fallback: use calendar day
            return calendar.ordinality(of: .day, in: .year, for: today) ?? 1
        }

        let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: today)) ?? today
        let dayOfYear = calendar.dateComponents([.day], from: startOfYear, to: today).day ?? 0

        // Count how many training days have occurred from Jan 1 through today
        var count = 0
        for dayOffset in 0...dayOfYear {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfYear) else { continue }
            let weekday = calendar.component(.weekday, from: date) // 1=Sun...7=Sat
            if trainingDays.contains(weekday) {
                count += 1
            }
        }

        return count
    }

    // MARK: - Phase Names

    func phaseName(_ phase: Int, for type: TendinopathyType) -> String {
        switch type {
        case .lbpNonspecific:
            return lbpPhaseName(phase)
        case .neckPain:
            return neckPhaseName(phase)
        case .neckShoulderTension:
            return tensionPhaseName(phase)
        case .shoulderImpingement:
            return shoulderPhaseName(phase)
        case .frozenShoulder:
            return frozenShoulderPhaseName(phase)
        case .lateralAnkleSprain:
            return lateralAnkleSprainPhaseName(phase)
        default:
            return tendinopathyPhaseName(phase)
        }
    }

    // MARK: - Private

    private func protocolKey(for type: TendinopathyType, aemSubtype: AemSubtype?, tsiSeverity: TsiSeverityGrade? = nil, siSeverity: SiSeverityGrade? = nil, fsSeverity: FsSeverityGrade? = nil, lasSeverity: LasSeverityGrade? = nil) -> String {
        switch type {
        case .tennisElbow: return "tennis_elbow"
        case .golfersElbow: return "golfers_elbow"
        case .achilles: return "achilles"
        case .patellar: return "patellar"
        case .rotatorCuff: return "rotator_cuff"
        case .gluteal: return "gluteal"
        case .proximalHamstring: return "proximal_hamstring"
        case .plantarFascia: return "plantar_fascia"
        case .lbpNonspecific:
            guard let subtype = aemSubtype else { return "lbp_ar" }
            return "lbp_\(subtype.rawValue.lowercased())"
        case .neckPain:
            return "neck_pain"
        case .neckShoulderTension:
            let grade = tsiSeverity ?? .LEICHT
            return "neck_shoulder_tension_\(grade.rawValue.lowercased())"
        case .shoulderImpingement:
            let grade = siSeverity ?? .LEICHT
            return "shoulder_impingement_\(grade.rawValue.lowercased())"
        case .frozenShoulder:
            let grade = fsSeverity ?? .LEICHT
            return "frozen_shoulder_\(grade.rawValue.lowercased())"
        case .lateralAnkleSprain:
            let grade = lasSeverity ?? .LEICHT
            return "lateral_ankle_sprain_\(grade.rawValue.lowercased())"
        case .aclReconstruction:
            return "acl_reconstruction"
        case .unknown:
            return "unknown"
        }
    }

    private func loadProtocol(filename: String) -> ExerciseProtocol? {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json", subdirectory: "Protocols") else {
            // Try without subdirectory
            guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
                Log.general.warning("Protocol file not found: \(filename).json")
                return nil
            }
            return decodeProtocol(from: url)
        }
        return decodeProtocol(from: url)
    }

    private func decodeProtocol(from url: URL) -> ExerciseProtocol? {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(ExerciseProtocol.self, from: data)
        } catch {
            Log.general.error("Failed to decode protocol: \(error)")
            return nil
        }
    }

    private func tendinopathyPhaseName(_ phase: Int) -> String {
        switch phase {
        case 1: "Phase 1: Isometrisch"
        case 2: "Phase 2: Heavy-Slow Resistance"
        case 3: "Phase 3: Exzentrisch"
        default: "Phase \(phase)"
        }
    }

    private func lbpPhaseName(_ phase: Int) -> String {
        switch phase {
        case 1: "Phase 1: Stabilisation"
        case 2: "Phase 2: Belastungsaufbau"
        case 3: "Phase 3: Funktionstraining"
        default: "Phase \(phase)"
        }
    }

    private func tensionPhaseName(_ phase: Int) -> String {
        switch phase {
        case 1: "Phase 1: Entspannung"
        case 2: "Phase 2: Mobilisation"
        case 3: "Phase 3: Kräftigung"
        case 4: "Phase 4: Funktionstraining"
        default: "Phase \(phase)"
        }
    }

    private func shoulderPhaseName(_ phase: Int) -> String {
        switch phase {
        case 1: "Phase 1: Akut / Schmerzlinderung"
        case 2: "Phase 2: Kräftigung"
        case 3: "Phase 3: Aufbau"
        case 4: "Phase 4: Rückkehr zur Aktivität"
        default: "Phase \(phase)"
        }
    }

    private func frozenShoulderPhaseName(_ phase: Int) -> String {
        switch phase {
        case 1: "Phase 1: Schmerzmanagement"
        case 2: "Phase 2: Intensive Dehnung"
        case 3: "Phase 3: Kräftigung"
        case 4: "Phase 4: Rückkehr & Erhaltung"
        default: "Phase \(phase)"
        }
    }

    private func neckPhaseName(_ phase: Int) -> String {
        switch phase {
        case 1: "Phase 1: Schmerzlinderung"
        case 2: "Phase 2: Mobilisation"
        case 3: "Phase 3: Stabilisation"
        case 4: "Phase 4: Funktionstraining"
        default: "Phase \(phase)"
        }
    }

    private func lateralAnkleSprainPhaseName(_ phase: Int) -> String {
        switch phase {
        case 1: "Phase 1: Schutz & Entstauung"
        case 2: "Phase 2: Frühe Mobilisation"
        case 3: "Phase 3: Kräftigung & Propriozeption"
        case 4: "Phase 4: Return to Sport"
        default: "Phase \(phase)"
        }
    }
}
