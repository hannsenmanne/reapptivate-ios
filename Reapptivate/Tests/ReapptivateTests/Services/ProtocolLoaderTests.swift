import XCTest
@testable import Reapptivate

final class ProtocolLoaderTests: XCTestCase {

    // MARK: - Protocol Key Mapping

    func testProtocolKeyForTendinopathyTypes() {
        let loader = ProtocolLoader.shared

        // Tendinopathy types map to expected filenames
        XCTAssertNotNil(loader.protocolFor(type: .achilles))
        XCTAssertNotNil(loader.protocolFor(type: .patellar))
        XCTAssertNotNil(loader.protocolFor(type: .tennisElbow))
        XCTAssertNotNil(loader.protocolFor(type: .golfersElbow))
        XCTAssertNotNil(loader.protocolFor(type: .rotatorCuff))
        XCTAssertNotNil(loader.protocolFor(type: .gluteal))
        XCTAssertNotNil(loader.protocolFor(type: .proximalHamstring))
        XCTAssertNotNil(loader.protocolFor(type: .plantarFascia))
    }

    func testProtocolKeyForLbpSubtypes() {
        let loader = ProtocolLoader.shared

        XCTAssertNotNil(loader.protocolFor(type: .lbpNonspecific, aemSubtype: .FAR))
        XCTAssertNotNil(loader.protocolFor(type: .lbpNonspecific, aemSubtype: .DER))
        XCTAssertNotNil(loader.protocolFor(type: .lbpNonspecific, aemSubtype: .EER))
        XCTAssertNotNil(loader.protocolFor(type: .lbpNonspecific, aemSubtype: .AR))
    }

    func testProtocolKeyForLbpWithoutSubtypeDefaultsToAR() {
        let loader = ProtocolLoader.shared

        let proto = loader.protocolFor(type: .lbpNonspecific)
        XCTAssertNotNil(proto)
    }

    func testProtocolKeyForNeckPain() {
        let loader = ProtocolLoader.shared
        XCTAssertNotNil(loader.protocolFor(type: .neckPain))
    }

    func testProtocolKeyForTensionSeverities() {
        let loader = ProtocolLoader.shared

        XCTAssertNotNil(loader.protocolFor(type: .neckShoulderTension, tsiSeverity: .LEICHT))
        XCTAssertNotNil(loader.protocolFor(type: .neckShoulderTension, tsiSeverity: .MITTEL))
        XCTAssertNotNil(loader.protocolFor(type: .neckShoulderTension, tsiSeverity: .SCHWER))
    }

    func testProtocolKeyForShoulderImpingementSeverities() {
        let loader = ProtocolLoader.shared

        XCTAssertNotNil(loader.protocolFor(type: .shoulderImpingement, siSeverity: .LEICHT))
        XCTAssertNotNil(loader.protocolFor(type: .shoulderImpingement, siSeverity: .MITTEL))
        XCTAssertNotNil(loader.protocolFor(type: .shoulderImpingement, siSeverity: .SCHWER))
    }

    func testProtocolKeyForFrozenShoulderSeverities() {
        let loader = ProtocolLoader.shared

        XCTAssertNotNil(loader.protocolFor(type: .frozenShoulder, fsSeverity: .LEICHT))
        XCTAssertNotNil(loader.protocolFor(type: .frozenShoulder, fsSeverity: .MITTEL))
        XCTAssertNotNil(loader.protocolFor(type: .frozenShoulder, fsSeverity: .SCHWER))
    }

    func testProtocolKeyForLateralAnkleSprainSeverities() {
        let loader = ProtocolLoader.shared

        XCTAssertNotNil(loader.protocolFor(type: .lateralAnkleSprain, lasSeverity: .LEICHT))
        XCTAssertNotNil(loader.protocolFor(type: .lateralAnkleSprain, lasSeverity: .MITTEL))
        XCTAssertNotNil(loader.protocolFor(type: .lateralAnkleSprain, lasSeverity: .SCHWER))
    }

    // MARK: - Cache Behavior

    func testClearCacheDoesNotCrash() {
        let loader = ProtocolLoader.shared

        // Load something to populate cache
        _ = loader.protocolFor(type: .achilles)

        // Clear should not crash
        loader.clearCache()

        // Reload should still work
        XCTAssertNotNil(loader.protocolFor(type: .achilles))
    }

    // MARK: - exercisesForPhase

    func testExercisesForPhaseFiltersCorrectly() {
        let loader = ProtocolLoader.shared
        guard let proto = loader.protocolFor(type: .achilles) else {
            XCTFail("Achilles protocol not found")
            return
        }

        let phase1 = loader.exercisesForPhase(protocol: proto, phase: 1)
        let phase2 = loader.exercisesForPhase(protocol: proto, phase: 2)

        XCTAssertFalse(phase1.isEmpty)
        XCTAssertTrue(phase1.allSatisfy { $0.phase == 1 })

        if !phase2.isEmpty {
            XCTAssertTrue(phase2.allSatisfy { $0.phase == 2 })
        }
    }

    func testExercisesForNonexistentPhaseReturnsEmpty() {
        let loader = ProtocolLoader.shared
        guard let proto = loader.protocolFor(type: .achilles) else {
            XCTFail("Achilles protocol not found")
            return
        }

        let phase99 = loader.exercisesForPhase(protocol: proto, phase: 99)
        XCTAssertTrue(phase99.isEmpty)
    }

    // MARK: - Phase Names

    func testPhaseNameForTendinopathy() {
        let loader = ProtocolLoader.shared

        let name = loader.phaseName(1, for: .achilles)
        XCTAssertTrue(name.contains("1"))
    }

    func testPhaseNameForLbp() {
        let loader = ProtocolLoader.shared

        let name = loader.phaseName(1, for: .lbpNonspecific)
        XCTAssertTrue(name.contains("1"))
    }

    func testPhaseNameForNeck() {
        let loader = ProtocolLoader.shared

        let name = loader.phaseName(1, for: .neckPain)
        XCTAssertTrue(name.contains("1"))
    }

    func testPhaseNameForFrozenShoulder() {
        let loader = ProtocolLoader.shared

        let name = loader.phaseName(1, for: .frozenShoulder)
        XCTAssertTrue(name.contains("1"))
    }

    // MARK: - Unknown type

    func testUnknownTypeReturnsNil() {
        let loader = ProtocolLoader.shared
        XCTAssertNil(loader.protocolFor(type: .unknown))
    }
}
