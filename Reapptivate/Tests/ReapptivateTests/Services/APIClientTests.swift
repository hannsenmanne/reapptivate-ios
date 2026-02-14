import XCTest
@testable import Reapptivate

@MainActor
final class APIClientTests: XCTestCase {

    private var apiClient: APIClient!

    override func setUp() async throws {
        let session = TestHelpers.makeTestSession()
        apiClient = APIClient(session: session)
    }

    override func tearDown() async throws {
        MockURLProtocol.requestHandler = nil
        apiClient = nil
    }

    // MARK: - request<T> Success

    func testRequestDecodesSuccessResponse() async throws {
        MockURLProtocol.requestHandler = { _ in
            let response = TestHelpers.makeHTTPResponse(statusCode: 200)
            let data = TestFixtures.userResponseJSON()
            return (response, data)
        }

        let result: UserResponse = try await apiClient.request(APIEndpoints.me())
        XCTAssertEqual(result.user.id, "user-1")
        XCTAssertEqual(result.user.email, "test@test.com")
    }

    // MARK: - requestVoid Success

    func testRequestVoidSucceeds() async throws {
        MockURLProtocol.requestHandler = { _ in
            let response = TestHelpers.makeHTTPResponse(statusCode: 200)
            return (response, Data())
        }

        do {
            try await apiClient.requestVoid(APIEndpoints.me())
        } catch {
            XCTFail("requestVoid should not throw on 200: \(error)")
        }
    }

    // MARK: - requestData Success

    func testRequestDataReturnsRawBytes() async throws {
        let expected = "raw-data".data(using: .utf8)!
        MockURLProtocol.requestHandler = { _ in
            let response = TestHelpers.makeHTTPResponse(statusCode: 200)
            return (response, expected)
        }

        let data = try await apiClient.requestData(APIEndpoints.me())
        XCTAssertEqual(data, expected)
    }

    // MARK: - 401 Unauthorized

    func testUnauthorizedTriggersTokenExpiredCallback() async {
        var callbackFired = false
        apiClient.onTokenExpired = {
            callbackFired = true
        }

        MockURLProtocol.requestHandler = { _ in
            let response = TestHelpers.makeHTTPResponse(statusCode: 401)
            return (response, Data())
        }

        do {
            let _: UserResponse = try await apiClient.request(APIEndpoints.me())
            XCTFail("Should have thrown")
        } catch let error as APIError {
            switch error {
            case .unauthorized:
                break
            default:
                XCTFail("Expected .unauthorized, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertTrue(callbackFired)
    }

    func testUnauthorizedCallbackFiresOnlyOnce() async {
        var callbackCount = 0
        apiClient.onTokenExpired = {
            callbackCount += 1
        }

        MockURLProtocol.requestHandler = { _ in
            let response = TestHelpers.makeHTTPResponse(statusCode: 401)
            return (response, Data())
        }

        // First call
        _ = try? await apiClient.request(APIEndpoints.me()) as UserResponse

        // Second call
        _ = try? await apiClient.request(APIEndpoints.me()) as UserResponse

        XCTAssertEqual(callbackCount, 1, "Callback should fire only once due to hasTriggeredLogout guard")
    }

    // MARK: - resetLogoutGuard

    func testResetLogoutGuardReenablesCallback() async {
        var callbackCount = 0
        apiClient.onTokenExpired = {
            callbackCount += 1
        }

        MockURLProtocol.requestHandler = { _ in
            let response = TestHelpers.makeHTTPResponse(statusCode: 401)
            return (response, Data())
        }

        // First 401
        _ = try? await apiClient.request(APIEndpoints.me()) as UserResponse
        XCTAssertEqual(callbackCount, 1)

        // Reset guard
        apiClient.resetLogoutGuard()

        // Second 401 should fire again
        _ = try? await apiClient.request(APIEndpoints.me()) as UserResponse
        XCTAssertEqual(callbackCount, 2)
    }

    // MARK: - Error Status Codes

    func testNotFoundThrowsNotFound() async {
        MockURLProtocol.requestHandler = { _ in
            let response = TestHelpers.makeHTTPResponse(statusCode: 404)
            return (response, Data())
        }

        do {
            let _: UserResponse = try await apiClient.request(APIEndpoints.me())
            XCTFail("Should throw")
        } catch let error as APIError {
            switch error {
            case .notFound: break
            default: XCTFail("Expected .notFound, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testRateLimitedThrowsRateLimited() async {
        MockURLProtocol.requestHandler = { _ in
            let response = TestHelpers.makeHTTPResponse(statusCode: 429)
            return (response, Data())
        }

        do {
            let _: UserResponse = try await apiClient.request(APIEndpoints.me())
            XCTFail("Should throw")
        } catch let error as APIError {
            switch error {
            case .rateLimited: break
            default: XCTFail("Expected .rateLimited, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testServerErrorThrowsServerError() async {
        MockURLProtocol.requestHandler = { _ in
            let response = TestHelpers.makeHTTPResponse(statusCode: 500)
            return (response, Data())
        }

        do {
            let _: UserResponse = try await apiClient.request(APIEndpoints.me())
            XCTFail("Should throw")
        } catch let error as APIError {
            switch error {
            case .serverError(let code):
                XCTAssertEqual(code, 500)
            default:
                XCTFail("Expected .serverError, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testBadRequestIncludesServerMessage() async {
        MockURLProtocol.requestHandler = { _ in
            let response = TestHelpers.makeHTTPResponse(statusCode: 400)
            let data = TestFixtures.errorResponseJSON(message: "Invalid input")
            return (response, data)
        }

        do {
            let _: UserResponse = try await apiClient.request(APIEndpoints.me())
            XCTFail("Should throw")
        } catch let error as APIError {
            switch error {
            case .badRequest(let message):
                XCTAssertEqual(message, "Invalid input")
            default:
                XCTFail("Expected .badRequest, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Decoding Error

    func testMalformedJSONThrowsDecodingError() async {
        MockURLProtocol.requestHandler = { _ in
            let response = TestHelpers.makeHTTPResponse(statusCode: 200)
            let data = "not json".data(using: .utf8)!
            return (response, data)
        }

        do {
            let _: UserResponse = try await apiClient.request(APIEndpoints.me())
            XCTFail("Should throw")
        } catch let error as APIError {
            switch error {
            case .decodingError: break
            default: XCTFail("Expected .decodingError, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Auth Token Injection

    func testAuthTokenInjectedInHeader() async throws {
        TokenManager.shared.saveToken("test-bearer-token")

        var capturedRequest: URLRequest?
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            let response = TestHelpers.makeHTTPResponse(statusCode: 200)
            let data = TestFixtures.userResponseJSON()
            return (response, data)
        }

        let _: UserResponse = try await apiClient.request(APIEndpoints.me())

        let authHeader = capturedRequest?.value(forHTTPHeaderField: "Authorization")
        XCTAssertEqual(authHeader, "Bearer test-bearer-token")

        TokenManager.shared.clearAll()
    }
}
