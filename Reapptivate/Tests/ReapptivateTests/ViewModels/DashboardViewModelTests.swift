import XCTest
@testable import Reapptivate

@MainActor
final class DashboardViewModelTests: XCTestCase {

    private var apiClient: APIClient!
    private var appState: AppState!
    private var viewModel: DashboardViewModel!

    override func setUp() async throws {
        let session = TestHelpers.makeTestSession()
        apiClient = APIClient(session: session)
        appState = AppState()
        appState.handleLogin(user: TestFixtures.userProfile())
        viewModel = DashboardViewModel(apiClient: apiClient, appState: appState)
    }

    override func tearDown() async throws {
        MockURLProtocol.requestHandler = nil
        viewModel = nil
        appState = nil
        apiClient = nil
    }

    // MARK: - loadDashboard

    func testLoadDashboardPopulatesData() async {
        MockURLProtocol.requestHandler = { request in
            let url = request.url?.absoluteString ?? ""
            let response = TestHelpers.makeHTTPResponse(statusCode: 200)

            if url.contains("phase-status") {
                return (response, TestFixtures.phaseStatusResponseJSON())
            } else if url.contains("progress/stats") {
                return (response, TestFixtures.statsResponseJSON())
            } else if url.contains("progress/today") {
                return (response, TestFixtures.todayProgressResponseJSON())
            }
            return (response, Data())
        }

        await viewModel.loadDashboard()

        XCTAssertNotNil(viewModel.phaseStatus)
        XCTAssertEqual(viewModel.phaseStatus?.currentPhase, 1)
        XCTAssertNotNil(viewModel.progressStats)
        XCTAssertEqual(viewModel.progressStats?.totalSessions, 25)
        XCTAssertFalse(viewModel.completedToday.isEmpty)
    }

    // MARK: - Partial Failure

    func testLoadDashboardHandlesPartialFailure() async {
        MockURLProtocol.requestHandler = { request in
            let url = request.url?.absoluteString ?? ""

            if url.contains("phase-status") {
                return (TestHelpers.makeHTTPResponse(statusCode: 500), Data())
            } else if url.contains("progress/stats") {
                return (TestHelpers.makeHTTPResponse(statusCode: 200), TestFixtures.statsResponseJSON())
            } else if url.contains("progress/today") {
                return (TestHelpers.makeHTTPResponse(statusCode: 200), TestFixtures.todayProgressResponseJSON())
            }
            return (TestHelpers.makeHTTPResponse(statusCode: 200), Data())
        }

        await viewModel.loadDashboard()

        // Phase status failed but stats and today should still work
        XCTAssertNil(viewModel.phaseStatus)
        XCTAssertNotNil(viewModel.progressStats)
    }

    // MARK: - isExerciseCompletedToday

    func testIsExerciseCompletedToday() async {
        MockURLProtocol.requestHandler = { request in
            let url = request.url?.absoluteString ?? ""
            let response = TestHelpers.makeHTTPResponse(statusCode: 200)

            if url.contains("progress/today") {
                return (response, TestFixtures.todayProgressResponseJSON())
            }
            return (response, Data("{}".utf8))
        }

        await viewModel.loadDashboard()

        XCTAssertTrue(viewModel.isExerciseCompletedToday("ex-1"))
        XCTAssertFalse(viewModel.isExerciseCompletedToday("nonexistent"))
    }

    // MARK: - Refresh

    func testRefreshReloadsData() async {
        var callCount = 0
        MockURLProtocol.requestHandler = { request in
            let url = request.url?.absoluteString ?? ""
            let response = TestHelpers.makeHTTPResponse(statusCode: 200)

            if url.contains("phase-status") {
                callCount += 1
                return (response, TestFixtures.phaseStatusResponseJSON())
            } else if url.contains("progress/stats") {
                return (response, TestFixtures.statsResponseJSON())
            } else if url.contains("progress/today") {
                return (response, TestFixtures.todayProgressResponseJSON())
            }
            return (response, Data())
        }

        await viewModel.loadDashboard()
        await viewModel.refresh()

        XCTAssertGreaterThanOrEqual(callCount, 2, "Phase status should be fetched on each load")
    }
}
