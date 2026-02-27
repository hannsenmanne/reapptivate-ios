import Foundation

enum DateFormatters: Sendable {
    /// ISO8601 formatter with fractional seconds (UTC timezone)
    /// Use for parsing/formatting full ISO8601 timestamps from API
    nonisolated(unsafe) static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(secondsFromGMT: 0) // Explicit UTC
        return formatter
    }()

    /// ISO8601 formatter without fractional seconds (UTC timezone)
    /// Use for parsing timestamps without milliseconds
    nonisolated(unsafe) static let iso8601NoFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = TimeZone(secondsFromGMT: 0) // Explicit UTC
        return formatter
    }()

    /// Date-only formatter for "yyyy-MM-dd" strings (UTC timezone)
    /// Use for parsing/formatting date strings without time component
    /// IMPORTANT: Uses UTC to prevent date shifts across timezones
    nonisolated(unsafe) static let dateOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0) // Explicit UTC
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    /// German date formatter (user's current timezone)
    /// Use for displaying dates to users
    nonisolated(unsafe) static let germanDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.timeZone = .current // Explicit current timezone
        return formatter
    }()

    /// Time-only formatter (user's current timezone)
    /// Use for displaying time in messaging threads (e.g., "14:30")
    nonisolated(unsafe) static let timeOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.timeZone = .current
        return formatter
    }()

    /// German date+time formatter (user's current timezone)
    /// Use for displaying date and time to users
    nonisolated(unsafe) static let germanDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.timeZone = .current // Explicit current timezone
        return formatter
    }()

    static let apiDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            if let date = iso8601.date(from: dateString) {
                return date
            }
            if let date = iso8601NoFractional.date(from: dateString) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date: \(dateString)"
            )
        }
        return decoder
    }()
}
