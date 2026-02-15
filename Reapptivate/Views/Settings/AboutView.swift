import SwiftUI

struct AboutView: View {
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Brand
                VStack(spacing: 12) {
                    Circle()
                        .fill(Color.accent.opacity(0.12))
                        .frame(width: 80, height: 80)
                        .overlay {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.system(size: 32))
                                .foregroundStyle(.accent)
                        }

                    Text(brandWordmark)
                        .font(.outfit(.bold, size: 24))

                    Text("Version \(appVersion) (\(buildNumber))")
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                }
                .padding(.top, 8)

                // Description
                VStack(alignment: .leading, spacing: 8) {
                    Text("Über die App")
                        .font(.appHeadline)
                        .foregroundStyle(.textPrimary)

                    Text("Reapptivate ist eine evidenzbasierte Physiotherapie-App, die individuelle Trainingsprogramme für verschiedene muskuloskelettale Beschwerden bietet. Die App passt sich adaptiv an Ihren Fortschritt und Schmerzlevel an.")
                        .font(.appSubheadline)
                        .foregroundStyle(.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()

                // Credits
                VStack(alignment: .leading, spacing: 8) {
                    Text("Entwicklung")
                        .font(.appHeadline)
                        .foregroundStyle(.textPrimary)

                    CreditRow(icon: "person.fill", label: "Konzept & Entwicklung", value: "Marc Toschew")
                    CreditRow(icon: "stethoscope", label: "Fachliche Beratung", value: "Physiotherapie-Team")
                    CreditRow(icon: "graduationcap.fill", label: "Evidenzbasis", value: "Aktuelle Leitlinien")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()

                // Technology
                VStack(alignment: .leading, spacing: 8) {
                    Text("Technologie")
                        .font(.appHeadline)
                        .foregroundStyle(.textPrimary)

                    TechRow(label: "Platform", value: "iOS 17+")
                    TechRow(label: "Framework", value: "SwiftUI")
                    TechRow(label: "Sprache", value: "Swift 6.0")
                    TechRow(label: "Architektur", value: "MVVM + @Observable")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()
            }
            .padding(16)
        }
        .background(Color.appBg)
        .navigationTitle("Über die App")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var brandWordmark: AttributedString {
        var re = AttributedString("re")
        re.foregroundColor = UIColor(.textPrimary)
        var app = AttributedString("app")
        app.foregroundColor = UIColor(.accent)
        var tivate = AttributedString("tivate")
        tivate.foregroundColor = UIColor(.textPrimary)
        return re + app + tivate
    }
}

private struct CreditRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.appCaption)
                .foregroundStyle(.accent)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
                Text(value)
                    .font(.appSubheadlineMedium)
                    .foregroundStyle(.textPrimary)
            }
        }
    }
}

private struct TechRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.appSubheadline)
                .foregroundStyle(.textSecondary)
            Spacer()
            Text(value)
                .font(.appSubheadlineMedium)
                .foregroundStyle(.textPrimary)
        }
    }
}
