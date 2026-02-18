import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(APIClient.self) private var apiClient
    @Environment(\.dismiss) private var dismiss

    @State private var notificationService = NotificationService.shared
    @State private var showLogoutConfirmation = false
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true

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

                        if let severity = user.tsiSeverity {
                            HStack {
                                Text("TSI-Stufe")
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

                // Appearance
                Section("Darstellung") {
                    Picker(selection: $appearanceMode) {
                        ForEach(AppearanceMode.allCases, id: \.self) { mode in
                            Text(mode.label).tag(mode)
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "circle.lefthalf.filled")
                                .foregroundStyle(.accent)
                            Text("Erscheinungsbild")
                        }
                    }

                    Toggle(isOn: $hapticsEnabled) {
                        HStack(spacing: 12) {
                            Image(systemName: "hand.tap.fill")
                                .foregroundStyle(.accent)
                            Text("Haptisches Feedback")
                        }
                    }
                }

                // Achievements
                Section("Erfolge") {
                    NavigationLink {
                        AchievementsView()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "trophy.fill")
                                .foregroundStyle(.accent)
                            Text("Meine Erfolge")
                        }
                    }
                }

                // Data Privacy
                Section("Datenschutz") {
                    NavigationLink {
                        DataPrivacyView()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "hand.raised.fill")
                                .foregroundStyle(.accent)
                            Text("Daten & Datenschutz")
                        }
                    }
                }

                // App Info
                Section("App") {
                    NavigationLink {
                        AboutView()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.accent)
                            Text("Über die App")
                        }
                    }
                }

                // Logout
                Section {
                    Button(role: .destructive) {
                        showLogoutConfirmation = true
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
            .alert("Abmelden?", isPresented: $showLogoutConfirmation) {
                Button("Abbrechen", role: .cancel) { }
                Button("Abmelden", role: .destructive) {
                    appState.performLogout(apiClient: apiClient)
                    dismiss()
                }
            } message: {
                Text("Sie werden ausgeloggt und müssen sich erneut anmelden.")
            }
        }
    }
}
