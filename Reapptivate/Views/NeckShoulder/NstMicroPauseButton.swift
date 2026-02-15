import SwiftUI

struct NstMicroPauseButton: View {
    let stats: NstMicroPauseStats?
    let accentColor: Color
    let isLogging: Bool
    let onLog: () -> Void

    private var completed: Int { stats?.completed ?? 0 }
    private var target: Int { stats?.target ?? 8 }

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Image(systemName: "timer")
                    .foregroundStyle(accentColor)
                Text("Mikro-Pausen heute")
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)
                Spacer()
                Text("\(completed)/\(target)")
                    .font(.appCaptionBold)
                    .foregroundStyle(completed >= target ? .painGreen : .textSecondary)
            }

            // Progress ring
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Color.gray200, lineWidth: 6)
                        .frame(width: 56, height: 56)

                    Circle()
                        .trim(from: 0, to: ringProgress)
                        .stroke(accentColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 56, height: 56)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(duration: 0.4), value: completed)

                    Text("\(completed)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.textPrimary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    if completed >= target {
                        Text("Tagesziel erreicht!")
                            .font(.appSubheadlineMedium)
                            .foregroundStyle(.painGreen)
                    } else {
                        Text("Noch \(target - completed) Pausen übrig")
                            .font(.appSubheadlineMedium)
                            .foregroundStyle(.textSecondary)
                    }
                    Text("Empfohlen: alle \(target > 0 ? 60 : 45) Minuten")
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                }

                Spacer()
            }

            // Log button
            Button(action: onLog) {
                HStack(spacing: 8) {
                    if isLogging {
                        ProgressView().controlSize(.small).tint(.white)
                    } else {
                        Image(systemName: "plus.circle.fill")
                    }
                    Text("Mikro-Pause erfassen")
                }
                .font(.appSubheadlineMedium)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(accentColor)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.buttonRadius, style: .continuous))
            }
            .disabled(isLogging)
        }
        .cardStyle()
    }

    private var ringProgress: Double {
        guard target > 0 else { return 0 }
        return min(Double(completed) / Double(target), 1.0)
    }
}
