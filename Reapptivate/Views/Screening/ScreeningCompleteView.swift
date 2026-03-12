import SwiftUI

struct ScreeningCompleteView: View {
    @Environment(AppState.self) private var appState
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false
    @AppStorage("appLanguage") private var appLanguage = "de"

    var body: some View {
        let isEn = appLanguage == "en"
        ScrollView {
            VStack(spacing: 24) {
                Spacer()
                    .frame(height: 16)

                // Hero icon
                Circle()
                    .fill(Color.accent.opacity(0.12))
                    .frame(width: 88, height: 88)
                    .overlay {
                        Image(systemName: conditionIcon)
                            .font(.system(size: 36))
                            .foregroundStyle(.accent)
                    }

                // Greeting
                VStack(spacing: 8) {
                    Text(greetingTitle)
                        .font(.appTitle)
                        .foregroundStyle(.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(conditionName)
                        .font(.appHeadline)
                        .foregroundStyle(.accent)
                }

                // Condition summary card
                VStack(alignment: .leading, spacing: 12) {
                    Label(isEn ? "Your diagnosis" : "Ihre Diagnose", systemImage: "stethoscope")
                        .font(.appSubheadlineSemibold)
                        .foregroundStyle(.textPrimary)

                    Text(conditionDescription)
                        .font(.appBody)
                        .foregroundStyle(.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()

                // What to expect card
                VStack(alignment: .leading, spacing: 12) {
                    Label(isEn ? "What to expect" : "Was Sie erwartet", systemImage: "sparkles")
                        .font(.appSubheadlineSemibold)
                        .foregroundStyle(.textPrimary)

                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(expectations, id: \.self) { item in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.accent)
                                    .padding(.top, 2)

                                Text(item)
                                    .font(.appSubheadline)
                                    .foregroundStyle(.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()

                // Subtype info for LBP
                if let subtypeInfo = subtypeExplanation {
                    VStack(alignment: .leading, spacing: 12) {
                        Label(isEn ? "Your profile" : "Ihr Profil", systemImage: "person.text.rectangle")
                            .font(.appSubheadlineSemibold)
                            .foregroundStyle(.textPrimary)

                        Text(subtypeInfo)
                            .font(.appBody)
                            .foregroundStyle(.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accentCardStyle(color: subtypeColor)
                }

                // Continue button
                Button {
                    hasSeenWelcome = true
                } label: {
                    Text(isEn ? "Continue" : "Weiter")
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                }
                .buttonStyle(.accentFilled)
                .padding(.top, 8)

                Spacer()
                    .frame(height: 16)
            }
            .padding(.horizontal, 24)
        }
        .background(Color.appBg)
    }

    // MARK: - Computed Content

    private var user: UserProfile? {
        appState.currentUser
    }

    private var greetingTitle: String {
        let isEn = appLanguage == "en"
        if let name = user?.name.split(separator: " ").first {
            return isEn ? "Welcome, \(name)!" : "Willkommen, \(name)!"
        }
        return isEn ? "Welcome!" : "Willkommen!"
    }

    private var conditionName: String {
        guard let user else { return "" }

        if user.tendinopathyType.isLbp, let subtype = user.aemSubtype {
            return "\(user.tendinopathyType.displayName) (\(subtype.displayName))"
        }
        return user.tendinopathyType.displayName
    }

    private var conditionIcon: String {
        guard let user else { return "heart.text.clipboard" }

        switch user.tendinopathyType {
        case .lbpNonspecific: return "figure.walk"
        case .neckPain: return "figure.mind.and.body"
        case .neckShoulderTension: return "figure.mind.and.body"
        case .tennisElbow, .golfersElbow: return "hand.raised"
        case .achilles, .plantarFascia: return "figure.run"
        case .patellar: return "figure.strengthtraining.functional"
        case .rotatorCuff: return "figure.boxing"
        case .gluteal, .proximalHamstring: return "figure.cooldown"
        case .aclReconstruction: return "figure.strengthtraining.functional"
        case .shoulderImpingement: return "figure.arms.open"
        case .frozenShoulder: return "figure.arms.open"
        case .lateralAnkleSprain: return "figure.run"
        case .unknown: return "heart.text.clipboard"
        }
    }

    private var conditionDescription: String {
        let isEn = appLanguage == "en"
        guard let user else { return "" }

        switch user.tendinopathyType {
        case .lbpNonspecific:
            return isEn
                ? "Your screening has been evaluated and an individual program for your non-specific low back pain has been created. The program continuously adapts to your progress."
                : "Ihr Screening wurde ausgewertet und ein individuelles Programm für Ihren unspezifischen Rückenschmerz erstellt. Das Programm passt sich laufend an Ihren Fortschritt an."
        case .neckPain:
            return isEn
                ? "Your NDI screening has been evaluated. Based on your results, you will receive a graded program that specifically addresses your neck complaints."
                : "Ihr NDI-Screening wurde ausgewertet. Basierend auf Ihren Ergebnissen erhalten Sie ein abgestuftes Programm, das gezielt Ihre Nackenbeschwerden adressiert."
        case .neckShoulderTension:
            return isEn
                ? "Your TSI screening has been evaluated. Based on your results, you will receive a graded program that specifically addresses your neck and shoulder tension."
                : "Ihr TSI-Screening wurde ausgewertet. Basierend auf Ihren Ergebnissen erhalten Sie ein abgestuftes Programm, das gezielt Ihre Nacken-Schulter-Verspannungen adressiert."
        case .aclReconstruction:
            return isEn
                ? "Your ACL screening has been evaluated. Based on your graft type and sport level, you will receive a 5-milestone program with 9 training streams for your ACL reconstruction."
                : "Ihr ACL-Screening wurde ausgewertet. Basierend auf Ihrem Transplantattyp und Sportniveau erhalten Sie ein 5-Meilenstein-Programm mit 9 Trainings-Streams für Ihre Kreuzbandrekonstruktion."
        case .shoulderImpingement:
            return isEn
                ? "Your QuickDASH screening has been evaluated. Based on your results, you will receive a 4-phase program that specifically addresses your shoulder impingement."
                : "Ihr QuickDASH-Screening wurde ausgewertet. Basierend auf Ihren Ergebnissen erhalten Sie ein 4-Phasen-Programm, das gezielt Ihre Schulter-Impingement-Beschwerden adressiert."
        case .frozenShoulder:
            return isEn
                ? "Your SPADI screening has been evaluated. Based on your results, you will receive a 4-phase program that specifically treats your frozen shoulder (adhesive capsulitis) — from gentle mobilization to full return to daily activities and sports."
                : "Ihr SPADI-Screening wurde ausgewertet. Basierend auf Ihren Ergebnissen erhalten Sie ein 4-Phasen-Programm, das gezielt Ihre Frozen Shoulder (Adhesive Capsulitis) behandelt — von sanfter Mobilisation bis zur vollen Rückkehr in Alltag und Sport."
        case .lateralAnkleSprain:
            return isEn
                ? "Your CAIT screening has been evaluated. Based on your results, you will receive a 4-phase program following the PEACE & LOVE protocol — from protection and decompression through proprioception to return to sport."
                : "Ihr CAIT-Screening wurde ausgewertet. Basierend auf Ihren Ergebnissen erhalten Sie ein 4-Phasen-Programm nach dem PEACE & LOVE-Protokoll — von Schutz und Entstauung über Propriozeption bis zum Return to Sport."
        default:
            return isEn
                ? "Your program has been created based on your diagnosis. It consists of three phases that adapt to your pain level and progress."
                : "Ihr Programm wurde basierend auf Ihrer Diagnose erstellt. Es besteht aus drei Phasen, die sich an Ihren Schmerzlevel und Fortschritt anpassen."
        }
    }

    private var expectations: [String] {
        let isEn = appLanguage == "en"
        guard let user else { return [] }

        switch user.tendinopathyType {
        case .lbpNonspecific:
            return isEn ? [
                "Individually tailored exercises",
                "Pain-adaptive phase progression",
                "Psychoeducational micro-modules",
                "Progress tracking and analytics"
            ] : [
                "Individuell angepasste Übungen",
                "Schmerzadaptive Phasen-Progression",
                "Psychoedukative Mikro-Module",
                "Fortschritts-Tracking und Analysen"
            ]
        case .neckPain:
            return isEn ? [
                "Exercises matched to your severity level",
                "4 progressive training phases",
                "Micro-modules for neck complaints",
                "Regular NDI progress monitoring"
            ] : [
                "Auf Ihren Schweregrad abgestimmte Übungen",
                "4 progressive Trainingsphasen",
                "Mikro-Module für Nackenbeschwerden",
                "Regelmäßige NDI-Verlaufskontrolle"
            ]
        case .neckShoulderTension:
            return isEn ? [
                "Exercises matched to your severity level",
                "4 progressive training phases",
                "Micro-modules for tension relief",
                "Regular TSI progress monitoring"
            ] : [
                "Auf Ihren Schweregrad abgestimmte Übungen",
                "4 progressive Trainingsphasen",
                "Mikro-Module für Verspannungen",
                "Regelmäßige TSI-Verlaufskontrolle"
            ]
        case .aclReconstruction:
            return isEn ? [
                "5-milestone program (pre-op to return-to-sport)",
                "9 specialized training streams",
                "Daily and weekly KPI tracking",
                "Discharge criteria tracking"
            ] : [
                "5-Meilenstein-Programm (Pre-OP bis Return-to-Sport)",
                "9 spezialisierte Trainings-Streams",
                "Tägliche und wöchentliche KPI-Erfassung",
                "Entlassungskriterien-Tracking"
            ]
        case .shoulderImpingement:
            return isEn ? [
                "Exercises matched to your severity level",
                "4 progressive training phases",
                "Micro-modules for shoulder complaints",
                "Regular QuickDASH progress monitoring"
            ] : [
                "Auf Ihren Schweregrad abgestimmte Übungen",
                "4 progressive Trainingsphasen",
                "Mikro-Module für Schulterbeschwerden",
                "Regelmäßige QuickDASH-Verlaufskontrolle"
            ]
        case .frozenShoulder:
            return isEn ? [
                "Exercises matched to your stage",
                "4 progressive training phases (mobilization to return)",
                "Micro-modules for frozen shoulder",
                "Regular SPADI progress monitoring"
            ] : [
                "Auf Ihr Stadium abgestimmte Übungen",
                "4 progressive Trainingsphasen (Mobilisation bis Rückkehr)",
                "Mikro-Module für Frozen Shoulder",
                "Regelmäßige SPADI-Verlaufskontrolle"
            ]
        case .lateralAnkleSprain:
            return isEn ? [
                "Exercises matched to your severity level",
                "4 progressive training phases (PEACE & LOVE to return to sport)",
                "Micro-modules for ankle stability",
                "Regular CAIT progress monitoring"
            ] : [
                "Auf Ihren Schweregrad abgestimmte Übungen",
                "4 progressive Trainingsphasen (PEACE & LOVE bis Return to Sport)",
                "Mikro-Module für Sprunggelenksstabilität",
                "Regelmäßige CAIT-Verlaufskontrolle"
            ]
        default:
            return isEn ? [
                "3-phase program (isometric, HSR, eccentric)",
                "Pain-adaptive adjustment",
                "Daily new knowledge cards",
                "Progress tracking"
            ] : [
                "3-Phasen-Programm (Isometrisch, HSR, Exzentrisch)",
                "Schmerzadaptive Anpassung",
                "Täglich neue Wissenskarten",
                "Fortschritts-Tracking"
            ]
        }
    }

    private var subtypeExplanation: String? {
        let isEn = appLanguage == "en"
        guard let user, user.tendinopathyType.isLbp, let subtype = user.aemSubtype else {
            return nil
        }

        switch subtype {
        case .FAR:
            return isEn
                ? "Your profile shows elevated fear-avoidance. Your program includes a fear hierarchy and gradual exposure exercises to reduce movement anxiety."
                : "Ihr Profil zeigt erhöhte Angst-Vermeidung. Ihr Programm beinhaltet eine Angst-Hierarchie und schrittweise Konfrontationsübungen, um Bewegungsangst abzubauen."
        case .DER:
            return isEn
                ? "Your profile shows distress-endurance patterns. Your program includes pacing strategies to avoid overexertion and better manage activities."
                : "Ihr Profil zeigt Distress-Durchhaltemuster. Ihr Programm beinhaltet Pacing-Strategien, um Überbelastung zu vermeiden und Aktivitäten besser zu dosieren."
        case .EER:
            return isEn
                ? "Your profile shows eustress-endurance patterns. Your program includes pacing strategies to find the right balance despite good motivation."
                : "Ihr Profil zeigt Eustress-Durchhaltemuster. Ihr Programm beinhaltet Pacing-Strategien, um trotz guter Motivation die richtige Balance zu finden."
        case .AR, .unknown:
            return isEn
                ? "Your profile shows adaptive pain management. Your program focuses on consistent progression with adjusted load."
                : "Ihr Profil zeigt einen adaptiven Umgang mit Schmerz. Ihr Programm setzt auf konsequente Progression mit angepasster Belastung."
        }
    }

    private var subtypeColor: Color {
        guard let subtype = user?.aemSubtype else { return .accent }
        return Color.subtypeColor(for: subtype)
    }
}
