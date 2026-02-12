import SwiftUI

struct NdiProgressView: View {
    @Environment(APIClient.self) private var apiClient
    @State private var history: [NdiHistoryEntry] = []
    @State private var isLoading = true
    @State private var showRescreening = false

    var latestScore: Int? {
        history.first?.ndiScore
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "chart.xyaxis.line")
                    .font(.title3)
                    .foregroundStyle(.farBlue)
                Text("NDI-Verlauf")
                    .font(.headline)
                    .foregroundStyle(.textPrimary)
                Spacer()
            }

            if isLoading {
                ProgressView()
                    .padding(.vertical, 16)
            } else if history.isEmpty {
                Text("Noch keine Screening-Daten")
                    .font(.subheadline)
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
                    HStack(spacing: 12) {
                        // Score circle
                        Circle()
                            .fill(Color.severityColor(for: entry.severityGrade))
                            .frame(width: 32, height: 32)
                            .overlay {
                                Text("\(entry.ndiScore)")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white)
                            }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("NDI: \(entry.ndiScore)/50")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.textPrimary)
                            Text(entry.ndiCategory)
                                .font(.caption)
                                .foregroundStyle(.textSecondary)
                        }

                        Spacer()

                        if let date = entry.createdAtDate {
                            Text(date.formattedGerman)
                                .font(.caption)
                                .foregroundStyle(.textSecondary)
                        }
                    }
                    .padding(10)
                    .background(Color.appBg)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Rescreening button
                Button {
                    showRescreening = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Rescreening durchfuhren")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.accent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(Color.accent.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .sheet(isPresented: $showRescreening) {
                    NeckScreeningView(isRescreening: true)
                }
            }
        }
        .padding(16)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .task {
            await loadHistory()
        }
    }

    private func loadHistory() async {
        isLoading = true
        do {
            history = try await apiClient.request(APIEndpoints.neckHistory())
        } catch {
            history = []
        }
        isLoading = false
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
    }
}
