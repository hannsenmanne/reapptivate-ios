import SwiftUI

struct NdiProgressView: View {
    @Environment(APIClient.self) private var apiClient
    @AppStorage("appLanguage") private var appLanguage = "de"
    @State private var history: [NdiHistoryEntry] = []
    @State private var isLoading = true
    @State private var showRescreening = false
    @State private var errorMessage: String?

    var latestScore: Int? {
        history.first?.ndiScore
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "chart.xyaxis.line")
                    .font(.appTitle3)
                    .foregroundStyle(.farBlue)
                    .accessibilityHidden(true)
                Text(appLanguage == "en" ? "NDI Progress" : "NDI-Verlauf")
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)
                Spacer()
            }

            if isLoading {
                ProgressView(appLanguage == "en" ? "Loading NDI progress..." : "NDI-Verlauf laden...")
                    .padding(.vertical, 16)
            } else if let error = errorMessage {
                InlineErrorView(
                    message: error,
                    errorType: .network,
                    onRetry: {
                        Task { await loadHistory() }
                    }
                )
            } else if history.isEmpty {
                Text(appLanguage == "en" ? "No screening data yet" : "Noch keine Screening-Daten")
                    .font(.appSubheadline)
                    .foregroundStyle(.textSecondary)
                    .padding(.vertical, 16)
            } else {
                // Score sparkline
                if history.count > 1 {
                    NdiSparkline(entries: history)
                        .frame(height: 80)
                        .padding(.horizontal, 4)
                }

                // History entries
                ForEach(history) { entry in
                    NdiHistoryRow(entry: entry)
                }

                // Rescreening button
                Button {
                    showRescreening = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text(appLanguage == "en" ? "Perform rescreening" : "Rescreening durchführen")
                    }
                    .font(.appSubheadlineMedium)
                    .foregroundStyle(.accent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(Color.accent.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.buttonRadius, style: .continuous))
                }
                .sheet(isPresented: $showRescreening) {
                    NeckScreeningView(isRescreening: true)
                        .glassSheet()
                }
            }
        }
        .cardStyle()
        .task {
            await loadHistory()
        }
    }

    private func loadHistory() async {
        isLoading = true
        errorMessage = nil
        do {
            let response: NeckHistoryResponse = try await apiClient.request(APIEndpoints.neckHistory())
            history = response.history
        } catch {
            errorMessage = appLanguage == "en" ? "Could not load NDI progress." : "NDI-Verlauf konnte nicht geladen werden."
        }
        isLoading = false
    }
}

// MARK: - NDI History Row

private struct NdiHistoryRow: View {
    let entry: NdiHistoryEntry
    @AppStorage("appLanguage") private var appLanguage = "de"
    @ScaledMetric(relativeTo: .caption) private var scoreCircleSize: CGFloat = 32

    var body: some View {
        HStack(spacing: 12) {
            // Score circle
            Circle()
                .fill(entry.severityGrade.map { Color.severityColor(for: $0) } ?? Color.arGray)
                .frame(width: scoreCircleSize, height: scoreCircleSize)
                .overlay {
                    Text("\(entry.ndiScore)")
                        .font(.appCaptionBold)
                        .foregroundStyle(.white)
                }
                .accessibilityLabel(appLanguage == "en" ? "NDI score \(entry.ndiScore)" : "NDI-Score \(entry.ndiScore)")

            VStack(alignment: .leading, spacing: 2) {
                Text("NDI: \(entry.ndiScore)/50")
                    .font(.appSubheadlineMedium)
                    .foregroundStyle(.textPrimary)
                Text(entry.ndiCategory ?? "")
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
            }

            Spacer()

            if let date = entry.createdAtDate {
                Text(date.formattedLocalizedLong)
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
            }
        }
        .padding(10)
        .background(Color.appBg)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.smallRadius, style: .continuous))
    }
}

// MARK: - NDI Sparkline

struct NdiSparkline: View {
    let entries: [NdiHistoryEntry]

    var body: some View {
        GeometryReader { geo in
            let scores = entries.reversed().map(\.ndiScore)
            let width = geo.size.width
            let height = geo.size.height
            let maxScore = 50.0

            Path { path in
                guard scores.count > 1 else { return }
                let stepX = width / CGFloat(scores.count - 1)

                for (index, score) in scores.enumerated() {
                    let x = CGFloat(index) * stepX
                    let y = height - (CGFloat(score) / CGFloat(maxScore) * height)

                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(Color.farBlue, lineWidth: 2.5)

            // Data points
            ForEach(Array(scores.enumerated()), id: \.offset) { index, score in
                let stepX = width / CGFloat(max(1, scores.count - 1))
                let x = CGFloat(index) * stepX
                let y = height - (CGFloat(score) / maxScore * height)

                Circle()
                    .fill(Color.severityColor(for: NdiSeverityGrade.from(ndiScore: score)))
                    .frame(width: 8, height: 8)
                    .position(x: x, y: y)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("NDI progress chart")
    }
}
