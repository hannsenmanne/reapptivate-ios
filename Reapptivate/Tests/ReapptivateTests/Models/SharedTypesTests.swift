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

    func testIsTendinopathyExcludesLbpAndNeck() {
        XCTAssertFalse(TendinopathyType.lbpNonspecific.isTendinopathy)
        XCTAssertFalse(TendinopathyType.neckPain.isTendinopathy)
        XCTAssertTrue(TendinopathyType.achilles.isTendinopathy)
        XCTAssertTrue(TendinopathyType.tennisElbow.isTendinopathy)
        XCTAssertTrue(TendinopathyType.rotatorCuff.isTendinopathy)
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
