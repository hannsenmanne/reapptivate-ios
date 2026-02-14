import SwiftUI

@Observable
@MainActor
final class MilestoneService {
    @ObservationIgnored
    @AppStorage("milestones_shown") private var shownRaw: String = ""

    private var shownSet: Set<String> {
        Set(shownRaw.split(separator: ",").map(String.init))
    }

    /// Returns the first unshown milestone that qualifies, or nil.
    func check(totalSessions: Int, currentStreak: Int, currentPhase: Int) -> Milestone? {
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
            }

            if qualifies { return milestone }
        }

        return nil
    }

    func markShown(_ milestone: Milestone) {
        var set = shownSet
        set.insert(milestone.rawValue)
        shownRaw = set.sorted().joined(separator: ",")
    }
}
