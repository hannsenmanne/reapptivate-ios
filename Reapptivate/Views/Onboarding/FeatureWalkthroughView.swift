import SwiftUI

struct FeatureWalkthroughView: View {
    @AppStorage("hasSeenWalkthrough") private var hasSeenWalkthrough = false
    @State private var currentPage = 0

    private let pages: [WalkthroughPage] = [
        WalkthroughPage(
            icon: "chart.bar.fill",
            iconColor: .accent,
            title: "Ihr Dashboard",
            description: "Sehen Sie Ihren Fortschritt auf einen Blick -- Trainingsserie, Phase und Statistiken."
        ),
        WalkthroughPage(
            icon: "figure.strengthtraining.traditional",
            iconColor: .farBlue,
            title: "Übungsprogramm",
            description: "Individuell angepasste Übungen mit Timer, Satz-Tracking und Schmerzprotokoll."
        ),
        WalkthroughPage(
            icon: "book.fill",
            iconColor: .painAmber,
            title: "Edukation",
            description: "Lernen Sie mehr über Ihre Beschwerden mit täglichen Wissenskarten und Mikro-Modulen."
        ),
        WalkthroughPage(
            icon: "chart.line.uptrend.xyaxis",
            iconColor: .painGreen,
            title: "Fortschritt verfolgen",
            description: "Verfolgen Sie Ihre Schmerzentwicklung, Compliance und Phasen-Progression."
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Skip button
            HStack {
                Spacer()
                Button("Überspringen") {
                    hasSeenWalkthrough = true
                }
                .font(.appSubheadlineMedium)
                .foregroundStyle(.textSecondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            // Pages
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    VStack(spacing: 24) {
                        Spacer()

                        // Icon circle
                        Circle()
                            .fill(page.iconColor.opacity(0.12))
                            .frame(width: 100, height: 100)
                            .overlay {
                                Image(systemName: page.icon)
                                    .font(.system(size: 40))
                                    .foregroundStyle(page.iconColor)
                            }

                        Text(page.title)
                            .font(.appTitle)
                            .foregroundStyle(.textPrimary)

                        Text(page.description)
                            .font(.appBody)
                            .foregroundStyle(.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)

                        Spacer()
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: currentPage)

            // Page indicators
            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? Color.accent : Color.textSecondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.bottom, 24)

            // Button
            Button {
                if currentPage < pages.count - 1 {
                    withAnimation { currentPage += 1 }
                } else {
                    hasSeenWalkthrough = true
                }
            } label: {
                Text(currentPage < pages.count - 1 ? "Weiter" : "Los geht's")
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
            }
            .buttonStyle(.accentFilled)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Color.appBg)
    }
}

private struct WalkthroughPage {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
}
