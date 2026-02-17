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
        XCTAssertEqual(TendinopathyType.allCases.count, 11)
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

    func testIsTendinopathyExcludesLbpNeckAndTension() {
        XCTAssertFalse(TendinopathyType.lbpNonspecific.isTendinopathy)
        XCTAssertFalse(TendinopathyType.neckPain.isTendinopathy)
        XCTAssertFalse(TendinopathyType.neckShoulderTension.isTendinopathy)
        XCTAssertTrue(TendinopathyType.achilles.isTendinopathy)
        XCTAssertTrue(TendinopathyType.tennisElbow.isTendinopathy)
        XCTAssertTrue(TendinopathyType.rotatorCuff.isTendinopathy)
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

    func testNdiSeverityFromScoreBoundary15To28() {
        XCTAssertEqual(NdiSeverityGrade.from(ndiScore: 15), .MITTEL)
        XCTAssertEqual(NdiSeverityGrade.from(ndiScore: 28), .MITTEL)
    }

    func testNdiSeverityFromScoreBoundary29Plus() {
        XCTAssertEqual(NdiSeverityGrade.from(ndiScore: 29), .SCHWER)
        XCTAssertEqual(NdiSeverityGrade.from(ndiScore: 50), .SCHWER)
    }

    // MARK: - TsiSeverityGrade

    func testTsiSeverityFromScore_Leicht() {
        XCTAssertEqual(TsiSeverityGrade.from(tsiScore: 0), .LEICHT)
        XCTAssertEqual(TsiSeverityGrade.from(tsiScore: 10), .LEICHT)
        XCTAssertEqual(TsiSeverityGrade.from(tsiScore: 16), .LEICHT)
    }

    func testTsiSeverityFromScore_Mittel() {
        XCTAssertEqual(TsiSeverityGrade.from(tsiScore: 17), .MITTEL)
        XCTAssertEqual(TsiSeverityGrade.from(tsiScore: 25), .MITTEL)
        XCTAssertEqual(TsiSeverityGrade.from(tsiScore: 33), .MITTEL)
    }

    func testTsiSeverityFromScore_Schwer() {
        XCTAssertEqual(TsiSeverityGrade.from(tsiScore: 34), .SCHWER)
        XCTAssertEqual(TsiSeverityGrade.from(tsiScore: 42), .SCHWER)
        XCTAssertEqual(TsiSeverityGrade.from(tsiScore: 50), .SCHWER)
    }

    func testTsiSeverityFromScore_EdgeCases() {
        // Boundary at 16/17
        XCTAssertEqual(TsiSeverityGrade.from(tsiScore: 16), .LEICHT)
        XCTAssertEqual(TsiSeverityGrade.from(tsiScore: 17), .MITTEL)
        // Boundary at 33/34
        XCTAssertEqual(TsiSeverityGrade.from(tsiScore: 33), .MITTEL)
        XCTAssertEqual(TsiSeverityGrade.from(tsiScore: 34), .SCHWER)
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
}
