import SwiftUI

private var isEnglishLocale: Bool {
    UserDefaults.standard.string(forKey: "appLanguage") == "en"
}

struct AclMilestoneCelebrationView: View {
    let milestone: Int
    let onDismiss: () -> Void

    @AppStorage("appLanguage") private var appLanguage = "de"
    @State private var isVisible = false
    @State private var confettiTrigger = false

    var body: some View {
        VStack {
            ZStack {
                // Confetti ring
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

                HStack(spacing: 12) {
                    Image(systemName: "trophy.fill")
                        .font(.appTitle2)
                        .foregroundStyle(.painAmber)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(isEnglishLocale
                            ? "Milestone \(milestone) reached!"
                            : "Meilenstein \(milestone) erreicht!")
                            .font(.appSubheadlineSemibold)
                            .foregroundStyle(.white)
                        Text(milestoneDescription(for: milestone))
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
                .background(Color(hex: "1A1A1A"))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardRadius, style: .continuous))
                .padding(.horizontal, 16)
            }

            Spacer()
        }
        .scaleEffect(isVisible ? 1 : 0.5)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                isVisible = true
            }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(300))
                confettiTrigger = true
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

    private func milestoneDescription(for milestone: Int) -> String {
        if isEnglishLocale {
            switch milestone {
            case 1: return "Early rehabilitation completed"
            case 2: return "Building phase reached"
            case 3: return "Functional phase reached"
            case 4: return "Return-to-Sport phase"
            case 5: return "Full clearance"
            default: return "Keep going!"
            }
        }
        switch milestone {
        case 1: return "Frührehabilitation abgeschlossen"
        case 2: return "Aufbauphase erreicht"
        case 3: return "Funktionelle Phase erreicht"
        case 4: return "Return-to-Sport Phase"
        case 5: return "Vollständige Freigabe"
        default: return "Weiter so!"
        }
    }
}
