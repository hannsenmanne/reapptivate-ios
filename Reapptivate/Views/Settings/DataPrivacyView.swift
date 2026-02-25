import SwiftUI

struct DataPrivacyView: View {
    @Environment(AppState.self) private var appState
    @Environment(APIClient.self) private var apiClient
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false
    @State private var showExportInfo = false
    @State private var isDeleting = false
    @State private var deleteError: String?

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
                        if isDeleting {
                            ProgressView()
                        } else {
                            Image(systemName: "trash.fill")
                        }
                        Text("Konto und Daten löschen")
                    }
                }
                .disabled(isDeleting)
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
                Task { await deleteAccount() }
            }
        } message: {
            Text("Alle Ihre Daten werden unwiderruflich gelöscht. Diese Aktion kann nicht rückgängig gemacht werden.")
        }
        .alert("Fehler", isPresented: Binding(get: { deleteError != nil }, set: { if !$0 { deleteError = nil } })) {
            Button("OK") { }
        } message: {
            Text(deleteError ?? "")
        }
    }
}

extension DataPrivacyView {
    private func deleteAccount() async {
        isDeleting = true
        defer { isDeleting = false }

        do {
            try await apiClient.requestVoid(APIEndpoints.deleteAccount())
            dismiss()
            appState.performLogout(apiClient: apiClient)
        } catch {
            deleteError = "Konto konnte nicht gelöscht werden. Bitte versuchen Sie es erneut."
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
