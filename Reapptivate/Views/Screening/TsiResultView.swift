import SwiftUI

struct TsiResultView: View {
    let result: TsiScreeningResult
    let onContinue: () -> Void

    var severity: TsiSeverityGrade {
        TsiSeverityGrade.from(tsiScore: result.tsiScore)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Score display
                VStack(spacing: 12) {
                    Circle()
                        .fill(Color.severityColor(for: severity))
                        .frame(width: 72, height: 72)
                        .overlay {
                            Text("\(result.tsiScore)")
                                .font(.appTitle)
                                .foregroundStyle(.white)
                        }

                    Text("TSI-Score: \(result.tsiScore)/50")
                        .font(.appTitle3)
                        .foregroundStyle(.textPrimary)

                    Text(severity.displayName)
                        .font(.appHeadline)
                        .foregroundStyle(Color.severityColor(for: severity))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.severityColor(for: severity).opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.badgeRadius, style: .continuous))
                }
                .padding(.top, 32)

                // Severity description
                VStack(alignment: .leading, spacing: 12) {
                    Text("Ihre Einstufung")
                        .font(.appHeadline)
                        .foregroundStyle(.textPrimary)

                    Text(severityDescription)
                        .font(.appBody)
                        .foregroundStyle(.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()

                // Continue button
                Button {
                    onContinue()
                } label: {
                    Text("Weiter zum Dashboard")
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                }
                .buttonStyle(.accentFilled)
            }
            .padding(24)
        }
        .background(Color.appBg)
    }

    var severityDescription: String {
        switch severity {
        case .LEICHT:
            "Leichte Verspannung. Ihr Programm folgt der Standard-Progression mit Fokus auf Entspannung und Mobilisation."
        case .MITTEL:
            "Moderate Verspannung. Ihr Programm enthält angepasste Übungen mit langsamerer Steigerung und gezielter Entspannung."
        case .SCHWER, .unknown:
            "Deutliche Verspannung. Ihr Programm beginnt sanft mit verlängerten Entspannungsphasen und reduzierter Belastung."
        }
    }
}
