import SwiftUI

struct DataPrivacyView: View {
    @Environment(AppState.self) private var appState
    @Environment(APIClient.self) private var apiClient
    @State private var showDeleteConfirmation = false
    @State private var showDeleteNotAvailable = false
    @State private var showExportInfo = false

    var body: some View {
        List {
            // What data is stored
            Section("Gespeicherte Daten") {
                DataRow(icon: "person.fill", title: "Profildaten", detail: "Name, E-Mail, Diagnose")
                DataRow(icon: "chart.bar.fill", title: "Trainingsdaten", detail: "Übungen, Schmerzverlauf, Fortschritt")
                DataRow(icon: "calendar", title: "Zeitplan", detail: "Trainingstage, Erinnerungen")
                DataRow(icon: "key.fill", title: "Authentifizierung", detail: "JWT-Token im Keychain")
            }

            // Usage explanation
            Section("Datenverwendung") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ihre Daten werden ausschliesslich zur Bereitstellung und Verbesserung Ihres Trainingsprogramms verwendet. Es findet keine Weitergabe an Dritte statt.")
                        .font(.appSubheadline)
                        .foregroundStyle(.textSecondary)
                }
            }

            // Data export
            Section("Datenexport") {
                Button {
                    showExportInfo = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(.accent)
                        Text("Daten exportieren (JSON)")
                            .foregroundStyle(.textPrimary)
                    }
                }
            }

            // Delete account
            Section {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "trash.fill")
                        Text("Konto und Daten löschen")
                    }
                }
            } footer: {
                Text("Diese Aktion ist unwiderruflich. Alle Ihre Daten werden permanent gelöscht.")
                    .font(.appCaption2)
            }
        }
        .navigationTitle("Datenschutz")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Daten exportieren", isPresented: $showExportInfo) {
            Button("OK") { }
        } message: {
            Text("Die Exportfunktion wird in einem zukünftigen Update verfügbar sein.")
        }
        .alert("Konto löschen?", isPresented: $showDeleteConfirmation) {
            Button("Abbrechen", role: .cancel) { }
            Button("Endgültig löschen", role: .destructive) {
                showDeleteNotAvailable = true
            }
        } message: {
            Text("Alle Ihre Daten werden unwiderruflich gelöscht. Diese Aktion kann nicht rückgängig gemacht werden.")
        }
        .alert("Nicht verfügbar", isPresented: $showDeleteNotAvailable) {
            Button("OK") { }
        } message: {
            Text("Diese Funktion ist noch nicht verfügbar. Bitte kontaktieren Sie uns direkt für die Löschung Ihres Kontos.")
        }
    }
}

private struct DataRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.appSubheadline)
                .foregroundStyle(.accent)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.appSubheadlineMedium)
                    .foregroundStyle(.textPrimary)
                Text(detail)
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
            }
        }
    }
}
