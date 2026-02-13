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
        ndiSeverity: NdiSeverityGrade? = nil
    ) -> ExerciseProtocol? {
        let key = protocolKey(for: type, aemSubtype: aemSubtype)

        lock.lock()
        if let cached = cache[key] {
            lock.unlock()
            return cached
        }
        lock.unlock()

        guard let proto = loadProtocol(filename: key) else {
            Log.general.error("Failed to load protocol: \(key)")
            return nil
        }

        lock.lock()
        cache[key] = proto
        lock.unlock()
        return proto
    }

    /// Get exercises for a specific phase, with optional severity filtering
    func exercisesForPhase(
        protocol proto: ExerciseProtocol,
        phase: Int,
        ndiSeverity: NdiSeverityGrade? = nil
    ) -> [ExerciseWithPhase] {
        proto.exercises.filter { $0.phase == phase }
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
