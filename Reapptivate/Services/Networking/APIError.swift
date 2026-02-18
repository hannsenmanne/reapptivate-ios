import Foundation

enum APIError: LocalizedError {
    case unauthorized
    case forbidden
    case notFound
    case badRequest(String)
    case conflict(String)
    case rateLimited(retryAfter: Int?)
    case serverError(Int)
    case networkError(Error)
    case decodingError(Error)
    case tokenExpired
    case noData
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            "Nicht autorisiert. Bitte melden Sie sich erneut an."
        case .forbidden:
            "Zugriff verweigert."
        case .notFound:
            "Die angeforderte Ressource wurde nicht gefunden."
        case .badRequest(let message):
            message
        case .conflict(let message):
            message
        case .rateLimited(let retryAfter):
            if let seconds = retryAfter {
                "Zu viele Anfragen. Bitte warten Sie \(seconds) Sekunden."
            } else {
                "Zu viele Anfragen. Bitte warten Sie einen Moment."
            }
        case .serverError(let code):
            "Serverfehler (\(code)). Bitte versuchen Sie es später erneut."
        case .networkError:
            "Netzwerkfehler. Bitte überprüfen Sie Ihre Verbindung."
        case .decodingError:
            "Daten konnten nicht verarbeitet werden."
        case .tokenExpired:
            "Ihre Sitzung ist abgelaufen. Bitte melden Sie sich erneut an."
        case .noData:
            "Keine Daten empfangen."
        case .invalidURL:
            "Ungultige URL."
        }
    }
}

// MARK: - API Error Response (from server)

struct APIErrorResponse: Codable {
    let error: String?
    let message: String?

    var displayMessage: String {
        message ?? error ?? "Unbekannter Fehler"
    }
}
