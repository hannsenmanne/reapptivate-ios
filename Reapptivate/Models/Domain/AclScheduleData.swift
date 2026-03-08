import Foundation

/// Client-side prescribed weekly schedule for ACL rehabilitation.
/// Mirrors SCHEDULE_BLOCKS from the web companion (AclWeeklySchedule.tsx).
enum AclScheduleData {

    struct ScheduleDay {
        let label: String
        let streamIds: [String]
        let type: DayType

        enum DayType {
            case training
            case activeRecovery
            case rest
        }

        var isTraining: Bool { type == .training }
        var isRest: Bool { type == .rest }
        var hasExercises: Bool { !streamIds.isEmpty }
    }

    struct ScheduleBlock {
        let weekRange: ClosedRange<Int>
        let title: String
        let days: [ScheduleDay] // Always 7 entries (Mon-Sun)
    }

    /// Returns the schedule block for a given week post-surgery.
    static func block(forWeek week: Int) -> ScheduleBlock? {
        blocks.first { $0.weekRange.contains(week) }
    }

    /// Returns today's schedule day within the current block.
    static func today(forWeek week: Int) -> (day: ScheduleDay, dayIndex: Int)? {
        guard let block = block(forWeek: week) else { return nil }
        let dayIndex = todayIndex()
        guard dayIndex < block.days.count else { return nil }
        return (block.days[dayIndex], dayIndex)
    }

    /// 0 = Monday ... 6 = Sunday (ISO convention)
    static func todayIndex() -> Int {
        let weekday = Calendar.current.component(.weekday, from: Date())
        // Calendar: 1=Sun, 2=Mon, ... 7=Sat -> 0=Mon, ... 6=Sun
        return (weekday + 5) % 7
    }

    // MARK: - All schedule blocks

