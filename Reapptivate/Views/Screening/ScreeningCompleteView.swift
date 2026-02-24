import SwiftUI

struct ScreeningCompleteView: View {
    @Environment(AppState.self) private var appState
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false

    var body: some View {
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
                    Label("Ihre Diagnose", systemImage: "stethoscope")
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
                    Label("Was Sie erwartet", systemImage: "sparkles")
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
                        Label("Ihr Profil", systemImage: "person.text.rectangle")
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
                    Text("Weiter")
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
        if let name = user?.name.split(separator: " ").first {
            return "Willkommen, \(name)!"
        }
        return "Willkommen!"
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
        }
    }

    private var conditionDescription: String {
        guard let user else { return "" }

        switch user.tendinopathyType {
        case .lbpNonspecific:
            return "Ihr Screening wurde ausgewertet und ein individuelles Programm fuer Ihren unspezifischen Rueckenschmerz erstellt. Das Programm passt sich laufend an Ihren Fortschritt an."
        case .neckPain:
            return "Ihr NDI-Screening wurde ausgewertet. Basierend auf Ihren Ergebnissen erhalten Sie ein abgestuftes Programm, das gezielt Ihre Nackenbeschwerden adressiert."
        case .neckShoulderTension:
            return "Ihr TSI-Screening wurde ausgewertet. Basierend auf Ihren Ergebnissen erhalten Sie ein abgestuftes Programm, das gezielt Ihre Nacken-Schulter-Verspannungen adressiert."
        default:
            return "Ihr Programm wurde basierend auf Ihrer Diagnose erstellt. Es besteht aus drei Phasen, die sich an Ihren Schmerzlevel und Fortschritt anpassen."
        }
    }

    private var expectations: [String] {
        guard let user else { return [] }

        switch user.tendinopathyType {
        case .lbpNonspecific:
            return [
                "Individuell angepasste Uebungen",
                "Schmerzadaptive Phasen-Progression",
                "Psychoedukative Mikro-Module",
                "Fortschritts-Tracking und Analysen"
            ]
        case .neckPain:
            return [
                "Auf Ihren Schweregrad abgestimmte Uebungen",
                "4 progressive Trainingsphasen",
                "Mikro-Module fuer Nackenbeschwerden",
                "Regelmaessige NDI-Verlaufskontrolle"
            ]
        case .neckShoulderTension:
            return [
                "Auf Ihren Schweregrad abgestimmte Uebungen",
                "4 progressive Trainingsphasen",
                "Mikro-Module fuer Verspannungen",
                "Regelmaessige TSI-Verlaufskontrolle"
            ]
        default:
            return [
                "3-Phasen-Programm (Isometrisch, HSR, Exzentrisch)",
                "Schmerzadaptive Anpassung",
                "Taeglich neue Wissenskarten",
                "Fortschritts-Tracking"
            ]
        }
    }

    private var subtypeExplanation: String? {
        guard let user, user.tendinopathyType.isLbp, let subtype = user.aemSubtype else {
            return nil
        }

        switch subtype {
        case .FAR:
            return "Ihr Profil zeigt erhoehte Angst-Vermeidung. Ihr Programm beinhaltet eine Angst-Hierarchie und schrittweise Konfrontationsuebungen, um Bewegungsangst abzubauen."
        case .DER:
            return "Ihr Profil zeigt Distress-Durchhaltemuster. Ihr Programm beinhaltet Pacing-Strategien, um Ueberbelastung zu vermeiden und Aktivitaeten besser zu dosieren."
        case .EER:
            return "Ihr Profil zeigt Eustress-Durchhaltemuster. Ihr Programm beinhaltet Pacing-Strategien, um trotz guter Motivation die richtige Balance zu finden."
        case .AR:
            return "Ihr Profil zeigt einen adaptiven Umgang mit Schmerz. Ihr Programm setzt auf konsequente Progression mit angepasster Belastung."
        }
    }

    private var subtypeColor: Color {
        guard let subtype = user?.aemSubtype else { return .accent }
        return Color.subtypeColor(for: subtype)
    }
}
