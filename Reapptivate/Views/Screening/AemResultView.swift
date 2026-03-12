import SwiftUI

struct AemResultView: View {
    @AppStorage("appLanguage") private var appLanguage = "de"
    let result: AemScreeningResult
    let onContinue: () -> Void

    var body: some View {
        let isEn = appLanguage == "en"

        ScrollView {
            VStack(spacing: 24) {
                // Subtype badge
                VStack(spacing: 12) {
                    Circle()
                        .fill(Color.subtypeColor(for: result.subtype))
                        .frame(width: 72, height: 72)
                        .overlay {
                            subtypeIcon
                                .font(.appTitle)
                                .foregroundStyle(.white)
                        }

                    Text(result.subtype.displayName)
                        .font(.appTitle2)
                        .foregroundStyle(.textPrimary)

                    Text(subtypeDescription)
                        .font(.appBody)
                        .foregroundStyle(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(.top, 32)

                // Subscale scores
                VStack(alignment: .leading, spacing: 12) {
                    Text(isEn ? "Your Results" : "Ihre Ergebnisse")
                        .font(.appHeadline)
                        .foregroundStyle(.textPrimary)

                    ScoreBar(label: "Fear-Avoidance", score: result.subscaleScores.fearAvoidance, maxScore: 6, color: .farBlue)
                    ScoreBar(label: "Distress-Endurance", score: result.subscaleScores.distressEndurance, maxScore: 6, color: .derOrange)
                    ScoreBar(label: "Eustress-Endurance", score: result.subscaleScores.eustressEndurance, maxScore: 6, color: .eerGreen)
                }
                .cardStyle()

                // Pain threshold
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.painAmber)
                    Text(isEn ? "Your pain threshold: max. \(result.subtype.maxPainLevel)/10 during training" : "Ihr Schmerzgrenzwert: max. \(result.subtype.maxPainLevel)/10 während des Trainings")
                        .font(.appSubheadline)
                        .foregroundStyle(.textPrimary)
                }
                .infoBoxStyle(color: .painAmber)

                // Continue button
                Button {
                    onContinue()
                } label: {
                    Text(isEn ? "Continue to Dashboard" : "Weiter zum Dashboard")
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                }
                .buttonStyle(.accentFilled)
            }
            .padding(24)
        }
        .background(Color.appBg)
    }

    @ViewBuilder
    var subtypeIcon: some View {
        switch result.subtype {
        case .FAR: Image(systemName: "magnifyingglass")
        case .DER: Image(systemName: "timer")
        case .EER: Image(systemName: "chart.bar")
        case .AR, .unknown: Image(systemName: "checkmark.circle")
        }
    }

    var subtypeDescription: String {
        let isEn = appLanguage == "en"
        switch result.subtype {
        case .FAR:
            return isEn ? "You tend to avoid movement due to fear of pain. Your program includes gradual exposure." : "Sie neigen dazu, Bewegung aus Angst vor Schmerzen zu vermeiden. Ihr Programm enthält schrittweise Exposition."
        case .DER:
            return isEn ? "You tend to push through despite strain. Your program emphasizes pacing and planned breaks." : "Sie neigen dazu, trotz Belastung weiterzumachen. Ihr Programm betont Pacing und geplante Pausen."
        case .EER:
            return isEn ? "You are highly motivated and tend to overexert. Your program focuses on quality over quantity." : "Sie sind hoch motiviert und neigen zu Überbelastung. Ihr Programm fokussiert auf Qualität statt Quantität."
        case .AR, .unknown:
            return isEn ? "You have a balanced load profile. Your program follows the standard protocol." : "Sie haben ein ausgewogenes Belastungsprofil. Ihr Programm folgt dem Standardprotokoll."
        }
    }
}

struct ScoreBar: View {
    let label: String
    let score: Double
    let maxScore: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
                Spacer()
                Text(String(format: "%.1f", score))
                    .font(.appCaptionBold)
                    .foregroundStyle(color)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.textSecondary.opacity(0.15))

                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(score / maxScore))
                }
            }
            .frame(height: 6)
        }
    }
}
