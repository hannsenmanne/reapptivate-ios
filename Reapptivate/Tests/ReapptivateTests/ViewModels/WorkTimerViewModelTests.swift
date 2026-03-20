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
        WorkTimerViewModel.clearPersistedState(includingPreferences: true)
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

    func testProgressAtZeroSecondsIsOne() {
        viewModel.breakIntervalMinutes = 60
        viewModel.secondsUntilBreak = 0
        XCTAssertEqual(viewModel.progress, 1.0, accuracy: 0.01)
    }

    func testProgressAtFullIntervalIsZero() {
        viewModel.breakIntervalMinutes = 60
        viewModel.secondsUntilBreak = 3600
        XCTAssertEqual(viewModel.progress, 0.0, accuracy: 0.01)
    }

    func testProgressClampsNegativeSeconds() {
        viewModel.breakIntervalMinutes = 60
        viewModel.secondsUntilBreak = -10
        XCTAssertEqual(viewModel.progress, 1.0)
    }

    // MARK: - Break Progress

    func testBreakProgress() {
        viewModel.currentBreakNumber = 2 // even = full break
        viewModel.breakDurationMinutes = 3
        viewModel.breakSecondsRemaining = 90 // 90 of 180 seconds remaining

        // elapsed = 180 - 90 = 90, progress = 90/180 = 0.5
        XCTAssertEqual(viewModel.breakProgress, 0.5, accuracy: 0.01)
    }

    func testBreakProgressMicroBreak() {
        viewModel.currentBreakNumber = 1 // odd = micro break (30s)
        viewModel.breakSecondsRemaining = 15

        // elapsed = 30 - 15 = 15, progress = 15/30 = 0.5
        XCTAssertEqual(viewModel.breakProgress, 0.5, accuracy: 0.01)
    }

    func testBreakProgressAtZeroIsOne() {
        viewModel.currentBreakNumber = 2
        viewModel.breakDurationMinutes = 3
        viewModel.breakSecondsRemaining = 0

        XCTAssertEqual(viewModel.breakProgress, 1.0, accuracy: 0.01)
    }

    func testFormattedBreakTimeRemaining() {
        viewModel.breakSecondsRemaining = 95 // 1:35
        XCTAssertEqual(viewModel.formattedBreakTimeRemaining, "01:35")
    }

    func testFormattedBreakTimeRemainingClampsNegative() {
        viewModel.breakSecondsRemaining = -5
        XCTAssertEqual(viewModel.formattedBreakTimeRemaining, "00:00")
    }

    // MARK: - Micro Break Detection

    func testIsMicroBreakOddNumbers() {
        viewModel.currentBreakNumber = 1
        XCTAssertTrue(viewModel.isMicroBreak)

        viewModel.currentBreakNumber = 3
        XCTAssertTrue(viewModel.isMicroBreak)

        viewModel.currentBreakNumber = 5
        XCTAssertTrue(viewModel.isMicroBreak)
    }

    func testIsMicroBreakEvenNumbers() {
        viewModel.currentBreakNumber = 2
        XCTAssertFalse(viewModel.isMicroBreak)

        viewModel.currentBreakNumber = 4
        XCTAssertFalse(viewModel.isMicroBreak)

        viewModel.currentBreakNumber = 0
        XCTAssertFalse(viewModel.isMicroBreak)
    }

    // MARK: - Trigger Break

    func testTriggerBreakIncrementsBreakNumber() {
        viewModel.startWorkday()

        viewModel.triggerBreak()

        XCTAssertEqual(viewModel.currentBreakNumber, 1)
        XCTAssertTrue(viewModel.isOnBreak)
        XCTAssertTrue(viewModel.showingBreak)
    }

    func testTriggerBreakResetsSnoozesUsed() {
        viewModel.startWorkday()
        viewModel.snoozesUsed = 2

        viewModel.triggerBreak()

        XCTAssertEqual(viewModel.snoozesUsed, 0)
    }

    func testTriggerBreakGuardsPreventsDoubleCall() {
        viewModel.startWorkday()

        viewModel.triggerBreak()
        XCTAssertEqual(viewModel.currentBreakNumber, 1)

        // Second call should be blocked by isOnBreak guard
        viewModel.triggerBreak()
        XCTAssertEqual(viewModel.currentBreakNumber, 1, "triggerBreak should not double-increment when already on break")
    }

    func testTriggerBreakSetsMicroBreakDuration() {
        viewModel.startWorkday()
        viewModel.breakDurationMinutes = 3

        viewModel.triggerBreak() // break #1 = micro (odd)
        XCTAssertEqual(viewModel.breakSecondsRemaining, 30) // microBreakDuration
    }

    func testTriggerBreakSetsFullBreakDuration() {
        viewModel.startWorkday()
        viewModel.breakDurationMinutes = 3
        viewModel.currentBreakNumber = 1 // next will be #2 = full (even)

        viewModel.isOnBreak = false // reset from any prior state
        viewModel.triggerBreak() // break #2 = full
        XCTAssertEqual(viewModel.breakSecondsRemaining, 180) // 3 * 60
    }

    // MARK: - Snooze Break

    func testSnoozeBreakIncrementsSnoozesUsed() {
        viewModel.startWorkday()
        viewModel.isOnBreak = true
        viewModel.currentBreakNumber = 1

        viewModel.snoozeBreak()

        XCTAssertEqual(viewModel.snoozesUsed, 1)
        XCTAssertFalse(viewModel.isOnBreak)
        XCTAssertFalse(viewModel.showingBreak)
    }

    func testSnoozeBreakSchedulesFiveMinuteDelay() {
        viewModel.startWorkday()
        viewModel.isOnBreak = true
        viewModel.currentBreakNumber = 1

        let before = Date()
        viewModel.snoozeBreak()

        let expected = before.addingTimeInterval(5 * 60)
        XCTAssertNotNil(viewModel.nextBreakAt)
        XCTAssertEqual(viewModel.nextBreakAt!.timeIntervalSince1970, expected.timeIntervalSince1970, accuracy: 2.0)
    }

    func testCanSnoozeRespectsMaxLimit() {
        viewModel.snoozesUsed = 0
        XCTAssertTrue(viewModel.canSnooze)

        viewModel.snoozesUsed = 1
        XCTAssertTrue(viewModel.canSnooze)

        viewModel.snoozesUsed = 2
        XCTAssertFalse(viewModel.canSnooze)
    }

    // MARK: - Complete Break Guards

    func testCompleteBreakGuardsWhenNotOnBreak() async {
        MockURLProtocol.requestHandler = { _ in
            XCTFail("Should not make API call when not on break")
            return (TestHelpers.makeHTTPResponse(statusCode: 200), Data())
        }

        viewModel.startWorkday()
        viewModel.isOnBreak = false

        await viewModel.completeBreak()

        XCTAssertEqual(viewModel.breaksTakenToday, 0)
    }

    func testCompleteBreakSchedulesNextBreak() async {
        MockURLProtocol.requestHandler = { _ in
            (TestHelpers.makeHTTPResponse(statusCode: 200), Data())
        }

        viewModel.startWorkday()
        viewModel.breakIntervalMinutes = 45
        viewModel.currentBreakNumber = 1
        viewModel.isOnBreak = true

        let before = Date()
        await viewModel.completeBreak()

        XCTAssertNotNil(viewModel.nextBreakAt)
        let expectedNext = before.addingTimeInterval(45 * 60)
        XCTAssertEqual(viewModel.nextBreakAt!.timeIntervalSince1970, expectedNext.timeIntervalSince1970, accuracy: 2.0)
    }

    // MARK: - Restore Timer State

    func testRestoreBreakInProgressResumesBreak() {
        let defaults = UserDefaults.standard
        let now = Date()
        let breakStart = now.addingTimeInterval(-60) // started 60s ago

        // Set up running timer state
        defaults.set(true, forKey: "workTimer_isRunning")
        defaults.set(now.addingTimeInterval(-3600).timeIntervalSince1970, forKey: "workTimer_startedAt")
        defaults.set(now.addingTimeInterval(1800).timeIntervalSince1970, forKey: "workTimer_nextBreakAt")
        defaults.set(2, forKey: "workTimer_breaksTaken")
        defaults.set(0, forKey: "workTimer_breaksSkipped")
        defaults.set(4, forKey: "workTimer_currentBreakNumber") // even = full break (not micro)

        // Set up break in progress
        defaults.set(true, forKey: "workTimer_isOnBreak")
        defaults.set(breakStart.timeIntervalSince1970, forKey: "workTimer_breakStartedAt")

        // Use local date formatter for the date key
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        defaults.set(formatter.string(from: now), forKey: "workTimer_date")

        viewModel.breakDurationMinutes = 3 // 180s total, 60s elapsed = 120s remaining

        viewModel.restoreTimerState()

        XCTAssertTrue(viewModel.isRunning)
        XCTAssertTrue(viewModel.isOnBreak)
        XCTAssertTrue(viewModel.showingBreak)
        XCTAssertEqual(viewModel.breakSecondsRemaining, 120, accuracy: 2)
        XCTAssertEqual(viewModel.breaksTakenToday, 2) // not incremented
    }

    func testRestoreExpiredBreakCountsAsCompleted() {
        let defaults = UserDefaults.standard
        let now = Date()
        let breakStart = now.addingTimeInterval(-300) // started 5 min ago (expired for 3-min break)

        defaults.set(true, forKey: "workTimer_isRunning")
        defaults.set(now.addingTimeInterval(-7200).timeIntervalSince1970, forKey: "workTimer_startedAt")
        defaults.set(now.addingTimeInterval(1800).timeIntervalSince1970, forKey: "workTimer_nextBreakAt")
        defaults.set(1, forKey: "workTimer_breaksTaken")
        defaults.set(0, forKey: "workTimer_breaksSkipped")
        defaults.set(2, forKey: "workTimer_currentBreakNumber")

        defaults.set(true, forKey: "workTimer_isOnBreak")
        defaults.set(breakStart.timeIntervalSince1970, forKey: "workTimer_breakStartedAt")

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        defaults.set(formatter.string(from: now), forKey: "workTimer_date")

        viewModel.breakDurationMinutes = 3

        MockURLProtocol.requestHandler = { _ in
            (TestHelpers.makeHTTPResponse(statusCode: 200), Data())
        }

        viewModel.restoreTimerState()

        XCTAssertTrue(viewModel.isRunning)
        XCTAssertFalse(viewModel.isOnBreak, "Expired break should not leave isOnBreak true")
        XCTAssertEqual(viewModel.breaksTakenToday, 2, "Should increment breaksTaken for expired break")
        XCTAssertEqual(viewModel.breaksSkippedToday, 0, "breaksSkipped should not change")

        // Next break should be scheduled from break end time, not from now
        // breakStart was 300s ago, break duration = 3min (180s for even break), so breakEnd = 300-180 = 120s ago
        // nextBreak = breakEnd + 60min interval
        XCTAssertNotNil(viewModel.nextBreakAt)
        let breakEnd = breakStart.addingTimeInterval(Double(viewModel.breakDurationMinutes * 60))
        let expectedNext = breakEnd.addingTimeInterval(Double(viewModel.breakIntervalMinutes * 60))
        XCTAssertEqual(viewModel.nextBreakAt!.timeIntervalSince1970, expectedNext.timeIntervalSince1970, accuracy: 2.0)
    }

    func testRestoreWithMissedBreaksTriggers() {
        let defaults = UserDefaults.standard
        let now = Date()

        defaults.set(true, forKey: "workTimer_isRunning")
        defaults.set(now.addingTimeInterval(-7200).timeIntervalSince1970, forKey: "workTimer_startedAt")
        // Next break was 90 minutes ago (missed at least 1 with 60-min interval)
        defaults.set(now.addingTimeInterval(-5400).timeIntervalSince1970, forKey: "workTimer_nextBreakAt")
        defaults.set(0, forKey: "workTimer_breaksTaken")
        defaults.set(0, forKey: "workTimer_breaksSkipped")
        defaults.set(0, forKey: "workTimer_currentBreakNumber")

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        defaults.set(formatter.string(from: now), forKey: "workTimer_date")

        viewModel.breakIntervalMinutes = 60

        viewModel.restoreTimerState()

        XCTAssertTrue(viewModel.isRunning)
        XCTAssertTrue(viewModel.isOnBreak, "Should trigger a break for missed break")
        XCTAssertGreaterThan(viewModel.currentBreakNumber, 0)
    }

    func testRestoreWithFutureBreakDoesNotTrigger() {
        let defaults = UserDefaults.standard
        let now = Date()

        defaults.set(true, forKey: "workTimer_isRunning")
        defaults.set(now.addingTimeInterval(-1800).timeIntervalSince1970, forKey: "workTimer_startedAt")
        // Next break in 30 minutes
        defaults.set(now.addingTimeInterval(1800).timeIntervalSince1970, forKey: "workTimer_nextBreakAt")
        defaults.set(0, forKey: "workTimer_breaksTaken")
        defaults.set(0, forKey: "workTimer_breaksSkipped")
        defaults.set(0, forKey: "workTimer_currentBreakNumber")

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        defaults.set(formatter.string(from: now), forKey: "workTimer_date")

        viewModel.restoreTimerState()

        XCTAssertTrue(viewModel.isRunning)
        XCTAssertFalse(viewModel.isOnBreak)
        XCTAssertEqual(viewModel.secondsUntilBreak, 1800, accuracy: 2)
    }

    func testRestoreWithMissingStartedAtClears() {
        let defaults = UserDefaults.standard

        defaults.set(true, forKey: "workTimer_isRunning")
        defaults.set(0.0, forKey: "workTimer_startedAt") // Invalid
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        defaults.set(formatter.string(from: Date()), forKey: "workTimer_date")

        viewModel.restoreTimerState()

        XCTAssertFalse(viewModel.isRunning)
    }

    func testRestoreIsReentrantSafe() {
        viewModel.startWorkday()
        viewModel.saveTimerState()

        let newVM = WorkTimerViewModel(apiClient: apiClient)
        newVM.restoreTimerState()
        // Second call should be no-op (isRestoringState guard)
        let breaksBefore = newVM.breaksTakenToday
        newVM.restoreTimerState()
        XCTAssertEqual(newVM.breaksTakenToday, breaksBefore)
    }

    // MARK: - Foreground Return

    func testForegroundReturnWhenNotRunning() {
        viewModel.isRunning = false

        viewModel.handleForegroundReturn()

        XCTAssertFalse(viewModel.isOnBreak)
    }

    func testForegroundReturnRecalculatesSecondsUntilBreak() {
        viewModel.startWorkday()
        let nextBreak = Date().addingTimeInterval(600) // 10 minutes
        viewModel.nextBreakAt = nextBreak

        viewModel.handleForegroundReturn()

        XCTAssertEqual(viewModel.secondsUntilBreak, 600, accuracy: 2)
        XCTAssertFalse(viewModel.isOnBreak)
    }

    func testForegroundReturnShowsBreakStillInProgress() {
        viewModel.startWorkday()
        viewModel.breakDurationMinutes = 3
        // Break was due 10 seconds ago — micro-break (30s) still has 20s remaining
        viewModel.nextBreakAt = Date().addingTimeInterval(-10)

        viewModel.handleForegroundReturn()

        XCTAssertTrue(viewModel.isOnBreak, "Should show break when still in progress")
        XCTAssertEqual(viewModel.currentBreakNumber, 1)
        XCTAssertEqual(viewModel.breakSecondsRemaining, 20, accuracy: 2)
    }

    func testForegroundReturnAutoCompletesFullyExpiredBreak() {
        viewModel.startWorkday()
        viewModel.breakDurationMinutes = 3
        // Break was due 60 seconds ago — micro-break (30s) fully expired
        viewModel.nextBreakAt = Date().addingTimeInterval(-60)

        viewModel.handleForegroundReturn()

        // Break was silently triggered and auto-completed via Task
        // isOnBreak is true momentarily (triggerBreak sets it) but completeBreak runs async
        XCTAssertEqual(viewModel.currentBreakNumber, 1)
    }

    func testForegroundReturnExpiredBreakSchedulesFromBreakEnd() async {
        MockURLProtocol.requestHandler = { _ in
            (TestHelpers.makeHTTPResponse(statusCode: 200), Data())
        }

        viewModel.startWorkday()
        viewModel.breakIntervalMinutes = 60
        viewModel.breakDurationMinutes = 3
        // Break was due 120s ago — micro-break (30s) expired 90s ago
        let breakDueTime = Date().addingTimeInterval(-120)
        viewModel.nextBreakAt = breakDueTime

        viewModel.handleForegroundReturn()

        // Let the async completeBreak run
        try? await Task.sleep(for: .milliseconds(100))

        // Next break should be from breakEnd (breakDueTime + 30s), NOT from now
        let expectedBreakEnd = breakDueTime.addingTimeInterval(30) // micro-break = 30s
        let expectedNext = expectedBreakEnd.addingTimeInterval(3600) // + 60 min interval
        XCTAssertNotNil(viewModel.nextBreakAt)
        XCTAssertEqual(viewModel.nextBreakAt!.timeIntervalSince1970, expectedNext.timeIntervalSince1970, accuracy: 2.0)
    }

    func testForegroundReturnDuringBreakRecalculatesRemaining() {
        viewModel.startWorkday()
        viewModel.isOnBreak = true
        viewModel.currentBreakNumber = 2
        viewModel.breakDurationMinutes = 3

        // Simulate break started 60s ago
        let defaults = UserDefaults.standard
        defaults.set(Date().addingTimeInterval(-60).timeIntervalSince1970, forKey: "workTimer_breakStartedAt")

        viewModel.handleForegroundReturn()

        XCTAssertTrue(viewModel.isOnBreak)
        XCTAssertEqual(viewModel.breakSecondsRemaining, 120, accuracy: 2)
    }

    // MARK: - Auto Start

    func testCheckAutoStartWhenEnabled() {
        // Create settings to satisfy settings != nil guard
        viewModel.settings = WorkTimerSettings(
            startTime: "00:00", endTime: "23:59",
            breakIntervalMinutes: 60, breakDurationMinutes: 3, isEnabled: true
        )
        viewModel.autoStartEnabled = true

        // Set work hours to include now
        viewModel.startTime = Calendar.current.date(from: DateComponents(hour: 0, minute: 0)) ?? Date()
        viewModel.endTime = Calendar.current.date(from: DateComponents(hour: 23, minute: 59)) ?? Date()

        viewModel.checkAutoStart()

        XCTAssertTrue(viewModel.isRunning)
    }

    func testCheckAutoStartDisabledDoesNotStart() {
        viewModel.settings = WorkTimerSettings(
            startTime: "00:00", endTime: "23:59",
            breakIntervalMinutes: 60, breakDurationMinutes: 3, isEnabled: true
        )
        viewModel.autoStartEnabled = false

        viewModel.checkAutoStart()

        XCTAssertFalse(viewModel.isRunning)
    }

    func testCheckAutoStartWhenAlreadyRunning() {
        viewModel.settings = WorkTimerSettings(
            startTime: "00:00", endTime: "23:59",
            breakIntervalMinutes: 60, breakDurationMinutes: 3, isEnabled: true
        )
        viewModel.autoStartEnabled = true
        viewModel.startWorkday() // Already running

        let breaksBefore = viewModel.breaksTakenToday
        viewModel.checkAutoStart()

        // Should not restart (breaksTaken would reset to 0 if startWorkday ran again)
        XCTAssertEqual(viewModel.breaksTakenToday, breaksBefore)
    }

    func testCheckAutoStartWorksWithDefaultSettings() {
        viewModel.autoStartEnabled = true
        viewModel.settings = nil // Settings not loaded from API

        // Set work hours to include now so auto-start triggers
        viewModel.startTime = Calendar.current.date(from: DateComponents(hour: 0, minute: 0)) ?? Date()
        viewModel.endTime = Calendar.current.date(from: DateComponents(hour: 23, minute: 59)) ?? Date()

        viewModel.checkAutoStart()

        XCTAssertTrue(viewModel.isRunning, "Should auto-start with default settings even if API failed")
    }

    func testAutoStartPreservesPreferenceAfterStop() async {
        MockURLProtocol.requestHandler = { _ in
            (TestHelpers.makeHTTPResponse(statusCode: 200), Data())
        }

        viewModel.autoStartEnabled = true
        viewModel.startWorkday()
        await viewModel.stopWorkday()

        XCTAssertTrue(viewModel.autoStartEnabled, "Auto-start preference should survive workday stop")
    }

    // MARK: - isWithinWorkHours

    func testIsWithinNormalWorkHours() {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)

        // Set work hours to include current hour
        viewModel.startTime = calendar.date(from: DateComponents(hour: (hour - 1 + 24) % 24, minute: 0)) ?? Date()
        viewModel.endTime = calendar.date(from: DateComponents(hour: (hour + 1) % 24, minute: 0)) ?? Date()

        XCTAssertTrue(viewModel.isWithinWorkHours)
    }

    func testIsOutsideWorkHours() {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)

        // Set work hours to exclude current hour (2 hours in the future)
        viewModel.startTime = calendar.date(from: DateComponents(hour: (hour + 2) % 24, minute: 0)) ?? Date()
        viewModel.endTime = calendar.date(from: DateComponents(hour: (hour + 4) % 24, minute: 0)) ?? Date()

        XCTAssertFalse(viewModel.isWithinWorkHours)
    }

    func testIsWithinOvernightWorkHours() {
        let calendar = Calendar.current
        // Set overnight hours: 22:00 - 06:00
        viewModel.startTime = calendar.date(from: DateComponents(hour: 22, minute: 0)) ?? Date()
        viewModel.endTime = calendar.date(from: DateComponents(hour: 6, minute: 0)) ?? Date()

        let hour = calendar.component(.hour, from: Date())
        if hour >= 22 || hour < 6 {
            XCTAssertTrue(viewModel.isWithinWorkHours)
        } else {
            XCTAssertFalse(viewModel.isWithinWorkHours)
        }
    }

    func testIsWithinWorkHoursEqualStartEnd() {
        let calendar = Calendar.current
        viewModel.startTime = calendar.date(from: DateComponents(hour: 12, minute: 0)) ?? Date()
        viewModel.endTime = calendar.date(from: DateComponents(hour: 12, minute: 0)) ?? Date()

        XCTAssertFalse(viewModel.isWithinWorkHours, "Equal start/end should return false")
    }

    // MARK: - Weekly Adherence & Streak

    func testWeeklyAdherenceCalculation() {
        viewModel.weekHistory = [
            WorkTimerDaySummary(date: "2026-03-18", totalWorkMinutes: 480, breaksOffered: 8, breaksCompleted: 6, breaksSkipped: 2, adherencePercent: 75.0),
            WorkTimerDaySummary(date: "2026-03-19", totalWorkMinutes: 480, breaksOffered: 8, breaksCompleted: 8, breaksSkipped: 0, adherencePercent: 100.0),
        ]

        XCTAssertEqual(viewModel.weeklyAdherence, 87.5, accuracy: 0.1)
    }

    func testWeeklyAdherenceEmptyHistory() {
        viewModel.weekHistory = []
        XCTAssertEqual(viewModel.weeklyAdherence, 0.0)
    }

    func testCurrentStreakConsecutiveDays() {
        viewModel.weekHistory = [
            WorkTimerDaySummary(date: "2026-03-18", totalWorkMinutes: 480, breaksOffered: 8, breaksCompleted: 4, breaksSkipped: 4, adherencePercent: 50.0),
            WorkTimerDaySummary(date: "2026-03-19", totalWorkMinutes: 480, breaksOffered: 8, breaksCompleted: 6, breaksSkipped: 2, adherencePercent: 75.0),
            WorkTimerDaySummary(date: "2026-03-20", totalWorkMinutes: 480, breaksOffered: 8, breaksCompleted: 8, breaksSkipped: 0, adherencePercent: 100.0),
        ]

        XCTAssertEqual(viewModel.currentStreak, 3)
    }

    func testCurrentStreakBrokenByZeroBreaks() {
        viewModel.weekHistory = [
            WorkTimerDaySummary(date: "2026-03-17", totalWorkMinutes: 480, breaksOffered: 8, breaksCompleted: 4, breaksSkipped: 4, adherencePercent: 50.0),
            WorkTimerDaySummary(date: "2026-03-18", totalWorkMinutes: 480, breaksOffered: 8, breaksCompleted: 0, breaksSkipped: 8, adherencePercent: 0.0),
            WorkTimerDaySummary(date: "2026-03-19", totalWorkMinutes: 480, breaksOffered: 8, breaksCompleted: 6, breaksSkipped: 2, adherencePercent: 75.0),
            WorkTimerDaySummary(date: "2026-03-20", totalWorkMinutes: 480, breaksOffered: 8, breaksCompleted: 8, breaksSkipped: 0, adherencePercent: 100.0),
        ]

        XCTAssertEqual(viewModel.currentStreak, 2, "Streak should break at day with 0 completed breaks")
    }

    func testCurrentStreakEmptyHistory() {
        viewModel.weekHistory = []
        XCTAssertEqual(viewModel.currentStreak, 0)
    }

    // MARK: - Stop Workday with Snoozed Break

    func testStopWorkdayLogsSnoozedBreakAsSkipped() async {
        var loggedBreak = false
        MockURLProtocol.requestHandler = { request in
            if request.httpMethod == "POST" {
                loggedBreak = true
            }
            return (TestHelpers.makeHTTPResponse(statusCode: 200), Data())
        }

        viewModel.startWorkday()
        viewModel.isOnBreak = true
        viewModel.currentBreakNumber = 1
        viewModel.snoozeBreak() // snoozesUsed = 1, isOnBreak = false, nextBreakAt = 5min from now

        await viewModel.stopWorkday()

        XCTAssertTrue(loggedBreak, "Should log the snoozed break as skipped")
        XCTAssertEqual(viewModel.breaksSkippedToday, 1)
    }

    // MARK: - Stop Workday Summary

    func testStopWorkdayBuildsSummary() async {
        MockURLProtocol.requestHandler = { _ in
            (TestHelpers.makeHTTPResponse(statusCode: 200), Data())
        }

        viewModel.startWorkday()
        viewModel.breaksTakenToday = 3
        viewModel.breaksSkippedToday = 1

        await viewModel.stopWorkday()

        XCTAssertNotNil(viewModel.todaySummary)
        XCTAssertEqual(viewModel.todaySummary?.breaksCompleted, 3)
        XCTAssertEqual(viewModel.todaySummary?.breaksSkipped, 1)
        XCTAssertEqual(viewModel.todaySummary?.breaksOffered, 4)
    }

    // MARK: - Clear Persisted State

    func testClearPersistedStatePreservesAutoStart() {
        UserDefaults.standard.set(true, forKey: "workTimer_autoStart")
        UserDefaults.standard.set(true, forKey: "workTimer_isRunning")

        WorkTimerViewModel.clearPersistedState(includingPreferences: false)

        XCTAssertTrue(UserDefaults.standard.bool(forKey: "workTimer_autoStart"), "Auto-start should be preserved")
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "workTimer_isRunning"), "Running state should be cleared")
    }

    func testClearPersistedStateWithPreferencesClearsAll() {
        UserDefaults.standard.set(true, forKey: "workTimer_autoStart")
        UserDefaults.standard.set(true, forKey: "workTimer_isRunning")

        WorkTimerViewModel.clearPersistedState(includingPreferences: true)

        XCTAssertFalse(UserDefaults.standard.bool(forKey: "workTimer_autoStart"))
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "workTimer_isRunning"))
    }

    // MARK: - Formatted Work Time

    func testFormattedWorkTimeNoStartedAt() {
        viewModel.timerStartedAt = nil
        let result = viewModel.formattedWorkTime
        // Should return "0 Min." or "0 min" depending on language
        XCTAssertTrue(result.contains("0"))
    }

    func testFormattedWorkTimeWithElapsedTime() {
        viewModel.timerStartedAt = Date().addingTimeInterval(-3660) // 1hr 1min ago
        let result = viewModel.formattedWorkTime
        // Should contain "1" for hours
        XCTAssertTrue(result.contains("1"))
    }

    // MARK: - Exercise Selection

    func testSelectBreakExercisesEmptyAllExercises() {
        viewModel.startWorkday()
        viewModel.allExercises = []

        viewModel.triggerBreak()

        XCTAssertTrue(viewModel.breakExercises.isEmpty)
    }

    func testSelectBreakExercisesDeterministic() {
        let exercises = (1...10).map { i in
            WorkTimerBreakExercise(
                id: "ex\(i)", name: "Exercise \(i)", description: "Desc \(i)",
                durationSeconds: 30, targetConditions: nil, minPhase: nil, category: "mobility"
            )
        }
        viewModel.allExercises = exercises
        viewModel.startWorkday()

        viewModel.triggerBreak()
        let firstSelection = viewModel.breakExercises.map(\.id)

        // Reset and trigger again with same state — should get same selection
        viewModel.isOnBreak = false
        viewModel.currentBreakNumber = 0
        viewModel.triggerBreak()
        let secondSelection = viewModel.breakExercises.map(\.id)

        XCTAssertEqual(firstSelection, secondSelection, "Same break number should produce same exercise selection")
    }

    func testMicroBreakSelectsOneExercise() {
        let exercises = (1...5).map { i in
            WorkTimerBreakExercise(
                id: "ex\(i)", name: "Ex \(i)", description: "D",
                durationSeconds: 30, targetConditions: nil, minPhase: nil, category: "mobility"
            )
        }
        viewModel.allExercises = exercises
        viewModel.startWorkday()

        viewModel.triggerBreak() // break #1 = micro
        XCTAssertTrue(viewModel.isMicroBreak)
        XCTAssertEqual(viewModel.breakExercises.count, 1)
    }

    func testFullBreakSelectsThreeExercises() {
        let exercises = (1...10).map { i in
            WorkTimerBreakExercise(
                id: "ex\(i)", name: "Ex \(i)", description: "D",
                durationSeconds: 30, targetConditions: nil, minPhase: nil, category: "mobility"
            )
        }
        viewModel.allExercises = exercises
        viewModel.startWorkday()
        viewModel.currentBreakNumber = 1 // next will be #2 = full

        viewModel.triggerBreak() // break #2 = full
        XCTAssertFalse(viewModel.isMicroBreak)
        XCTAssertEqual(viewModel.breakExercises.count, 3)
    }

    // MARK: - Exercise Filtering by Condition (#12)

    func testExerciseFilteringByCondition() {
        let exercises = [
            WorkTimerBreakExercise(id: "lbp1", name: "LBP Ex", description: "D", durationSeconds: 30,
                                   targetConditions: ["lbpNonspecific"], minPhase: nil, category: "mobility"),
            WorkTimerBreakExercise(id: "neck1", name: "Neck Ex", description: "D", durationSeconds: 30,
                                   targetConditions: ["neckPain"], minPhase: nil, category: "stretch"),
            WorkTimerBreakExercise(id: "gen1", name: "Generic Ex", description: "D", durationSeconds: 30,
                                   targetConditions: nil, minPhase: nil, category: "mobility"),
        ]
        viewModel.allExercises = exercises
        viewModel.patientCondition = "lbpNonspecific"
        viewModel.startWorkday()
        viewModel.currentBreakNumber = 1 // next = #2 full break

        viewModel.triggerBreak()

        // Should only include "lbp1" and "gen1", not "neck1"
        let ids = viewModel.breakExercises.map(\.id)
        XCTAssertFalse(ids.contains("neck1"), "Neck exercise should be filtered out for LBP patient")
    }

    func testExerciseFilteringByMinPhase() {
        let exercises = [
            WorkTimerBreakExercise(id: "p1", name: "Phase 1", description: "D", durationSeconds: 30,
                                   targetConditions: nil, minPhase: 1, category: "mobility"),
            WorkTimerBreakExercise(id: "p3", name: "Phase 3", description: "D", durationSeconds: 30,
                                   targetConditions: nil, minPhase: 3, category: "mobility"),
        ]
        viewModel.allExercises = exercises
        viewModel.patientPhase = 1
        viewModel.startWorkday()

        viewModel.triggerBreak()

        let ids = viewModel.breakExercises.map(\.id)
        XCTAssertTrue(ids.contains("p1"))
        XCTAssertFalse(ids.contains("p3"), "Phase 3 exercise should be filtered for phase 1 patient")
    }

    func testExerciseFilteringFallsBackWhenAllFiltered() {
        let exercises = [
            WorkTimerBreakExercise(id: "neck1", name: "Neck Only", description: "D", durationSeconds: 30,
                                   targetConditions: ["neckPain"], minPhase: nil, category: "mobility"),
        ]
        viewModel.allExercises = exercises
        viewModel.patientCondition = "lbpNonspecific"
        viewModel.startWorkday()

        viewModel.triggerBreak()

        // Should fall back to all exercises when filtering removes everything
        XCTAssertEqual(viewModel.breakExercises.count, 1)
    }

    // MARK: - Snooze Continuation (#9)

    func testSnoozedBreakRetainsSameBreakNumber() {
        viewModel.startWorkday()

        viewModel.triggerBreak() // break #1
        XCTAssertEqual(viewModel.currentBreakNumber, 1)

        viewModel.snoozeBreak()
        XCTAssertEqual(viewModel.currentBreakNumber, 1, "Snooze should not change break number")

        // Simulate snooze timer expiring — triggerBreak re-fires
        viewModel.triggerBreak() // should be break #1 again (snooze continuation)
        XCTAssertEqual(viewModel.currentBreakNumber, 1, "Snooze re-trigger should keep same break number")
        XCTAssertTrue(viewModel.isOnBreak)
    }

    func testSnoozedBreakPreservesSnoozesUsed() {
        viewModel.startWorkday()

        viewModel.triggerBreak()
        viewModel.snoozeBreak() // snoozesUsed = 1
        XCTAssertEqual(viewModel.snoozesUsed, 1)

        viewModel.triggerBreak() // re-trigger from snooze
        XCTAssertEqual(viewModel.snoozesUsed, 1, "Snooze re-trigger should preserve snoozesUsed")
    }

    func testCompleteBreakResetsSnoozesUsed() async {
        MockURLProtocol.requestHandler = { _ in
            (TestHelpers.makeHTTPResponse(statusCode: 200), Data())
        }

        viewModel.startWorkday()
        viewModel.triggerBreak()
        viewModel.snoozeBreak()

        // Re-trigger after snooze, then complete
        viewModel.triggerBreak()
        await viewModel.completeBreak()

        XCTAssertEqual(viewModel.snoozesUsed, 0, "Completing break should reset snoozesUsed")
    }

    func testSkipBreakResetsSnoozesUsed() async {
        MockURLProtocol.requestHandler = { _ in
            (TestHelpers.makeHTTPResponse(statusCode: 200), Data())
        }

        viewModel.startWorkday()
        viewModel.triggerBreak()
        viewModel.snoozeBreak()

        viewModel.triggerBreak()
        await viewModel.skipBreak()

        XCTAssertEqual(viewModel.snoozesUsed, 0, "Skipping break should reset snoozesUsed")
    }

    // MARK: - Stop Workday Snoozed Break Number (#10)

    func testStopWorkdaySnoozedBreakLogsAsSkipped() async {
        var postRequestMade = false
        MockURLProtocol.requestHandler = { request in
            if request.httpMethod == "POST" { postRequestMade = true }
            return (TestHelpers.makeHTTPResponse(statusCode: 200), Data())
        }

        viewModel.startWorkday()
        viewModel.triggerBreak() // break #1
        viewModel.snoozeBreak() // isSnoozePending = true

        await viewModel.stopWorkday()

        XCTAssertTrue(postRequestMade, "Should send POST to log snoozed break")
        XCTAssertEqual(viewModel.breaksSkippedToday, 1, "Snoozed break should count as skipped")
    }

    func testStopWorkdayNoPhantomSkipAfterComplete() async {
        MockURLProtocol.requestHandler = { _ in
            (TestHelpers.makeHTTPResponse(statusCode: 200), Data())
        }

        viewModel.startWorkday()
        viewModel.triggerBreak()
        viewModel.snoozeBreak()
        viewModel.triggerBreak() // re-trigger
        await viewModel.completeBreak() // completes, resets snoozesUsed & isSnoozePending

        await viewModel.stopWorkday()

        // breaksSkippedToday should be 0 — the snoozed break was completed, no phantom skip
        XCTAssertEqual(viewModel.breaksSkippedToday, 0, "No phantom skip after snooze→complete")
    }

    // MARK: - Settings Change While Running (#8)

    func testSaveSettingsRecalculatesBreakWhenRunning() async {
        viewModel.startWorkday()
        viewModel.breakIntervalMinutes = 60

        let originalNextBreak = viewModel.nextBreakAt

        // Simulate settings save with new interval
        MockURLProtocol.requestHandler = { _ in
            let json: [String: Any] = [
                "settings": [
                    "startTime": "08:00", "endTime": "17:00",
                    "breakIntervalMinutes": 30, "breakDurationMinutes": 3, "isEnabled": true
                ]
            ]
            let data = try! JSONSerialization.data(withJSONObject: json)
            return (TestHelpers.makeHTTPResponse(statusCode: 200), data)
        }

        await viewModel.saveSettings()

        XCTAssertEqual(viewModel.breakIntervalMinutes, 30)
        XCTAssertNotEqual(viewModel.nextBreakAt, originalNextBreak, "Next break should be recalculated")
    }

    func testSaveSettingsDoesNotRecalculateWhenNotRunning() async {
        viewModel.breakIntervalMinutes = 60

        MockURLProtocol.requestHandler = { _ in
            let json: [String: Any] = [
                "settings": [
                    "startTime": "08:00", "endTime": "17:00",
                    "breakIntervalMinutes": 30, "breakDurationMinutes": 3, "isEnabled": true
                ]
            ]
            let data = try! JSONSerialization.data(withJSONObject: json)
            return (TestHelpers.makeHTTPResponse(statusCode: 200), data)
        }

        await viewModel.saveSettings()

        XCTAssertEqual(viewModel.breakIntervalMinutes, 30)
        XCTAssertNil(viewModel.nextBreakAt, "Should not set nextBreakAt when not running")
    }

    // MARK: - Missed Break Count Cap (#15)

    func testMissedBreakCountCapped() {
        let defaults = UserDefaults.standard
        let now = Date()

        defaults.set(true, forKey: "workTimer_isRunning")
        defaults.set(now.addingTimeInterval(-86400).timeIntervalSince1970, forKey: "workTimer_startedAt")
        // Break was 24 hours ago — would be 24 missed with 60-min interval
        defaults.set(now.addingTimeInterval(-86400).timeIntervalSince1970, forKey: "workTimer_nextBreakAt")
        defaults.set(0, forKey: "workTimer_breaksTaken")
        defaults.set(0, forKey: "workTimer_breaksSkipped")
        defaults.set(0, forKey: "workTimer_currentBreakNumber")

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        defaults.set(formatter.string(from: now), forKey: "workTimer_date")

        viewModel.breakIntervalMinutes = 60

        viewModel.restoreTimerState()

        // missedBreakCount capped at 10, so skipped = 10-1 = 9, breakNumber = 9+1 = 10
        XCTAssertLessThanOrEqual(viewModel.breaksSkippedToday, 9, "Missed breaks should be capped")
        XCTAssertLessThanOrEqual(viewModel.currentBreakNumber, 10, "Break number should be capped")
    }

    // MARK: - Current Streak Date Continuity (#20)

    func testCurrentStreakRequiresConsecutiveDates() {
        viewModel.weekHistory = [
            WorkTimerDaySummary(date: "2026-03-17", totalWorkMinutes: 480, breaksOffered: 8, breaksCompleted: 4, breaksSkipped: 4, adherencePercent: 50.0),
            // Gap: 2026-03-18 missing
            WorkTimerDaySummary(date: "2026-03-19", totalWorkMinutes: 480, breaksOffered: 8, breaksCompleted: 6, breaksSkipped: 2, adherencePercent: 75.0),
            WorkTimerDaySummary(date: "2026-03-20", totalWorkMinutes: 480, breaksOffered: 8, breaksCompleted: 8, breaksSkipped: 0, adherencePercent: 100.0),
        ]

        XCTAssertEqual(viewModel.currentStreak, 2, "Streak should break at date gap")
    }

    func testCurrentStreakSingleDay() {
        viewModel.weekHistory = [
            WorkTimerDaySummary(date: "2026-03-20", totalWorkMinutes: 480, breaksOffered: 4, breaksCompleted: 4, breaksSkipped: 0, adherencePercent: 100.0),
        ]

        XCTAssertEqual(viewModel.currentStreak, 1)
    }
}
