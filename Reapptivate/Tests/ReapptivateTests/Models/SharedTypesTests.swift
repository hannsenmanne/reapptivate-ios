import XCTest
@testable import Reapptivate

final class SharedTypesTests: XCTestCase {

    // MARK: - TendinopathyType

    func testTendinopathyTypeRawValueRoundTrip() {
        for type in TendinopathyType.allCases {
            let encoded = type.rawValue
            let decoded = TendinopathyType(rawValue: encoded)
            XCTAssertEqual(decoded, type, "Round-trip failed for \(type)")
        }
    }

    func testTendinopathyTypeCount() {
        XCTAssertEqual(TendinopathyType.allCases.count, 15)
    }

    func testIsLbpOnlyForLbpNonspecific() {
        XCTAssertTrue(TendinopathyType.lbpNonspecific.isLbp)
        XCTAssertFalse(TendinopathyType.neckPain.isLbp)
        XCTAssertFalse(TendinopathyType.achilles.isLbp)
    }

    func testIsNeckOnlyForNeckPain() {
        XCTAssertTrue(TendinopathyType.neckPain.isNeck)
        XCTAssertFalse(TendinopathyType.lbpNonspecific.isNeck)
        XCTAssertFalse(TendinopathyType.patellar.isNeck)
    }

    func testIsTendinopathyExcludesLbpNeckTensionAndAcl() {
        XCTAssertFalse(TendinopathyType.lbpNonspecific.isTendinopathy)
        XCTAssertFalse(TendinopathyType.neckPain.isTendinopathy)
        XCTAssertFalse(TendinopathyType.neckShoulderTension.isTendinopathy)
        XCTAssertFalse(TendinopathyType.aclReconstruction.isTendinopathy)
        XCTAssertFalse(TendinopathyType.shoulderImpingement.isTendinopathy)
        XCTAssertTrue(TendinopathyType.achilles.isTendinopathy)
        XCTAssertTrue(TendinopathyType.tennisElbow.isTendinopathy)
        XCTAssertTrue(TendinopathyType.rotatorCuff.isTendinopathy)
    }

    func testIsAclOnlyForAclReconstruction() {
        XCTAssertTrue(TendinopathyType.aclReconstruction.isAcl)
        XCTAssertFalse(TendinopathyType.lbpNonspecific.isAcl)
        XCTAssertFalse(TendinopathyType.neckPain.isAcl)
        XCTAssertFalse(TendinopathyType.achilles.isAcl)
    }

    func testIsTensionOnlyForNeckShoulderTension() {
        XCTAssertTrue(TendinopathyType.neckShoulderTension.isTension)
        XCTAssertFalse(TendinopathyType.neckPain.isTension)
        XCTAssertFalse(TendinopathyType.lbpNonspecific.isTension)
        XCTAssertFalse(TendinopathyType.achilles.isTension)
    }

    func testTendinopathyTypeDisplayNames() {
        XCTAssertEqual(TendinopathyType.achilles.displayName, "Achillessehne")
        XCTAssertEqual(TendinopathyType.lbpNonspecific.displayName, "Unspez. Rückenschmerz")
        XCTAssertEqual(TendinopathyType.neckPain.displayName, "Nackenschmerz")
    }

    // MARK: - NdiSeverityGrade

    func testNdiSeverityFromScoreBoundary14() {
        XCTAssertEqual(NdiSeverityGrade.from(ndiScore: 0), .LEICHT)
        XCTAssertEqual(NdiSeverityGrade.from(ndiScore: 14), .LEICHT)
    }

    func testNdiSeverityFromScoreBoundary15To24() {
        XCTAssertEqual(NdiSeverityGrade.from(ndiScore: 15), .MITTEL)
        XCTAssertEqual(NdiSeverityGrade.from(ndiScore: 24), .MITTEL)
    }

    func testNdiSeverityFromScoreBoundary25Plus() {
        XCTAssertEqual(NdiSeverityGrade.from(ndiScore: 25), .SCHWER)
        XCTAssertEqual(NdiSeverityGrade.from(ndiScore: 50), .SCHWER)
    }

    // MARK: - TsiSeverityGrade

    func testTsiSeverityFromScore_Leicht() {
        XCTAssertEqual(TsiSeverityGrade.from(tsiScore: 0), .LEICHT)
        XCTAssertEqual(TsiSeverityGrade.from(tsiScore: 10), .LEICHT)
        XCTAssertEqual(TsiSeverityGrade.from(tsiScore: 15), .LEICHT)
    }

