import SwiftUI

struct FirstExerciseGuide: View {
    @AppStorage("hasCompletedFirstExercise") private var hasCompleted = false
    @AppStorage("appLanguage") private var appLanguage = "de"
    @State private var step = 0
    @State private var stepTrigger = false

    let onDismiss: () -> Void

    private var steps: [GuideStep] {
        let isEn = appLanguage == "en"
        return [
            GuideStep(
                title: isEn ? "Set progress" : "Satz-Fortschritt",
                description: isEn ? "The bar at the top shows your progress through the sets. Green = completed." : "Die Leiste oben zeigt Ihren Fortschritt durch die Sätze. Grün = abgeschlossen.",
                icon: "chart.bar.fill"
            ),
            GuideStep(
                title: isEn ? "Complete a set" : "Satz abschliessen",
                description: isEn ? "Tap the button to mark a set as completed." : "Tippen Sie auf den Button, um einen Satz als erledigt zu markieren.",
                icon: "checkmark.circle.fill"
            ),
            GuideStep(
                title: isEn ? "Log pain" : "Schmerz protokollieren",
                description: isEn ? "After the last set, record your pain level and save the workout." : "Nach dem letzten Satz erfassen Sie Ihren Schmerz und speichern das Training.",
                icon: "waveform.path.ecg"
            ),
        ]
    }

    var body: some View {
        let isEn = appLanguage == "en"

        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Step content
                VStack(spacing: 16) {
                    Image(systemName: steps[step].icon)
                        .font(.system(size: 40))
                        .foregroundStyle(.accent)

                    Text(steps[step].title)
                        .font(.appTitle2)
                        .foregroundStyle(.white)

                    Text(steps[step].description)
                        .font(.appBody)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Spacer()

                // Step dots
                HStack(spacing: 8) {
                    ForEach(0..<steps.count, id: \.self) { i in
                        Circle()
                            .fill(i == step ? Color.accent : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }

                // Button
                Button {
                    if step < steps.count - 1 {
                        stepTrigger.toggle()
                        withAnimation { step += 1 }
                    } else {
                        hasCompleted = true
                        onDismiss()
                    }
                } label: {
                    Text(step < steps.count - 1 ? (isEn ? "Next" : "Weiter") : (isEn ? "Got it" : "Verstanden"))
                        .font(.appBodySemibold)
                        .foregroundStyle(Color(red: 0.1, green: 0.1, blue: 0.1))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.buttonRadius, style: .continuous))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .conditionalHaptic(.selection, trigger: stepTrigger)
        }
    }
}

private struct GuideStep {
    let title: String
    let description: String
    let icon: String
}
