import SwiftUI

@Observable
@MainActor
final class MilestoneService {
    @ObservationIgnored
    @AppStorage("milestones_shown") private var shownRaw: String = ""

    @ObservationIgnored
    @AppStorage("milestones_dates") private var datesRaw: String = ""

    // Cached parsed values — invalidated when the underlying raw strings change
    @ObservationIgnored private var cachedShownRaw: String?
    @ObservationIgnored private var cachedShownSet: Set<String> = []
    @ObservationIgnored private var cachedDatesRaw: String?
    @ObservationIgnored private var cachedDatesDict: [String: String] = [:]

    private var shownSet: Set<String> {
        if cachedShownRaw != shownRaw {
            cachedShownRaw = shownRaw
            cachedShownSet = Set(shownRaw.split(separator: ",").map(String.init))
        }
        return cachedShownSet
    }

    private var datesDict: [String: String] {
        if cachedDatesRaw != datesRaw {
            cachedDatesRaw = datesRaw
            if let data = datesRaw.data(using: .utf8),
               let dict = try? JSONDecoder().decode([String: String].self, from: data) {
                cachedDatesDict = dict
            } else {
                cachedDatesDict = [:]
            }
        }
        return cachedDatesDict
    }

    private func saveDatesDict(_ dict: [String: String]) {
        if let data = try? JSONEncoder().encode(dict),
           let string = String(data: data, encoding: .utf8) {
            datesRaw = string
        }
    }

    /// Returns the first unshown milestone that qualifies, or nil.
    func check(totalSessions: Int, currentStreak: Int, currentPhase: Int, maxPhase: Int = 3) -> Milestone? {
        let shown = shownSet

        for milestone in Milestone.allCases {
            guard !shown.contains(milestone.rawValue) else { continue }

            let qualifies: Bool
            switch milestone {
            case .firstTraining:
                qualifies = totalSessions >= 1
            case .threeDayStreak:
                qualifies = currentStreak >= 3
            case .sevenDayStreak:
                qualifies = currentStreak >= 7
            case .tenSessions:
                qualifies = totalSessions >= 10
            case .phaseUp:
                qualifies = currentPhase >= 2
            case .fourteenDayStreak:
                qualifies = currentStreak >= 14
            case .thirtyDayStreak:
                qualifies = currentStreak >= 30
            case .twentyFiveSessions:
                qualifies = totalSessions >= 25
            case .fiftySessions:
                qualifies = totalSessions >= 50
            case .hundredSessions:
                qualifies = totalSessions >= 100
            case .allPhasesComplete:
                qualifies = currentPhase >= maxPhase
            }

            if qualifies { return milestone }
        }

        return nil
    }

    func markShown(_ milestone: Milestone) {
        var set = shownSet
        set.insert(milestone.rawValue)
        shownRaw = set.sorted().joined(separator: ",")

        // Store earned date
        var dates = datesDict
        if dates[milestone.rawValue] == nil {
            dates[milestone.rawValue] = ISO8601DateFormatter().string(from: Date())
            saveDatesDict(dates)
        }
    }

    func isEarned(_ milestone: Milestone) -> Bool {
        shownSet.contains(milestone.rawValue)
    }

    func earnedDate(for milestone: Milestone) -> Date? {
        guard let dateString = datesDict[milestone.rawValue] else { return nil }
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: dateString)
    }
}
