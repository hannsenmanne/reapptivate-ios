import Foundation

/// Loads exercise protocols from bundled JSON resources.
/// Protocols are bundled locally so they work offline.
/// The JSON files are generated from the web app's mockProtocols.ts
/// using scripts/translate-protocols.js
final class ProtocolLoader {
    static let shared = ProtocolLoader()

    private var cache: [String: ExerciseProtocol] = [:]

    private init() {}

    // MARK: - Protocol Loading

    /// Get the correct protocol for a patient based on their condition and subtype
    func protocolFor(
        type: TendinopathyType,
        aemSubtype: AemSubtype? = nil,
        ndiSeverity: NdiSeverityGrade? = nil
    ) -> ExerciseProtocol? {
        let key = protocolKey(for: type, aemSubtype: aemSubtype)

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

    /// Get exercises for a specific phase, with optional severity filtering
    func exercisesForPhase(
        protocol proto: ExerciseProtocol,
        phase: Int,
        ndiSeverity: NdiSeverityGrade? = nil
    ) -> [ExerciseWithPhase] {
        // Load the phase-organized exercises from the protocol bundle
        let key = proto.id
        guard let phaseExercises = loadPhaseExercises(filename: key) else {
            // Fallback: wrap plain exercises with phase metadata
            return proto.exercises.map { exercise in
                ExerciseWithPhase(
                    exercise: exercise,
                    phase: phase,
                    phaseTitle: phaseName(phase, for: proto.tendinopathyType),
                    weeksRange: "",
                    phaseGoal: "",
                    ndiSeverity: ndiSeverity,
                    dosageModifier: nil
                )
            }
        }

        return phaseExercises.filter { $0.phase == phase }
    }

    // MARK: - Phase Names

    func phaseName(_ phase: Int, for type: TendinopathyType) -> String {
        switch type {
        case .lbpNonspecific:
            return lbpPhaseName(phase)
        case .neckPain:
            return neckPhaseName(phase)
        default:
            return tendinopathyPhaseName(phase)
        }
    }

    // MARK: - Private

    private func protocolKey(for type: TendinopathyType, aemSubtype: AemSubtype?) -> String {
        switch type {
        case .tennisElbow: return "tennis-elbow-protocol"
        case .golfersElbow: return "golfers-elbow-protocol"
        case .achilles: return "achilles-protocol"
        case .patellar: return "patellar-protocol"
        case .rotatorCuff: return "rotator-cuff-protocol"
        case .gluteal: return "gluteal-protocol"
        case .proximalHamstring: return "hamstring-protocol"
        case .plantarFascia: return "plantar-protocol"
        case .lbpNonspecific:
            guard let subtype = aemSubtype else { return "lbp-ar-protocol" }
            return "lbp-\(subtype.rawValue.lowercased())-protocol"
        case .neckPain:
            return "neck-nonspecific-protocol"
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

    private func loadPhaseExercises(filename: String) -> [ExerciseWithPhase]? {
        let phasesFilename = "\(filename)-phases"
        guard let url = Bundle.main.url(forResource: phasesFilename, withExtension: "json", subdirectory: "Protocols")
            ?? Bundle.main.url(forResource: phasesFilename, withExtension: "json") else {
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([ExerciseWithPhase].self, from: data)
        } catch {
            Log.general.error("Failed to decode phase exercises: \(error)")
            return nil
        }
    }

    private func decodeProtocol(from url: URL) -> ExerciseProtocol? {
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(ExerciseProtocol.self, from: data)
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

    private func neckPhaseName(_ phase: Int) -> String {
        switch phase {
        case 1: "Phase 1: Schmerzlinderung"
        case 2: "Phase 2: Mobilisation"
        case 3: "Phase 3: Stabilisation"
        case 4: "Phase 4: Funktionstraining"
        default: "Phase \(phase)"
        }
    }
}
