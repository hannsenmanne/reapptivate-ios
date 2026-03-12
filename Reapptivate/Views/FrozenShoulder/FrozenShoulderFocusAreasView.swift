import SwiftUI

struct FrozenShoulderFocusAreasView: View {
    @Environment(APIClient.self) private var apiClient
    @AppStorage("appLanguage") private var appLanguage = "de"
    @State private var focusAreas: [FsFocusArea] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "scope")
                    .font(.appTitle3)
                    .foregroundStyle(.accent)
                    .accessibilityHidden(true)
                Text(appLanguage == "en" ? "Focus Areas" : "Schwerpunktbereiche")
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)
                Spacer()
            }

            if isLoading {
                ProgressView(appLanguage == "en" ? "Loading focus areas..." : "Schwerpunkte laden...")
                    .padding(.vertical, 16)
            } else if let error = errorMessage {
                InlineErrorView(
                    message: error,
                    errorType: .network,
                    onRetry: {
                        Task { await loadFocusAreas() }
                    }
                )
            } else if focusAreas.isEmpty {
                Text(appLanguage == "en" ? "No focus areas available" : "Keine Schwerpunktbereiche verfügbar")
                    .font(.appSubheadline)
                    .foregroundStyle(.textSecondary)
                    .padding(.vertical, 16)
            } else {
                ForEach(focusAreas) { area in
                    FsFocusAreaRow(area: area)
                }
            }
        }
        .cardStyle()
        .task {
            await loadFocusAreas()
        }
    }

    private func loadFocusAreas() async {
        isLoading = true
        errorMessage = nil
        do {
            let response: FsFocusAreasResponse = try await apiClient.request(APIEndpoints.fsFocusAreas())
            focusAreas = response.focusAreas
        } catch {
            errorMessage = appLanguage == "en" ? "Could not load focus areas." : "Schwerpunkte konnten nicht geladen werden."
        }
        isLoading = false
    }
}

// MARK: - FS Focus Area Row

struct FsFocusAreaRow: View {
    let area: FsFocusArea
    @ScaledMetric(relativeTo: .caption) private var areaIconSize: CGFloat = 24

    var areaIcon: String {
        let domain = area.domainLabel.lowercased()
        if domain.contains("schmerz") || domain.contains("pain") { return "waveform.path.ecg" }
        if domain.contains("schulter") || domain.contains("shoulder") { return "figure.arms.open" }
        if domain.contains("kraft") || domain.contains("strength") { return "figure.strengthtraining.traditional" }
        if domain.contains("arbeit") || domain.contains("work") { return "briefcase" }
        if domain.contains("freizeit") || domain.contains("recr") { return "figure.walk" }
        if domain.contains("sport") { return "sportscourt" }
        if domain.contains("schlaf") || domain.contains("sleep") { return "moon.fill" }
        if domain.contains("kribbeln") || domain.contains("tingling") { return "hand.raised" }
        if domain.contains("tragen") || domain.contains("carry") || domain.contains("heben") { return "bag" }
        if domain.contains("haar") || domain.contains("hair") || domain.contains("anzieh") { return "comb" }
        if domain.contains("alltag") || domain.contains("daily") { return "house" }
        if domain.contains("beweglich") || domain.contains("rom") || domain.contains("beweg") { return "arrow.up.left.and.arrow.down.right" }
        if domain.contains("kopf") || domain.contains("nacken") { return "figure.mind.and.body" }
        return "figure.arms.open"
    }

    var scoreColor: Color {
        let pct = area.percentage
        if pct <= 30 { return .painGreen }
        if pct <= 60 { return .painAmber }
        return .painRed
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: areaIcon)
                    .font(.appCaption)
                    .foregroundStyle(.accent)
                    .frame(width: areaIconSize, height: areaIconSize)
                    .accessibilityHidden(true)

                Text(area.domainLabel)
                    .font(.appSubheadline)
                    .foregroundStyle(.textPrimary)

                Spacer()

                Text("\(area.score)/\(area.maxScore)")
                    .font(.appCaptionBold.monospacedDigit())
                    .foregroundStyle(scoreColor)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: DesignTokens.progressBarRadius)
                        .fill(Color.textSecondary.opacity(0.12))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: DesignTokens.progressBarRadius)
                        .fill(scoreColor)
                        .frame(width: geo.size.width * CGFloat(area.percentage) / 100, height: 6)
                }
            }
            .frame(height: 6)

            if let tips = area.dailyTips, let tip = tips.first {
                Text(tip)
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(10)
        .background(Color.appBg)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.smallRadius, style: .continuous))
    }
}
