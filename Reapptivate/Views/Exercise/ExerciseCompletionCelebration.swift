import SwiftUI

struct ExerciseCompletionCelebration: View {
    let onComplete: () -> Void

    @State private var isVisible = false
    @State private var confettiTrigger = false
    @ScaledMetric(relativeTo: .largeTitle) private var iconSize: CGFloat = 48

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            ZStack {
                // Confetti dots
                ForEach(0..<12, id: \.self) { i in
                    Circle()
                        .fill(confettiColor(for: i))
                        .frame(width: 8, height: 8)
                        .offset(confettiOffset(for: i))
                        .opacity(confettiTrigger ? 0 : 1)
                        .animation(
                            .easeOut(duration: 1.0).delay(Double(i) * 0.04),
                            value: confettiTrigger
                        )
                }

                // Checkmark circle
                Circle()
                    .fill(Color.painGreen.opacity(0.15))
                    .frame(width: iconSize * 2, height: iconSize * 2)
                    .overlay {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: iconSize))
                            .foregroundStyle(.painGreen)
                    }
                    .scaleEffect(isVisible ? 1 : 0.5)
            }
        }
        .task {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                isVisible = true
            }
            try? await Task.sleep(for: .milliseconds(200))
            confettiTrigger = true
            try? await Task.sleep(for: .seconds(1.0))
            onComplete()
        }
    }

    private func confettiColor(for index: Int) -> Color {
        let colors: [Color] = [.accent, .painAmber, .farBlue, .painGreen]
        return colors[index % colors.count]
    }

    private func confettiOffset(for index: Int) -> CGSize {
        let angle = Double(index) * (360.0 / 12.0) * .pi / 180.0
        let radius: Double = confettiTrigger ? 70 : 25
        return CGSize(width: cos(angle) * radius, height: sin(angle) * radius)
    }
}
