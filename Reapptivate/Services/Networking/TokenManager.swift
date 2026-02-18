import Foundation

@MainActor
final class TokenManager: Sendable {
    static let shared = TokenManager()

    private let service = "com.reapptivate.ios"
    private let tokenAccount = "jwt_token"
    private let userIdAccount = "user_id"

    private init() {}

    // MARK: - Token

    func saveToken(_ token: String) {
        _ = KeychainHelper.saveString(token, service: service, account: tokenAccount)
        Log.auth.info("Token saved to Keychain")
    }

    func getToken() -> String? {
        KeychainHelper.readString(service: service, account: tokenAccount)
    }

    func deleteToken() {
        _ = KeychainHelper.delete(service: service, account: tokenAccount)
        Log.auth.info("Token deleted from Keychain")
    }

    var hasToken: Bool {
        getToken() != nil
    }

    // MARK: - User ID

    func saveUserId(_ id: String) {
        _ = KeychainHelper.saveString(id, service: service, account: userIdAccount)
    }

    func getUserId() -> String? {
        KeychainHelper.readString(service: service, account: userIdAccount)
    }

    func deleteUserId() {
        _ = KeychainHelper.delete(service: service, account: userIdAccount)
    }

    // MARK: - Token Expiry Check

    func isTokenExpired() -> Bool {
        guard let token = getToken() else { return true }
        guard let payload = decodeJWTPayload(token) else { return true }
        guard let exp = payload["exp"] as? TimeInterval else { return true }

        let expirationDate = Date(timeIntervalSince1970: exp)
        // Consider expired if less than 5 minutes remaining
        return expirationDate.timeIntervalSinceNow < 300
    }

    // MARK: - Logout

    func clearAll() {
        deleteToken()
        deleteUserId()
        Log.auth.info("All credentials cleared from Keychain")
    }

    // MARK: - JWT Decoding

    private func decodeJWTPayload(_ jwt: String) -> [String: Any]? {
        let parts = jwt.split(separator: ".")
        guard parts.count == 3 else { return nil }

        var base64 = String(parts[1])
        // Pad to multiple of 4
        while base64.count % 4 != 0 {
            base64.append("=")
        }

        guard let data = Data(base64Encoded: base64) else { return nil }
        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }
}
