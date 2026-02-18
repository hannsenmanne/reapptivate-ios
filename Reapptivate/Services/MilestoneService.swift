import SwiftUI

@Observable
@MainActor
final class MilestoneService {
    private var userId: String?

    private var shownKey: String { "milestones_shown_\(userId ?? "unknown")" }
    private var datesKey: String { "milestones_dates_\(userId ?? "unknown")" }

    private var shownRaw: String {
        get { UserDefaults.standard.string(forKey: shownKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: shownKey) }
    }

    private var datesRaw: String {
        get { UserDefaults.standard.string(forKey: datesKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: datesKey) }
    }

    private var shownSet: Set<String> {
        Set(shownRaw.split(separator: ",").map(String.init))
    }

    private var datesDict: [String: String] {
        guard let data = datesRaw.data(using: .utf8),
              let dict = try? JSONDecoder().decode([String: String].self, from: data) else {
            return [:]
        }
        return dict
    }

    private func saveDatesDict(_ dict: [String: String]) {
        if let data = try? JSONEncoder().encode(dict),
           let string = String(data: data, encoding: .utf8) {
            datesRaw = string
        }
    }

    private var initializedKey: String { "milestones_initialized_\(userId ?? "unknown")" }

    /// Set the current user ID so milestones are stored per-user.
    func configure(userId: String) {
        self.userId = userId
        migrateFromGlobalKeyIfNeeded()
    }

    /// Seed all currently qualifying milestones as already shown.
    /// Call once after stats are available to prevent stale popups for existing users.
    func seedExistingIfNeeded(totalSessions: Int, currentPhase: Int, maxPhase: Int = 3) {
        guard userId != nil else { return }
        // Only seed once per user
        guard !UserDefaults.standard.bool(forKey: initializedKey) else { return }
        UserDefaults.standard.set(true, forKey: initializedKey)

        // Mark all currently qualifying milestones as shown
        for milestone in Milestone.allCases {
            let qualifies: Bool
            switch milestone {
            case .firstTraining:    qualifies = totalSessions >= 1
            case .tenSessions:      qualifies = totalSessions >= 10
            case .phaseUp:          qualifies = currentPhase >= 2
            case .twentyFiveSessions: qualifies = totalSessions >= 25
            case .fiftySessions:    qualifies = totalSessions >= 50
            case .hundredSessions:  qualifies = totalSessions >= 100
            case .allPhasesComplete: qualifies = currentPhase >= maxPhase
            }
            if qualifies {
                markShown(milestone)
            }
        }
    }

    /// Migrate data from the old global @AppStorage keys to per-user keys.
    private func migrateFromGlobalKeyIfNeeded() {
        // If per-user key already has data, no migration needed
        guard UserDefaults.standard.string(forKey: shownKey) == nil else { return }

        if let globalShown = UserDefaults.standard.string(forKey: "milestones_shown"),
           !globalShown.isEmpty {
            UserDefaults.standard.set(globalShown, forKey: shownKey)
        }
        if let globalDates = UserDefaults.standard.string(forKey: "milestones_dates"),
           !globalDates.isEmpty {
            UserDefaults.standard.set(globalDates, forKey: datesKey)
        }
    }

    /// Returns the first unshown milestone that qualifies, or nil.
    func check(totalSessions: Int, currentPhase: Int, maxPhase: Int = 3) -> Milestone? {
        guard userId != nil else { return nil }
        let shown = shownSet

        for milestone in Milestone.allCases {
            guard !shown.contains(milestone.rawValue) else { continue }

            let qualifies: Bool
            switch milestone {
            case .firstTraining:
                qualifies = totalSessions >= 1
            case .tenSessions:
                qualifies = totalSessions >= 10
            case .phaseUp:
                qualifies = currentPhase >= 2
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
            dates[milestone.rawValue] = Date().iso8601String
            saveDatesDict(dates)
        }
    }

    func isEarned(_ milestone: Milestone) -> Bool {
        shownSet.contains(milestone.rawValue)
    }

    func earnedDate(for milestone: Milestone) -> Date? {
        guard let dateString = datesDict[milestone.rawValue] else { return nil }
        return Date.fromISO8601(dateString)
    }
}
