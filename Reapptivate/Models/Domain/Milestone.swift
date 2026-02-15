import SwiftUI

enum Milestone: String, CaseIterable, Sendable {
    case firstTraining = "first_training"
    case threeDayStreak = "three_day_streak"
    case sevenDayStreak = "seven_day_streak"
    case tenSessions = "ten_sessions"
    case phaseUp = "phase_up"
    case fourteenDayStreak = "fourteen_day_streak"
    case thirtyDayStreak = "thirty_day_streak"
    case twentyFiveSessions = "twenty_five_sessions"
    case fiftySessions = "fifty_sessions"
    case hundredSessions = "hundred_sessions"
    case allPhasesComplete = "all_phases_complete"

    var title: String {
        switch self {
        case .firstTraining: "Erstes Training!"
        case .threeDayStreak: "3-Tage-Serie!"
        case .sevenDayStreak: "7-Tage-Serie!"
        case .tenSessions: "10 Trainings!"
        case .phaseUp: "Phase aufgestiegen!"
        case .fourteenDayStreak: "14-Tage-Serie!"
        case .thirtyDayStreak: "30-Tage-Serie!"
        case .twentyFiveSessions: "25 Trainings!"
        case .fiftySessions: "50 Trainings!"
        case .hundredSessions: "100 Trainings!"
        case .allPhasesComplete: "Alle Phasen gemeistert!"
        }
    }

    var message: String {
        switch self {
        case .firstTraining: "Sie haben Ihr erstes Training abgeschlossen. Der Anfang ist gemacht!"
        case .threeDayStreak: "Drei Tage in Folge trainiert. Weiter so!"
        case .sevenDayStreak: "Eine ganze Woche am Stück! Sie bauen eine starke Gewohnheit auf."
        case .tenSessions: "Zehn Trainingseinheiten geschafft. Ihre Ausdauer zahlt sich aus!"
        case .phaseUp: "Sie sind in die nächste Phase aufgestiegen. Ihr Fortschritt ist beeindruckend!"
        case .fourteenDayStreak: "Zwei Wochen am Stück trainiert. Fantastisch!"
        case .thirtyDayStreak: "Ein ganzer Monat! Sie sind ein Vorbild an Disziplin."
        case .twentyFiveSessions: "25 Einheiten geschafft. Sie werden immer stärker!"
        case .fiftySessions: "Halbhundert! Ihre Beständigkeit ist beeindruckend."
        case .hundredSessions: "Einhundert Trainingseinheiten — eine unglaubliche Leistung!"
        case .allPhasesComplete: "Sie haben alle Trainingsphasen abgeschlossen. Grossartige Arbeit!"
        }
    }

    var icon: String {
        switch self {
        case .firstTraining: "star.fill"
        case .threeDayStreak: "flame.fill"
        case .sevenDayStreak: "flame.fill"
        case .tenSessions: "trophy.fill"
        case .phaseUp: "arrow.up.circle.fill"
        case .fourteenDayStreak: "flame.fill"
        case .thirtyDayStreak: "flame.fill"
        case .twentyFiveSessions: "trophy.fill"
        case .fiftySessions: "trophy.fill"
        case .hundredSessions: "trophy.fill"
        case .allPhasesComplete: "star.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .firstTraining: .accent
        case .threeDayStreak: .painAmber
        case .sevenDayStreak: .painRed
        case .tenSessions: .farBlue
        case .phaseUp: .phaseProgress
        case .fourteenDayStreak: .painRed
        case .thirtyDayStreak: .accent
        case .twentyFiveSessions: .painAmber
        case .fiftySessions: .farBlue
        case .hundredSessions: .accent
        case .allPhasesComplete: .phaseProgress
        }
    }
}
