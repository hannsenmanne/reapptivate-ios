import SwiftUI

struct MilestoneAlert: View {
    let milestone: Milestone
    let onDismiss: () -> Void

    @State private var isVisible = false
    @State private var confettiTrigger = false
    @ScaledMetric(relativeTo: .largeTitle) private var iconSize: CGFloat = 56

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            // Card
            VStack(spacing: 20) {
                // Confetti dots
                ZStack {
                    ForEach(0..<12, id: \.self) { i in
                        Circle()
                            .fill(confettiColor(for: i))
                            .frame(width: 8, height: 8)
                            .offset(confettiOffset(for: i))
                            .opacity(confettiTrigger ? 0 : 1)
                            .animation(
                                .easeOut(duration: 1.2).delay(Double(i) * 0.05),
                                value: confettiTrigger
                            )
                    }

                    // Icon circle
                    Circle()
                        .fill(milestone.color.opacity(0.15))
                        .frame(width: iconSize * 1.6, height: iconSize * 1.6)
                        .overlay {
                            Image(systemName: milestone.icon)
                                .font(.system(size: iconSize * 0.6))
                                .foregroundStyle(milestone.color)
                        }
                }

                Text(milestone.title)
                    .font(.appTitle2)
                    .foregroundStyle(.textPrimary)

                Text(milestone.message)
                    .font(.appBody)
                    .foregroundStyle(.textSecondary)
                    .multilineTextAlignment(.center)

                Button {
                    dismiss()
                } label: {
                    Text("Weiter")
                        .font(.appSubheadlineSemibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(milestone.color)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.buttonRadius, style: .continuous))
                }
            }
            .padding(28)
            .background(Color.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardRadius, style: .continuous))
            .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
            .padding(.horizontal, 32)
            .scaleEffect(isVisible ? 1 : 0.8)
            .opacity(isVisible ? 1 : 0)
        }
        .sensoryFeedback(.success, trigger: confettiTrigger)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                isVisible = true
            }
            // Trigger confetti fade-out
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                confettiTrigger = true
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeIn(duration: 0.2)) {
            isVisible = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }

    private func confettiColor(for index: Int) -> Color {
        let colors: [Color] = [.accent, .painAmber, .farBlue, .painGreen]
        return colors[index % colors.count]
    }

    private func confettiOffset(for index: Int) -> CGSize {
        let angle = Double(index) * (360.0 / 12.0) * .pi / 180.0
        let radius: Double = confettiTrigger ? 80 : 30
        return CGSize(width: cos(angle) * radius, height: sin(angle) * radius)
    }
}
