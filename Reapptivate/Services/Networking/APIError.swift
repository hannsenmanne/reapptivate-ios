import Foundation

private var isEnglishLocale: Bool {
    UserDefaults.standard.string(forKey: "appLanguage") == "en"
}

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

    var errorDescription: String? {
        let isEn = isEnglishLocale
        switch self {
        case .unauthorized:
            return isEn ? "Unauthorized. Please sign in again."
                        : "Nicht autorisiert. Bitte melden Sie sich erneut an."
        case .forbidden:
            return isEn ? "Access denied."
                        : "Zugriff verweigert."
        case .notFound:
            return isEn ? "The requested resource was not found."
                        : "Die angeforderte Ressource wurde nicht gefunden."
        case .badRequest(let message):
            return message
        case .conflict(let message):
            return message
        case .rateLimited(let retryAfter):
            if let seconds = retryAfter {
                return isEn ? "Too many requests. Please wait \(seconds) seconds."
                            : "Zu viele Anfragen. Bitte warten Sie \(seconds) Sekunden."
            } else {
                return isEn ? "Too many requests. Please wait a moment."
                            : "Zu viele Anfragen. Bitte warten Sie einen Moment."
            }
        case .serverError(let code):
            return isEn ? "Server error (\(code)). Please try again later."
                        : "Serverfehler (\(code)). Bitte versuchen Sie es später erneut."
        case .networkError:
            return isEn ? "Network error. Please check your connection."
                        : "Netzwerkfehler. Bitte überprüfen Sie Ihre Verbindung."
        case .decodingError:
            return isEn ? "Data could not be processed."
                        : "Daten konnten nicht verarbeitet werden."
        }
    }
}

// MARK: - API Error Response (from server)

struct APIErrorResponse: Codable {
    let error: String?
    let message: String?

    var displayMessage: String {
        message ?? error ?? (isEnglishLocale ? "Unknown error" : "Unbekannter Fehler")
    }
}
