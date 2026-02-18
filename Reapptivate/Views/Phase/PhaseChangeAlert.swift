import SwiftUI

struct PhaseChangeAlert: View {
    let result: AdaptationResult
    let phaseName: String
    let onDismiss: () -> Void

    @State private var isVisible = false
    @State private var confettiTrigger = false
    @State private var hapticTrigger = false

    var isProgress: Bool { result.decision == .progress }

    var body: some View {
        VStack {
            ZStack {
                // Confetti ring for progress
                if isProgress {
                    ForEach(0..<12, id: \.self) { i in
                        Circle()
                            .fill(confettiColor(for: i))
                            .frame(width: 6, height: 6)
                            .offset(confettiOffset(for: i))
                            .opacity(confettiTrigger ? 0 : 1)
                            .animation(
                                .easeOut(duration: 1.0).delay(Double(i) * 0.04),
                                value: confettiTrigger
                            )
                    }
                }

                HStack(spacing: 12) {
                    Image(systemName: isProgress ? "arrow.up.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.appTitle2)
                        .foregroundStyle(isProgress ? .painGreen : .painAmber)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(isProgress ? "Phase aufgestiegen!" : "Phase angepasst")
                            .font(.appSubheadlineSemibold)
                            .foregroundStyle(.white)
                        Text(phaseName)
                            .font(.appCaption)
                            .foregroundStyle(.white.opacity(0.8))
                    }

                    Spacer()

                    Button {
                        withAnimation(.easeIn(duration: 0.2)) {
                            isVisible = false
                        }
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(200))
                            onDismiss()
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .padding(16)
                .background(isProgress ? Color(hex: "1A1A1A") : Color.painAmber)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardRadius, style: .continuous))
                .padding(.horizontal, 16)
            }

            Spacer()
        }
        .scaleEffect(isVisible ? 1 : 0.5)
        .opacity(isVisible ? 1 : 0)
        .conditionalHaptic(isProgress ? .success : .warning, trigger: hapticTrigger)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                isVisible = true
            }
            hapticTrigger.toggle()
            if isProgress {
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(300))
                    confettiTrigger = true
                }
            }
        }
    }

    private func confettiColor(for index: Int) -> Color {
        let colors: [Color] = [.accent, .painAmber, .farBlue, .painGreen]
        return colors[index % colors.count]
    }

    private func confettiOffset(for index: Int) -> CGSize {
        let angle = Double(index) * (360.0 / 12.0) * .pi / 180.0
        let radius: Double = confettiTrigger ? 60 : 20
        return CGSize(width: cos(angle) * radius, height: sin(angle) * radius)
    }
}
