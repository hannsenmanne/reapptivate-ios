import XCTest
@testable import Reapptivate

final class UserProfileTests: XCTestCase {

    func testCurrentPhaseDefaultsTo1WhenAdaptivePhaseNil() {
        let user = TestFixtures.userProfile(adaptivePhase: nil)
        XCTAssertEqual(user.currentPhase, 1)
    }

    func testCurrentPhaseReturnsValueWhenSet() {
        let user = TestFixtures.userProfile(adaptivePhase: 3)
        XCTAssertEqual(user.currentPhase, 3)
    }

    func testMaxPhaseIs4ForNeck() {
        let user = TestFixtures.neckUser()
        XCTAssertEqual(user.maxPhase, 4)
    }

    func testMaxPhaseIs3ForTendinopathy() {
        let user = TestFixtures.userProfile(tendinopathyType: .achilles)
        XCTAssertEqual(user.maxPhase, 3)
    }

    func testMaxPhaseIs3ForLbp() {
        let user = TestFixtures.userProfile(tendinopathyType: .lbpNonspecific)
        XCTAssertEqual(user.maxPhase, 3)
    }

    func testStartDateParsedHandlesISO8601() {
        let user = TestFixtures.userProfile(startDate: "2025-01-15T00:00:00.000Z")
        XCTAssertNotNil(user.startDateParsed)

        let components = Calendar.current.dateComponents([.year, .month, .day], from: user.startDateParsed!)
        XCTAssertEqual(components.year, 2025)
        XCTAssertEqual(components.month, 1)
        XCTAssertEqual(components.day, 15)
    }
}
