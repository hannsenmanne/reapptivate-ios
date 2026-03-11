# Full App Localization (German ↔ English) Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add English language support with instant in-app switching via Settings, covering all UI strings, content JSON files, and backend-generated text.

**Architecture:** `LanguageManager` (@Observable, @AppStorage) injected via SwiftUI environment. `.environment(\.locale, Locale(identifier:))` at root causes all `Text("key")` views to look up translations from `Localizable.xcstrings` instantly. Backend receives `Accept-Language` header and returns localized text. German strings are used as localization keys, so existing German view code requires minimal changes.

**Tech Stack:** Swift 6, SwiftUI, @Observable, Xcode 15 String Catalog (.xcstrings), Express/TypeScript backend.

---

## Task 1: Create LanguageManager

**Files:**
- Create: `Reapptivate/App/LanguageManager.swift`

**Step 1: Create the file**

```swift
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case german = "de"
    case english = "en"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .german: return "Deutsch"
        case .english: return "English"
        }
    }

    var locale: Locale { Locale(identifier: rawValue) }
}

@Observable @MainActor final class LanguageManager {
    @ObservationIgnored @AppStorage("appLanguage")
    private var _language: String = AppLanguage.german.rawValue

    var language: AppLanguage {
        get { AppLanguage(rawValue: _language) ?? .german }
        set { _language = newValue.rawValue }
    }

    var isEnglish: Bool { language == .english }
}
```

**Step 2: Commit**
```bash
git add Reapptivate/App/LanguageManager.swift
git commit -m "feat: add LanguageManager with AppLanguage enum"
```

---

## Task 2: Inject LanguageManager into App + Locale Environment

**Files:**
- Modify: `Reapptivate/App/ReapptivateApp.swift`

**Step 1: Add `@State private var languageManager = LanguageManager()` in `ReapptivateApp`**

In `ReapptivateApp.swift`, add next to the other `@State` properties at the top:
```swift
@State private var languageManager = LanguageManager()
```

**Step 2: Inject into environment on `WindowGroup`**

Find the `.environment(appState)` chain and add:
```swift
.environment(languageManager)
.environment(\.locale, languageManager.language.locale)
```

The complete modifier chain on `WindowGroup { RootView() }` should look like:
```swift
WindowGroup {
    RootView()
}
.environment(appState)
.environment(apiClient)
.environment(networkMonitor)
.environment(languageManager)                              // ADD
.environment(\.locale, languageManager.language.locale)   // ADD
.modelContainer(for: [CachedUser.self, CachedProgress.self, PendingSync.self])
.preferredColorScheme(AppearanceMode(rawValue: appearanceMode)?.colorScheme)
```

**Step 3: Also localize the 3 notification action labels in `registerNotificationCategories()`**

Find the notification registration code and add language-aware labels:
```swift
// Before registering, build labels based on stored language
let lang = AppLanguage(rawValue: UserDefaults.standard.string(forKey: "appLanguage") ?? "de") ?? .german
let doneLabel    = lang == .english ? "Done"         : "Erledigt"
let snoozeLabel  = lang == .english ? "Later (5 min)" : "Später (5 Min.)"
let skipLabel    = lang == .english ? "Skip"         : "Überspringen"

let completeAction = UNNotificationAction(identifier: "COMPLETE", title: doneLabel, options: [])
let snoozeAction   = UNNotificationAction(identifier: "SNOOZE",   title: snoozeLabel, options: [])
let skipAction     = UNNotificationAction(identifier: "SKIP",     title: skipLabel, options: [])
```

**Step 4: Commit**
```bash
git add Reapptivate/App/ReapptivateApp.swift
git commit -m "feat: inject LanguageManager and locale environment into app root"
```

---

## Task 3: Add Language Picker to SettingsView

**Files:**
- Modify: `Reapptivate/Views/Settings/SettingsView.swift`

**Step 1: Add `@Environment(LanguageManager.self) private var languageManager` at top of `SettingsView`**

```swift
@Environment(LanguageManager.self) private var languageManager
```

**Step 2: Add a new "Sprache / Language" section**

Add this section ABOVE the existing "Darstellung" (appearance) section:

```swift
// MARK: - Language Section
Section {
    @Bindable var lm = languageManager
    Picker("Sprache", selection: $lm.language) {
        ForEach(AppLanguage.allCases) { lang in
            Text(lang.displayName).tag(lang)
        }
    }
    .pickerStyle(.segmented)
} header: {
    Text("Sprache / Language")
}
```

**Step 3: Commit**
```bash
git add Reapptivate/Views/Settings/SettingsView.swift
git commit -m "feat: add language picker (DE/EN) to SettingsView"
```

---

## Task 4: Add Accept-Language Header to APIClient

**Files:**
- Modify: `Reapptivate/Services/Networking/APIClient.swift`

**Step 1: Add `LanguageManager` dependency**

