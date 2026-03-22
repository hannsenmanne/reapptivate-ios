import XCTest
@testable import Reapptivate

@MainActor
final class NeckScreeningViewModelTests: XCTestCase {

    private var apiClient: APIClient!
    private var viewModel: NeckScreeningViewModel!

    override func setUp() async throws {
        let session = TestHelpers.makeTestSession()
        apiClient = APIClient(session: session)
        viewModel = NeckScreeningViewModel(apiClient: apiClient)
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
            return (response, TestFixtures.neckScreeningConfigResponseData())
        }

        await viewModel.loadConfig()

        XCTAssertNotNil(viewModel.config)
        XCTAssertFalse(viewModel.allItems.isEmpty)
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
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - Part Navigation

    func testInitialPartIsA() {
        XCTAssertEqual(viewModel.currentPart, "A")
        XCTAssertEqual(viewModel.currentItemIndex, 0)
    }

    func testRescreeningStartsAtPartB() {
        let rescreeningVM = NeckScreeningViewModel(apiClient: apiClient, isRescreening: true)
        XCTAssertEqual(rescreeningVM.currentPart, "B")
    }

    func testContinueToPartBResetsIndex() async {
        await loadConfig()
        viewModel.currentItemIndex = 2

        viewModel.continueToPartB()

        XCTAssertEqual(viewModel.currentPart, "B")
        XCTAssertEqual(viewModel.currentItemIndex, 0)
        XCTAssertFalse(viewModel.showPartTransition)
    }

    func testGoBackFromPartBToPartA() async {
        await loadConfig()
        viewModel.continueToPartB()
        XCTAssertEqual(viewModel.currentPart, "B")
        viewModel.currentItemIndex = 0

        viewModel.goBack()

        XCTAssertEqual(viewModel.currentPart, "A")
    }

    func testGoBackInRescreeningDoesNotGoToPartA() async {
        let rescreeningVM = NeckScreeningViewModel(apiClient: apiClient, isRescreening: true)
        MockURLProtocol.requestHandler = { _ in
            let response = TestHelpers.makeHTTPResponse(statusCode: 200)
            return (response, TestFixtures.neckScreeningConfigResponseData())
        }
        await rescreeningVM.loadConfig()
        rescreeningVM.currentItemIndex = 0

        rescreeningVM.goBack()

        XCTAssertEqual(rescreeningVM.currentPart, "B")
        XCTAssertEqual(rescreeningVM.currentItemIndex, 0)
    }

    // MARK: - Progress

    func testProgressForFullScreening() async {
        await loadConfig()
        XCTAssertEqual(viewModel.progress, 0)

        // Fill all items
        for item in viewModel.allItems {
            viewModel.responses[item.id] = 1
        }
        XCTAssertEqual(viewModel.progress, 1.0, accuracy: 0.01)
    }

    func testProgressForRescreening() async {
        let rescreeningVM = NeckScreeningViewModel(apiClient: apiClient, isRescreening: true)
        MockURLProtocol.requestHandler = { _ in
            let response = TestHelpers.makeHTTPResponse(statusCode: 200)
            return (response, TestFixtures.neckScreeningConfigResponseData())
        }
        await rescreeningVM.loadConfig()

        // Rescreening only counts Part B items
        let partBItems = rescreeningVM.allItems.filter { $0.part == "B" }
        XCTAssertFalse(partBItems.isEmpty)

        for item in partBItems {
            rescreeningVM.responses[item.id] = 1
        }
        XCTAssertEqual(rescreeningVM.progress, 1.0, accuracy: 0.01)
    }

    // MARK: - canSubmit

    func testCanSubmitRequiresAllItems() async {
        await loadConfig()
        XCTAssertFalse(viewModel.canSubmit)

        for item in viewModel.allItems {
            viewModel.responses[item.id] = 1
        }
        XCTAssertTrue(viewModel.canSubmit)
    }

    func testCanSubmitRescreeningRequiresOnlyPartB() async {
        let rescreeningVM = NeckScreeningViewModel(apiClient: apiClient, isRescreening: true)
        MockURLProtocol.requestHandler = { _ in
            let response = TestHelpers.makeHTTPResponse(statusCode: 200)
            return (response, TestFixtures.neckScreeningConfigResponseData())
        }
        await rescreeningVM.loadConfig()

        let partBItems = rescreeningVM.allItems.filter { $0.part == "B" }
        for item in partBItems {
            rescreeningVM.responses[item.id] = 1
        }
        XCTAssertTrue(rescreeningVM.canSubmit)
    }

    // MARK: - submit

    func testSubmitSuccess() async {
        await loadConfig()
        for item in viewModel.allItems {
            viewModel.responses[item.id] = 1
        }

        MockURLProtocol.requestHandler = { _ in
            let response = TestHelpers.makeHTTPResponse(statusCode: 200)
            return (response, TestFixtures.neckScreeningResultResponseData())
        }

        let success = await viewModel.submit()

        XCTAssertTrue(success)
        XCTAssertNotNil(viewModel.result)
        XCTAssertFalse(viewModel.isSubmitting)
    }

    func testSubmitFailure() async {
        await loadConfig()
        for item in viewModel.allItems {
            viewModel.responses[item.id] = 1
        }

        MockURLProtocol.requestHandler = { _ in
            let response = TestHelpers.makeHTTPResponse(statusCode: 500)
            return (response, Data())
        }

        let success = await viewModel.submit()

        XCTAssertFalse(success)
        XCTAssertNil(viewModel.result)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    // MARK: - Helpers

    private func loadConfig() async {
        MockURLProtocol.requestHandler = { _ in
            let response = TestHelpers.makeHTTPResponse(statusCode: 200)
            return (response, TestFixtures.neckScreeningConfigResponseData())
        }
        await viewModel.loadConfig()
    }
}
