import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var notificationService = NotificationService.shared

    var body: some View {
        NavigationStack {
            List {
                // Account
                Section("Konto") {
                    if let user = appState.currentUser {
                        HStack {
                            Text("Name")
                                .foregroundStyle(.textSecondary)
                            Spacer()
                            Text(user.name)
                                .foregroundStyle(.textPrimary)
                        }

                        HStack {
                            Text("E-Mail")
                                .foregroundStyle(.textSecondary)
                            Spacer()
                            Text(user.email)
                                .foregroundStyle(.textPrimary)
                        }

                        HStack {
                            Text("Diagnose")
                                .foregroundStyle(.textSecondary)
                            Spacer()
                            Text(user.tendinopathyType.displayName)
                                .foregroundStyle(.textPrimary)
                        }

                        if let subtype = user.aemSubtype {
                            HStack {
                                Text("AEM-Subtyp")
                                    .foregroundStyle(.textSecondary)
                                Spacer()
                                Text(subtype.displayName)
                                    .foregroundStyle(Color.subtypeColor(for: subtype))
                            }
                        }

                        if let severity = user.ndiSeverity {
                            HStack {
                                Text("NDI-Stufe")
                                    .foregroundStyle(.textSecondary)
                                Spacer()
                                Text(severity.displayName)
                                    .foregroundStyle(Color.severityColor(for: severity))
                            }
                        }
                    }
                }

                // Schedule
                Section("Trainingsplan") {
                    NavigationLink {
                        ScheduleEditorView()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "calendar")
                                .foregroundStyle(.accent)
                            Text("Trainingstage & Uhrzeit")
                        }
                    }
                }

                // Notifications
                Section("Benachrichtigungen") {
                    NavigationLink {
                        NotificationPrefsView()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "bell.fill")
                                .foregroundStyle(.accent)
                            Text("Erinnerungen")

                            Spacer()

                            if notificationService.isAuthorized {
                                Text("Aktiv")
                                    .font(.appCaption)
                                    .foregroundStyle(.painGreen)
                            } else {
                                Text("Inaktiv")
                                    .font(.appCaption)
                                    .foregroundStyle(.textSecondary)
                            }
                        }
                    }
                }

                // App Info
                Section("App") {
                    HStack {
                        Text("Version")
                            .foregroundStyle(.textSecondary)
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.textPrimary)
                    }
                }

                // Logout
                Section {
                    Button(role: .destructive) {
                        TokenManager.shared.clearAll()
                        appState.handleLogout()
                        dismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Abmelden")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") { dismiss() }
                }
            }
            .task {
                await notificationService.checkStatus()
            }
        }
    }
}
