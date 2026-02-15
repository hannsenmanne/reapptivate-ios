import XCTest
@testable import Reapptivate

@MainActor
final class RatingServiceTests: XCTestCase {

    override func setUp() async throws {
        UserDefaults.standard.removeObject(forKey: "rating_prompt_count")
        UserDefaults.standard.removeObject(forKey: "rating_last_prompt_date")
    }

    override func tearDown() async throws {
        UserDefaults.standard.removeObject(forKey: "rating_prompt_count")
        UserDefaults.standard.removeObject(forKey: "rating_last_prompt_date")
    }

    // MARK: - Cooldown Logic

    func testCooldownBlocksPrompt() {
        // Set last prompt to today
        UserDefaults.standard.set(ISO8601DateFormatter().string(from: Date()), forKey: "rating_last_prompt_date")
        UserDefaults.standard.set(1, forKey: "rating_prompt_count")

        let service = RatingService()
        // This should not crash or throw — it just silently returns
        // We can't easily test SKStoreReviewController, but we verify no crash
        service.checkAndPrompt(totalSessions: 30, compliancePercent: 80)
        // Count should stay at 1 (cooldown not expired)
        XCTAssertEqual(UserDefaults.standard.integer(forKey: "rating_prompt_count"), 1)
    }

    func testMaxPromptsBlocksFurtherPrompts() {
        UserDefaults.standard.set(3, forKey: "rating_prompt_count")

        let service = RatingService()
        service.checkAndPrompt(totalSessions: 100, compliancePercent: 100)
        // Count should stay at 3
        XCTAssertEqual(UserDefaults.standard.integer(forKey: "rating_prompt_count"), 3)
    }

    func testNoPromptForLowSessions() {
        let service = RatingService()
        service.checkAndPrompt(totalSessions: 3, compliancePercent: 50)
        // Count should stay at 0
        XCTAssertEqual(UserDefaults.standard.integer(forKey: "rating_prompt_count"), 0)
    }
}
