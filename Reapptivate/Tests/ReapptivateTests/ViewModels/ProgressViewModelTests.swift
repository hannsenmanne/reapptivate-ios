import XCTest
@testable import Reapptivate

@MainActor
final class ProgressViewModelTests: XCTestCase {

    private var apiClient: APIClient!
    private var viewModel: ProgressViewModel!

    override func setUp() async throws {
        let session = TestHelpers.makeTestSession()
        apiClient = APIClient(session: session)
        viewModel = ProgressViewModel(apiClient: apiClient)
    }

    override func tearDown() async throws {
        MockURLProtocol.requestHandler = nil
        viewModel = nil
        apiClient = nil
    }

    // MARK: - Configure

    func testConfigureSetsInitialState() {
        let exercise = TestFixtures.exercise(sets: 4, reps: 12)
        viewModel.configure(for: exercise)

        XCTAssertEqual(viewModel.setsCompleted, 4)
        XCTAssertEqual(viewModel.repsCompleted, 12)
        XCTAssertEqual(viewModel.painLevel, 0)
        XCTAssertTrue(viewModel.notes.isEmpty)
        XCTAssertNil(viewModel.symptomResponse)
        XCTAssertNil(viewModel.errorMessage)
    }

    // MARK: - Log Progress Success

    func testLogProgressSuccessReturnsTrue() async {
        MockURLProtocol.requestHandler = { _ in
            let response = TestHelpers.makeHTTPResponse(statusCode: 200)
            let data = TestFixtures.progressLogResponseJSON()
            return (response, data)
        }

        let success = await viewModel.logProgress(exerciseId: "ex-1")
        XCTAssertTrue(success)
        XCTAssertNil(viewModel.errorMessage)
    }

    // MARK: - Log Progress with Phase Change

    func testLogProgressWithPhaseChangeSetsShowPhaseChange() async {
        let adaptation = TestFixtures.adaptationResult(decision: .progress, currentPhase: 2, previousPhase: 1)
        MockURLProtocol.requestHandler = { _ in
            let response = TestHelpers.makeHTTPResponse(statusCode: 200)
            let data = TestFixtures.progressLogResponseJSON(adaptation: adaptation)
            return (response, data)
        }

        let success = await viewModel.logProgress(exerciseId: "ex-1")
        XCTAssertTrue(success)
        XCTAssertTrue(viewModel.showPhaseChange)
        XCTAssertNotNil(viewModel.adaptationResult)
        XCTAssertEqual(viewModel.adaptationResult?.decision, .progress)
    }

    // MARK: - Log Progress Failure

    func testLogProgressFailureSetsErrorMessage() async {
        MockURLProtocol.requestHandler = { _ in
            let response = TestHelpers.makeHTTPResponse(statusCode: 500)
            return (response, Data())
        }

        let success = await viewModel.logProgress(exerciseId: "ex-1")
        XCTAssertFalse(success)
        XCTAssertNotNil(viewModel.errorMessage)
    }
}
