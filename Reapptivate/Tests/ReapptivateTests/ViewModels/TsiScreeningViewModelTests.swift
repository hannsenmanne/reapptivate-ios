import XCTest
@testable import Reapptivate

@MainActor
final class TsiScreeningViewModelTests: XCTestCase {

    private var apiClient: APIClient!
    private var viewModel: TsiScreeningViewModel!

    override func setUp() async throws {
        let session = TestHelpers.makeTestSession()
        apiClient = APIClient(session: session)
        viewModel = TsiScreeningViewModel(apiClient: apiClient)
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
            return (response, TestFixtures.tsiScreeningConfigResponseData())
        }

        await viewModel.loadConfig()

        XCTAssertNotNil(viewModel.config)
        XCTAssertEqual(viewModel.items.count, 10)
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
        MockURLProtocol.requestHandler = { _ in
            let response = TestHelpers.makeHTTPResponse(statusCode: 200)
            return (response, TestFixtures.tsiScreeningConfigResponseData())
        }
        await viewModel.loadConfig()

        viewModel.selectResponse(itemId: "tsi-1", value: 3)

        XCTAssertEqual(viewModel.responses["tsi-1"], 3)
    }

    func testSelectResponseAdvancesIndex() async {
        MockURLProtocol.requestHandler = { _ in
            let response = TestHelpers.makeHTTPResponse(statusCode: 200)
            return (response, TestFixtures.tsiScreeningConfigResponseData())
        }
        await viewModel.loadConfig()
        XCTAssertEqual(viewModel.currentItemIndex, 0)

        viewModel.selectResponse(itemId: "tsi-1", value: 2)

        // Wait for the 500ms delay + animation to complete
        try? await Task.sleep(for: .milliseconds(700))
        XCTAssertEqual(viewModel.currentItemIndex, 1)
    }

    // MARK: - goBack

    func testGoBackDecreasesIndex() async {
        MockURLProtocol.requestHandler = { _ in
            let response = TestHelpers.makeHTTPResponse(statusCode: 200)
            return (response, TestFixtures.tsiScreeningConfigResponseData())
        }
        await viewModel.loadConfig()

        // Manually set index to simulate being on question 2
        viewModel.currentItemIndex = 2

        viewModel.goBack()
        XCTAssertEqual(viewModel.currentItemIndex, 1)
    }

    func testGoBackAtStartDoesNothing() async {
        MockURLProtocol.requestHandler = { _ in
            let response = TestHelpers.makeHTTPResponse(statusCode: 200)
            return (response, TestFixtures.tsiScreeningConfigResponseData())
        }
        await viewModel.loadConfig()
        XCTAssertEqual(viewModel.currentItemIndex, 0)

        viewModel.goBack()
        XCTAssertEqual(viewModel.currentItemIndex, 0)
    }

    // MARK: - progress

    func testProgressCalculation() async {
        MockURLProtocol.requestHandler = { _ in
            let response = TestHelpers.makeHTTPResponse(statusCode: 200)
            return (response, TestFixtures.tsiScreeningConfigResponseData())
        }
        await viewModel.loadConfig()

        // No responses => 0 progress
        XCTAssertEqual(viewModel.progress, 0.0, accuracy: 0.01)

        // Answer 5 of 10 => 0.5
        for i in 1...5 {
            viewModel.responses["tsi-\(i)"] = 2
        }
        XCTAssertEqual(viewModel.progress, 0.5, accuracy: 0.01)

        // Answer all 10 => 1.0
        for i in 6...10 {
            viewModel.responses["tsi-\(i)"] = 1
        }
        XCTAssertEqual(viewModel.progress, 1.0, accuracy: 0.01)
    }

    func testProgressZeroWhenNoConfig() {
        XCTAssertEqual(viewModel.progress, 0.0)
    }

    // MARK: - canSubmit

    func testCanSubmitFalseWhenIncomplete() async {
        MockURLProtocol.requestHandler = { _ in
            let response = TestHelpers.makeHTTPResponse(statusCode: 200)
            return (response, TestFixtures.tsiScreeningConfigResponseData())
        }
        await viewModel.loadConfig()

        // Answer only 9 of 10
        for i in 1...9 {
            viewModel.responses["tsi-\(i)"] = 2
        }
        XCTAssertFalse(viewModel.canSubmit)
    }

    func testCanSubmitTrueWhenAllAnswered() async {
        MockURLProtocol.requestHandler = { _ in
            let response = TestHelpers.makeHTTPResponse(statusCode: 200)
            return (response, TestFixtures.tsiScreeningConfigResponseData())
        }
        await viewModel.loadConfig()

        for i in 1...10 {
            viewModel.responses["tsi-\(i)"] = 3
        }
        XCTAssertTrue(viewModel.canSubmit)
    }

    // MARK: - submit

    func testSubmitCallsCorrectEndpoint() async {
        // Load config first
        var configLoaded = false
        MockURLProtocol.requestHandler = { request in
            let url = request.url?.absoluteString ?? ""
            let response = TestHelpers.makeHTTPResponse(statusCode: 200)

            if !configLoaded {
                configLoaded = true
                return (response, TestFixtures.tsiScreeningConfigResponseData())
            }

            // Verify the endpoint path
            XCTAssertTrue(url.contains("tension/screening"), "Expected tension/screening endpoint, got \(url)")
            XCTAssertFalse(url.contains("rescreening"))
            XCTAssertEqual(request.httpMethod, "POST")

            return (response, TestFixtures.tsiScreeningResultResponseData())
        }

        await viewModel.loadConfig()

        // Answer all questions
        for i in 1...10 {
            viewModel.responses["tsi-\(i)"] = 2
        }

        let success = await viewModel.submit()
        XCTAssertTrue(success)
    }

    func testSubmitRescreeningCallsRescreeningEndpoint() async {
        viewModel = TsiScreeningViewModel(apiClient: apiClient, isRescreening: true)

        var configLoaded = false
        MockURLProtocol.requestHandler = { request in
            let url = request.url?.absoluteString ?? ""
            let response = TestHelpers.makeHTTPResponse(statusCode: 200)

            if !configLoaded {
                configLoaded = true
                return (response, TestFixtures.tsiScreeningConfigResponseData())
            }

            XCTAssertTrue(url.contains("tension/rescreening"), "Expected rescreening endpoint, got \(url)")
            return (response, TestFixtures.tsiScreeningResultResponseData())
        }

        await viewModel.loadConfig()

        for i in 1...10 {
            viewModel.responses["tsi-\(i)"] = 1
        }

        let success = await viewModel.submit()
        XCTAssertTrue(success)
    }

    func testSubmitSetsResult() async {
        var configLoaded = false
        MockURLProtocol.requestHandler = { _ in
            let response = TestHelpers.makeHTTPResponse(statusCode: 200)
            if !configLoaded {
                configLoaded = true
                return (response, TestFixtures.tsiScreeningConfigResponseData())
            }
            return (response, TestFixtures.tsiScreeningResultResponseData(score: 22))
        }

        await viewModel.loadConfig()

        for i in 1...10 {
            viewModel.responses["tsi-\(i)"] = 2
        }

        let success = await viewModel.submit()

        XCTAssertTrue(success)
        XCTAssertNotNil(viewModel.result)
        XCTAssertEqual(viewModel.result?.tsiScore, 22)
        XCTAssertEqual(viewModel.result?.tsiCategory, "MITTEL")
        XCTAssertFalse(viewModel.isSubmitting)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testSubmitErrorSetsErrorMessage() async {
        var configLoaded = false
        MockURLProtocol.requestHandler = { _ in
            if !configLoaded {
                configLoaded = true
                return (TestHelpers.makeHTTPResponse(statusCode: 200), TestFixtures.tsiScreeningConfigResponseData())
            }
            return (TestHelpers.makeHTTPResponse(statusCode: 500), Data())
        }

        await viewModel.loadConfig()

        for i in 1...10 {
            viewModel.responses["tsi-\(i)"] = 2
        }

        let success = await viewModel.submit()

        XCTAssertFalse(success)
        XCTAssertNil(viewModel.result)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isSubmitting)
    }

    func testSubmitReturnsFalseWhenIncomplete() async {
        MockURLProtocol.requestHandler = { _ in
            let response = TestHelpers.makeHTTPResponse(statusCode: 200)
            return (response, TestFixtures.tsiScreeningConfigResponseData())
        }
        await viewModel.loadConfig()

        // Don't answer all questions
        viewModel.responses["tsi-1"] = 3

        let success = await viewModel.submit()
        XCTAssertFalse(success)
    }

    // MARK: - currentItem

    func testCurrentItemReturnsCorrectItem() async {
        MockURLProtocol.requestHandler = { _ in
            let response = TestHelpers.makeHTTPResponse(statusCode: 200)
            return (response, TestFixtures.tsiScreeningConfigResponseData())
        }
        await viewModel.loadConfig()

        XCTAssertEqual(viewModel.currentItem?.id, "tsi-1")

        viewModel.currentItemIndex = 4
        XCTAssertEqual(viewModel.currentItem?.id, "tsi-5")
    }

    func testCurrentItemNilWhenIndexOutOfBounds() async {
        MockURLProtocol.requestHandler = { _ in
            let response = TestHelpers.makeHTTPResponse(statusCode: 200)
            return (response, TestFixtures.tsiScreeningConfigResponseData())
        }
        await viewModel.loadConfig()

        viewModel.currentItemIndex = 100
        XCTAssertNil(viewModel.currentItem)
    }

    func testCurrentItemNilWhenNoConfig() {
        XCTAssertNil(viewModel.currentItem)
    }
}
