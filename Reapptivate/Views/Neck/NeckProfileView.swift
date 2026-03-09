import SwiftUI

struct NeckProfileView: View {
    let severity: NdiSeverityGrade
    let neckSubtype: NeckSubtype?

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Severity badge
                Circle()
                    .fill(Color.severityColor(for: severity))
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: severityIcon)
                            .font(.appTitle3)
                            .foregroundStyle(.white)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text("NDI-Schweregrad")
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                    Text(severity.displayName)
                        .font(.appHeadline)
                        .foregroundStyle(Color.severityColor(for: severity))
                }

                Spacer()

                // Severity pill
                Text(severityLabel)
                    .font(.outfit(.medium, size: 11))
                    .foregroundStyle(Color.severityColor(for: severity))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.severityColor(for: severity).opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.badgeRadius, style: .continuous))
            }

            // Subtype info
            if let subtype = neckSubtype, subtype == .neckRadiculopathy {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.painAmber)
                    Text("Radiculopathie — angepasstes Programm")
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                }
                .infoBoxStyle(color: .painAmber)
            }

            // Description
            Text(severityDescription)
                .font(.appCaption)
                .foregroundStyle(.textSecondary)
        }
        .cardStyle()
    }

    var severityIcon: String {
        switch severity {
        case .LEICHT: return "checkmark.circle"
        case .MITTEL: return "exclamationmark.circle"
        case .SCHWER, .unknown: return "exclamationmark.triangle"
        }
    }

    var severityLabel: String {
        switch severity {
        case .LEICHT: return "Mild"
        case .MITTEL: return "Moderat"
        case .SCHWER, .unknown: return "Schwer"
        }
    }

    var severityDescription: String {
        switch severity {
        case .LEICHT:
            "Leichte Einschränkung. Standard-Übungsprogression mit allen Intensitätsstufen."
        case .MITTEL:
            "Moderate Einschränkung. Angepasste Übungen mit langsamerer Steigerung."
        case .SCHWER, .unknown:
            "Deutliche Einschränkung. Sanfter Beginn mit verlängerten Phasen und reduzierter Belastung."
        }
    }
}