    func testTsiSeverityFromScore_Mittel() {
        XCTAssertEqual(TsiSeverityGrade.from(tsiScore: 16), .MITTEL)
        XCTAssertEqual(TsiSeverityGrade.from(tsiScore: 22), .MITTEL)
        XCTAssertEqual(TsiSeverityGrade.from(tsiScore: 27), .MITTEL)
    }

    func testTsiSeverityFromScore_Schwer() {
        XCTAssertEqual(TsiSeverityGrade.from(tsiScore: 28), .SCHWER)
        XCTAssertEqual(TsiSeverityGrade.from(tsiScore: 42), .SCHWER)
        XCTAssertEqual(TsiSeverityGrade.from(tsiScore: 50), .SCHWER)
    }

    func testTsiSeverityFromScore_EdgeCases() {
        // Boundary at 15/16
        XCTAssertEqual(TsiSeverityGrade.from(tsiScore: 15), .LEICHT)
        XCTAssertEqual(TsiSeverityGrade.from(tsiScore: 16), .MITTEL)
        // Boundary at 27/28
        XCTAssertEqual(TsiSeverityGrade.from(tsiScore: 27), .MITTEL)
        XCTAssertEqual(TsiSeverityGrade.from(tsiScore: 28), .SCHWER)
    }

    func testTsiSeverityDisplayNames() {
        XCTAssertEqual(TsiSeverityGrade.LEICHT.displayName, "Leicht")
        XCTAssertEqual(TsiSeverityGrade.MITTEL.displayName, "Mittel")
        XCTAssertEqual(TsiSeverityGrade.SCHWER.displayName, "Schwer")
    }

