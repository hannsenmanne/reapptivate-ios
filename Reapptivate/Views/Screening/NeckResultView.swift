import SwiftUI

struct NeckResultView: View {
    let result: NeckScreeningResult
    let onContinue: () -> Void

    var severity: NdiSeverityGrade {
        NdiSeverityGrade.from(ndiScore: result.ndiScore)
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
                            Text("\(result.ndiScore)")
                                .font(.appTitle)
                                .foregroundStyle(.white)
                        }

                    Text("NDI-Score: \(result.ndiScore)/50")
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

                    Text(result.ndiCategory)
                        .font(.appSubheadlineMedium)
                        .foregroundStyle(.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()

                // Subtype result
                if result.subtype == "NECK_RADICULOPATHY" {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(.painAmber)
                        Text("Radiculopathie erkannt. Ihr Ubungsprogramm ist entsprechend angepasst.")
                            .font(.appSubheadline)
                            .foregroundStyle(.textPrimary)
                    }
                    .infoBoxStyle(color: .painAmber)
                }

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
            "Leichte Einschrankung. Ihr Programm folgt der Standard-Ubungsprogression mit allen Intensitatsstufen."
        case .MITTEL:
            "Moderate Einschrankung. Ihr Programm enthalt angepasste Ubungen mit langsamerer Steigerung."
        case .SCHWER:
            "Deutliche Einschrankung. Ihr Programm beginnt sanft mit verlangerten Phasen und reduzierter Belastung."
        }
    }
}
