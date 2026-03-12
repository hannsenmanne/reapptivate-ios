import SwiftUI

struct DataPrivacyView: View {
    @Environment(AppState.self) private var appState
    @Environment(APIClient.self) private var apiClient
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appLanguage") private var appLanguage = "de"
    @State private var showDeleteConfirmation = false
    @State private var showExportInfo = false
    @State private var isDeleting = false
    @State private var deleteError: String?

    var body: some View {
        let isEn = appLanguage == "en"

        List {
            // What data is stored
            Section(isEn ? "Stored Data" : "Gespeicherte Daten") {
                DataRow(
                    icon: "person.fill",
                    title: isEn ? "Profile Data" : "Profildaten",
                    detail: isEn ? "Name, email, diagnosis" : "Name, E-Mail, Diagnose"
                )
                DataRow(
                    icon: "chart.bar.fill",
                    title: isEn ? "Training Data" : "Trainingsdaten",
                    detail: isEn ? "Exercises, pain history, progress" : "Übungen, Schmerzverlauf, Fortschritt"
                )
                DataRow(
                    icon: "calendar",
                    title: isEn ? "Schedule" : "Zeitplan",
                    detail: isEn ? "Training days, reminders" : "Trainingstage, Erinnerungen"
                )
                DataRow(
                    icon: "key.fill",
                    title: isEn ? "Authentication" : "Authentifizierung",
                    detail: isEn ? "JWT token in Keychain" : "JWT-Token im Keychain"
                )
            }

            // Usage explanation
            Section(isEn ? "Data Usage" : "Datenverwendung") {
                VStack(alignment: .leading, spacing: 8) {
                    Text(isEn
                        ? "Your data is used exclusively to provide and improve your training program. No data is shared with third parties."
                        : "Ihre Daten werden ausschliesslich zur Bereitstellung und Verbesserung Ihres Trainingsprogramms verwendet. Es findet keine Weitergabe an Dritte statt.")
                        .font(.appSubheadline)
                        .foregroundStyle(.textSecondary)
                }
            }

            // Data export
            Section(isEn ? "Data Export" : "Datenexport") {
                Button {
                    showExportInfo = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(.accent)
                        Text(isEn ? "Export Data (JSON)" : "Daten exportieren (JSON)")
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
                        Text(isEn ? "Delete Account & Data" : "Konto und Daten löschen")
                    }
                }
                .disabled(isDeleting)
            } footer: {
                Text(isEn
                    ? "This action is irreversible. All your data will be permanently deleted."
                    : "Diese Aktion ist unwiderruflich. Alle Ihre Daten werden permanent gelöscht.")
                    .font(.appCaption2)
            }
        }
        .navigationTitle(isEn ? "Data Privacy" : "Datenschutz")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isEn ? "Export Data" : "Daten exportieren", isPresented: $showExportInfo) {
            Button("OK") { }
        } message: {
            Text(isEn
                ? "The export feature will be available in a future update."
                : "Die Exportfunktion wird in einem zukünftigen Update verfügbar sein.")
        }
        .alert(isEn ? "Delete Account?" : "Konto löschen?", isPresented: $showDeleteConfirmation) {
            Button(isEn ? "Cancel" : "Abbrechen", role: .cancel) { }
            Button(isEn ? "Delete Permanently" : "Endgültig löschen", role: .destructive) {
                Task { await deleteAccount() }
            }
        } message: {
            Text(isEn
                ? "All your data will be permanently deleted. This action cannot be undone."
                : "Alle Ihre Daten werden unwiderruflich gelöscht. Diese Aktion kann nicht rückgängig gemacht werden.")
        }
        .alert(isEn ? "Error" : "Fehler", isPresented: Binding(get: { deleteError != nil }, set: { if !$0 { deleteError = nil } })) {
            Button("OK") { }
        } message: {
            Text(deleteError ?? "")
        }
    }
}

extension DataPrivacyView {
    private func deleteAccount() async {
        let isEn = appLanguage == "en"
        isDeleting = true
        defer { isDeleting = false }

        do {
            try await apiClient.requestVoid(APIEndpoints.deleteAccount())
            appState.performLogout(apiClient: apiClient)
        } catch {
            deleteError = isEn
                ? "Account could not be deleted. Please try again."
                : "Konto konnte nicht gelöscht werden. Bitte versuchen Sie es erneut."
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
