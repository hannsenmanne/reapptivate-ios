import SwiftUI

struct TensionFocusAreasView: View {
    @Environment(APIClient.self) private var apiClient
    @AppStorage("appLanguage") private var appLanguage = "de"
    @State private var focusAreas: [TsiFocusArea] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "scope")
                    .font(.appTitle3)
                    .foregroundStyle(.farBlue)
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
                    TsiFocusAreaRow(area: area)
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
            let response: TsiFocusAreasResponse = try await apiClient.request(APIEndpoints.tensionFocusAreas())
            focusAreas = response.focusAreas
        } catch {
            errorMessage = appLanguage == "en" ? "Could not load focus areas." : "Schwerpunkte konnten nicht geladen werden."
        }
        isLoading = false
    }
}

// MARK: - TSI Focus Area Row

struct TsiFocusAreaRow: View {
    let area: TsiFocusArea
    @ScaledMetric(relativeTo: .caption) private var areaIconSize: CGFloat = 24

    var areaIcon: String {
        let domain = area.domainLabel.lowercased()
        if domain.contains("schmerz") || domain.contains("pain") { return "waveform.path.ecg" }
        if domain.contains("nacken") || domain.contains("neck") { return "figure.mind.and.body" }
        if domain.contains("schulter") || domain.contains("shoulder") { return "figure.arms.open" }
        if domain.contains("kopfschmerz") || domain.contains("head") { return "brain.head.profile" }
        if domain.contains("schlaf") || domain.contains("sleep") { return "moon.fill" }
        if domain.contains("stress") { return "bolt.heart" }
        if domain.contains("arbeit") || domain.contains("work") { return "briefcase" }
        if domain.contains("freizeit") || domain.contains("recr") { return "figure.walk" }
        if domain.contains("haltung") || domain.contains("posture") { return "figure.stand" }
        return "circle.fill"
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
                    .foregroundStyle(.farBlue)
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

            // Progress bar
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

            // Tips
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
