import XCTest
@testable import Reapptivate

final class APIEndpointsTests: XCTestCase {

    // MARK: - Login

    func testLoginRequestIsPost() {
        let request = APIEndpoints.login(email: "a@b.com", password: "pass")
        XCTAssertEqual(request.httpMethod, "POST")
    }

    func testLoginRequestURLContainsPath() {
        let request = APIEndpoints.login(email: "a@b.com", password: "pass")
        XCTAssertTrue(request.url?.absoluteString.contains("onboarding/login") == true)
    }

    func testLoginRequestHasBody() throws {
        let request = APIEndpoints.login(email: "test@test.com", password: "secret")
        let body = try XCTUnwrap(request.httpBody)
        let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
        XCTAssertEqual(json?["email"] as? String, "test@test.com")
        XCTAssertEqual(json?["password"] as? String, "secret")
    }

    // MARK: - Me

    func testMeRequestIsGet() {
        let request = APIEndpoints.me()
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertTrue(request.url?.absoluteString.contains("patient/me") == true)
    }

    // MARK: - Progress

    func testGetProgressHasQueryParams() {
        let request = APIEndpoints.getProgress(limit: 10, offset: 5)
        let url = request.url?.absoluteString ?? ""
        XCTAssertTrue(url.contains("limit=10"))
        XCTAssertTrue(url.contains("offset=5"))
    }

    // MARK: - Phase Status

    func testPhaseStatusPath() {
        let request = APIEndpoints.phaseStatus()
        XCTAssertTrue(request.url?.absoluteString.contains("patient/phase-status") == true)
    }

    // MARK: - Exposure Logging

    func testLogExposureContainsItemIdInPath() {
        let body = ExposureLogRequest(
            predictedHarm: 5,
            predictedFear: 4,
            preFear: 7,
            prePain: 3,
            performedDose: nil,
            postFear: 4,
            postPain: 2,
            didAvoid: false,
            outcomeNotes: nil
        )
        let request = APIEndpoints.logExposure(itemId: "item-42", body: body)
        XCTAssertTrue(request.url?.absoluteString.contains("items/item-42/exposure") == true)
        XCTAssertEqual(request.httpMethod, "POST")
    }

    // MARK: - Neck Micro Modules

    func testNeckMicroModulesWithSeverity() {
        let request = APIEndpoints.neckMicroModules(severity: "MITTEL")
        let url = request.url?.absoluteString ?? ""
        XCTAssertTrue(url.contains("severity=MITTEL"))
    }

    func testNeckMicroModulesWithoutSeverity() {
        let request = APIEndpoints.neckMicroModules()
        let url = request.url?.absoluteString ?? ""
        XCTAssertFalse(url.contains("severity"))
    }

    // MARK: - Common Request Properties

    func testGetRequestsHaveAcceptHeader() {
        let request = APIEndpoints.me()
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json")
    }

    func testPostRequestsHaveContentType() {
        let request = APIEndpoints.login(email: "a@b.com", password: "p")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
    }

    func testRequestsHave30SecondTimeout() {
        XCTAssertEqual(APIEndpoints.me().timeoutInterval, 30)
        XCTAssertEqual(APIEndpoints.login(email: "", password: "").timeoutInterval, 30)
        XCTAssertEqual(APIEndpoints.phaseStatus().timeoutInterval, 30)
    }
}
