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
        DateFormatters.iso8601.string(from: self)
    }

    static func fromISO8601(_ string: String) -> Date? {
        if let date = DateFormatters.iso8601.date(from: string) {
            return date
        }
        return DateFormatters.iso8601NoFractional.date(from: string)
    }
}
