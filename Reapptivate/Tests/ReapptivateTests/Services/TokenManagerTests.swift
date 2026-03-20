import XCTest
@testable import Reapptivate

@MainActor
final class TokenManagerTests: XCTestCase {
    private let tokenManager = TokenManager.shared

    override func setUp() async throws {
        tokenManager.clearAll()
    }

    override func tearDown() async throws {
        tokenManager.clearAll()
    }

    // MARK: - Token CRUD

    func testSaveAndGetToken() {
        tokenManager.saveToken("abc123")
        XCTAssertEqual(tokenManager.getToken(), "abc123")
    }

    func testDeleteToken() {
        tokenManager.saveToken("abc123")
        tokenManager.deleteToken()
        XCTAssertNil(tokenManager.getToken())
    }

    func testHasTokenTrueWhenSaved() {
        tokenManager.saveToken("abc123")
        XCTAssertTrue(tokenManager.hasToken)
    }

    func testHasTokenFalseWhenEmpty() {
        XCTAssertFalse(tokenManager.hasToken)
    }

    func testClearAllRemovesEverything() {
        tokenManager.saveToken("token")
        tokenManager.saveUserId("user-1")
        tokenManager.clearAll()
        XCTAssertNil(tokenManager.getToken())
        XCTAssertNil(tokenManager.getUserId())
    }

    // MARK: - Token Expiry

    func testIsTokenExpiredReturnsTrueWhenNoToken() {
        XCTAssertTrue(tokenManager.isTokenExpired())
    }

    func testIsTokenExpiredReturnsTrueForExpiredJWT() {
        // Expired 1 hour ago
        let exp = Date().timeIntervalSince1970 - 3600
        let jwt = TestHelpers.makeJWT(exp: exp)
        tokenManager.saveToken(jwt)
        XCTAssertTrue(tokenManager.isTokenExpired())
    }

    func testIsTokenExpiredReturnsFalseForValidJWT() {
        // Expires 1 hour from now
        let exp = Date().timeIntervalSince1970 + 3600
        let jwt = TestHelpers.makeJWT(exp: exp)
        tokenManager.saveToken(jwt)
        XCTAssertFalse(tokenManager.isTokenExpired())
    }

    // MARK: - User ID

    func testSaveAndGetUserId() {
        tokenManager.saveUserId("user-42")
        XCTAssertEqual(tokenManager.getUserId(), "user-42")
    }
}
