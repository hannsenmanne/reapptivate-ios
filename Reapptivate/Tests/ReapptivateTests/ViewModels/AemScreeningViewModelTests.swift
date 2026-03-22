import XCTest
@testable import Reapptivate

@MainActor
final class AemScreeningViewModelTests: XCTestCase {

    private var apiClient: APIClient!
    private var viewModel: AemScreeningViewModel!

    override func setUp() async throws {
        let session = TestHelpers.makeTestSession()
        apiClient = APIClient(session: session)
        viewModel = AemScreeningViewModel(apiClient: apiClient)
    }

    override func tearDown() async throws {
        MockURLProtocol.requestHandler = nil
        viewModel = nil
        apiClient = nil
    }

    // MARK: - loadConfig

    func testLoadConfigSuccess() async {
        MockURLProtocol.requestHandler = { _ in
            let response = TestHelpers.makeHTTPResponse(statusCode: 200)
            return (response, TestFixtures.aemScreeningConfigResponseData())
        }

        await viewModel.loadConfig()

        XCTAssertNotNil(viewModel.config)
        XCTAssertEqual(viewModel.items.count, 3)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testLoadConfigError() async {
        MockURLProtocol.requestHandler = { _ in
            let response = TestHelpers.makeHTTPResponse(statusCode: 500)
            return (response, Data())
        }

        await viewModel.loadConfig()

        XCTAssertNil(viewModel.config)
        XCTAssertTrue(viewModel.items.isEmpty)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - selectResponse

    func testSelectResponseSetsValue() async {
        await loadConfig()

        viewModel.selectResponse(itemId: "aem-1", value: 4)

        XCTAssertEqual(viewModel.responses["aem-1"], 4)
    }

    func testSelectResponseAutoAdvances() async {
        await loadConfig()
        XCTAssertEqual(viewModel.currentItemIndex, 0)

        viewModel.selectResponse(itemId: "aem-1", value: 3)

        try? await Task.sleep(for: .milliseconds(700))
        XCTAssertEqual(viewModel.currentItemIndex, 1)
    }

    func testSelectResponseDoesNotAdvancePastLastItem() async {
        await loadConfig()
        viewModel.currentItemIndex = viewModel.items.count - 1

        viewModel.selectResponse(itemId: "aem-3", value: 2)

        try? await Task.sleep(for: .milliseconds(700))
        XCTAssertEqual(viewModel.currentItemIndex, viewModel.items.count - 1)
    }

    // MARK: - goBack

    func testGoBackDecrementsIndex() async {
        await loadConfig()
        viewModel.currentItemIndex = 2

        viewModel.goBack()

        XCTAssertEqual(viewModel.currentItemIndex, 1)
    }

    func testGoBackDoesNotGoBelowZero() async {
        await loadConfig()
        viewModel.currentItemIndex = 0

        viewModel.goBack()

        XCTAssertEqual(viewModel.currentItemIndex, 0)
    }

    // MARK: - Computed properties

    func testProgressCalculation() async {
        await loadConfig()
        XCTAssertEqual(viewModel.progress, 0)

        viewModel.responses["aem-1"] = 3
        XCTAssertEqual(viewModel.progress, 1.0 / 3.0, accuracy: 0.01)

        viewModel.responses["aem-2"] = 2
        viewModel.responses["aem-3"] = 1
        XCTAssertEqual(viewModel.progress, 1.0, accuracy: 0.01)
    }

    func testCanSubmitRequiresAllResponses() async {
        await loadConfig()
        XCTAssertFalse(viewModel.canSubmit)

        viewModel.responses["aem-1"] = 3
        viewModel.responses["aem-2"] = 2
        XCTAssertFalse(viewModel.canSubmit)

        viewModel.responses["aem-3"] = 1
        XCTAssertTrue(viewModel.canSubmit)
    }

    func testIsOnLastItem() async {
        await loadConfig()
        XCTAssertFalse(viewModel.isOnLastItem)

        viewModel.currentItemIndex = viewModel.items.count - 1
        XCTAssertTrue(viewModel.isOnLastItem)
    }

    // MARK: - submit

    func testSubmitSuccess() async {
        await loadConfig()
        viewModel.responses = ["aem-1": 4, "aem-2": 3, "aem-3": 2]

        MockURLProtocol.requestHandler = { _ in
            let response = TestHelpers.makeHTTPResponse(statusCode: 200)
            return (response, TestFixtures.aemScreeningResultResponseData())
        }

        let success = await viewModel.submit()

        XCTAssertTrue(success)
        XCTAssertNotNil(viewModel.result)
        XCTAssertEqual(viewModel.result?.subtype, .FAR)
        XCTAssertFalse(viewModel.isSubmitting)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testSubmitFailure() async {
        await loadConfig()
        viewModel.responses = ["aem-1": 4, "aem-2": 3, "aem-3": 2]

        MockURLProtocol.requestHandler = { _ in
            let response = TestHelpers.makeHTTPResponse(statusCode: 500)
            return (response, Data())
        }

        let success = await viewModel.submit()

        XCTAssertFalse(success)
        XCTAssertNil(viewModel.result)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isSubmitting)
    }

    func testSubmitReturnsFalseWhenNotReady() async {
        await loadConfig()
        // Only 1 of 3 responses provided
        viewModel.responses = ["aem-1": 4]

        let success = await viewModel.submit()

        XCTAssertFalse(success)
    }

    // MARK: - Helpers

    private func loadConfig() async {
        MockURLProtocol.requestHandler = { _ in
            let response = TestHelpers.makeHTTPResponse(statusCode: 200)
            return (response, TestFixtures.aemScreeningConfigResponseData())
        }
        await viewModel.loadConfig()
    }
}
