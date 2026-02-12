import SwiftUI

struct NotificationPrefsView: View {
    @State private var notificationService = NotificationService.shared
    @State private var showTestSent = false

    var body: some View {
        List {
            // Status
            Section("Status") {
                HStack {
                    Text("Benachrichtigungen")
                        .foregroundStyle(.textPrimary)
                    Spacer()

                    switch notificationService.authorizationStatus {
                    case .authorized:
                        Label("Erlaubt", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.painGreen)
                    case .denied:
                        Label("Blockiert", systemImage: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.painRed)
                    case .notDetermined:
                        Label("Nicht angefragt", systemImage: "questionmark.circle")
                            .font(.caption)
                            .foregroundStyle(.textSecondary)
                    default:
                        Label("Unbekannt", systemImage: "questionmark.circle")
                            .font(.caption)
                            .foregroundStyle(.textSecondary)
                    }
                }

                if notificationService.authorizationStatus == .notDetermined {
                    Button {
                        Task { await notificationService.requestPermission() }
                    } label: {
                        Text("Benachrichtigungen erlauben")
                    }
                }

                if notificationService.authorizationStatus == .denied {
                    Button {
                        notificationService.openSettings()
                    } label: {
                        Text("In Einstellungen offnen")
                    }
                }
            }

            // Test
            if notificationService.isAuthorized {
                Section("Test") {
                    Button {
                        Task {
                            await notificationService.sendTestNotification()
                            showTestSent = true
                            try? await Task.sleep(for: .seconds(3))
                            showTestSent = false
                        }
                    } label: {
                        HStack {
                            Text("Test-Benachrichtigung senden")
                            Spacer()
                            if showTestSent {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.painGreen)
                            }
                        }
                    }
                }
            }

            // Info
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Trainings-Erinnerungen werden an Ihren geplanten Trainingstagen zur eingestellten Uhrzeit gesendet.")
                        .font(.caption)
                        .foregroundStyle(.textSecondary)
                    Text("Sie konnen die Trainingstage in den Einstellungen unter 'Trainingsplan' anpassen.")
                        .font(.caption)
                        .foregroundStyle(.textSecondary)
                }
            }
        }
        .navigationTitle("Erinnerungen")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await notificationService.checkStatus()
        }
    }
}
