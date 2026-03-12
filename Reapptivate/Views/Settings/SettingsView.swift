import SwiftUI
import UserNotifications

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(APIClient.self) private var apiClient
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.dismiss) private var dismiss

    @State private var notificationService = NotificationService.shared
    @State private var showLogoutConfirmation = false
    @State private var hapticTrigger = false
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("appLanguage") private var appLanguage: String = "de"

    var body: some View {
        let isEn = appLanguage == "en"

        NavigationStack {
            List {
                // Account
                Section(isEn ? "Account" : "Konto") {
                    if let user = appState.currentUser {
                        HStack {
                            Text(isEn ? "Name" : "Name")
                                .foregroundStyle(.textSecondary)
                            Spacer()
                            Text(user.name)
                                .foregroundStyle(.textPrimary)
                        }

                        HStack {
                            Text(isEn ? "Email" : "E-Mail")
                                .foregroundStyle(.textSecondary)
                            Spacer()
                            Text(user.email)
                                .foregroundStyle(.textPrimary)
                        }

                        HStack {
                            Text(isEn ? "Diagnosis" : "Diagnose")
                                .foregroundStyle(.textSecondary)
                            Spacer()
                            Text(user.tendinopathyType.displayName)
                                .foregroundStyle(.textPrimary)
                        }

                        if let subtype = user.aemSubtype {
                            HStack {
                                Text(isEn ? "AEM Subtype" : "AEM-Subtyp")
                                    .foregroundStyle(.textSecondary)
                                Spacer()
                                Text(subtype.displayName)
                                    .foregroundStyle(Color.subtypeColor(for: subtype))
                            }
                        }

                        if let severity = user.ndiSeverity {
                            HStack {
                                Text(isEn ? "NDI Level" : "NDI-Stufe")
                                    .foregroundStyle(.textSecondary)
                                Spacer()
                                Text(severity.displayName)
                                    .foregroundStyle(Color.severityColor(for: severity))
                            }
                        }

                        if let severity = user.tsiSeverity {
                            HStack {
                                Text(isEn ? "TSI Level" : "TSI-Stufe")
                                    .foregroundStyle(.textSecondary)
                                Spacer()
                                Text(severity.displayName)
                                    .foregroundStyle(Color.severityColor(for: severity))
                            }
                        }
                    }
                }

                // Language
                Section {
                    languageButton(
                        flag: "\u{1F1E9}\u{1F1EA}",
                        label: "Deutsch",
                        languageCode: "de",
                        appLang: .german
                    )
                    languageButton(
                        flag: "\u{1F1EC}\u{1F1E7}",
                        label: "English",
                        languageCode: "en",
                        appLang: .english
                    )
                } header: {
                    HStack(spacing: 6) {
                        Image(systemName: "globe")
                            .font(.appCaption)
                        Text(isEn ? "Language" : "Sprache")
                    }
                }

                // Schedule
                Section(isEn ? "Training Schedule" : "Trainingsplan") {
                    NavigationLink {
                        ScheduleEditorView()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "calendar")
                                .foregroundStyle(.accent)
                            Text(isEn ? "Training Days & Time" : "Trainingstage & Uhrzeit")
                        }
                    }
                }

                // Notifications
                Section(isEn ? "Notifications" : "Benachrichtigungen") {
                    NavigationLink {
                        NotificationPrefsView()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "bell.fill")
                                .foregroundStyle(.accent)
                            Text(isEn ? "Reminders" : "Erinnerungen")

                            Spacer()

                            if notificationService.isAuthorized {
                                Text(isEn ? "Active" : "Aktiv")
                                    .font(.appCaption)
                                    .foregroundStyle(.painGreen)
                            } else {
                                Text(isEn ? "Inactive" : "Inaktiv")
                                    .font(.appCaption)
                                    .foregroundStyle(.textSecondary)
                            }
                        }
                    }
                }

                // Appearance
                Section(isEn ? "Appearance" : "Darstellung") {
                    Picker(selection: $appearanceMode) {
                        ForEach(AppearanceMode.allCases, id: \.self) { mode in
                            Text(appearanceModeLabel(mode, isEn: isEn)).tag(mode)
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "circle.lefthalf.filled")
                                .foregroundStyle(.accent)
                            Text(isEn ? "Appearance" : "Erscheinungsbild")
                        }
                    }

                    Toggle(isOn: $hapticsEnabled) {
                        HStack(spacing: 12) {
                            Image(systemName: "hand.tap.fill")
                                .foregroundStyle(.accent)
                            Text(isEn ? "Haptic Feedback" : "Haptisches Feedback")
                        }
                    }
                }

                // Achievements
                Section(isEn ? "Achievements" : "Erfolge") {
                    NavigationLink {
                        AchievementsView()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "trophy.fill")
                                .foregroundStyle(.accent)
                            Text(isEn ? "My Achievements" : "Meine Erfolge")
                        }
                    }
                }

                // Data Privacy
                Section(isEn ? "Privacy" : "Datenschutz") {
                    NavigationLink {
                        DataPrivacyView()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "hand.raised.fill")
                                .foregroundStyle(.accent)
                            Text(isEn ? "Data & Privacy" : "Daten & Datenschutz")
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
                            Text(isEn ? "About the App" : "Über die App")
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
                            Text(isEn ? "Log Out" : "Abmelden")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle(isEn ? "Settings" : "Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isEn ? "Done" : "Fertig") { dismiss() }
                }
            }
            .sensoryFeedback(.selection, trigger: hapticTrigger)
            .task {
                await notificationService.checkStatus()
            }
            .onChange(of: languageManager.language) { _, newLang in
                let doneLabel   = newLang == .english ? "Done"           : "Erledigt"
                let snoozeLabel = newLang == .english ? "Later (5 min)"  : "Später (5 Min.)"
                let skipLabel   = newLang == .english ? "Skip"           : "Überspringen"
                let completeAction = UNNotificationAction(identifier: "COMPLETE_BREAK", title: doneLabel, options: .foreground)
                let snoozeAction   = UNNotificationAction(identifier: "SNOOZE_BREAK",   title: snoozeLabel, options: [])
                let skipAction     = UNNotificationAction(identifier: "SKIP_BREAK",     title: skipLabel, options: .destructive)
                let breakCategory  = UNNotificationCategory(identifier: "WORK_TIMER_BREAK", actions: [completeAction, snoozeAction, skipAction], intentIdentifiers: [])
                UNUserNotificationCenter.current().setNotificationCategories([breakCategory])
            }
            .alert(isEn ? "Log Out?" : "Abmelden?", isPresented: $showLogoutConfirmation) {
                Button(isEn ? "Cancel" : "Abbrechen", role: .cancel) { }
                Button(isEn ? "Log Out" : "Abmelden", role: .destructive) {
                    appState.performLogout(apiClient: apiClient)
                    dismiss()
                }
            } message: {
                Text(isEn
                    ? "You will be logged out and need to sign in again."
                    : "Sie werden ausgeloggt und müssen sich erneut anmelden.")
            }
        }
    }

    private func languageButton(flag: String, label: String, languageCode: String, appLang: AppLanguage) -> some View {
        Button {
            guard appLanguage != languageCode else { return }
            appLanguage = languageCode
            languageManager.language = appLang
            hapticTrigger.toggle()
        } label: {
            HStack(spacing: 12) {
                Text(flag)
                    .font(.title3)
                Text(label)
                    .font(.appBody)
                    .foregroundStyle(.textPrimary)
                Spacer()
                if appLanguage == languageCode {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.accent)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .contentShape(Rectangle())
            .animation(.easeInOut(duration: 0.2), value: appLanguage)
        }
    }

    private func appearanceModeLabel(_ mode: AppearanceMode, isEn: Bool) -> String {
        switch mode {
        case .system: return "System"
        case .light: return isEn ? "Light" : "Hell"
        case .dark: return isEn ? "Dark" : "Dunkel"
        }
    }
}
