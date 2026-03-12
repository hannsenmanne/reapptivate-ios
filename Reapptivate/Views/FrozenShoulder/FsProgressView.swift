import SwiftUI

struct FsProgressView: View {
    @Environment(APIClient.self) private var apiClient
    @AppStorage("appLanguage") private var appLanguage = "de"
    @State private var history: [FsHistoryEntry] = []
    @State private var isLoading = true
    @State private var showRescreening = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "chart.xyaxis.line")
                    .font(.appTitle3)
                    .foregroundStyle(.accent)
                    .accessibilityHidden(true)
                Text(appLanguage == "en" ? "SPADI Progress" : "SPADI-Verlauf")
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)
                Spacer()
            }

            if isLoading {
                ProgressView(appLanguage == "en" ? "Loading SPADI progress..." : "SPADI-Verlauf laden...")
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
                    FsSparkline(entries: history)
                        .frame(height: 80)
                        .padding(.horizontal, 4)
                }

                // History entries
                ForEach(history) { entry in
                    FsHistoryRow(entry: entry)
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
                .sheet(isPresented: $showRescreening, onDismiss: {
                    Task { await loadHistory() }
                }) {
                    FsScreeningView(isRescreening: true)
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
            let response: FsHistoryResponse = try await apiClient.request(APIEndpoints.fsHistory())
            history = response.history
        } catch {
            errorMessage = appLanguage == "en" ? "Could not load SPADI progress." : "SPADI-Verlauf konnte nicht geladen werden."
        }
        isLoading = false
    }
}

// MARK: - FS History Row

private struct FsHistoryRow: View {
    let entry: FsHistoryEntry
    @AppStorage("appLanguage") private var appLanguage = "de"
    @ScaledMetric(relativeTo: .caption) private var scoreCircleSize: CGFloat = 32

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(entry.severityGrade.map { Color.severityColor(for: $0) } ?? Color.arGray)
                .frame(width: scoreCircleSize, height: scoreCircleSize)
                .overlay {
                    Text("\(Int(entry.spadiTotalScore))")
                        .font(.appCaptionBold)
                        .foregroundStyle(.white)
                }
                .accessibilityLabel(appLanguage == "en" ? "SPADI score \(Int(entry.spadiTotalScore))" : "SPADI-Score \(Int(entry.spadiTotalScore))")

            VStack(alignment: .leading, spacing: 2) {
                Text("SPADI: \(Int(entry.spadiTotalScore))%")
                    .font(.appSubheadlineMedium)
                    .foregroundStyle(.textPrimary)
                Text(entry.severityLabel ?? "")
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

// MARK: - FS Sparkline

struct FsSparkline: View {
    let entries: [FsHistoryEntry]

    private var scores: [Double] {
        entries.reversed().map(\.spadiTotalScore)
    }

    private var severities: [FsSeverityGrade] {
        entries.reversed().map { $0.severityGrade ?? FsSeverityGrade.from(spadiScore: $0.spadiTotalScore) }
    }

    private func xPos(_ index: Int, width: CGFloat) -> CGFloat {
        scores.count > 1 ? CGFloat(index) * width / CGFloat(scores.count - 1) : width / 2
    }

    private func yPos(_ score: Double, height: CGFloat, padding: CGFloat = 6) -> CGFloat {
        padding + (height - 2 * padding) * (1 - CGFloat(score) / 100.0)
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            Path { path in
                guard scores.count > 1 else { return }
                for (index, score) in scores.enumerated() {
                    let point = CGPoint(x: xPos(index, width: w), y: yPos(score, height: h))
                    if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
                }
            }
            .stroke(Color.accent, lineWidth: 2.5)

            ForEach(Array(scores.enumerated()), id: \.offset) { index, score in
                Circle()
                    .fill(Color.severityColor(for: severities[index]))
                    .frame(width: 8, height: 8)
                    .position(x: xPos(index, width: w), y: yPos(score, height: h))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("SPADI progress chart")
    }
}
