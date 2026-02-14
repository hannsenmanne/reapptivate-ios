import XCTest
@testable import Reapptivate

@MainActor
final class AppStateTests: XCTestCase {

    // MARK: - Initial State

    func testInitialState() {
        let state = AppState()
        XCTAssertTrue(state.isCheckingAuth)
        XCTAssertFalse(state.isAuthenticated)
        XCTAssertNil(state.currentUser)
    }

    // MARK: - handleLogin

    func testHandleLoginSetsAuthenticatedAndUser() {
        let state = AppState()
        let user = TestFixtures.userProfile()

        state.handleLogin(user: user)

        XCTAssertTrue(state.isAuthenticated)
        XCTAssertEqual(state.currentUser?.id, "user-1")
    }

    // MARK: - handleLogout

    func testHandleLogoutClearsState() {
        let state = AppState()
        state.handleLogin(user: TestFixtures.userProfile())

        state.handleLogout()

        XCTAssertFalse(state.isAuthenticated)
        XCTAssertNil(state.currentUser)
    }

    func testHandleLogoutCallsOnLogoutCallback() {
        let state = AppState()
        var callbackFired = false
        state.onLogout = { callbackFired = true }
        state.handleLogin(user: TestFixtures.userProfile())

        state.handleLogout()

        XCTAssertTrue(callbackFired)
    }

    // MARK: - isLbp

    func testIsLbpTrueForLbpNonspecific() {
        let state = AppState()
        state.handleLogin(user: TestFixtures.userProfile(tendinopathyType: .lbpNonspecific))
        XCTAssertTrue(state.isLbp)
    }

    func testIsLbpFalseForOthers() {
        let state = AppState()
        state.handleLogin(user: TestFixtures.userProfile(tendinopathyType: .achilles))
        XCTAssertFalse(state.isLbp)
    }

    // MARK: - isNeck

    func testIsNeckTrueForNeckPain() {
        let state = AppState()
        state.handleLogin(user: TestFixtures.neckUser())
        XCTAssertTrue(state.isNeck)
    }

    // MARK: - needsAemScreening

    func testNeedsAemScreeningTrueForLbpNotScreened() {
        let state = AppState()
        state.handleLogin(user: TestFixtures.userProfile(
            tendinopathyType: .lbpNonspecific,
            aemScreeningCompleted: nil
        ))
        XCTAssertTrue(state.needsAemScreening)
    }

    func testNeedsAemScreeningFalseWhenCompleted() {
        let state = AppState()
        state.handleLogin(user: TestFixtures.userProfile(
            tendinopathyType: .lbpNonspecific,
            aemScreeningCompleted: true
        ))
        XCTAssertFalse(state.needsAemScreening)
    }

    func testNeedsAemScreeningFalseForNonLbp() {
        let state = AppState()
        state.handleLogin(user: TestFixtures.userProfile(tendinopathyType: .achilles))
        XCTAssertFalse(state.needsAemScreening)
    }

    // MARK: - needsNeckScreening

    func testNeedsNeckScreeningTrueForNeckNotScreened() {
        let state = AppState()
        state.handleLogin(user: TestFixtures.neckUser(screened: false))
        XCTAssertTrue(state.needsNeckScreening)
    }

    func testNeedsNeckScreeningFalseWhenScreened() {
        let state = AppState()
        state.handleLogin(user: TestFixtures.neckUser(screened: true))
        XCTAssertFalse(state.needsNeckScreening)
    }
}
