import SwiftUI

struct PainSliderView: View {
    @Binding var painLevel: Int
    let maxPainLevel: Int

    @AppStorage("appLanguage") private var appLanguage = "de"
    @State private var thumbScale: CGFloat = 1.0
    @State private var numberScale: CGFloat = 1.0
    @State private var dragHapticTrigger = false
    @State private var thumbAnimationTask: Task<Void, Never>?
    @State private var numberAnimationTask: Task<Void, Never>?

    var body: some View {
        let isEn = appLanguage == "en"

        VStack(spacing: 16) {
            // Threshold indicator
            Text(isEn ? "Recommended for your profile: max. \(maxPainLevel)/10" : "Für Ihr Profil empfohlen: max. \(maxPainLevel)/10")
                .font(.appCaption)
                .foregroundStyle(.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Pain level display
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(painLevel)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(painColor)
                    .contentTransition(.numericText())
                    .animation(.spring(duration: 0.2), value: painLevel)
                    .scaleEffect(numberScale)

                Text("/10")
                    .font(.appTitle3)
                    .foregroundStyle(.textSecondary)
            }

            // Custom slider
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track background
                    PainGradientTrack(maxPainLevel: maxPainLevel)
                        .frame(height: 12)
                        .clipShape(Capsule())

                    // Filled portion
                    PainGradientTrack(maxPainLevel: maxPainLevel)
                        .frame(width: CGFloat(painLevel) / 10.0 * geometry.size.width, height: 12)
                        .clipShape(Capsule())

                    // Threshold marker
                    let thresholdX = CGFloat(maxPainLevel) / 10.0 * geometry.size.width
                    Rectangle()
                        .fill(Color.textSecondary.opacity(0.5))
                        .frame(width: 2, height: 20)
                        .offset(x: thresholdX - 1)

                    // Thumb
                    let thumbX = CGFloat(painLevel) / 10.0 * geometry.size.width
                    Circle()
                        .fill(Color.cardBg)
                        .frame(width: 28, height: 28)
                        .shadow(color: .primary.opacity(0.15), radius: 4, y: 2)
                        .overlay {
                            Circle()
                                .fill(painColor)
                                .frame(width: 12, height: 12)
                        }
                        .scaleEffect(thumbScale)
                        .offset(x: thumbX - 14)
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let fraction = max(0, min(1, value.location.x / geometry.size.width))
                            let newLevel = Int(round(fraction * 10))
                            if newLevel != painLevel {
                                painLevel = newLevel
                                dragHapticTrigger.toggle()

                                // Thumb bounce - cancel previous animation task to prevent race
                                thumbAnimationTask?.cancel()
                                withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                                    thumbScale = 1.2
                                }
                                thumbAnimationTask = Task { @MainActor in
                                    try? await Task.sleep(for: .milliseconds(150))
                                    guard !Task.isCancelled else { return }
                                    withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                        thumbScale = 1.0
                                    }
                                }

                                // Number bounce - cancel previous animation task to prevent race
                                numberAnimationTask?.cancel()
                                withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                                    numberScale = 1.1
                                }
                                numberAnimationTask = Task { @MainActor in
                                    try? await Task.sleep(for: .milliseconds(150))
                                    guard !Task.isCancelled else { return }
                                    withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                        numberScale = 1.0
                                    }
                                }
                            }
                        }
                )
            }
            .frame(height: 28)
            .padding(.horizontal, 14) // Thumb overhang

            // Scale labels
            HStack {
                Text(isEn ? "0 (no pain)" : "0 (kein Schmerz)")
                    .font(.appCaption2)
                    .foregroundStyle(.textSecondary)
                Spacer()
                Text(isEn ? "10 (worst)" : "10 (stärkster)")
                    .font(.appCaption2)
                    .foregroundStyle(.textSecondary)
            }

            // Feedback text
            Text(feedbackText(isEn: isEn))
                .font(.appSubheadlineMedium)
                .foregroundStyle(painColor)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .conditionalHaptic(.impact(weight: .light), trigger: dragHapticTrigger)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isEn ? "Pain scale" : "Schmerzskala")
        .accessibilityValue(isEn ? "\(painLevel) of 10" : "\(painLevel) von 10")
        .accessibilityHint(isEn ? "Swipe up or down to change the value" : "Wischen Sie nach oben oder unten, um den Wert zu ändern")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                painLevel = min(10, painLevel + 1)
            case .decrement:
                painLevel = max(0, painLevel - 1)
            @unknown default:
                break
            }
        }
    }

    var painColor: Color {
        Color.painColor(for: painLevel, maxPainLevel: maxPainLevel)
    }

    func feedbackText(isEn: Bool) -> String {
        if painLevel <= maxPainLevel {
            isEn ? "Within recommended range" : "Im empfohlenen Bereich"
        } else if painLevel <= maxPainLevel + 1 {
            isEn ? "Slightly above recommendation" : "Leicht über Empfehlung"
        } else {
            isEn ? "Significantly above recommendation — please be careful" : "Deutlich über Empfehlung — bitte aufpassen"
        }
    }
}

// MARK: - Pain Gradient Track

struct PainGradientTrack: View {
    let maxPainLevel: Int

    var body: some View {
        GeometryReader { geometry in
            let greenEnd = CGFloat(maxPainLevel) / 10.0
            let yellowEnd = CGFloat(maxPainLevel + 1) / 10.0

            LinearGradient(
                stops: [
                    .init(color: .painGreen, location: 0),
                    .init(color: .painGreen, location: greenEnd),
                    .init(color: .painAmber, location: greenEnd + 0.01),
                    .init(color: .painAmber, location: yellowEnd),
                    .init(color: .painRed, location: yellowEnd + 0.01),
                    .init(color: .painRed, location: 1),
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
}

#Preview {
    @Previewable @State var pain = 3
    PainSliderView(painLevel: $pain, maxPainLevel: 3)
        .padding(24)
}
