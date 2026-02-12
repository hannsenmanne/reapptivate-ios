import SwiftUI

struct NeckFocusAreasView: View {
    @Environment(APIClient.self) private var apiClient
    @State private var focusAreas: [NdiFocusArea] = []
    @State private var isLoading = true

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "scope")
                    .font(.title3)
                    .foregroundStyle(.farBlue)
                Text("Schwerpunktbereiche")
                    .font(.headline)
                    .foregroundStyle(.textPrimary)
                Spacer()
            }

            if isLoading {
                ProgressView()
                    .padding(.vertical, 16)
            } else if focusAreas.isEmpty {
                Text("Keine Schwerpunktbereiche verfugbar")
                    .font(.subheadline)
                    .foregroundStyle(.textSecondary)
                    .padding(.vertical, 16)
            } else {
                ForEach(focusAreas) { area in
                    FocusAreaRow(area: area)
                }
            }
        }
        .padding(16)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .task {
            await loadFocusAreas()
        }
    }

    private func loadFocusAreas() async {
        isLoading = true
        do {
            focusAreas = try await apiClient.request(APIEndpoints.neckFocusAreas())
        } catch {
            focusAreas = []
        }
        isLoading = false
    }
}

// MARK: - Focus Area Row

struct FocusAreaRow: View {
    let area: NdiFocusArea

    var areaIcon: String {
        let domain = area.domainLabel.lowercased()
        if domain.contains("schmerz") || domain.contains("pain") { return "waveform.path.ecg" }
        if domain.contains("konzentration") || domain.contains("read") { return "book" }
        if domain.contains("kopfschmerz") || domain.contains("head") { return "brain.head.profile" }
        if domain.contains("heben") || domain.contains("lift") { return "arrow.up.circle" }
        if domain.contains("arbeit") || domain.contains("work") { return "briefcase" }
        if domain.contains("auto") || domain.contains("driv") { return "car" }
        if domain.contains("schlaf") || domain.contains("sleep") { return "moon.fill" }
        if domain.contains("freizeit") || domain.contains("recr") { return "figure.walk" }
        if domain.contains("pflege") || domain.contains("care") { return "heart" }
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
                    .font(.caption)
                    .foregroundStyle(.farBlue)
                    .frame(width: 24, height: 24)

                Text(area.domainLabel)
                    .font(.subheadline)
                    .foregroundStyle(.textPrimary)

                Spacer()

                Text("\(area.score)/5")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(scoreColor)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.textSecondary.opacity(0.12))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(scoreColor)
                        .frame(width: geo.size.width * CGFloat(area.percentage) / 100, height: 6)
                }
            }
            .frame(height: 6)

            // Tips
            if let tips = area.dailyTips, let tip = tips.first {
                Text(tip)
                    .font(.caption)
                    .foregroundStyle(.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(10)
        .background(Color.appBg)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
