import SwiftUI

struct NotificationPrefsView: View {
    @AppStorage("appLanguage") private var appLanguage = "de"
    @State private var notificationService = NotificationService.shared
    @State private var showTestSent = false

    var body: some View {
        let isEn = appLanguage == "en"

        List {
            // Status
            Section("Status") {
                HStack {
                    Text(isEn ? "Notifications" : "Benachrichtigungen")
                        .foregroundStyle(.textPrimary)
                    Spacer()

                    switch notificationService.authorizationStatus {
                    case .authorized:
                        Label(isEn ? "Allowed" : "Erlaubt", systemImage: "checkmark.circle.fill")
                            .font(.appCaption)
                            .foregroundStyle(.painGreen)
                    case .denied:
                        Label(isEn ? "Blocked" : "Blockiert", systemImage: "xmark.circle.fill")
                            .font(.appCaption)
                            .foregroundStyle(.painRed)
                    case .notDetermined:
                        Label(isEn ? "Not requested" : "Nicht angefragt", systemImage: "questionmark.circle")
                            .font(.appCaption)
                            .foregroundStyle(.textSecondary)
                    default:
                        Label(isEn ? "Unknown" : "Unbekannt", systemImage: "questionmark.circle")
                            .font(.appCaption)
                            .foregroundStyle(.textSecondary)
                    }
                }

                if notificationService.authorizationStatus == .notDetermined {
                    Button {
                        Task { await notificationService.requestPermission() }
                    } label: {
                        Text(isEn ? "Allow Notifications" : "Benachrichtigungen erlauben")
                    }
                }

                if notificationService.authorizationStatus == .denied {
                    Button {
                        notificationService.openSettings()
                    } label: {
                        Text(isEn ? "Open Settings" : "In Einstellungen öffnen")
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
                            Text(isEn ? "Send Test Notification" : "Test-Benachrichtigung senden")
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
                    Text(isEn
                        ? "Training reminders are sent on your scheduled training days at the configured time."
                        : "Trainings-Erinnerungen werden an Ihren geplanten Trainingstagen zur eingestellten Uhrzeit gesendet.")
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                    Text(isEn
                        ? "You can adjust training days in Settings under 'Training Schedule'."
                        : "Sie können die Trainingstage in den Einstellungen unter 'Trainingsplan' anpassen.")
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                }
            }
        }
        .navigationTitle(isEn ? "Reminders" : "Erinnerungen")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await notificationService.checkStatus()
        }
    }
}
