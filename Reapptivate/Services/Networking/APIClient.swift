import Foundation

@Observable
@MainActor
final class APIClient {
    private let session: URLSession
    private let tokenManager: TokenManager
    private let decoder: JSONDecoder

    var onTokenExpired: (@MainActor () -> Void)?
    private var hasTriggeredLogout = false

    init(
        session: URLSession = .shared,
        tokenManager: TokenManager = .shared
    ) {
        self.session = session
        self.tokenManager = tokenManager

        self.decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            if let date = DateFormatters.iso8601.date(from: dateString) {
                return date
            }
            if let date = DateFormatters.iso8601NoFractional.date(from: dateString) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date: \(dateString)"
            )
        }
    }

    // MARK: - Generic Request

    func request<T: Decodable>(_ urlRequest: URLRequest) async throws -> T {
        var request = urlRequest
        injectAuth(&request)

        do {
            let (data, response) = try await session.data(for: request)
            try validateResponse(response, data: data)
            return try decoder.decode(T.self, from: data)
        } catch let error as APIError {
            throw error
        } catch let error as DecodingError {
            Log.api.error("Decoding error for \(request.url?.path ?? "?"): \(error)")
            throw APIError.decodingError(error)
        } catch {
            // Retry once on network failure
            Log.api.warning("Network error, retrying: \(error.localizedDescription)")
            try await Task.sleep(for: .seconds(2))

            var retryRequest = urlRequest
            injectAuth(&retryRequest)

            do {
                let (data, response) = try await session.data(for: retryRequest)
                try validateResponse(response, data: data)
                return try decoder.decode(T.self, from: data)
            } catch let retryError as APIError {
                throw retryError
            } catch let retryError as DecodingError {
                throw APIError.decodingError(retryError)
            } catch {
                throw APIError.networkError(error)
            }
        }
    }

    // MARK: - Request without response body

    func requestVoid(_ urlRequest: URLRequest) async throws {
        var request = urlRequest
        injectAuth(&request)

        do {
            let (data, response) = try await session.data(for: request)
            try validateResponse(response, data: data)
        } catch let error as APIError {
            throw error
        } catch {
            // Retry once on network failure
            Log.api.warning("Network error (void), retrying: \(error.localizedDescription)")
            try await Task.sleep(for: .seconds(2))

            var retryRequest = urlRequest
            injectAuth(&retryRequest)

            do {
                let (data, response) = try await session.data(for: retryRequest)
                try validateResponse(response, data: data)
            } catch let retryError as APIError {
                throw retryError
            } catch {
                throw APIError.networkError(error)
            }
        }
    }

    // MARK: - Request returning raw Data

    func requestData(_ urlRequest: URLRequest) async throws -> Data {
        var request = urlRequest
        injectAuth(&request)

        do {
            let (data, response) = try await session.data(for: request)
            try validateResponse(response, data: data)
            return data
        } catch let error as APIError {
            throw error
        } catch {
            // Retry once on network failure
            Log.api.warning("Network error (data), retrying: \(error.localizedDescription)")
            try await Task.sleep(for: .seconds(2))

            var retryRequest = urlRequest
            injectAuth(&retryRequest)

            do {
                let (data, response) = try await session.data(for: retryRequest)
                try validateResponse(response, data: data)
                return data
            } catch let retryError as APIError {
                throw retryError
            } catch {
                throw APIError.networkError(error)
            }
        }
    }

    // MARK: - Private

    /// Reset the logout guard when a new token is available (after fresh login)
    func resetLogoutGuard() {
        hasTriggeredLogout = false
    }

    private func injectAuth(_ request: inout URLRequest) {
        if let token = tokenManager.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }

    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(
                NSError(domain: "APIClient", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
            )
        }

        let statusCode = httpResponse.statusCode

        switch statusCode {
        case 200...299:
            return // Success

        case 401:
            Log.api.warning("401 Unauthorized - token may be expired")
            if !hasTriggeredLogout {
                hasTriggeredLogout = true
                onTokenExpired?()
            }
            throw APIError.unauthorized

        case 403:
            throw APIError.forbidden

        case 404:
            throw APIError.notFound

        case 400:
            let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data)
            throw APIError.badRequest(errorResponse?.displayMessage ?? "Ungultige Anfrage")

        case 409:
            let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data)
            throw APIError.conflict(errorResponse?.displayMessage ?? "Konflikt")

        case 429:
            let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After").flatMap(Int.init)
            throw APIError.rateLimited(retryAfter: retryAfter)

        default:
            throw APIError.serverError(statusCode)
        }
    }
}
