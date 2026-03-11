import SwiftUI

private var isEnglishLocale: Bool {
    UserDefaults.standard.string(forKey: "appLanguage") == "en"
}

enum Milestone: String, CaseIterable, Sendable {
    case firstTraining = "first_training"
    case tenSessions = "ten_sessions"
    case phaseUp = "phase_up"
    case twentyFiveSessions = "twenty_five_sessions"
    case fiftySessions = "fifty_sessions"
    case hundredSessions = "hundred_sessions"
    case allPhasesComplete = "all_phases_complete"

    var title: String {
        if isEnglishLocale {
            switch self {
            case .firstTraining: return "First Training!"
            case .tenSessions: return "10 Trainings!"
            case .phaseUp: return "Phase Progression!"
            case .twentyFiveSessions: return "25 Trainings!"
            case .fiftySessions: return "50 Trainings!"
            case .hundredSessions: return "100 Trainings!"
            case .allPhasesComplete: return "All Phases Complete!"
            }
        }
        switch self {
        case .firstTraining: return "Erstes Training!"
        case .tenSessions: return "10 Trainings!"
        case .phaseUp: return "Phase aufgestiegen!"
        case .twentyFiveSessions: return "25 Trainings!"
        case .fiftySessions: return "50 Trainings!"
        case .hundredSessions: return "100 Trainings!"
        case .allPhasesComplete: return "Alle Phasen gemeistert!"
        }
    }

    var message: String {
        if isEnglishLocale {
            switch self {
            case .firstTraining: return "You completed your first training. Great start!"
            case .tenSessions: return "Ten sessions done. Your consistency is paying off!"
            case .phaseUp: return "You advanced to the next phase. Impressive progress!"
            case .twentyFiveSessions: return "25 sessions done. You are getting stronger!"
            case .fiftySessions: return "Fifty sessions! Your dedication is impressive."
            case .hundredSessions: return "One hundred training sessions — an incredible achievement!"
            case .allPhasesComplete: return "You completed all training phases. Outstanding work!"
            }
        }
        switch self {
        case .firstTraining: return "Sie haben Ihr erstes Training abgeschlossen. Der Anfang ist gemacht!"
        case .tenSessions: return "Zehn Trainingseinheiten geschafft. Ihre Ausdauer zahlt sich aus!"
        case .phaseUp: return "Sie sind in die nächste Phase aufgestiegen. Ihr Fortschritt ist beeindruckend!"
        case .twentyFiveSessions: return "25 Einheiten geschafft. Sie werden immer stärker!"
        case .fiftySessions: return "Halbhundert! Ihre Beständigkeit ist beeindruckend."
        case .hundredSessions: return "Einhundert Trainingseinheiten — eine unglaubliche Leistung!"
        case .allPhasesComplete: return "Sie haben alle Trainingsphasen abgeschlossen. Grossartige Arbeit!"
        }
    }

    var icon: String {
        switch self {
        case .firstTraining: "star.fill"
        case .tenSessions: "trophy.fill"
        case .phaseUp: "arrow.up.circle.fill"
        case .twentyFiveSessions: "trophy.fill"
        case .fiftySessions: "trophy.fill"
        case .hundredSessions: "trophy.fill"
        case .allPhasesComplete: "star.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .firstTraining: .accent
        case .tenSessions: .farBlue
        case .phaseUp: .phaseProgress
        case .twentyFiveSessions: .painAmber
        case .fiftySessions: .farBlue
        case .hundredSessions: .accent
        case .allPhasesComplete: .phaseProgress
        }
    }
}