    static let blocks: [ScheduleBlock] = [
        ScheduleBlock(
            weekRange: 0...2,
            title: "Wundheilung + ROM-Wiederherstellung",
            days: [
                .init(label: "Kraft + ROM", streamIds: ["STRENGTH", "CLINICAL_ROM"], type: .training),
                .init(label: "ROM + Aktivierung", streamIds: ["CLINICAL_ROM", "MOTOR_CONTROL"], type: .training),
                .init(label: "Kraft + ROM", streamIds: ["STRENGTH", "CLINICAL_ROM"], type: .training),
                .init(label: "ROM + Aktivierung", streamIds: ["CLINICAL_ROM", "MOTOR_CONTROL"], type: .training),
                .init(label: "Kraft + ROM", streamIds: ["STRENGTH", "CLINICAL_ROM"], type: .training),
                .init(label: "ROM + leichte Aktivierung", streamIds: ["CLINICAL_ROM"], type: .activeRecovery),
                .init(label: "Ruhetag", streamIds: [], type: .rest),
            ]
        ),
        ScheduleBlock(
            weekRange: 3...4,
            title: "Belastbarkeit + Einbein-Kontrolle",
            days: [
                .init(label: "Kraft + ROM", streamIds: ["STRENGTH", "CLINICAL_ROM"], type: .training),
                .init(label: "Balance + Propriozeption + ROM", streamIds: ["MOTOR_CONTROL", "CLINICAL_ROM"], type: .training),
                .init(label: "Kraft + ROM", streamIds: ["STRENGTH", "CLINICAL_ROM"], type: .training),
                .init(label: "Balance + Radfahren", streamIds: ["MOTOR_CONTROL", "CONDITIONING"], type: .training),
                .init(label: "ROM + Spaziergang", streamIds: ["CLINICAL_ROM"], type: .activeRecovery),
                .init(label: "Kraft + ROM", streamIds: ["STRENGTH", "CLINICAL_ROM"], type: .training),
                .init(label: "Ruhetag / ROM + Eis", streamIds: [], type: .rest),
            ]
        ),
        ScheduleBlock(
            weekRange: 5...6,
            title: "Reaktive Stabilität + Kraftaufbau",
            days: [
                .init(label: "Kraft + Motor Control", streamIds: ["STRENGTH", "MOTOR_CONTROL"], type: .training),
                .init(label: "Reaktiv / Balance", streamIds: ["REACTIVE_STRENGTH", "MOTOR_CONTROL"], type: .training),
                .init(label: "Aktive Erholung / ROM", streamIds: ["CLINICAL_ROM"], type: .activeRecovery),
                .init(label: "Kraft + Conditioning", streamIds: ["STRENGTH", "CONDITIONING"], type: .training),
                .init(label: "Reaktiv / Plyo", streamIds: ["REACTIVE_STRENGTH", "EXPLOSIVENESS"], type: .training),
                .init(label: "Kraft + ROM", streamIds: ["STRENGTH", "CLINICAL_ROM"], type: .training),
                .init(label: "Ruhetag", streamIds: [], type: .rest),
            ]
        ),
        ScheduleBlock(
            weekRange: 7...8,
            title: "Progressiver Kraftaufbau + Plyometrie",
            days: [
                .init(label: "Kraft + Motor Control", streamIds: ["STRENGTH", "MOTOR_CONTROL"], type: .training),
                .init(label: "Reaktiv / Plyo + Balance", streamIds: ["REACTIVE_STRENGTH", "MOTOR_CONTROL"], type: .training),
                .init(label: "Aktive Erholung / Aqua", streamIds: ["CLINICAL_ROM"], type: .activeRecovery),
                .init(label: "Kraft + Conditioning", streamIds: ["STRENGTH", "CONDITIONING"], type: .training),
                .init(label: "Reaktiv / Plyo", streamIds: ["REACTIVE_STRENGTH", "EXPLOSIVENESS"], type: .training),
                .init(label: "Kraft + ROM", streamIds: ["STRENGTH", "CLINICAL_ROM"], type: .training),
                .init(label: "Ruhetag", streamIds: [], type: .rest),
            ]
        ),
        ScheduleBlock(
            weekRange: 9...11,
            title: "Explosivität + Ausdauer",
            days: [
                .init(label: "Kraft + Explosivität", streamIds: ["STRENGTH", "EXPLOSIVENESS"], type: .training),
                .init(label: "Plyo + Conditioning", streamIds: ["EXPLOSIVENESS", "CONDITIONING"], type: .training),
                .init(label: "Aktive Erholung / Ergometer", streamIds: ["CONDITIONING"], type: .activeRecovery),
                .init(label: "Kraft + Reaktiv", streamIds: ["STRENGTH", "REACTIVE_STRENGTH"], type: .training),
                .init(label: "Plyo + Conditioning", streamIds: ["EXPLOSIVENESS", "CONDITIONING"], type: .training),
                .init(label: "Kraft + Motor Control", streamIds: ["STRENGTH", "MOTOR_CONTROL"], type: .training),
                .init(label: "Ruhetag", streamIds: [], type: .rest),
            ]
        ),
        ScheduleBlock(
            weekRange: 12...12,
            title: "Return to Running",
            days: [
                .init(label: "Kraft + Explosivität", streamIds: ["STRENGTH", "EXPLOSIVENESS"], type: .training),
                .init(label: "Lauftraining + Plyo", streamIds: ["RUNNING", "EXPLOSIVENESS"], type: .training),
                .init(label: "Aktive Erholung", streamIds: ["CLINICAL_ROM"], type: .activeRecovery),
                .init(label: "Kraft + Reaktiv", streamIds: ["STRENGTH", "REACTIVE_STRENGTH"], type: .training),
                .init(label: "Lauftraining + Conditioning", streamIds: ["RUNNING", "CONDITIONING"], type: .training),
                .init(label: "Kraft + Plyo", streamIds: ["STRENGTH", "EXPLOSIVENESS"], type: .training),
                .init(label: "Ruhetag", streamIds: [], type: .rest),
            ]
        ),
        ScheduleBlock(
            weekRange: 13...17,
            title: "Laufen + Richtungswechsel",
            days: [
                .init(label: "Kraft + Explosivität", streamIds: ["STRENGTH", "EXPLOSIVENESS"], type: .training),
                .init(label: "Lauftraining + Plyo", streamIds: ["RUNNING", "EXPLOSIVENESS"], type: .training),
                .init(label: "Kraft + Conditioning", streamIds: ["STRENGTH", "CONDITIONING"], type: .training),
                .init(label: "Lauftraining + Richtungswechsel", streamIds: ["RUNNING", "CHANGE_OF_DIRECTION"], type: .training),
                .init(label: "Plyo + Reaktiv", streamIds: ["EXPLOSIVENESS", "REACTIVE_STRENGTH"], type: .training),
                .init(label: "Kraft + Lauftraining", streamIds: ["STRENGTH", "RUNNING"], type: .training),
                .init(label: "Ruhetag", streamIds: [], type: .rest),
            ]
        ),
        ScheduleBlock(
            weekRange: 18...156,
            title: "Sportspezifisches Training + RTS",
            days: [
                .init(label: "Kraft + Explosivität", streamIds: ["STRENGTH", "EXPLOSIVENESS"], type: .training),
                .init(label: "Lauftraining + Sportspezifisch", streamIds: ["RUNNING", "SPORTS_SPECIFIC"], type: .training),
                .init(label: "Kraft + Conditioning", streamIds: ["STRENGTH", "CONDITIONING"], type: .training),
                .init(label: "Richtungswechsel + Reaktiv", streamIds: ["CHANGE_OF_DIRECTION", "REACTIVE_STRENGTH"], type: .training),
                .init(label: "Lauftraining + Sportspezifisch", streamIds: ["RUNNING", "SPORTS_SPECIFIC"], type: .training),
                .init(label: "Kraft + Plyo", streamIds: ["STRENGTH", "EXPLOSIVENESS"], type: .training),
                .init(label: "Ruhetag / leichtes Training", streamIds: [], type: .rest),
            ]
        ),
    ]
}
