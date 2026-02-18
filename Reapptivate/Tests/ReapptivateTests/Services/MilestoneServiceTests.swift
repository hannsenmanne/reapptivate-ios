import XCTest
@testable import Reapptivate

@MainActor
final class MilestoneServiceTests: XCTestCase {

    private var service: MilestoneService!
    private let testUserId = "test-milestone-user"

    override func setUp() async throws {
        cleanUpDefaults()
        service = MilestoneService()
        service.configure(userId: testUserId)
    }

    override func tearDown() async throws {
        cleanUpDefaults()
        service = nil
    }

    private func cleanUpDefaults() {
        for key in [
            "milestones_shown_\(testUserId)",
            "milestones_dates_\(testUserId)",
            "milestones_initialized_\(testUserId)",
        ] {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    // MARK: - First Training

    func testFirstTrainingMilestone() {
        let result = service.check(totalSessions: 1, currentPhase: 1)
        XCTAssertEqual(result, .firstTraining)
    }

    func testNoMilestoneForZeroSessions() {
        let result = service.check(totalSessions: 0, currentPhase: 1)
        XCTAssertNil(result)
    }

    // MARK: - Ten Sessions

    func testTenSessionsMilestone() {
        service.markShown(.firstTraining)
        let result = service.check(totalSessions: 10, currentPhase: 1)
        XCTAssertEqual(result, .tenSessions)
    }

    // MARK: - Phase Up

    func testPhaseUpMilestone() {
        service.markShown(.firstTraining)
        service.markShown(.tenSessions)
        let result = service.check(totalSessions: 15, currentPhase: 2)
        XCTAssertEqual(result, .phaseUp)
    }

    // MARK: - Mark Shown

    func testMarkShownPreventsRepeat() {
        let first = service.check(totalSessions: 1, currentPhase: 1)
        XCTAssertEqual(first, .firstTraining)

        service.markShown(.firstTraining)
        let second = service.check(totalSessions: 1, currentPhase: 1)
        // Should not return firstTraining again; tenSessions not yet qualified
        XCTAssertNil(second)
    }

    func testAllMilestonesShownReturnsNil() {
        for milestone in Milestone.allCases {
            service.markShown(milestone)
        }
        let result = service.check(totalSessions: 100, currentPhase: 3)
        XCTAssertNil(result)
    }

    // MARK: - Returns First Unshown

    func testReturnsFirstUnshownQualifying() {
        // Both firstTraining and tenSessions qualify, but firstTraining comes first
        let result = service.check(totalSessions: 10, currentPhase: 1)
        XCTAssertEqual(result, .firstTraining)
    }

    // MARK: - Seed Existing

    func testSeedExistingMarksQualifyingMilestonesAsShown() {
        service.seedExistingIfNeeded(totalSessions: 15, currentPhase: 2)
        // firstTraining, tenSessions, phaseUp should all be seeded
        XCTAssertTrue(service.isEarned(.firstTraining))
        XCTAssertTrue(service.isEarned(.tenSessions))
        XCTAssertTrue(service.isEarned(.phaseUp))
        // twentyFiveSessions should NOT be seeded
        XCTAssertFalse(service.isEarned(.twentyFiveSessions))
        // check() should return nil since all qualifying are seeded
        XCTAssertNil(service.check(totalSessions: 15, currentPhase: 2))
    }

    func testSeedExistingRunsOnlyOnce() {
        service.seedExistingIfNeeded(totalSessions: 5, currentPhase: 1)
        XCTAssertTrue(service.isEarned(.firstTraining))
        // Second call with more sessions should NOT seed new milestones
        service.seedExistingIfNeeded(totalSessions: 50, currentPhase: 3)
        XCTAssertFalse(service.isEarned(.tenSessions))
    }
}

// Milestone needs Equatable for test assertions
extension Milestone: Equatable {}
