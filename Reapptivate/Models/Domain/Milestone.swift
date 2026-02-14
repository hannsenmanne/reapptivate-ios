import SwiftUI

enum Milestone: String, CaseIterable, Sendable {
    case firstTraining = "first_training"
    case threeDayStreak = "three_day_streak"
    case sevenDayStreak = "seven_day_streak"
    case tenSessions = "ten_sessions"
    case phaseUp = "phase_up"

    var title: String {
        switch self {
        case .firstTraining: "Erstes Training!"
        case .threeDayStreak: "3-Tage-Serie!"
        case .sevenDayStreak: "7-Tage-Serie!"
        case .tenSessions: "10 Trainings!"
        case .phaseUp: "Phase aufgestiegen!"
        }
    }

    var message: String {
        switch self {
        case .firstTraining: "Sie haben Ihr erstes Training abgeschlossen. Der Anfang ist gemacht!"
        case .threeDayStreak: "Drei Tage in Folge trainiert. Weiter so!"
        case .sevenDayStreak: "Eine ganze Woche am Stück! Sie bauen eine starke Gewohnheit auf."
        case .tenSessions: "Zehn Trainingseinheiten geschafft. Ihre Ausdauer zahlt sich aus!"
        case .phaseUp: "Sie sind in die nächste Phase aufgestiegen. Ihr Fortschritt ist beeindruckend!"
        }
    }

    var icon: String {
        switch self {
        case .firstTraining: "star.fill"
        case .threeDayStreak: "flame.fill"
        case .sevenDayStreak: "flame.fill"
        case .tenSessions: "trophy.fill"
        case .phaseUp: "arrow.up.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .firstTraining: .accent
        case .threeDayStreak: .painAmber
        case .sevenDayStreak: .painRed
        case .tenSessions: .farBlue
        case .phaseUp: .phaseProgress
        }
    }
}
