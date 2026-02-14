import XCTest
@testable import Reapptivate

final class PhaseAdaptationTests: XCTestCase {

    // MARK: - ProgressionReadiness.criteriaMetCount

    func testCriteriaMetCountAllFalse() {
        let readiness = ProgressionReadiness(
            minDaysMet: false,
            minSessionsMet: false,
            painCriteriaMet: false,
            complianceCriteriaMet: false
        )
        XCTAssertEqual(readiness.criteriaMetCount, 0)
    }

    func testCriteriaMetCountAllTrue() {
        let readiness = ProgressionReadiness(
            minDaysMet: true,
            minSessionsMet: true,
            painCriteriaMet: true,
            complianceCriteriaMet: true
        )
        XCTAssertEqual(readiness.criteriaMetCount, 4)
    }

    func testCriteriaMetCountPartial() {
        let readiness = ProgressionReadiness(
            minDaysMet: true,
            minSessionsMet: false,
            painCriteriaMet: true,
            complianceCriteriaMet: false
        )
        XCTAssertEqual(readiness.criteriaMetCount, 2)
    }

    func testCriteriaMetCountThreeOfFour() {
        let readiness = ProgressionReadiness(
            minDaysMet: true,
            minSessionsMet: true,
            painCriteriaMet: true,
            complianceCriteriaMet: false
        )
        XCTAssertEqual(readiness.criteriaMetCount, 3)
    }

    // MARK: - AdaptationResult.phaseChanged

    func testPhaseChangedForAllDecisions() {
        XCTAssertTrue(TestFixtures.adaptationResult(decision: .progress).phaseChanged)
        XCTAssertFalse(TestFixtures.adaptationResult(decision: .hold).phaseChanged)
        XCTAssertTrue(TestFixtures.adaptationResult(decision: .regress).phaseChanged)
        XCTAssertFalse(TestFixtures.adaptationResult(decision: .initial).phaseChanged)
    }
}