In `APIClient`, add a reference to `LanguageManager.shared` — but since `LanguageManager` is `@Observable @MainActor`, we read the stored `AppStorage` value directly (it's just a UserDefaults key):

Find the private helper that prepares a request (or the `request<T>` method) and add a language header before the request is sent:

```swift
// Add this helper inside APIClient:
private var languageHeader: String {
    UserDefaults.standard.string(forKey: "appLanguage") ?? "de"
}
```

In each of the three request methods (`request<T>`, `requestVoid`, `requestData`), before the `URLSession.shared.data(for:)` call, add:

```swift
var req = request  // make mutable copy
req.setValue(languageHeader, forHTTPHeaderField: "Accept-Language")
// then use `req` instead of `request` in the URLSession call
```

**Step 2: Commit**
```bash
git add Reapptivate/Services/Networking/APIClient.swift
git commit -m "feat: send Accept-Language header on all API requests"
```

---

## Task 5: Create Localizable.xcstrings (String Catalog)

**Files:**
- Create: `Reapptivate/Resources/Localizable.xcstrings`
- Add to `project.yml` sources

**Step 1: Add Localizable.xcstrings to project.yml**

In `project.yml`, under the `sources` array that includes `Reapptivate/Resources`, the xcstrings file will be picked up automatically since the Resources directory is already included.

**Step 2: Create the Localizable.xcstrings file**

Create `Reapptivate/Resources/Localizable.xcstrings` with the following content.
This file uses German text as keys. When `locale = "en"`, SwiftUI looks up translations.
When `locale = "de"`, SwiftUI uses the key itself as-is.

```json
{
  "sourceLanguage" : "de",
  "strings" : {

    "Laden..." : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Loading..." } } } },
    "Tagesplan wird geladen" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Loading daily plan" } } } },
    "Ihr personalisierter Tagesplan wird erstellt." : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Your personalized daily plan is being created." } } } },
    "Tagesstatus laden..." : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Loading daily status..." } } } },

    "Trainingstag" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Training Day" } } } },
    "Ruhetag" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Rest Day" } } } },
    "Erholungstag" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Recovery Day" } } } },
    "Heute ist ein guter Tag zur Erholung. Nutze die Zeit für leichte Bewegung oder Entspannung." : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Today is a good day for recovery. Use the time for light movement or relaxation." } } } },
    "Wochen post-OP" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Weeks Post-Op" } } } },
    "Meilenstein" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Milestone" } } } },
    "Tag Streak" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Day Streak" } } } },
    "Tage Streak" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Day Streak" } } } },
    "Rekord:" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Record:" } } } },
    "Empfohlene Lektüre" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Recommended Reading" } } } },
    "Einführung in Phase " : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Introduction to Phase " } } } },

    "Übungsprogramm" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Exercise Program" } } } },
    "Übungen anzeigen und protokollieren" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "View and log exercises" } } } },
    "Heutiges Programm" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Today's Program" } } } },
    "Diagnose" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Diagnosis" } } } },
    "Training seit" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Training since" } } } },
    "Phase" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Phase" } } } },
    "Tage" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Days" } } } },
    "Willkommen bei Reapptivate!" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Welcome to Reapptivate!" } } } },
    "Starten Sie Ihr erstes Training, um Ihren Fortschritt zu verfolgen." : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Start your first training session to track your progress." } } } },

    "Konto" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Account" } } } },
    "Trainingsplan" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Training Schedule" } } } },
    "Benachrichtigungen" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Notifications" } } } },
    "Darstellung" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Appearance" } } } },
    "Erfolge" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Achievements" } } } },
    "Datenschutz" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Privacy" } } } },
    "Einstellungen" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Settings" } } } },
    "Abmelden" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Sign Out" } } } },
    "Abmelden?" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Sign Out?" } } } },
    "Abbrechen" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Cancel" } } } },
    "Sie werden ausgeloggt und müssen sich erneut anmelden." : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "You will be signed out and need to sign in again." } } } },
    "Trainingstage & Uhrzeit" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Training Days & Time" } } } },
    "Erinnerungen" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Reminders" } } } },
    "Erscheinungsbild" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Appearance" } } } },
    "Systemstandard" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "System Default" } } } },
    "Hell" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Light" } } } },
    "Dunkel" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Dark" } } } },
    "Haptisches Feedback" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Haptic Feedback" } } } },
    "Meine Erfolge" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "My Achievements" } } } },
    "Sprache" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Language" } } } },
    "Sprache / Language" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Language" } } } },
    "Profil und Abmelden" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Profile and Sign Out" } } } },
    "Aktiv" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Active" } } } },
    "Inaktiv" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Inactive" } } } },
    "Benachrichtigungen erlauben" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Allow Notifications" } } } },
    "In iOS Einstellungen öffnen" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Open iOS Settings" } } } },
    "Über Reapptivate" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "About Reapptivate" } } } },
    "Datenschutzerklärung" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Privacy Policy" } } } },
    "AEM-Subtyp" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "AEM Subtype" } } } },
    "NDI-Stufe" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "NDI Level" } } } },
    "TSI-Stufe" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "TSI Level" } } } },

    "Übungen" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Exercises" } } } },
    "Sets" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Sets" } } } },
    "Wiederholungen" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Repetitions" } } } },
    "Sekunden" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Seconds" } } } },
    "Minuten" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Minutes" } } } },
    "Protokollieren" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Log" } } } },
    "Erledigt" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Done" } } } },
    "Abgeschlossen" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Completed" } } } },
    "Schmerzlevel" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Pain Level" } } } },
    "Schmerzwert" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Pain Level" } } } },
    "Symptomreaktion" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Symptom Response" } } } },
    "Besser" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Better" } } } },
    "Gleich" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Same" } } } },
    "Schlechter" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Worse" } } } },
    "Training protokollieren" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Log Training" } } } },
    "Heute" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Today" } } } },
    "Gestern" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Yesterday" } } } },
    "Keine Übungen für heute geplant." : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "No exercises planned for today." } } } },
    "Übungsdetails" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Exercise Details" } } } },
    "Eigene Übungen" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Custom Exercises" } } } },
    "Übung hinzufügen" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Add Exercise" } } } },
    "Übung bearbeiten" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Edit Exercise" } } } },
    "Übung löschen" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Delete Exercise" } } } },
    "Keine eigenen Übungen" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "No custom exercises" } } } },
    "Übung speichern" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Save Exercise" } } } },
    "Name der Übung" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Exercise Name" } } } },
    "Beschreibung (optional)" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Description (optional)" } } } },
    "Empfohlene Reihenfolge" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Recommended Order" } } } },
    "Video aufnehmen" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Record Video" } } } },
    "Video aus Bibliothek" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Choose from Library" } } } },
    "Video entfernen" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Remove Video" } } } },

    "Fortschritt" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Progress" } } } },
    "Statistiken" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Statistics" } } } },
    "Trainingseinheiten" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Training Sessions" } } } },
    "Compliance" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Compliance" } } } },
    "Schmerzverlauf" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Pain History" } } } },
    "Keine Daten" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "No Data" } } } },
    "Wochen" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Weeks" } } } },
    "Noch kein Training protokolliert." : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "No training logged yet." } } } },
    "Letzte 30 Tage" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Last 30 Days" } } } },
    "Letzte 7 Tage" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Last 7 Days" } } } },
    "Schmerz" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Pain" } } } },
    "Sitzungen" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Sessions" } } } },
    "Gesamt" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Total" } } } },
    "Ø Schmerz" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Avg Pain" } } } },

    "Verbindungsfehler" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Connection Error" } } } },
    "Keine Verbindung" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "No Connection" } } } },
    "Erneut versuchen" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Retry" } } } },
    "Schließen" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Close" } } } },
    "Speichern" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Save" } } } },
    "Bestätigen" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Confirm" } } } },
    "Weiter" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Continue" } } } },
    "Zurück" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Back" } } } },
    "Fertig" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Done" } } } },
    "Bearbeiten" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Edit" } } } },
    "Löschen" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Delete" } } } },
    "Hinzufügen" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Add" } } } },
    "Ja" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Yes" } } } },
    "Nein" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "No" } } } },
    "Senden" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Send" } } } },
    "Nachrichten laden..." : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Loading messages..." } } } },
    "Profil und Abmelden" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Profile and Sign Out" } } } },

    "Trainingsplan" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Training Schedule" } } } },
    "Trainingstage" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Training Days" } } } },
    "Montag" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Monday" } } } },
    "Dienstag" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Tuesday" } } } },
    "Mittwoch" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Wednesday" } } } },
    "Donnerstag" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Thursday" } } } },
    "Freitag" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Friday" } } } },
    "Samstag" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Saturday" } } } },
    "Sonntag" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Sunday" } } } },
    "Mo" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Mon" } } } },
    "Di" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Tue" } } } },
    "Mi" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Wed" } } } },
    "Do" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Thu" } } } },
    "Fr" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Fri" } } } },
    "Sa" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Sat" } } } },
    "So" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Sun" } } } },
    "Trainingszeit" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Training Time" } } } },
    "Kein Training geplant" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "No training scheduled" } } } },

    "Analyse" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Analytics" } } } },
    "Einblicke" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Insights" } } } },
    "Nachrichten" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Messages" } } } },
    "Übersicht" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Overview" } } } },
    "Programm" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Program" } } } },
    "Edukation" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Education" } } } },

    "Bewegungspause" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Movement Break" } } } },
    "Pause starten" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Start Break" } } } },
    "Pause" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Break" } } } },
    "Sitzen" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Sitting" } } } },
    "Zeit am Stück" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Time at a stretch" } } } },
    "Pausendauer" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Break Duration" } } } },
    "Arbeitszeit" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Work Time" } } } },
    "Übungen absolviert" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Exercises completed" } } } },
    "Pausen heute" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Breaks today" } } } },
    "Verlauf" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "History" } } } },
    "Heute keine Pausen" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "No breaks today" } } } },
    "Bewegungspause beendet" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Movement break completed" } } } },
    "Timer" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Timer" } } } },
    "Übung wählen" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Choose exercise" } } } },

    "Guten Morgen" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Good morning" } } } },
    "Wie geht es Ihnen heute?" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "How are you feeling today?" } } } },
    "Wie sind Ihre Schmerzen heute?" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "What is your pain level today?" } } } },
    "Check-in abschließen" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Complete Check-in" } } } },
    "Tages-Check-in" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Daily Check-in" } } } },
    "Morgen-Check-in" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Morning Check-in" } } } },

    "Screening" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Screening" } } } },
    "Screening abschließen" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Complete Screening" } } } },
    "Rescreening durchführen" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Perform Rescreening" } } } },
    "Weiter zur App" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Continue to App" } } } },
    "Ergebnis" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Result" } } } },
    "Leichte Einschränkung" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Mild Impairment" } } } },
    "Mittlere Einschränkung" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Moderate Impairment" } } } },
    "Schwere Einschränkung" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Severe Impairment" } } } },
    "Keine Einschränkung" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "No Impairment" } } } },
    "Screening abgeschlossen" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Screening Completed" } } } },
    "Fragebogen" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Questionnaire" } } } },
    "Frage" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Question" } } } },
    "von" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "of" } } } },

    "Angst-Hierarchie" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Fear Hierarchy" } } } },
    "Exposition" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Exposure" } } } },
    "Pacing-Plan" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Pacing Plan" } } } },
    "Baseline" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Baseline" } } } },
    "Aktivität" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Activity" } } } },
    "Aktivitäten" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Activities" } } } },
    "Angst-Level" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Fear Level" } } } },
    "Expositions-Level" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Exposure Level" } } } },

    "Fokus-Bereiche" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Focus Areas" } } } },
    "Micro-Module" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Micro-Modules" } } } },
    "Modul lesen" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Read Module" } } } },
    "Modul abgeschlossen" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Module completed" } } } },
    "Gelesen" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Read" } } } },
    "Noch nicht gelesen" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Not yet read" } } } },

    "NDI-Verlauf" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "NDI History" } } } },
    "TSI-Verlauf" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "TSI History" } } } },
    "QuickDASH-Verlauf" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "QuickDASH History" } } } },
    "SPADI-Verlauf" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "SPADI History" } } } },
    "Noch keine Screening-Daten" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "No screening data yet" } } } },
    "NDI-Verlauf konnte nicht geladen werden." : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Could not load NDI history." } } } },
    "TSI-Verlauf konnte nicht geladen werden." : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Could not load TSI history." } } } },
    "QuickDASH-Verlauf konnte nicht geladen werden." : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Could not load QuickDASH history." } } } },
    "SPADI-Verlauf konnte nicht geladen werden." : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Could not load SPADI history." } } } },

    "ACL-Rehabilitation" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "ACL Rehabilitation" } } } },
    "Meilenstein erreicht" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Milestone Reached" } } } },
    "Nächster Meilenstein" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Next Milestone" } } } },
    "Wochen nach OP" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Weeks Post-Op" } } } },
    "Kriterien" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Criteria" } } } },
    "Kriterium erfüllt" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Criterion met" } } } },
    "Strom" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Stream" } } } },
    "Ströme" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Streams" } } } },
    "Gesperrt" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Locked" } } } },
    "Freigeschaltet" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Unlocked" } } } },
    "KPI protokollieren" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Log KPI" } } } },
    "Wöchentlicher Fortschritt" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Weekly Progress" } } } },
    "Entlassungsfortschritt" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Discharge Progress" } } } },

    "Phase-Status" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Phase Status" } } } },
    "Nächste Auswertung" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Next Evaluation" } } } },
    "Fortschritt" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Progress" } } } },
    "Halten" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Hold" } } } },
    "Rückschritt" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Regress" } } } },
    "Phase geändert" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Phase Changed" } } } },
    "Sie sind in Phase" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "You are in Phase" } } } },
    "Neue Phase" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "New Phase" } } } },

    "Anmelden" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Sign In" } } } },
    "E-Mail" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Email" } } } },
    "Passwort" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Password" } } } },
    "Anmeldung fehlgeschlagen" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Sign in failed" } } } },
    "QR-Code scannen" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Scan QR Code" } } } },
    "Kamera-Zugriff benötigt" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Camera Access Required" } } } },
    "Bitte erlauben Sie den Kamera-Zugriff in den Einstellungen." : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Please allow camera access in Settings." } } } },

    "Täglich" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Daily" } } } },
    "Wöchentlich" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Weekly" } } } },
    "Monatlich" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Monthly" } } } },
    "Nacken & Schulter" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Neck & Shoulder" } } } },
    "Verspannung" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Tension" } } } },
    "Leicht" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Mild" } } } },
    "Mittel" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Moderate" } } } },
    "Schwer" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Severe" } } } },
    "Keine" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "None" } } } },
    "Unbekannt" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Unknown" } } } },

    "Anrufen" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Call" } } } },
    "Bedenken melden" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Flag Concern" } } } },
    "Nachricht senden" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Send Message" } } } },
    "Keine Nachrichten" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "No Messages" } } } },
    "Tippen um zu schreiben..." : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Tap to write..." } } } },

    "Später (5 Min.)" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Later (5 min)" } } } },
    "Überspringen" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Skip" } } } }
  },
  "version" : "1.0"
}
```

**Step 3: Run xcodegen to register the file**
```bash
cd /Users/marctoschew/Documents/Reapptivate-iOS && xcodegen generate
```

**Step 4: Open Xcode and verify String Catalog is recognized**
Build the project: `make generate && xcodebuild ... build`

**Step 5: Commit**
```bash
git add Reapptivate/Resources/Localizable.xcstrings
git commit -m "feat: add Localizable.xcstrings with 150+ German→English UI string translations"
```

---

## Task 6: Localize SharedTypes displayName Properties

**Files:**
- Modify: `Reapptivate/Models/Domain/SharedTypes.swift`

The `LanguageManager` is a `@MainActor` class, but `displayName` computed properties on enums are called from anywhere. Use `UserDefaults` directly (same backing store as `@AppStorage`):

**Step 1: Add a file-private helper at the top of SharedTypes.swift**

```swift
// File-private language helper — reads AppStorage backing store
private var isEnglishLocale: Bool {
    UserDefaults.standard.string(forKey: "appLanguage") == "en"
}
```

**Step 2: Update `TendinopathyType.displayName`**

```swift
var displayName: String {
    if isEnglishLocale {
        switch self {
        case .achilles: return "Achilles Tendinopathy"
        case .patellar: return "Patellar Tendinopathy"
        case .tennisElbow: return "Tennis Elbow"
        case .golfersElbow: return "Golfer's Elbow"
        case .rotatorCuff: return "Rotator Cuff Tendinopathy"
        case .gluteal: return "Gluteal Tendinopathy"
        case .proximalHamstring: return "Proximal Hamstring Tendinopathy"
        case .plantarFascia: return "Plantar Fasciitis"
        case .lbpNonspecific: return "Non-specific Lower Back Pain"
        case .neckPain: return "Neck Pain"
        case .neckShoulderTension: return "Neck & Shoulder Tension"
        case .aclReconstruction: return "ACL Reconstruction"
        case .shoulderImpingement: return "Shoulder Impingement"
        case .frozenShoulder: return "Frozen Shoulder"
        case .lateralAnkleSprain: return "Lateral Ankle Sprain"
        case .unknown: return "Unknown"
        }
    }
    switch self {
    case .achilles: return "Achillessehnenentzündung"
    case .patellar: return "Patellarsehne"
    case .tennisElbow: return "Tennisellenbogen"
    case .golfersElbow: return "Golferellenbogen"
    case .rotatorCuff: return "Rotatorenmanschette"
    case .gluteal: return "Glutealsehne"
    case .proximalHamstring: return "Proximale Hamstrings"
    case .plantarFascia: return "Plantarfasziitis"
    case .lbpNonspecific: return "Unspezifischer Rückenschmerz"
    case .neckPain: return "Nackenschmerz"
    case .neckShoulderTension: return "Nacken- & Schulterverspannung"
    case .aclReconstruction: return "VKB-Rekonstruktion"
    case .shoulderImpingement: return "Schulterimpingement"
    case .frozenShoulder: return "Frozen Shoulder"
    case .lateralAnkleSprain: return "Laterale Sprunggelenksdistorsion"
    case .unknown: return "Unbekannt"
    }
}
```

**Step 3: Update `ExerciseType.displayName`**

```swift
var displayName: String {
    if isEnglishLocale {
        switch self {
        case .ISOMETRIC: return "Isometric"
        case .HSR: return "Heavy Slow Resistance (HSR)"
        case .ECCENTRIC: return "Eccentric"
        case .STRETCHING: return "Stretching"
        case .STRENGTHENING: return "Strengthening"
        case .MOBILITY: return "Mobility"
        case .BALANCE: return "Balance"
        case .CARDIO: return "Cardio"
        case .FUNCTIONAL: return "Functional"
        case .CUSTOM: return "Custom"
        }
    }
    // existing German switch...
}
```

**Step 4: Update `AdaptationDecision.displayName`**

```swift
var displayName: String {
    if isEnglishLocale {
        switch self {
        case .progress: return "Progress"
        case .hold: return "Hold"
        case .regress: return "Regress"
        case .initial: return "Initial"
        case .unknown: return "Unknown"
        }
    }
    switch self {
    case .progress: return "Fortschritt"
    case .hold: return "Halten"
    case .regress: return "Rückschritt"
    case .initial: return "Initial"
    case .unknown: return "Unbekannt"
    }
}
```

**Step 5: Update `AemSubtype.displayName`, `NdiSeverityGrade.displayName`, and `SymptomResponse.displayName` with the same pattern**

AemSubtype English:
- `.FAR` → "Fear-Avoidance Response (FAR)"
- `.DER` → "Disuse & Reconditioning (DER)"
- `.EER` → "Elevated Emotion & Recovery (EER)"
- `.AR` → "Adaptive Response (AR)"

NdiSeverityGrade English:
- `.LEICHT` → "Mild Disability"
- `.MITTEL` → "Moderate Disability"
- `.SCHWER` → "Severe Disability"
- `.VOLLSTAENDIG` → "Complete Disability"

SymptomResponse English:
- `.BETTER` → "Better"
- `.SAME` → "Same"
- `.WORSE` → "Worse"

**Step 6: Commit**
```bash
git add Reapptivate/Models/Domain/SharedTypes.swift
git commit -m "feat: localize TendinopathyType, ExerciseType, AdaptationDecision displayNames"
```

---

## Task 7: Localize ProtocolLoader Phase Names (iOS)

**Files:**
- Modify: `Reapptivate/Services/ProtocolLoader.swift`

**Step 1: Add the same `isEnglishLocale` helper** (or import from SharedTypes if it's internal)

Add at top of ProtocolLoader.swift:
```swift
private var isEnglish: Bool {
    UserDefaults.standard.string(forKey: "appLanguage") == "en"
}
```

**Step 2: Update all 7 phase name methods with bilingual returns**

```swift
func tendinopathyPhaseName(phase: Int) -> String {
    if isEnglish {
        switch phase {
        case 1: return "Phase 1: Isometric"
        case 2: return "Phase 2: Heavy Slow Resistance (HSR)"
        case 3: return "Phase 3: Eccentric / Maintenance"
        default: return "Phase \(phase)"
        }
    }
    switch phase {
    case 1: return "Phase 1: Isometrisch"
    case 2: return "Phase 2: Schwerlast-Widerstand (HSR)"
    case 3: return "Phase 3: Exzentrisch / Erhaltung"
    default: return "Phase \(phase)"
    }
}

func lbpPhaseName(phase: Int) -> String {
    if isEnglish {
        switch phase {
        case 1: return "Phase 1: Core Activation & Mobility"
        case 2: return "Phase 2: Progressive Loading"
        case 3: return "Phase 3: Functional Movements"
        default: return "Phase \(phase)"
        }
    }
    switch phase {
    case 1: return "Phase 1: Core-Aktivierung & Mobilität"
    case 2: return "Phase 2: Progressive Belastung"
    case 3: return "Phase 3: Funktionelle Bewegungen"
    default: return "Phase \(phase)"
    }
}

func tensionPhaseName(phase: Int) -> String {
    if isEnglish {
        switch phase {
        case 1: return "Phase 1: Relaxation & Mobilisation"
        case 2: return "Phase 2: Motor Control"
        case 3: return "Phase 3: Strengthening"
        case 4: return "Phase 4: Functional Integration"
        default: return "Phase \(phase)"
        }
    }
    switch phase {
    case 1: return "Phase 1: Entspannung & Mobilisation"
    case 2: return "Phase 2: Motorische Kontrolle"
    case 3: return "Phase 3: Kräftigung"
    case 4: return "Phase 4: Funktionelle Integration"
    default: return "Phase \(phase)"
    }
}

func shoulderPhaseName(phase: Int) -> String {
    if isEnglish {
        switch phase {
        case 1: return "Phase 1: Acute / Pain Relief"
        case 2: return "Phase 2: Strengthening"
        case 3: return "Phase 3: Advanced Strengthening"
        case 4: return "Phase 4: Return to Activity"
        default: return "Phase \(phase)"
        }
    }
    switch phase {
    case 1: return "Phase 1: Akut / Schmerzlinderung"
    case 2: return "Phase 2: Kräftigung"
    case 3: return "Phase 3: Fortgeschrittene Kräftigung"
    case 4: return "Phase 4: Rückkehr zur Aktivität"
    default: return "Phase \(phase)"
    }
}

func frozenShoulderPhaseName(phase: Int) -> String {
    if isEnglish {
        switch phase {
        case 1: return "Phase 1: Pain Management & Gentle Mobilisation"
        case 2: return "Phase 2: Intensive Stretching & Capsule Mobilisation"
        case 3: return "Phase 3: Strengthening & Active ROM"
        case 4: return "Phase 4: Return & Maintenance"
        default: return "Phase \(phase)"
        }
    }
    switch phase {
    case 1: return "Phase 1: Schmerzmanagement & sanfte Mobilisation"
    case 2: return "Phase 2: Intensive Dehnung & Kapsel-Mobilisation"
    case 3: return "Phase 3: Kräftigung & aktive ROM"
    case 4: return "Phase 4: Rückkehr & Erhaltung"
    default: return "Phase \(phase)"
    }
}

func neckPhaseName(phase: Int, isRadiculopathy: Bool = false) -> String {
    if isEnglish {
        if isRadiculopathy {
            switch phase {
            case 1: return "Phase 1: Acute / Decompression"
            case 2: return "Phase 2: Neuromobilisation"
            case 3: return "Phase 3: Strengthening"
            case 4: return "Phase 4: Functional Integration"
            default: return "Phase \(phase)"
            }
        }
        switch phase {
        case 1: return "Phase 1: Acute / Pain Relief"
        case 2: return "Phase 2: Motor Control"
        case 3: return "Phase 3: Strengthening"
        case 4: return "Phase 4: Functional Integration"
        default: return "Phase \(phase)"
        }
    }
    // existing German...
}

func lateralAnkleSprainPhaseName(phase: Int) -> String {
    if isEnglish {
        switch phase {
        case 1: return "Phase 1: Protection & Decongestive Therapy"
        case 2: return "Phase 2: Early Mobilisation & ROM"
        case 3: return "Phase 3: Strengthening & Proprioception"
        case 4: return "Phase 4: Return to Sport & Prevention"
        default: return "Phase \(phase)"
        }
    }
    switch phase {
    case 1: return "Phase 1: Schutz & Entstauung"
    case 2: return "Phase 2: Frühe Mobilisation & ROM"
    case 3: return "Phase 3: Kräftigung & Propriozeption"
    case 4: return "Phase 4: Return to Sport & Prävention"
    default: return "Phase \(phase)"
    }
}
```

**Step 3: Commit**
```bash
git add Reapptivate/Services/ProtocolLoader.swift
git commit -m "feat: localize ProtocolLoader phase names for all 7 condition types"
```

---

## Task 8: Localize Milestone displayNames (iOS)

**Files:**
- Modify: `Reapptivate/Models/Domain/Milestone.swift`

Find all `displayName`/`title`/`description` computed properties and add English variants using the `isEnglishLocale` helper.

Example:
```swift
var title: String {
    if isEnglishLocale {
        switch type {
        case .firstSession: return "First Training Session!"
        case .tenSessions: return "10 Training Sessions!"
        case .phaseProgress: return "Phase Progression!"
        // ...
        }
    }
    // existing German...
}
```

**Step 4: Commit**
```bash
git add Reapptivate/Models/Domain/Milestone.swift
git commit -m "feat: localize Milestone display names"
```

---

## Task 9: Backend — Localize phaseAdaptation.service.ts Phase Names

**Files:**
- Modify: `Physio-App/server/src/services/phaseAdaptation.service.ts`

**Step 1: Add English phase name dictionaries after each German dictionary**

```typescript
// English translations
const TENDINOPATHY_PHASE_NAMES_EN: Record<number, string> = {
  1: 'Phase 1: Isometric',
  2: 'Phase 2: Heavy Slow Resistance (HSR)',
  3: 'Phase 3: Eccentric / Maintenance',
};

const LBP_PHASE_NAMES_EN: Record<number, string> = {
  1: 'Phase 1: Core Activation & Mobility',
  2: 'Phase 2: Progressive Loading',
  3: 'Phase 3: Functional Movements',
};

const NECK_NONSPECIFIC_PHASE_NAMES_EN: Record<number, string> = {
  1: 'Phase 1: Acute / Pain Relief',
  2: 'Phase 2: Motor Control',
  3: 'Phase 3: Strengthening',
  4: 'Phase 4: Functional Integration',
};

const NECK_RADICULOPATHY_PHASE_NAMES_EN: Record<number, string> = {
  1: 'Phase 1: Acute / Decompression',
  2: 'Phase 2: Neuromobilisation',
  3: 'Phase 3: Strengthening',
  4: 'Phase 4: Functional Integration',
};

const TENSION_PHASE_NAMES_EN: Record<number, string> = {
  1: 'Phase 1: Relaxation & Mobilisation',
  2: 'Phase 2: Motor Control',
  3: 'Phase 3: Strengthening',
  4: 'Phase 4: Functional Integration',
};

const SI_PHASE_NAMES_EN: Record<number, string> = {
  1: 'Phase 1: Acute / Pain Relief',
  2: 'Phase 2: Strengthening',
  3: 'Phase 3: Advanced Strengthening',
  4: 'Phase 4: Return to Activity',
};

const FS_PHASE_NAMES_EN: Record<number, string> = {
  1: 'Phase 1: Pain Management & Gentle Mobilisation',
  2: 'Phase 2: Intensive Stretching & Capsule Mobilisation',
  3: 'Phase 3: Strengthening & Active ROM',
  4: 'Phase 4: Return & Maintenance',
};

const LAS_PHASE_NAMES_EN: Record<number, string> = {
  1: 'Phase 1: Protection & Decongestive Therapy',
  2: 'Phase 2: Early Mobilisation & ROM',
  3: 'Phase 3: Strengthening & Proprioception',
  4: 'Phase 4: Return to Sport & Prevention',
};

const ACL_PHASE_NAMES_EN: Record<number, string> = {
  0: 'Milestone 0: Pre-Op',
  1: 'Milestone 1: Acute Phase',
  2: 'Milestone 2: Early Rehabilitation',
  3: 'Milestone 3: Strength Development',
  4: 'Milestone 4: Neuromuscular Training',
  5: 'Milestone 5: Return to Sport',
  6: 'Milestone 6: Full Clearance',
};
```

**Step 2: Update `getPhaseNames()` to accept a `locale` parameter**

```typescript
export function getPhaseNames(
  tendinopathyType: string,
  locale: string = 'de'
): Record<number, string> {
  const en = locale.startsWith('en');

  if (tendinopathyType === 'ACL_RECONSTRUCTION') {
    return en ? ACL_PHASE_NAMES_EN : ACL_PHASE_NAMES;
  }
  if (tendinopathyType === 'LBP_NONSPECIFIC') {
    return en ? LBP_PHASE_NAMES_EN : LBP_PHASE_NAMES;
  }
  if (tendinopathyType === 'NECK_PAIN') {
    return en ? NECK_NONSPECIFIC_PHASE_NAMES_EN : NECK_NONSPECIFIC_PHASE_NAMES;
  }
  if (tendinopathyType === 'NECK_RADICULOPATHY') {
    return en ? NECK_RADICULOPATHY_PHASE_NAMES_EN : NECK_RADICULOPATHY_PHASE_NAMES;
  }
  if (tendinopathyType === 'NECK_SHOULDER_TENSION') {
    return en ? TENSION_PHASE_NAMES_EN : TENSION_PHASE_NAMES;
  }
  if (tendinopathyType === 'SHOULDER_IMPINGEMENT') {
    return en ? SI_PHASE_NAMES_EN : SI_PHASE_NAMES;
  }
  if (tendinopathyType === 'FROZEN_SHOULDER') {
    return en ? FS_PHASE_NAMES_EN : FS_PHASE_NAMES;
  }
  if (tendinopathyType === 'LATERAL_ANKLE_SPRAIN') {
    return en ? LAS_PHASE_NAMES_EN : LAS_PHASE_NAMES;
  }
  return en ? TENDINOPATHY_PHASE_NAMES_EN : TENDINOPATHY_PHASE_NAMES;
}
```

**Step 3: Update all callers of `getPhaseNames()` in `phaseAdaptation.service.ts` and any other files to pass the locale from `req.headers['accept-language']`**

In `getPhaseStatusForUser()`, add a `locale` parameter:
```typescript
export async function getPhaseStatusForUser(
  userId: string,
  configOverride?: Partial<AdaptationConfig>,
  locale: string = 'de'
): Promise<AdaptivePhaseStatus | null> {
  // ...
  const phaseNames = getPhaseNames(user.tendinopathy_type, locale);
  // ...
}
```

Update all callers in `bridge.controller.ts` and other controllers to pass `req.headers['accept-language'] as string`.

**Step 4: Commit**
```bash
cd /Users/marctoschew/Documents/Physio-App
git add server/src/services/phaseAdaptation.service.ts
git commit -m "feat: add English phase name dictionaries and locale param to getPhaseNames"
```

---

## Task 10: Backend — Localize bridge.controller.ts Day Messages

**Files:**
- Modify: `Physio-App/server/src/controllers/bridge.controller.ts`

**Step 1: Extract language from Accept-Language header**

At the top of the `getSmartDay` handler (or wherever the main handler function is):
```typescript
const locale = (req.headers['accept-language'] as string) || 'de';
const en = locale.startsWith('en');
```

Pass `locale` through to the generator functions.

**Step 2: Update `generateDayMessage` to accept and use `locale`**

```typescript
function generateDayMessage(
  user: any,
  checkin: MorningCheckinModel.MorningCheckin | null,
  isTrainingDay: boolean,
  streak: number,
  isAcl: boolean,
  aclContext: any,
  clientTz?: string,
  locale: string = 'de'
): string {
  const name = user.name?.split(' ')[0] || 'Patient';
  const en = locale.startsWith('en');
  let hour: number;
  try {
    hour = clientTz
      ? parseInt(new Date().toLocaleString('en-US', { timeZone: clientTz, hour: 'numeric', hour12: false }), 10)
      : new Date().getHours();
  } catch { hour = new Date().getHours(); }

  const greeting = en
    ? (hour < 12 ? 'Good morning' : hour < 18 ? 'Good afternoon' : 'Good evening')
    : (hour < 12 ? 'Guten Morgen' : hour < 18 ? 'Guten Tag' : 'Guten Abend');

  if (!checkin) {
    return en
      ? `${greeting}, ${name}! How are you feeling today?`
      : `${greeting}, ${name}! Wie geht es Ihnen heute?`;
  }
  if (checkin.pain_level >= 7) {
    return en
      ? `${name}, today seems like a difficult day. Adjust your training accordingly.`
      : `${name}, heute scheint ein schwieriger Tag zu sein. Passen Sie das Training entsprechend an.`;
  }
  if (checkin.pain_level >= 5) {
    return en
      ? `${name}, today calls for caution. Start gently and listen to your body.`
      : `${name}, heute ist ein vorsichtiger Tag. Starten Sie sanft und hören Sie auf Ihren Körper.`;
  }
  if (!isTrainingDay) {
    return en
      ? `${greeting}, ${name}! Today is your rest day — recovery is just as important as training.`
      : `${greeting}, ${name}! Heute ist Ihr Ruhetag — Erholung ist genauso wichtig wie Training.`;
  }
  if (isAcl && aclContext) {
    return en
      ? `${greeting}, ${name}! Week ${aclContext.weeksPostSurgery} post-op — keep it up!`
      : `${greeting}, ${name}! Woche ${aclContext.weeksPostSurgery} nach der OP — weiter so!`;
  }
  if (streak >= 7) {
    return en
      ? `${greeting}, ${name}! ${streak} days in a row — impressive consistency!`
      : `${greeting}, ${name}! ${streak} Tage am Stück — beeindruckende Konstanz!`;
  }
  if (checkin.pain_level <= 2) {
    return en
      ? `${greeting}, ${name}! Pain is low — a great day for training.`
      : `${greeting}, ${name}! Schmerzen niedrig — ein guter Tag für das Training.`;
  }
  return en
    ? `${greeting}, ${name}! Ready for today's training.`
    : `${greeting}, ${name}! Bereit für das heutige Training.`;
}
```

**Step 3: Update `generateDayInsight` with locale parameter**

```typescript
function generateDayInsight(
  recentPain: { date: string; avgPain: number }[],
  recentCheckinAvg: number | null,
  phaseStatus: any,
  isAcl: boolean,
  aclContext: any,
  locale: string = 'de'
): string {
  const en = locale.startsWith('en');
  if (recentPain.length === 0) {
    return en
      ? 'Start your first training session to gain insights.'
      : 'Starten Sie mit Ihrem ersten Training, um Einblicke zu erhalten.';
  }
  const allLow = recentPain.length >= 5 && recentPain.every(p => p.avgPain <= 3);
  if (allLow) {
    return en
      ? `Your pain has been below 3/10 for ${recentPain.length} days — excellent progress!`
      : `Ihre Schmerzen sind seit ${recentPain.length} Tagen unter 3/10 — sehr guter Verlauf!`;
  }
  if (recentPain.length >= 3) {
    const first = recentPain[0]?.avgPain || 0;
    const last = recentPain[recentPain.length - 1]?.avgPain || 0;
    if (first > last + 1) {
      return en
        ? `Your pain is improving — from ${first.toFixed(1)} to ${last.toFixed(1)}/10.`
        : `Ihre Schmerzen verbessern sich — von ${first.toFixed(1)} auf ${last.toFixed(1)}/10.`;
    }
  }
  if (isAcl && aclContext) {
    return en
      ? `Week ${aclContext.weeksPostSurgery}: Milestone ${aclContext.currentMilestone} reached.`
      : `Woche ${aclContext.weeksPostSurgery}: Meilenstein ${aclContext.currentMilestone} erreicht.`;
  }
  if (phaseStatus) {
    const avg = phaseStatus.currentPainAvg;
    return en
      ? `Average pain in this phase: ${avg.toFixed(1)}/10.`
      : `Durchschnittliche Schmerzen in dieser Phase: ${avg.toFixed(1)}/10.`;
  }
  return en
    ? 'Train regularly for the best results.'
    : 'Trainieren Sie regelmäßig für die besten Ergebnisse.';
}
```

**Step 4: Update `generateProgressHint` with locale parameter**

```typescript
function generateProgressHint(phaseStatus: any, locale: string = 'de'): string | null {
  if (!phaseStatus?.progressionReadiness) return null;
  const r = phaseStatus.progressionReadiness;
  const en = locale.startsWith('en');
  const allMet = r.minDaysMet && r.minSessionsMet && r.painCriteriaMet && r.complianceCriteriaMet;
  if (allMet) {
    return en
      ? 'All criteria for the next phase met — progression is imminent!'
      : 'Alle Kriterien für die nächste Phase erfüllt — Progression steht bevor!';
  }
  const missing: string[] = [];
  if (!r.minDaysMet) missing.push(en ? 'minimum days' : 'Mindest-Tage');
  if (!r.minSessionsMet) missing.push(en ? 'minimum sessions' : 'Mindest-Sitzungen');
  if (!r.painCriteriaMet) missing.push(en ? 'pain criterion' : 'Schmerzkriterium');
  if (!r.complianceCriteriaMet) missing.push(en ? 'adherence' : 'Adhärenz');
  if (missing.length <= 2) {
    return en
      ? `Almost ready for Phase ${phaseStatus.currentPhase + 1} — still open: ${missing.join(', ')}.`
      : `Fast bereit für Phase ${phaseStatus.currentPhase + 1} — noch offen: ${missing.join(', ')}.`;
  }
  return null;
}
```

**Step 5: Update all call sites** to pass `locale` from `req.headers['accept-language']`.

**Step 6: Commit**
```bash
git add server/src/controllers/bridge.controller.ts
git commit -m "feat: localize Smart Day day messages, insights and progress hints (DE/EN)"
```

---

## Task 11: Enable ProtocolLoader to Load English Protocol JSON Files

**Files:**
- Modify: `Reapptivate/Services/ProtocolLoader.swift`

**Step 1: Update the file-loading logic to check for `_en` suffix**

Find the protocol loading function. After getting the base filename key, add:

```swift
func load(for user: UserProfile, trainingDays: [Int]?) -> ExerciseProtocol? {
    let baseKey = protocolKey(for: user)
    // Choose english file if language is english AND english file exists
    let englishKey = isEnglish ? "\(baseKey)_en" : nil

    // Check english file first
    if let engKey = englishKey, let cached = cache[engKey] {
        return cached
    }
    if let cached = cache[baseKey] {
        return cached
    }

    // Load from bundle
    if let engKey = englishKey,
       let url = Bundle.main.url(forResource: engKey, withExtension: "json", subdirectory: "Protocols")
                 ?? Bundle.main.url(forResource: engKey, withExtension: "json") {
        if let protocol = try? loadFromURL(url) {
            cache[engKey] = protocol
            return protocol
        }
    }

    // Fallback to German
    if let url = Bundle.main.url(forResource: baseKey, withExtension: "json", subdirectory: "Protocols")
               ?? Bundle.main.url(forResource: baseKey, withExtension: "json") {
        if let protocol = try? loadFromURL(url) {
            cache[baseKey] = protocol
            return protocol
        }
    }
    return nil
}
```

**Step 2: Invalidate cache on language change**

Add a public method `invalidateCache()` and call it from `LanguageManager` when language changes:

In `LanguageManager.swift`:
```swift
var language: AppLanguage {
    get { AppLanguage(rawValue: _language) ?? .german }
    set {
        _language = newValue.rawValue
        ProtocolLoader.shared.invalidateCache()
    }
}
```

**Step 3: Commit**
```bash
git add Reapptivate/Services/ProtocolLoader.swift Reapptivate/App/LanguageManager.swift
git commit -m "feat: ProtocolLoader loads _en JSON variants when English is selected"
```

---

## Task 12: Create English Protocol JSON Files — Tendinopathy

**Files to create** (in `Reapptivate/Resources/Protocols/`):
- `achilles_en.json`, `patellar_en.json`, `tennis_elbow_en.json`, `golfers_elbow_en.json`
- `rotator_cuff_en.json`, `gluteal_en.json`, `plantar_fascia_en.json`, `proximal_hamstring_en.json`

**Step 1: Copy `achilles.json` and translate exercise fields**

For each protocol file, translate these fields only (keep numeric values identical):
- `name` → English exercise name
- `description` → English description
- `instructions` → English instructions array
- Phase `name` (if present) → English phase name

Example translated `achilles_en.json` exercise entry:
```json
{
  "id": "achilles_isometric_1",
  "name": "Isometric Calf Hold",
  "description": "A static hold exercise to reduce pain and maintain tendon load during the acute phase.",
  "instructions": [
    "Stand on one leg, rise onto the ball of your foot",
    "Hold the position for the specified number of seconds",
    "Lower slowly and repeat"
  ],
  "sets": 3,
  "reps": null,
  "holdSeconds": 45,
  "type": "ISOMETRIC"
}
```

**Step 2: For each of the 8 tendinopathy protocol files, create the `_en` variant**

See original files in `Reapptivate/Resources/Protocols/` for structure.

**Step 3: Commit after all tendinopathy files**
```bash
git add Reapptivate/Resources/Protocols/*_en.json
git commit -m "feat: add English protocol JSON files for all tendinopathy conditions"
```

---

## Task 13: Create English Protocol JSON Files — LBP, Neck, Tension

Translate these protocol files to English variants (`_en.json`):
- `lbp_ar_en.json`, `lbp_der_en.json`, `lbp_eer_en.json`, `lbp_far_en.json`
- `neck_pain_en.json`, `neck_radiculopathy_en.json`
- `neck_shoulder_tension_leicht_en.json`, `neck_shoulder_tension_mittel_en.json`, `neck_shoulder_tension_schwer_en.json`

Same approach as Task 12 — translate `name`, `description`, `instructions` fields only.

```bash
git commit -m "feat: add English protocol files for LBP, Neck and Tension conditions"
```

---

## Task 14: Create English Protocol JSON Files — SI, FS, LAS

Translate:
- `shoulder_impingement_leicht_en.json`, `_mittel_en.json`, `_schwer_en.json`
- `frozen_shoulder_leicht_en.json`, `_mittel_en.json`, `_schwer_en.json`
- `lateral_ankle_sprain_leicht_en.json`, `_mittel_en.json`, `_schwer_en.json`

```bash
git commit -m "feat: add English protocol files for SI, FS and LAS conditions"
```

---

## Task 15: Create English Education Cards JSON (iOS Bundle)

**Files:**
- Create: `Reapptivate/Resources/education-cards_en.json`

**Step 1: Update `EducationCardLoader` to check language**

In `EducationCard.swift`, find `EducationCardLoader.load()` and add:

```swift
private static func loadCards() -> [EducationCard] {
    let isEnglish = UserDefaults.standard.string(forKey: "appLanguage") == "en"
    let filename = isEnglish ? "education-cards_en" : "education-cards"
    guard let url = Bundle.main.url(forResource: filename, withExtension: "json")
                    ?? Bundle.main.url(forResource: "education-cards", withExtension: "json"),
          let data = try? Data(contentsOf: url),
          let cards = try? JSONDecoder().decode([EducationCard].self, from: data)
    else { return [] }
    return cards
}
```

Also add cache invalidation on language change (same pattern as ProtocolLoader).

**Step 2: Create `education-cards_en.json`**

Translate every card's `title`, `subtitle`, and `body` fields from German to English.
Structure is identical to `education-cards.json`.

Key translations for common cards:
- "Warum tut es weh?" → "Why Does It Hurt?"
- "Die Nozizeptor-Theorie" → "The Nociceptor Theory"
- "Schmerz ist kein Maß für Gewebeschaden" → "Pain is Not a Measure of Tissue Damage"
- "Aktiv bleiben hilft" → "Staying Active Helps"
- "Was ist eine Tendinopathie?" → "What is Tendinopathy?"

**Step 3: Commit**
```bash
git add Reapptivate/Resources/education-cards_en.json Reapptivate/Models/Domain/EducationCard.swift
git commit -m "feat: add English education cards JSON and language-aware card loading"
```

---

## Task 16: Backend — Add English Micro-Module Entries

**Files:**
- Modify: `Physio-App/server/src/data/micro-modules.json`

**Step 1: For every module entry with `"locale": "de"`, add a parallel `"locale": "en"` entry with the same key**

The `micro-modules.json` contains entries like:
```json
{
  "key": "lbp_understanding_pain",
  "locale": "de",
  "title": "Schmerz verstehen",
  "bodyMarkdown": "...",
  "takeHome": "...",
  "taskType": "REFLECTION",
  "targetCondition": "LBP"
}
```

Add after each `"de"` entry:
```json
{
  "key": "lbp_understanding_pain",
  "locale": "en",
  "title": "Understanding Pain",
  "bodyMarkdown": "...",
  "takeHome": "...",
  "taskType": "REFLECTION",
  "targetCondition": "LBP"
}
```

**Step 2: Update all backend micro-module endpoints to filter by locale**

In `lbpEnhancements.controller.ts`, `tension.controller.ts`, `neck.controller.ts`, `shoulderImpingement.controller.ts`, `frozenShoulder.controller.ts`, `lateralAnkleSprain.controller.ts`:

```typescript
const locale = (req.headers['accept-language'] as string)?.startsWith('en') ? 'en' : 'de';
const modules = allModules.filter(m => m.locale === locale && /* existing filters */);
```

**Step 3: Do the same for `acl-micro-modules.json`**

**Step 4: Commit**
```bash
git add server/src/data/micro-modules.json server/src/data/acl-micro-modules.json
git add server/src/controllers/*.controller.ts
git commit -m "feat: add English micro-module entries and locale-based filtering"
```

---

## Task 17: Backend — English Screening Config Files

**Files to create** (in `Physio-App/server/src/data/`):
- `aem-screening-config_en.json`
- `neck-screening-config_en.json`
- `tension-screening-config_en.json`
- `shoulder-impingement-screening-config_en.json`
- `frozen-shoulder-screening-config_en.json`
- `lateral-ankle-sprain-screening-config_en.json`
- `acl-screening-config_en.json`

**Step 1: For each screening config, create `_en` variant**

Translate all question `text`, `subtitle`, answer `label` fields to English. Keep all scoring logic, IDs, and values identical.

Example neck screening question:
```json
{
  "id": "pain_intensity",
  "text": "How intense is your neck pain?",
  "subtitle": "0 = no pain, 10 = worst possible pain",
  "type": "SCALE",
  "min": 0,
  "max": 10
}
```

**Step 2: Update `getConfig` endpoints to check Accept-Language header**

In each screening controller's `getConfig` function:
```typescript
export async function getConfig(req: Request, res: Response): Promise<void> {
  const locale = (req.headers['accept-language'] as string)?.startsWith('en') ? 'en' : 'de';
  const config = loadConfig(locale);  // pass locale to loadConfig
  res.json({ ... });
}
```

Update `loadConfig()` to accept locale and load `_en.json` when `locale === 'en'`.

**Step 3: Commit**
```bash
git add server/src/data/*-screening-config_en.json
git commit -m "feat: add English screening config files for all conditions"
```

---

## Task 18: Backend — English Daily Tips JSON Files

**Files to create:**
- `neck-daily-tips_en.json`, `tension-daily-tips_en.json`
- `shoulder-impingement-daily-tips_en.json`, `frozen-shoulder-daily-tips_en.json`
- `lateral-ankle-sprain-daily-tips_en.json`, `acl-daily-tips_en.json`

Translate all tip text fields to English. Update focus areas controllers to load `_en` variant when `Accept-Language: en`.

```bash
git commit -m "feat: add English daily tips files and locale-aware loading"
```

---

## Task 19: Backend — English Work Timer Exercises

**Files:**
- Create: `Physio-App/server/src/data/work-timer-exercises_en.json`

Translate all exercise `name`, `description`, and `instructions` fields.

Example:
```json
{
  "id": "neck_circles",
  "name": "Neck Circles",
  "description": "Gentle neck rotation to relieve tension",
  "duration": 60,
  "category": "neck"
}
```

Update work timer controller to load `_en` variant when `Accept-Language: en`.

```bash
git commit -m "feat: add English work timer exercises and locale-aware loading"
```

---

## Task 20: Add English to project.yml (Xcode Localization)

**Files:**
- Modify: `project.yml`

**Step 1: Add English to known regions and localization settings**

In `project.yml` under the project settings:
```yaml
settings:
  DEVELOPMENT_LANGUAGE: de
  KNOWN_REGIONS:
    - de
    - en
    - Base
```

This ensures Xcode recognizes `Localizable.xcstrings` as a localized resource with `de` and `en` variants.

**Step 2: Regenerate project**
```bash
xcodegen generate
```

**Step 3: Build to verify no errors**
```bash
xcodebuild -project Reapptivate.xcodeproj -scheme Reapptivate \
  -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO 2>&1 | grep -E "error:|warning:|BUILD"
```

**Step 4: Commit**
```bash
git add project.yml Reapptivate.xcodeproj/project.pbxproj
git commit -m "feat: add English to Xcode project known regions"
```

---

## Task 21: iOS — Handle Interpolated Strings in Views

Some views use string interpolation that can't be handled by the locale environment alone:
- `Text("\(count) Tage Streak")` — needs refactoring
- `Text("\(user.daysSinceStart) Tage")` — needs refactoring

**Step 1: Create a `String` extension helper**

Create `Reapptivate/Utils/StringLocalization.swift`:
```swift
import Foundation

extension String {
    /// Returns "day" or "days" (or German equivalent) based on count and current language
    static func days(_ count: Int) -> String {
        let en = UserDefaults.standard.string(forKey: "appLanguage") == "en"
        return en ? (count == 1 ? "day" : "days") : (count == 1 ? "Tag" : "Tage")
    }

    static func weeks(_ count: Int) -> String {
        let en = UserDefaults.standard.string(forKey: "appLanguage") == "en"
        return en ? (count == 1 ? "week" : "weeks") : (count == 1 ? "Woche" : "Wochen")
    }

    static func sessions(_ count: Int) -> String {
        let en = UserDefaults.standard.string(forKey: "appLanguage") == "en"
        return en ? (count == 1 ? "session" : "sessions") : (count == 1 ? "Einheit" : "Einheiten")
    }
}
```

**Step 2: Update views using these patterns**

Find occurrences of `"\(count) Tage"` etc. and replace:
```swift
// Before:
Text("\(streak.current) \(streak.current == 1 ? "Tag Streak" : "Tage Streak")")

// After:
Text("\(streak.current) \(String.days(streak.current)) Streak")
```

**Step 3: Commit**
```bash
git add Reapptivate/Utils/StringLocalization.swift
git commit -m "feat: add StringLocalization helpers for plural-aware day/week/session strings"
```

---

## Task 22: Final Integration Test

**Step 1: Build**
```bash
make generate && xcodebuild -project Reapptivate.xcodeproj -scheme Reapptivate \
  -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO 2>&1 | tail -5
```

**Step 2: Launch app and test**
```bash
xcrun simctl launch "iPhone 17 Pro" com.reapptivate.ios
```

1. Open Settings → verify "Sprache / Language" picker visible
2. Switch to English → verify all main UI strings change immediately
3. Check Overview tab: "Training Day" / "Rest Day", streak, today's program
4. Check Settings: all section headers in English
5. Check program tab: exercise names in English (if _en protocol file exists)
6. Switch back to German → verify everything reverts

**Step 3: Commit any fixes found during testing**

---

## Execution Notes

- **Tasks 1–4** = infrastructure, do first, enables language switching (even if most text still German)
- **Tasks 5–8** = core UI strings, highest user-visible impact
- **Tasks 9–10** = backend day messages
- **Tasks 11–21** = content files, can be done incrementally
- English falls back to German if `_en` file doesn't exist yet (safe incremental delivery)
- Run `xcodegen generate` after any `project.yml` changes
- Backend auto-reloads (nodemon) — no restart needed for controller changes
