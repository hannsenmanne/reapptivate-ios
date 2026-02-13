import SwiftUI

struct PainSliderView: View {
    @Binding var painLevel: Int
    let maxPainLevel: Int

    var body: some View {
        VStack(spacing: 16) {
            // Threshold indicator
            Text("Fur Ihr Profil empfohlen: max. \(maxPainLevel)/10")
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
                        .fill(.white)
                        .frame(width: 28, height: 28)
                        .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                        .overlay {
                            Circle()
                                .fill(painColor)
                                .frame(width: 12, height: 12)
                        }
                        .offset(x: thumbX - 14)
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let fraction = max(0, min(1, value.location.x / geometry.size.width))
                            let newLevel = Int(round(fraction * 10))
                            if newLevel != painLevel {
                                painLevel = newLevel
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        }
                )
            }
            .frame(height: 28)
            .padding(.horizontal, 14) // Thumb overhang

            // Scale labels
            HStack {
                Text("0 (kein Schmerz)")
                    .font(.appCaption2)
                    .foregroundStyle(.textSecondary)
                Spacer()
                Text("10 (starkster)")
                    .font(.appCaption2)
                    .foregroundStyle(.textSecondary)
            }

            // Feedback text
            Text(feedbackText)
                .font(.appSubheadlineMedium)
                .foregroundStyle(painColor)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    var painColor: Color {
        Color.painColor(for: painLevel, maxPainLevel: maxPainLevel)
    }

    var feedbackText: String {
        if painLevel <= maxPainLevel {
            "Im empfohlenen Bereich"
        } else if painLevel <= maxPainLevel + 1 {
            "Leicht uber Empfehlung"
        } else {
            "Deutlich uber Empfehlung — bitte aufpassen"
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
