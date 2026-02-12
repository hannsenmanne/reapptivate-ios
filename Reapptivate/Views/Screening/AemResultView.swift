import SwiftUI

struct AemResultView: View {
    let result: AemScreeningResult
    let onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Subtype badge
                VStack(spacing: 12) {
                    Circle()
                        .fill(Color.subtypeColor(for: result.subtype))
                        .frame(width: 72, height: 72)
                        .overlay {
                            subtypeIcon
                                .font(.title)
                                .foregroundStyle(.white)
                        }

                    Text(result.subtype.displayName)
                        .font(.title2.bold())
                        .foregroundStyle(.textPrimary)

                    Text(subtypeDescription)
                        .font(.body)
                        .foregroundStyle(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(.top, 32)

                // Subscale scores
                VStack(alignment: .leading, spacing: 12) {
                    Text("Ihre Ergebnisse")
                        .font(.headline)
                        .foregroundStyle(.textPrimary)

                    ScoreBar(label: "Fear-Avoidance", score: result.subscaleScores.fearAvoidance, maxScore: 6, color: .farBlue)
                    ScoreBar(label: "Distress-Endurance", score: result.subscaleScores.distressEndurance, maxScore: 6, color: .derOrange)
                    ScoreBar(label: "Eustress-Endurance", score: result.subscaleScores.eustressEndurance, maxScore: 6, color: .eerGreen)
                }
                .padding(16)
                .background(Color.cardBg)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Pain threshold
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.painAmber)
                    Text("Ihr Schmerzgrenzwert: max. \(result.subtype.maxPainLevel)/10 wahrend des Trainings")
                        .font(.subheadline)
                        .foregroundStyle(.textPrimary)
                }
                .padding(16)
                .background(Color.painAmber.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Continue button
                Button {
                    onContinue()
                } label: {
                    Text("Weiter zum Dashboard")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                }
                .buttonStyle(.borderedProminent)
                .tint(.accent)
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
        case .AR: Image(systemName: "checkmark.circle")
        }
    }

    var subtypeDescription: String {
        switch result.subtype {
        case .FAR:
            "Sie neigen dazu, Bewegung aus Angst vor Schmerzen zu vermeiden. Ihr Programm enthalt schrittweise Exposition."
        case .DER:
            "Sie neigen dazu, trotz Belastung weiterzumachen. Ihr Programm betont Pacing und geplante Pausen."
        case .EER:
            "Sie sind hoch motiviert und neigen zu Uberbelastung. Ihr Programm fokussiert auf Qualitat statt Quantitat."
        case .AR:
            "Sie haben ein ausgewogenes Belastungsprofil. Ihr Programm folgt dem Standardprotokoll."
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
                    .font(.caption)
                    .foregroundStyle(.textSecondary)
                Spacer()
                Text(String(format: "%.1f", score))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(color)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.textSecondary.opacity(0.15))

                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(score / maxScore))
                }
            }
            .frame(height: 6)
        }
    }
}
