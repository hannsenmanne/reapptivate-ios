import XCTest
@testable import Reapptivate

@MainActor
final class WorkTimerViewModelTests: XCTestCase {

    private var apiClient: APIClient!
    private var viewModel: WorkTimerViewModel!

    override func setUp() async throws {
        let session = TestHelpers.makeTestSession()
        apiClient = APIClient(session: session)
        viewModel = WorkTimerViewModel(apiClient: apiClient)
    }

    override func tearDown() async throws {
        MockURLProtocol.requestHandler = nil
        viewModel = nil
        apiClient = nil

        // Clean up all UserDefaults keys (includes isOnBreak, breakStartedAt, autoStart, snoozesUsed)
        WorkTimerViewModel.clearPersistedState()
    }

    // MARK: - Load Settings

    func testLoadSettingsSuccess() async {
        MockURLProtocol.requestHandler = { request in
            let json: [String: Any] = [
                "settings": [
                    "startTime": "09:00",
                    "endTime": "18:00",
                    "breakIntervalMinutes": 45,
                    "breakDurationMinutes": 2,
                    "isEnabled": true,
                ]
            ]
            let data = try! JSONSerialization.data(withJSONObject: json)
            let response = TestHelpers.makeHTTPResponse(statusCode: 200)
            return (response, data)
        }

        await viewModel.loadSettings()

        XCTAssertNotNil(viewModel.settings)
        XCTAssertEqual(viewModel.breakIntervalMinutes, 45)
        XCTAssertEqual(viewModel.breakDurationMinutes, 2)
    }

    func testLoadSettingsFailureUsesDefaults() async {
        MockURLProtocol.requestHandler = { _ in
            let response = TestHelpers.makeHTTPResponse(statusCode: 404)
            return (response, Data())
        }

        await viewModel.loadSettings()

        XCTAssertNil(viewModel.settings)
        XCTAssertEqual(viewModel.breakIntervalMinutes, 60)
        XCTAssertEqual(viewModel.breakDurationMinutes, 3)
    }

    // MARK: - Save Settings

    func testSaveSettingsSuccess() async {
        viewModel.breakIntervalMinutes = 30
        viewModel.breakDurationMinutes = 5

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "PUT")
            let json: [String: Any] = [
                "settings": [
                    "startTime": "08:00",
                    "endTime": "17:00",
                    "breakIntervalMinutes": 30,
                    "breakDurationMinutes": 5,
                    "isEnabled": true,
                ]
            ]
            let data = try! JSONSerialization.data(withJSONObject: json)
            let response = TestHelpers.makeHTTPResponse(statusCode: 200)
            return (response, data)
        }

        await viewModel.saveSettings()

        XCTAssertNotNil(viewModel.settings)
        XCTAssertNil(viewModel.errorMessage)
    }

    // MARK: - Start Workday

    func testStartWorkdaySetsRunningState() {
        viewModel.startWorkday()

        XCTAssertTrue(viewModel.isRunning)
        XCTAssertNotNil(viewModel.timerStartedAt)
        XCTAssertNotNil(viewModel.nextBreakAt)
        XCTAssertEqual(viewModel.breaksTakenToday, 0)
        XCTAssertEqual(viewModel.currentBreakNumber, 0)
    }

    func testStartWorkdayCalculatesNextBreak() {
        viewModel.breakIntervalMinutes = 30
        viewModel.startWorkday()

        let expectedInterval: TimeInterval = 30 * 60
        let actualInterval = viewModel.nextBreakAt!.timeIntervalSince(viewModel.timerStartedAt!)
        XCTAssertEqual(actualInterval, expectedInterval, accuracy: 2.0)
    }

    // MARK: - Stop Workday

    func testStopWorkdayClearsRunningState() async {
        MockURLProtocol.requestHandler = { _ in
            let json: [String: Any] = [
                "summary": [
                    "date": "2026-02-18",
                    "totalWorkMinutes": 120,
                    "breaksOffered": 2,
                    "breaksCompleted": 1,
                    "breaksSkipped": 1,
                    "adherencePercent": 50.0,
                ]
            ]
            let data = try! JSONSerialization.data(withJSONObject: json)
            let response = TestHelpers.makeHTTPResponse(statusCode: 200)
            return (response, data)
        }

        viewModel.startWorkday()
        await viewModel.stopWorkday()

        XCTAssertFalse(viewModel.isRunning)
        XCTAssertTrue(viewModel.showingSummary)
        XCTAssertNotNil(viewModel.todaySummary)
    }

    // MARK: - Complete Break

    func testCompleteBreakIncrementsCount() async {
        MockURLProtocol.requestHandler = { _ in
            let response = TestHelpers.makeHTTPResponse(statusCode: 200)
            return (response, Data())
        }

        viewModel.startWorkday()
        viewModel.currentBreakNumber = 1
        viewModel.isOnBreak = true

        await viewModel.completeBreak()

        XCTAssertEqual(viewModel.breaksTakenToday, 1)
        XCTAssertFalse(viewModel.isOnBreak)
        XCTAssertFalse(viewModel.showingBreak)
    }

    // MARK: - Skip Break

    func testSkipBreakIncrementsSkippedCount() async {
        MockURLProtocol.requestHandler = { _ in
            let response = TestHelpers.makeHTTPResponse(statusCode: 200)
            return (response, Data())
        }

        viewModel.startWorkday()
        viewModel.currentBreakNumber = 1
        viewModel.isOnBreak = true

        await viewModel.skipBreak()

        XCTAssertEqual(viewModel.breaksSkippedToday, 1)
        XCTAssertEqual(viewModel.breaksTakenToday, 0)
        XCTAssertFalse(viewModel.isOnBreak)
    }

    // MARK: - Timer Persistence

    func testTimerStatePersistsAndRestores() {
        viewModel.startWorkday()
        viewModel.saveTimerState()

        let newVM = WorkTimerViewModel(apiClient: apiClient)
        newVM.restoreTimerState()

        XCTAssertTrue(newVM.isRunning)
        XCTAssertNotNil(newVM.timerStartedAt)
    }

    func testStaleTimerStateClearedOnNewDay() {
        // Simulate a timer from yesterday
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: "workTimer_isRunning")
        defaults.set(Date().addingTimeInterval(-86400).timeIntervalSince1970, forKey: "workTimer_startedAt")
        defaults.set("2020-01-01", forKey: "workTimer_date")

        viewModel.restoreTimerState()

        XCTAssertFalse(viewModel.isRunning)
        XCTAssertNil(viewModel.timerStartedAt)
    }

    // MARK: - Computed Properties

    func testAdherencePercent() {
        viewModel.breaksTakenToday = 3
        viewModel.breaksSkippedToday = 1

        XCTAssertEqual(viewModel.adherencePercent, 75.0, accuracy: 0.1)
    }

    func testAdherencePercentZeroWhenNoBreaks() {
        viewModel.breaksTakenToday = 0
        viewModel.breaksSkippedToday = 0

        XCTAssertEqual(viewModel.adherencePercent, 0.0)
    }

    func testFormattedTimeUntilBreak() {
        viewModel.secondsUntilBreak = 125 // 2:05

        XCTAssertEqual(viewModel.formattedTimeUntilBreak, "02:05")
    }

    func testProgressComputation() {
        viewModel.breakIntervalMinutes = 60
        viewModel.secondsUntilBreak = 1800 // 30 minutes left out of 60

        // elapsed = 3600 - 1800 = 1800, progress = 1800/3600 = 0.5
        XCTAssertEqual(viewModel.progress, 0.5, accuracy: 0.01)
    }
}
