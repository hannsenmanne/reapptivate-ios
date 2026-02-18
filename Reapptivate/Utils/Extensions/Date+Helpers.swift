import Foundation

extension Date {
    var daysSinceNow: Int {
        Calendar.current.dateComponents([.day], from: self, to: .now).day ?? 0
    }

    func daysSince(_ other: Date) -> Int {
        Calendar.current.dateComponents([.day], from: other, to: self).day ?? 0
    }

    /// Formats date in German locale with user's current timezone
    /// Example: "15. Januar 2024"
    var formattedGerman: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.timeZone = .current
        return formatter.string(from: self)
    }

    /// Formats date in German locale with abbreviated month, user's current timezone
    /// Example: "15. Jan"
    var formattedShortGerman: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "d. MMM"
        formatter.timeZone = .current
        return formatter.string(from: self)
    }

    /// Converts date to ISO8601 string in UTC timezone
    /// Used for API requests
    var iso8601String: String {
        DateFormatters.iso8601.string(from: self)
    }

    /// Converts date to "yyyy-MM-dd" string in UTC timezone
    /// Used for date-only comparisons and grouping
    var dateOnlyString: String {
        DateFormatters.dateOnly.string(from: self)
    }

    /// Parses ISO8601 string (with or without fractional seconds) to Date
    /// Expects UTC timezone in input string
    static func fromISO8601(_ string: String) -> Date? {
        if let date = DateFormatters.iso8601.date(from: string) {
            return date
        }
        return DateFormatters.iso8601NoFractional.date(from: string)
    }

    /// Parses "yyyy-MM-dd" date string in UTC timezone
    /// Used for backend date-only fields
    static func fromDateOnly(_ string: String) -> Date? {
        DateFormatters.dateOnly.date(from: string)
    }
}