    func testTsiSeverityGradeCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for grade in [TsiSeverityGrade.LEICHT, .MITTEL, .SCHWER] {
            let data = try encoder.encode(grade)
            let decoded = try decoder.decode(TsiSeverityGrade.self, from: data)
            XCTAssertEqual(decoded, grade)
        }
    }

    // MARK: - FsSeverityGrade

    func testFsSeverityFromScore_Leicht() {
        XCTAssertEqual(FsSeverityGrade.from(spadiScore: 0), .LEICHT)
        XCTAssertEqual(FsSeverityGrade.from(spadiScore: 17), .LEICHT)
        XCTAssertEqual(FsSeverityGrade.from(spadiScore: 34), .LEICHT)
    }

    func testFsSeverityFromScore_Mittel() {
        XCTAssertEqual(FsSeverityGrade.from(spadiScore: 35), .MITTEL)
        XCTAssertEqual(FsSeverityGrade.from(spadiScore: 47), .MITTEL)
        XCTAssertEqual(FsSeverityGrade.from(spadiScore: 59), .MITTEL)
    }

    func testFsSeverityFromScore_Schwer() {
        XCTAssertEqual(FsSeverityGrade.from(spadiScore: 60), .SCHWER)
        XCTAssertEqual(FsSeverityGrade.from(spadiScore: 80), .SCHWER)
        XCTAssertEqual(FsSeverityGrade.from(spadiScore: 100), .SCHWER)
    }

    func testFsSeverityFromScore_EdgeCases() {
        // Boundary at 34/35
        XCTAssertEqual(FsSeverityGrade.from(spadiScore: 34), .LEICHT)
        XCTAssertEqual(FsSeverityGrade.from(spadiScore: 35), .MITTEL)
        // Boundary at 59/60
        XCTAssertEqual(FsSeverityGrade.from(spadiScore: 59), .MITTEL)
        XCTAssertEqual(FsSeverityGrade.from(spadiScore: 60), .SCHWER)
    }

    func testFsSeverityGradeCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for grade in [FsSeverityGrade.LEICHT, .MITTEL, .SCHWER] {
            let data = try encoder.encode(grade)
            let decoded = try decoder.decode(FsSeverityGrade.self, from: data)
            XCTAssertEqual(decoded, grade)
        }
    }

    func testFsSeverityDisplayNames() {
        XCTAssertEqual(FsSeverityGrade.LEICHT.displayName, "Leicht")
        XCTAssertEqual(FsSeverityGrade.MITTEL.displayName, "Mittel")
        XCTAssertEqual(FsSeverityGrade.SCHWER.displayName, "Schwer")
    }

    // MARK: - AemSubtype

    func testAemSubtypeMaxPainLevels() {
        XCTAssertEqual(AemSubtype.FAR.maxPainLevel, 5)
        XCTAssertEqual(AemSubtype.DER.maxPainLevel, 3)
        XCTAssertEqual(AemSubtype.EER.maxPainLevel, 3)
        XCTAssertEqual(AemSubtype.AR.maxPainLevel, 4)
    }

    // MARK: - AdaptationDecision

    func testAdaptationDecisionRawValues() {
        XCTAssertEqual(AdaptationDecision.progress.rawValue, "PROGRESS")
        XCTAssertEqual(AdaptationDecision.hold.rawValue, "HOLD")
        XCTAssertEqual(AdaptationDecision.regress.rawValue, "REGRESS")
        XCTAssertEqual(AdaptationDecision.initial.rawValue, "INITIAL")
    }

    func testAdaptationDecisionCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for decision in [AdaptationDecision.progress, .hold, .regress, .initial] {
            let data = try encoder.encode(decision)
            let decoded = try decoder.decode(AdaptationDecision.self, from: data)
            XCTAssertEqual(decoded, decision)
        }
    }

    // MARK: - LasSeverityGrade

    func testLasSeverityFromScore_Leicht() {
        // CAIT >= 24 → LEICHT (good stability)
        XCTAssertEqual(LasSeverityGrade.from(caitScore: 30), .LEICHT)
        XCTAssertEqual(LasSeverityGrade.from(caitScore: 27), .LEICHT)
        XCTAssertEqual(LasSeverityGrade.from(caitScore: 24), .LEICHT)
    }

    func testLasSeverityFromScore_Mittel() {
        // CAIT 12-23 → MITTEL (moderate instability)
        XCTAssertEqual(LasSeverityGrade.from(caitScore: 23), .MITTEL)
        XCTAssertEqual(LasSeverityGrade.from(caitScore: 17), .MITTEL)
        XCTAssertEqual(LasSeverityGrade.from(caitScore: 12), .MITTEL)
    }

    func testLasSeverityFromScore_Schwer() {
        // CAIT <= 11 → SCHWER (chronic instability)
        XCTAssertEqual(LasSeverityGrade.from(caitScore: 11), .SCHWER)
        XCTAssertEqual(LasSeverityGrade.from(caitScore: 5), .SCHWER)
        XCTAssertEqual(LasSeverityGrade.from(caitScore: 0), .SCHWER)
    }

    func testLasSeverityFromScore_EdgeCases() {
        // Exact boundaries
        XCTAssertEqual(LasSeverityGrade.from(caitScore: 24), .LEICHT, "24 should be LEICHT")
        XCTAssertEqual(LasSeverityGrade.from(caitScore: 23), .MITTEL, "23 should be MITTEL")
        XCTAssertEqual(LasSeverityGrade.from(caitScore: 12), .MITTEL, "12 should be MITTEL")
        XCTAssertEqual(LasSeverityGrade.from(caitScore: 11), .SCHWER, "11 should be SCHWER")
    }

    func testLasSeverityGradeCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        for grade in [LasSeverityGrade.LEICHT, .MITTEL, .SCHWER] {
            let data = try encoder.encode(grade)
            let decoded = try decoder.decode(LasSeverityGrade.self, from: data)
            XCTAssertEqual(decoded, grade)
        }
    }

    func testLasSeverityGradeUnknownDecoding() throws {
        let data = Data("\"INVALID\"".utf8)
        let decoded = try JSONDecoder().decode(LasSeverityGrade.self, from: data)
        XCTAssertEqual(decoded, .unknown)
    }

    func testLasSeverityDisplayNames() {
        XCTAssertEqual(LasSeverityGrade.LEICHT.displayName, "Leicht")
        XCTAssertEqual(LasSeverityGrade.MITTEL.displayName, "Mittel")
        XCTAssertEqual(LasSeverityGrade.SCHWER.displayName, "Schwer")
    }

    func testLateralAnkleSprainIsNotTendinopathy() {
        XCTAssertFalse(TendinopathyType.lateralAnkleSprain.isTendinopathy)
        XCTAssertTrue(TendinopathyType.lateralAnkleSprain.isLateralAnkleSprain)
    }
}
