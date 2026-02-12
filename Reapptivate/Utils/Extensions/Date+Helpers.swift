import Foundation

extension Date {
    var daysSinceNow: Int {
        Calendar.current.dateComponents([.day], from: self, to: .now).day ?? 0
    }

    func daysSince(_ other: Date) -> Int {
        Calendar.current.dateComponents([.day], from: other, to: self).day ?? 0
    }

    var formattedGerman: String {
        self.formatted(.dateTime.day().month(.wide).year().locale(Locale(identifier: "de_DE")))
    }

    var formattedShortGerman: String {
        self.formatted(.dateTime.day().month(.abbreviated).locale(Locale(identifier: "de_DE")))
    }

    var iso8601String: String {
        ISO8601DateFormatter().string(from: self)
    }

    static func fromISO8601(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: string) {
            return date
        }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: string)
    }
}
