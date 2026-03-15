import SwiftUI

// MARK: - Configuration

struct FocusAreasConfig<Area: FocusAreaProtocol> {
    let fetchAreas: @Sendable (APIClient) async throws -> [Area]
}

extension FocusAreasConfig where Area == NdiFocusArea {
    static var neck: FocusAreasConfig {
        FocusAreasConfig { apiClient in
            let response: NeckFocusAreasResponse = try await apiClient.request(APIEndpoints.neckFocusAreas())
            return response.focusAreas
        }
    }
}

extension FocusAreasConfig where Area == TsiFocusArea {
    static var tension: FocusAreasConfig {
        FocusAreasConfig { apiClient in
            let response: TsiFocusAreasResponse = try await apiClient.request(APIEndpoints.tensionFocusAreas())
            return response.focusAreas
        }
    }
}

extension FocusAreasConfig where Area == SiFocusArea {
    static var shoulder: FocusAreasConfig {
        FocusAreasConfig { apiClient in
            let response: SiFocusAreasResponse = try await apiClient.request(APIEndpoints.siFocusAreas())
            return response.focusAreas
        }
    }
}

extension FocusAreasConfig where Area == FsFocusArea {
    static var frozenShoulder: FocusAreasConfig {
        FocusAreasConfig { apiClient in
            let response: FsFocusAreasResponse = try await apiClient.request(APIEndpoints.fsFocusAreas())
            return response.focusAreas
        }
    }
}

extension FocusAreasConfig where Area == LasFocusArea {
    static var lateralAnkleSprain: FocusAreasConfig {
        FocusAreasConfig { apiClient in
            let response: LasFocusAreasResponse = try await apiClient.request(APIEndpoints.lasFocusAreas())
            return response.focusAreas
        }
    }
}

// MARK: - Generic Focus Areas View

struct ConditionFocusAreasView<Area: FocusAreaProtocol>: View {
    @Environment(APIClient.self) private var apiClient
    @AppStorage("appLanguage") private var appLanguage = "de"
    @State private var focusAreas: [Area] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    let config: FocusAreasConfig<Area>

    private var isEn: Bool { appLanguage == "en" }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "scope")
                    .font(.appTitle3)
                    .foregroundStyle(.farBlue)
                    .accessibilityHidden(true)
                Text(isEn ? "Focus Areas" : "Schwerpunktbereiche")
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)
                Spacer()
            }

            if isLoading {
                ProgressView(isEn ? "Loading focus areas..." : "Schwerpunkte laden...")
                    .padding(.vertical, 16)
            } else if let error = errorMessage {
                InlineErrorView(
                    message: error,
                    errorType: .network,
                    onRetry: { Task { await loadFocusAreas() } }
                )
            } else if focusAreas.isEmpty {
                Text(isEn ? "No focus areas available" : "Keine Schwerpunktbereiche verfügbar")
                    .font(.appSubheadline)
                    .foregroundStyle(.textSecondary)
                    .padding(.vertical, 16)
            } else {
                ForEach(focusAreas) { area in
                    FocusAreaRow(area: area)
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
            focusAreas = try await config.fetchAreas(apiClient)
        } catch {
            errorMessage = isEn ? "Could not load focus areas." : "Schwerpunkte konnten nicht geladen werden."
        }
        isLoading = false
    }
}

// MARK: - Shared Focus Area Row

struct FocusAreaRow<Area: FocusAreaProtocol>: View {
    let area: Area
    @ScaledMetric(relativeTo: .caption) private var areaIconSize: CGFloat = 24

    private var areaIcon: String {
        let domain = area.domainLabel.lowercased()
        // Superset of all condition-specific icon mappings
        if domain.contains("schmerz") || domain.contains("pain") { return "waveform.path.ecg" }
        if domain.contains("konzentration") || domain.contains("read") { return "book" }
        if domain.contains("kopfschmerz") || domain.contains("head") { return "brain.head.profile" }
        if domain.contains("heben") || domain.contains("lift") { return "arrow.up.circle" }
        if domain.contains("nacken") || domain.contains("neck") { return "figure.mind.and.body" }
        if domain.contains("schulter") || domain.contains("shoulder") { return "figure.arms.open" }
        if domain.contains("kraft") || domain.contains("strength") { return "figure.strengthtraining.traditional" }
        if domain.contains("knöchel") || domain.contains("ankle") { return "figure.walk" }
        if domain.contains("gleichgewicht") || domain.contains("balance") { return "figure.cooldown" }
        if domain.contains("steifigkeit") || domain.contains("stiff") { return "arrow.triangle.2.circlepath" }
        if domain.contains("arbeit") || domain.contains("work") { return "briefcase" }
        if domain.contains("auto") || domain.contains("driv") { return "car" }
        if domain.contains("schlaf") || domain.contains("sleep") { return "moon.fill" }
        if domain.contains("freizeit") || domain.contains("recr") { return "figure.walk" }
        if domain.contains("pflege") || domain.contains("care") { return "heart" }
        if domain.contains("haltung") || domain.contains("posture") { return "figure.stand" }
        if domain.contains("stress") { return "bolt.heart" }
        if domain.contains("sport") { return "sportscourt" }
        if domain.contains("kribbeln") || domain.contains("tingling") { return "hand.raised" }
        if domain.contains("schwellung") || domain.contains("swell") { return "drop.fill" }
        if domain.contains("treppen") || domain.contains("stair") { return "figure.stairs" }
        return "circle.fill"
    }

    private var scoreColor: Color {
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
