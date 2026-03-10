import SwiftUI

struct SiProgressView: View {
    @Environment(APIClient.self) private var apiClient
    @State private var history: [SiHistoryEntry] = []
    @State private var isLoading = true
    @State private var showRescreening = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "chart.xyaxis.line")
                    .font(.appTitle3)
                    .foregroundStyle(.farBlue)
                    .accessibilityHidden(true)
                Text("QuickDASH-Verlauf")
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)
                Spacer()
            }

            if isLoading {
                ProgressView("QuickDASH-Verlauf laden...")
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
                Text("Noch keine Screening-Daten")
                    .font(.appSubheadline)
                    .foregroundStyle(.textSecondary)
                    .padding(.vertical, 16)
            } else {
                // Score sparkline
                if history.count > 1 {
                    SiSparkline(entries: history)
                        .frame(height: 80)
                        .padding(.horizontal, 4)
                }

                // History entries
                ForEach(history) { entry in
                    SiHistoryRow(entry: entry)
                }

                // Rescreening button
                Button {
                    showRescreening = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Rescreening durchführen")
                    }
                    .font(.appSubheadlineMedium)
                    .foregroundStyle(.accent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(Color.accent.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.buttonRadius, style: .continuous))
                }
                .sheet(isPresented: $showRescreening) {
                    SiScreeningView(isRescreening: true)
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
            let response: SiHistoryResponse = try await apiClient.request(APIEndpoints.siHistory())
            history = response.history
        } catch {
            errorMessage = "QuickDASH-Verlauf konnte nicht geladen werden."
        }
        isLoading = false
    }
}

// MARK: - SI History Row

private struct SiHistoryRow: View {
    let entry: SiHistoryEntry
    @ScaledMetric(relativeTo: .caption) private var scoreCircleSize: CGFloat = 32

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(entry.severityGrade.map { Color.severityColor(for: $0) } ?? Color.arGray)
                .frame(width: scoreCircleSize, height: scoreCircleSize)
                .overlay {
                    Text("\(Int(entry.quickDashScore))")
                        .font(.appCaptionBold)
                        .foregroundStyle(.white)
                }
                .accessibilityLabel("QuickDASH-Score \(Int(entry.quickDashScore))")

            VStack(alignment: .leading, spacing: 2) {
                Text("QuickDASH: \(Int(entry.quickDashScore))%")
                    .font(.appSubheadlineMedium)
                    .foregroundStyle(.textPrimary)
                Text(entry.severityLabel ?? "")
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
            }

            Spacer()

            if let date = entry.createdAtDate {
                Text(date.formattedGerman)
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
            }
        }
        .padding(10)
        .background(Color.appBg)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.smallRadius, style: .continuous))
    }
}

// MARK: - SI Sparkline

struct SiSparkline: View {
    let entries: [SiHistoryEntry]

    var body: some View {
        GeometryReader { geo in
            let scores = entries.reversed().map(\.quickDashScore)
            let width = geo.size.width
            let height = geo.size.height
            let maxScore = 100.0

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
                    .fill(Color.severityColor(for: SiSeverityGrade.from(quickDashScore: score)))
                    .frame(width: 8, height: 8)
                    .position(x: x, y: y)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("QuickDASH-Verlaufsdiagramm")
    }
}
