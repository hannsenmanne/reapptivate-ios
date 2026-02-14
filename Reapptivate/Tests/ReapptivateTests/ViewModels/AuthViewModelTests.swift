import XCTest
@testable import Reapptivate

@MainActor
final class AuthViewModelTests: XCTestCase {

    private var apiClient: APIClient!
    private var appState: AppState!
    private var viewModel: AuthViewModel!

    override func setUp() async throws {
        let session = TestHelpers.makeTestSession()
        apiClient = APIClient(session: session)
        appState = AppState()
        viewModel = AuthViewModel(apiClient: apiClient)
        TokenManager.shared.clearAll()
    }

    override func tearDown() async throws {
        MockURLProtocol.requestHandler = nil
        TokenManager.shared.clearAll()
        viewModel = nil
        appState = nil
        apiClient = nil
    }

    // MARK: - Login Success

    func testLoginSuccessSetsAuthenticated() async {
        var requestCount = 0
        MockURLProtocol.requestHandler = { request in
            requestCount += 1
            let response = TestHelpers.makeHTTPResponse(statusCode: 200)
            if requestCount == 1 {
                // Login response
                return (response, TestFixtures.loginResponseJSON())
            } else {
                // /me response
                return (response, TestFixtures.userResponseJSON())
            }
        }

        viewModel.email = "test@test.com"
        viewModel.password = "Test1234!"
        await viewModel.login(appState: appState)

        XCTAssertTrue(appState.isAuthenticated)
        XCTAssertNotNil(appState.currentUser)
        XCTAssertNil(viewModel.errorMessage)
    }

    // MARK: - Login 401

    func testLogin401SetsErrorMessage() async {
        MockURLProtocol.requestHandler = { _ in
            let response = TestHelpers.makeHTTPResponse(statusCode: 401)
            return (response, Data())
        }

        viewModel.email = "wrong@test.com"
        viewModel.password = "wrong"
        await viewModel.login(appState: appState)

        XCTAssertFalse(appState.isAuthenticated)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage?.contains("falsch") == true)
    }

    // MARK: - Empty Credentials

    func testLoginEmptyCredentialsSetsError() async {
        viewModel.email = ""
        viewModel.password = ""
        await viewModel.login(appState: appState)

        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(appState.isAuthenticated)
    }

    // MARK: - Logout

    func testLogoutClearsState() {
        appState.handleLogin(user: TestFixtures.userProfile())
        XCTAssertTrue(appState.isAuthenticated)

        viewModel.logout(appState: appState)

        XCTAssertFalse(appState.isAuthenticated)
        XCTAssertNil(appState.currentUser)
    }

    // MARK: - Onboarding Validation

    func testOnboardingPasswordValidFalseForShort() {
        viewModel.onboardingPassword = "abc"
        XCTAssertFalse(viewModel.onboardingPasswordValid)
    }

    func testOnboardingPasswordValidTrueForLongEnough() {
        viewModel.onboardingPassword = "12345678"
        XCTAssertTrue(viewModel.onboardingPasswordValid)
    }

    func testOnboardingPasswordsMatchFalseWhenDifferent() {
        viewModel.onboardingPassword = "password1"
        viewModel.onboardingPasswordConfirm = "password2"
        XCTAssertFalse(viewModel.onboardingPasswordsMatch)
    }

    func testOnboardingPasswordsMatchTrueWhenSame() {
        viewModel.onboardingPassword = "password1"
        viewModel.onboardingPasswordConfirm = "password1"
        XCTAssertTrue(viewModel.onboardingPasswordsMatch)
    }
}
