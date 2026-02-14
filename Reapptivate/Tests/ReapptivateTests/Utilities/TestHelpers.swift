import Foundation

enum TestHelpers {
    static func makeTestSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }

    static func makeHTTPResponse(
        url: URL? = nil,
        statusCode: Int = 200
    ) -> HTTPURLResponse {
        HTTPURLResponse(
            url: url ?? URL(string: "http://localhost:3000/api/test")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
    }

    static func jsonData<T: Encodable>(_ value: T) -> Data {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return (try? encoder.encode(value)) ?? Data()
    }

    /// Create a minimal valid JWT with the given expiration timestamp.
    static func makeJWT(exp: TimeInterval) -> String {
        let header = #"{"alg":"HS256","typ":"JWT"}"#
        let payload = #"{"sub":"test-user","exp":\#(Int(exp))}"#
        let headerB64 = Data(header.utf8).base64EncodedString()
            .replacingOccurrences(of: "=", with: "")
        let payloadB64 = Data(payload.utf8).base64EncodedString()
            .replacingOccurrences(of: "=", with: "")
        return "\(headerB64).\(payloadB64).fake-signature"
    }
}
