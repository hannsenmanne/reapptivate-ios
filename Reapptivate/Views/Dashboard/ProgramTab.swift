import SwiftUI

struct ProgramTab: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 20) {
            // AEM Profile (LBP)
            if appState.isLbp, let subtype = appState.currentUser?.aemSubtype {
                AemProfileQuickCard(subtype: subtype)
            }

            // NDI Profile (Neck)
            if appState.isNeck, let severity = appState.currentUser?.ndiSeverity {
                NdiProfileQuickCard(severity: severity)
            }

            // Exercise list by phase - M5 will populate
            VStack(alignment: .leading, spacing: 12) {
                Text("Ubungsprogramm")
                    .font(.headline)
                    .foregroundStyle(.textPrimary)

                Text("Vollstandige Ubungsliste kommt in M5")
                    .font(.subheadline)
                    .foregroundStyle(.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .background(Color.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.bottom, 32)
    }
}

// MARK: - Quick Profile Cards

struct AemProfileQuickCard: View {
    let subtype: AemSubtype

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.subtypeColor(for: subtype))
                .frame(width: 40, height: 40)
                .overlay {
                    subtypeIcon
                        .font(.body)
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text("AEM-Profil")
                    .font(.caption)
                    .foregroundStyle(.textSecondary)
                Text(subtype.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.textPrimary)
            }

            Spacer()

            Text("Max. \(subtype.maxPainLevel)/10")
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.subtypeColor(for: subtype))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.subtypeColor(for: subtype).opacity(0.1))
                .clipShape(Capsule())
        }
        .padding(16)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    var subtypeIcon: some View {
        switch subtype {
        case .FAR: Image(systemName: "magnifyingglass")
        case .DER: Image(systemName: "timer")
        case .EER: Image(systemName: "chart.bar")
        case .AR: Image(systemName: "checkmark.circle")
        }
    }
}

struct NdiProfileQuickCard: View {
    let severity: NdiSeverityGrade

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.severityColor(for: severity))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: "neck")
                        .font(.body)
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text("NDI-Schweregrad")
                    .font(.caption)
                    .foregroundStyle(.textSecondary)
                Text(severity.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.textPrimary)
            }

            Spacer()
        }
        .padding(16)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
