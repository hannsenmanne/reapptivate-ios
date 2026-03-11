import SwiftUI

struct LateralAnkleSprainFocusAreasView: View {
    @Environment(APIClient.self) private var apiClient
    @State private var focusAreas: [LasFocusArea] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "scope")
                    .font(.appTitle3)
                    .foregroundStyle(.accent)
                    .accessibilityHidden(true)
                Text("Schwerpunktbereiche")
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)
                Spacer()
            }

            if isLoading {
                ProgressView("Schwerpunkte laden...")
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
                Text("Keine Schwerpunktbereiche verfügbar")
                    .font(.appSubheadline)
                    .foregroundStyle(.textSecondary)
                    .padding(.vertical, 16)
            } else {
                ForEach(focusAreas) { area in
                    LasFocusAreaRow(area: area)
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
            let response: LasFocusAreasResponse = try await apiClient.request(APIEndpoints.lasFocusAreas())
            focusAreas = response.focusAreas
        } catch {
            errorMessage = "Schwerpunkte konnten nicht geladen werden."
        }
        isLoading = false
    }
}

// MARK: - LAS Focus Area Row

struct LasFocusAreaRow: View {
    let area: LasFocusArea
    @ScaledMetric(relativeTo: .caption) private var areaIconSize: CGFloat = 24

    var areaIcon: String {
        let domain = area.domainLabel.lowercased()
        if domain.contains("schmerz") || domain.contains("pain") { return "waveform.path.ecg" }
        if domain.contains("instabil") || domain.contains("nachgeb") { return "arrow.up.and.down.and.arrow.left.and.right" }
        if domain.contains("richtung") || domain.contains("lateral") { return "arrow.left.and.right" }
        if domain.contains("trepp") || domain.contains("stair") { return "stairs" }
        if domain.contains("einbein") || domain.contains("stand") { return "figure.stand" }
        if domain.contains("hüpf") || domain.contains("sprung") || domain.contains("hop") { return "figure.jumprope" }
        if domain.contains("spring") || domain.contains("land") { return "figure.basketball" }
        if domain.contains("uneben") || domain.contains("gelände") || domain.contains("terrain") { return "figure.hiking" }
        if domain.contains("gewicht") || domain.contains("verlager") || domain.contains("shift") { return "figure.walk" }
        return "figure.walk"
    }

    var scoreColor: Color {
        // CAIT is inverted: high percentage = high problem
        let pct = area.percentage
        if pct >= 70 { return .painRed }
        if pct >= 40 { return .painAmber }
        return .painGreen
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
