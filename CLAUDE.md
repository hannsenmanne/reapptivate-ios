# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Skills

**MANDATORY — DO NOT REMOVE THIS SECTION, even when updating or rewriting CLAUDE.md**: At the start of EVERY prompt, invoke the `using-superpowers` skill via the Skill tool. This skill determines which other skills apply to the current task and ensures they are used. No exceptions — even for simple questions or clarifications. This instruction is permanent and must be preserved across all edits to this file.

## Code Review

After writing or modifying code, always run the `ios-code-reviewer` agent to review the changes before considering the task complete. This applies to new features, bug fixes, and refactors.

# REAPPTIVATE iOS

Native iOS companion app for the Reapptivate physiotherapy platform. Communicates with the same Express/PostgreSQL backend as the web app.

**Tech stack**: iOS 17.0+, Swift 6.0, SwiftUI, @Observable, MVVM, SwiftData, URLSession async/await. Zero external dependencies.

## Build & Run

```bash
# Generate Xcode project from project.yml (requires xcodegen: brew install xcodegen)
xcodegen generate

# Build for simulator
xcodebuild -project Reapptivate.xcodeproj -scheme Reapptivate \
  -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Install & launch on simulator (build output goes to DerivedData)
xcrun simctl install "iPhone 17 Pro" \
  ~/Library/Developer/Xcode/DerivedData/Reapptivate-*/Build/Products/Debug-iphonesimulator/Reapptivate.app
xcrun simctl launch "iPhone 17 Pro" com.reapptivate.ios

# Launch with dev token injection (DEBUG builds only)
# Token MUST come from localhost:3000 (local JWT secret differs from production)
xcrun simctl launch "iPhone 17 Pro" com.reapptivate.ios --dev-token "$JWT" --dev-user-id "$USER_ID"

# Get a local dev token
curl -s -X POST "http://localhost:3000/api/onboarding/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"FARtest@test.com","password":"Test1234!"}'

# Switch simulator dark/light mode
xcrun simctl ui "iPhone 17 Pro" appearance dark   # or light
```

Backend must be running at `localhost:3000` for DEBUG builds. Start it from the Physio-App repo: `cd ../Physio-App && npm run dev`

## Testing

```bash
# Run all unit tests (generates project first)
make test

# Run a single test class
xcodebuild test -project Reapptivate.xcodeproj -scheme Reapptivate \
  -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:ReapptivateTests/APIClientTests \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO

# Run a single test method
xcodebuild test ... -only-testing:ReapptivateTests/APIClientTests/testRequestDecodesSuccessResponse

# Run UI tests
make test-ui

# View coverage report (after make test)
make coverage
```

**~310 unit tests** in `Reapptivate/Tests/ReapptivateTests/` covering Models, Services, ViewModels, and AppState. CI runs on GitHub Actions (`.github/workflows/test.yml`) on every push/PR to main.

**Makefile shortcuts:**
- `make generate` — Generate Xcode project from project.yml
- `make test` — Run all unit tests (generates project first)
- `make test-ui` — Run UI tests
- `make coverage` — View coverage report (run after make test)
- `make clean` — Clean build artifacts

### Test Architecture
- **`MockURLProtocol`** — URLProtocol subclass intercepting all requests via static `requestHandler`. Uses `nonisolated(unsafe)` for Swift 6.0.
- **`TestHelpers`** — `makeTestSession()` (ephemeral URLSession with MockURLProtocol), `makeHTTPResponse()`, `makeJWT(exp:)` for TokenManager tests.
- **`TestFixtures`** — Factory methods for domain models and JSON response data.
- All ViewModel/Service tests use `@MainActor` with `override func setUp() async throws` (no `super.setUp()` call — required for Xcode 16.4 Sendable compatibility).

## XcodeGen (`project.yml`)

Resources MUST be in the `sources` array with `buildPhase: resources` — NOT as a separate top-level key:

```yaml
sources:
  - path: Reapptivate
    excludes:
      - "Tests/**"
      - "Resources/**"
  - path: Reapptivate/Resources
    buildPhase: resources
```

After any changes to `project.yml`, regenerate: `xcodegen generate`

## Architecture

### MVVM with @Observable

All ViewModels: `@Observable @MainActor final class`. They take `APIClient` via init and are created in views with the lazy optional `@State` + `.task` pattern:

```swift
@State private var viewModel: SomeViewModel?
.task {
    let vm = SomeViewModel(apiClient: apiClient)
    viewModel = vm
    await vm.loadData()
}
```

The ViewModel is always `Optional` and created once inside `.task`. **Exception:** `ExerciseViewModel` has no `APIClient` dependency — it uses `ProtocolLoader.shared` to load bundled JSON.

### Environment Injection

Four shared `@Observable` objects injected via SwiftUI environment from `ReapptivateApp`:
- `AppState` — auth state, current user, computed flags: `isLbp`, `isNeck`, `isTension`, `isShoulder`, `isFrozenShoulder`, `isAcl`, `isLateralAnkleSprain`, `needsAemScreening`, `needsNeckScreening`, `needsTsiScreening`, `needsShoulderScreening`, `needsFsScreening`, `needsAclScreening`, `needsLasScreening`
- `APIClient` — networking with auto JWT injection, 401 detection + logout callback, 1 retry on network failure
- `NetworkMonitor` — NWPathMonitor wrapper for connectivity
- `LanguageManager` — language state (`AppLanguage` enum: `.german`/`.english`), persisted to UserDefaults(`"appLanguage"`), also set as `.environment(\.locale)` on WindowGroup

SwiftData `ModelContainer` is configured at `WindowGroup` level (not in AppState): `.modelContainer(for: [CachedUser.self, CachedProgress.self, PendingSync.self])`. `SyncService` receives its `ModelContext` via a deferred `setModelContext()` call — not at init — because the context comes from the view environment.

### Navigation Flow (RootView)

```
ReapptivateApp (root)
├── LoadingView (isCheckingAuth)
├── LoginView (not authenticated)
├── AemScreeningView (LBP + needsAemScreening)
├── NeckScreeningView (Neck + needsNeckScreening)
├── TsiScreeningView (Tension + needsTsiScreening)
├── AclScreeningView (ACL + needsAclScreening)
├── SiScreeningView (Shoulder + needsShoulderScreening)
├── FsScreeningView (FrozenShoulder + needsFsScreening)
├── LasScreeningView (LateralAnkleSprain + needsLasScreening)
├── ScreeningCompleteView (first login, after screening)
├── FeatureWalkthroughView (first login, after welcome)
└── DashboardView (authenticated + screened + onboarded)
    ├── OverviewTab — Phase status, Wissen daily card (tendinopathy only), condition info
    ├── ProgramTab — Exercise list + LBP enhancements
    ├── EdukationTab — Micro-modules (LBP/Neck/Tension/SI/FS/LAS) or Wissen cards (tendinopathy only)
    ├── ProgressTab — Pain history, statistics
    ├── InsightsTab — Analytics (LBP/Neck only)
    └── MessagesTab — Clinical messaging threads (all conditions)
```

EdukationTab is always visible. InsightsTab only appears for LBP/Neck patients. MessagesTab is available for all conditions. Tab visibility is controlled by `FloatingTabBar.tabs` computed property (not by `DashboardViewModel.availableTabs`, which is unused).

**WissenCardView / WissenAllCardsView** are only shown for tendinopathy patients. SI, FS, ACL, LAS patients do NOT show these — they use condition-specific micro-modules in EdukationTab and have no daily Wissen card in OverviewTab.

### Networking

`APIEndpoints` enum: static methods returning `URLRequest` with 30-second timeout. Base URL switches on `#if DEBUG`:
- DEBUG: `http://localhost:3000/api`
- RELEASE: `https://physio-app-server-production.up.railway.app/api`

`APIClient` has three request methods:
- `request<T: Decodable>()` — decodes response to `T`
- `requestVoid()` — ignores response body
- `requestData()` — returns raw `Data`

All requests: Bearer token injection, snake_case → camelCase **decoding only** (uploads use standard camelCase encoding — no `convertToSnakeCase`), ISO8601 date parsing (with/without fractional seconds), 401 → `onTokenExpired` callback, 1 retry with 2s delay **only on network errors** (not on 4xx/5xx).

**Encoding gotcha**: Most backend controllers destructure camelCase from `req.body` (e.g., `exerciseId`, `painLevel`). When a request fails silently (data not persisted), check the backend controller's destructuring. Fix with `CodingKeys` on the request struct.

**Schedule weekday convention**: Backend uses JS `getDay()` (0=Sun, 1=Mon, ..., 6=Sat). iOS uses `Calendar.component(.weekday)` (1=Sun, 2=Mon, ..., 7=Sat). `ScheduleResponse.iosWeekdays` converts JS→iOS (+1), `ScheduleUpdateRequest.fromIOSWeekdays()` converts iOS→JS (-1).

Backend wraps responses in containers (`{user: ...}`, `{plan: ...}`). All wrappers defined in `APIResponses.swift`. **Not all responses are wrapped** — some return data directly (e.g., schedule, analytics). Always verify the actual response shape from the backend controller's `res.json(...)` call.

### JWT Token Storage

`TokenManager` (singleton, `@unchecked Sendable`) stores JWT + user ID in iOS Keychain via `KeychainHelper`. Checks expiry by decoding JWT payload `exp` claim with 5-minute buffer.

**Important**: Keychain persists across app reinstalls. To clear during testing: `xcrun simctl keychain "iPhone 17 Pro" reset`

### Offline Support (SwiftData)

- `CachedUser` / `CachedProgress` — last-known-good data for offline display (`@Attribute(.unique)` on IDs)
- `PendingSync` — queued failed requests (max 5 retries, sorted by `createdAt`)
- `SyncService` drains queue when `NetworkMonitor.isConnected` becomes true

### Protocol Loading

`ProtocolLoader.shared` (`@unchecked Sendable` singleton with in-memory cache) loads bundled JSON from `Resources/Protocols/`. Falls back to bundle root if subdirectory not found (XcodeGen bundles files flat). Uses `convertFromSnakeCase` key decoding. Cache is never invalidated (protocol changes require app restart).

Protocol key mapping: `TendinopathyType` → filename (e.g., `.achilles` → `achilles.json`, `.lbpNonspecific` + `.FAR` → `lbp_far.json`, `.neckShoulderTension` + `.LEICHT` → `neck_shoulder_tension_leicht.json`, `.shoulderImpingement` + `.LEICHT` → `shoulder_impingement_leicht.json`, `.frozenShoulder` + `.SCHWER` → `frozen_shoulder_schwer.json`, `.lateralAnkleSprain` + `.LEICHT` → `lateral_ankle_sprain_leicht.json`).

**Dosage modifier application**: `ExerciseWithPhase.dosageModifier` is a `[String: DosageMultipliers]` keyed by severity raw value. Applied at load time in `ExerciseViewModel.loadExercises()` for FS SCHWER patients via `applyingDosageModifier(severityKey:)`. For example, SCHWER applies 67% sets and 80% reps. Must call `max(1, ...)` when applying to prevent zero values.

### Localization (German/English)

The app uses a **runtime language switching** pattern — NOT native iOS `String(localized:)` or `NSLocalizedString`. All 124 view files, 6 ViewModels, and 2 services are localized.

**In Views** — use `@AppStorage("appLanguage")` with ternaries:
```swift
@AppStorage("appLanguage") private var appLanguage = "de"
// Then for every user-visible string:
Text(appLanguage == "en" ? "English text" : "German text")
```

**In ViewModels/Services** — use `UserDefaults` directly (no `@AppStorage` available):
```swift
private var isEn: Bool { UserDefaults.standard.string(forKey: "appLanguage") == "en" }
// Then: errorMessage = isEn ? "English error" : "German error"
```

**For `displayName` on enums** (in `SharedTypes.swift`, `ProtocolLoader.swift`) — use file-level helper:
```swift
private var isEnglishLocale: Bool {
    UserDefaults.standard.string(forKey: "appLanguage") == "en"
}
```

**Protocol JSON files** have language variants: `lbp_far.json` (German) / `lbp_far_en.json` (English). `ProtocolLoader.resolveFilename()` automatically resolves `_en` variants when English is active, with fallback to German if no English file exists. Cache keys are language-aware.

**Rules for new code:**
- Every new View MUST include `@AppStorage("appLanguage")` and localize all user-visible strings
- Every new ViewModel error/success message MUST use the `isEn` pattern
- German is the default language (`appLanguage` defaults to `"de"`)
- Language choice persists across app restarts (UserDefaults) and is NOT cleared on logout
- `Localizable.xcstrings` exists (239 entries) but is NOT used by the runtime pattern — it's a reference catalog

### Content Filtering Pattern (Condition-Specific Content)

To prevent cross-contamination of condition-specific educational content:

**Client-side defensive filtering:**
- ViewModels filter loaded content by `targetCondition` field
- Example: `LbpEnhancementsViewModel` excludes modules with `targetCondition === "NECK_PAIN"` or `"NECK_SHOULDER_TENSION"`
- Only shows modules where `targetCondition` is `nil` (generic) or matches the patient's condition

**Backend filtering:**
- Endpoints filter by `targetCondition` before returning data
- Example: `/lbp-enhancements/micro-modules` excludes non-LBP modules server-side
- Defense-in-depth approach: both client and server enforce filtering

**Pattern:** Always implement both client-side defensive filtering (catch backend mistakes) and server-side authoritative filtering (prevent wrong data from being sent).

## Key Gotchas

- **`adaptivePhase` in `UserProfile`** is optional and NOT populated from `/patient/me`. It comes from the separate `/patient/phase-status` endpoint. `currentPhase` computed property defaults to `1`.
- **`ExerciseWithPhase`** has a custom decoder that handles both nested (`{"exercise": {...}, "phase": 1}`) and flat (`{"id": "...", "name": "...", "phase": 1}`) JSON formats from protocol files.
- **`AnyCodable`** helper in `LbpTypes.swift` wraps dynamic JSON values (used for `ExposureLog.performedDose` which can be String, Int, Double, Bool, or nested).
- **`UserProfile.id` is `String`**, not UUID.
- **`@unchecked Sendable`** is used on `TokenManager`, `ProtocolLoader`, and `NetworkMonitor` for cross-actor access in Swift 6.0 strict concurrency mode.
- **Dev token must come from local backend** — local and production JWT secrets differ, so a production token won't work with `localhost:3000` and vice versa.
- **`Color.textPrimary` flips in dark mode** (light→1A1A1A, dark→F2F2F7). Don't use it as a background with hardcoded `.white` text — use `Color.appBg` for the text instead so both adapt together. Same applies to any adaptive color used as a bg.
- **`AnalyticsSummary` has a custom decoder** — backend sends `adjustmentStats: {total, applied}` (nested) and `triggerFireCount: {ruleId: count}` (dict), but the model exposes flat `totalAdjustments`/`appliedAdjustments` and `triggerFires: [TriggerFireCount]` (array). Don't add simple `CodingKeys` — the custom `init(from:)` handles the shape transformation.
- **Onboarding `@AppStorage` flags** (`hasSeenWelcome`, `hasSeenWalkthrough`) must NOT be cleared on logout — they persist so returning users skip the walkthrough. Only SwiftData caches are cleared via `SyncService.clearAllData()`.
- **All DateFormatters use explicit UTC timezone** — Date-only strings ("yyyy-MM-dd") must use `DateFormatters.dateOnly` formatter, never `Date()` string interpolation. ISO8601 formatters explicitly set `timeZone = TimeZone(secondsFromGMT: 0)`. This prevents date shifts when parsing/formatting across timezones (e.g., "2024-01-15" parsed in PST becoming Jan 14).

## Domain Models (Models/Domain/)

- `SharedTypes.swift` — All shared enums: `TendinopathyType` (15 cases: achilles, patellar, tennisElbow, golfersElbow, rotatorCuff, gluteal, proximalHamstring, plantarFascia, lbpNonspecific, neckPain, neckShoulderTension, aclReconstruction, shoulderImpingement, frozenShoulder, lateralAnkleSprain), `ExerciseType`, `AdaptationDecision`, `AemSubtype`, `NdiSeverityGrade`, `LasSeverityGrade`, `SymptomResponse`
- `LbpTypes.swift` — Largest model file: fear hierarchies, exposure logs, pacing plans/templates/logs, plan adjustments, micro-modules, analytics types, `AnyCodable`
- `NeckTypes.swift` — NDI screening config/results, focus areas, NDI history
- `TensionTypes.swift` — TSI screening config/results/submission, focus areas, history, micro-modules
- `ShoulderImpingementTypes.swift` — QuickDASH screening config/results/submission, `SiSeverityGrade` (LEICHT/MITTEL/SCHWER from QuickDASH score), focus areas, history, micro-modules
- `FrozenShoulderTypes.swift` — SPADI screening config/results/submission, `FsSeverityGrade` (LEICHT ≤34 / MITTEL 35–59 / SCHWER ≥60), focus areas, history, micro-modules
- `AclTypes.swift` — ACL stream/exercise models, milestone status, schedule data, KPI types. `AclStreamExercise` has custom decoder for flexible backend shapes.
- `LateralAnkleSprainTypes.swift` — CAIT screening config/results/submission, `LasSeverityGrade` (LEICHT ≥24 / MITTEL 12–23 / SCHWER ≤11 from CAIT score), focus areas, history, micro-modules
- `AemTypes.swift` — AEM screening config/results/submission
- `AuthTypes.swift` — Login/onboarding request/response types
- `MorningCheckin.swift` — Morning check-in models, smart day response, streak info
- `ClinicalThread.swift` / `ClinicalMessage.swift` — Clinical messaging thread and message models
- `MotivationalQuote.swift` — Quote model + `QuoteLoader` singleton (loads bundled quotes, daily rotation)
- `APIResponses.swift` — All backend response wrappers (`{user:}`, `{plan:}`, `{hierarchy:}`, etc.)
- `EducationCard.swift` — Education card model + `EducationCardLoader` singleton (loads bundled `education-cards.json`, filters by phase/condition, daily rotation via day-of-year modulo). Cards with `condition == nil` are generic tendinopathy cards — SI/FS/ACL patients never see them.
- `CustomExercise.swift` — Custom exercises added by users (displayed in ProgramTab alongside protocol exercises)
- `UserSchedule.swift` — `ScheduleResponse` (GET response with `trainingDays` + `isTrainingDay`, JS weekday convention) and `ScheduleUpdateRequest` (PUT body, with `fromIOSWeekdays()` converter)

## Design System

### Design Tokens (`DesignTokens` enum)
Cards: 14px continuous corners, adaptive shadow (black 6% light / white 4% dark, radius 8, y: 2). Buttons: 12px corners, 50px height, spring scale(0.97). Inputs: 10px corners, 1px gray300 border. Badges: 8px corners, color.opacity(0.1) background.

### Colors (`Color+Theme.swift`) — Dark Mode Adaptive
All semantic colors use `Color(UIColor { traitCollection in ... })` via a private `adaptive(light:dark:)` helper:

| Token | Light | Dark |
|-------|-------|------|
| appBg | F8F8FA | 121214 |
| cardBg | FFFFFF | 1C1C1E |
| textPrimary | 1A1A1A | F2F2F7 |
| textSecondary | 6B7280 | 8E8E93 |
| accent | 10B981 | 34D399 |

Domain colors (painGreen, painAmber, painRed, farBlue, etc.) are vivid enough for both modes and don't adapt. ShapeStyle extensions enable `.foregroundStyle(.textPrimary)` syntax. Helpers: `Color.painColor(for:)`, `Color.subtypeColor(for:)`, `Color.severityColor(for:)`.

### Appearance Mode
`AppearanceMode` enum (system/light/dark) persisted via `@AppStorage("appearanceMode")`. Applied on root `WindowGroup` with `.preferredColorScheme()`. User-facing picker in SettingsView under "Darstellung" section.

### Typography (`Font+Theme.swift`)
Outfit font family (6 weights bundled as TTF). Semantic: `.appLargeTitle` (34), `.appTitle` (28), `.appTitle2` (22), `.appHeadline` (17 semibold), `.appBody` (17), `.appCaption` (12). Custom: `Font.outfit(.semibold, size: 18)`.

### View Modifiers (`ViewModifiers+Design.swift`)
`.cardStyle()`, `.accentCardStyle(color:)` (4px left accent via `UnevenRoundedRectangle`), `.inputFieldStyle()`, `.badgeStyle(color:)`, `.infoBoxStyle(color:)`. Button styles: `.primary` (dark), `.secondary` (border, has disabled state with `.gray400`/`.opacity(0.6)`), `.accentFilled` (emerald).

### Common Views
- `InlineErrorView` — compact error banner with icon + message + retry button, used for recoverable API failures in neck views
- `EmptyStateView` — icon + title + message for empty data states

## UX Patterns

### Haptic Feedback
Uses SwiftUI `.sensoryFeedback()` modifier (iOS 17+) with boolean trigger pattern:
```swift
@State private var hapticTrigger = false
.sensoryFeedback(.success, trigger: hapticTrigger)
// then: hapticTrigger.toggle()
```
Applied to: tab selection (`.selection`), set completion (`.impact`), exercise/progress log submit (`.success`), fear hierarchy save, exposure step advance, activity/symptom selection (`.selection`), module marked read (`.success`).

### Audio Cues
`AudioService.shared` (`@Observable @MainActor` singleton) centralizes system sounds + haptics. Key methods: `playDoubleKnock()` (80% pacing cue), `playTripleBeep()` (100% pacing cue). Must call `activateSession()` before and `deactivateSession()` after timer use.

### Accessibility
- `@ScaledMetric` on icon container sizes (badges, rank circles, play/pause buttons)
- `.accessibilityElement(children: .ignore)` + `.accessibilityAdjustableAction` on `PainSliderView` for VoiceOver
- `.accessibilityAddTraits(.isSelected)` on tab bar, symptom picker, AEM Likert options
- `.accessibilityHidden(true)` on decorative header icons
- `.accessibilityLabel()` on icon-only buttons (settings gear, profile menu, move/delete)
- Contextual loading labels: `ProgressView(isEn ? "Loading neck modules..." : "Nacken-Module laden...")` instead of bare `ProgressView()`

### Error Handling in Views
Views that load data from API use a consistent pattern:
```swift
@State private var errorMessage: String?
// In catch block: errorMessage = isEn ? "English message." : "German message."
// In body: if let error = errorMessage { InlineErrorView(message: error) { Task { await reload() } } }
```

## Key Domain Concepts

### Conditions & Subtypes
- **Tendinopathies** (8 types): 3-phase progression (Isometric → HSR → Eccentric)
- **LBP**: AEM subtyping → FAR (fear hierarchy + exposure), DER/EER (pacing plans + timer), AR (standard)
- **Neck Pain**: NDI severity (LEICHT/MITTEL/SCHWER), 4-phase progression
- **Tension**: TSI severity grading (LEICHT/MITTEL/SCHWER), 4-phase progression, micro-modules
- **Shoulder Impingement (SI)**: QuickDASH severity grading (`SiSeverityGrade`), phase-based protocol with severity-keyed JSON files (`shoulder_impingement_{leicht|mittel|schwer}.json`), focus areas, micro-modules, SPADI-style rescreening via `SiScreeningView`
- **Frozen Shoulder (FS)**: SPADI severity grading (`FsSeverityGrade`: LEICHT ≤34 / MITTEL 35–59 / SCHWER ≥60), phase-based protocol with severity-keyed files (`frozen_shoulder_{leicht|mittel|schwer}.json`), focus areas, micro-modules, rescreening via `FsScreeningView`. SCHWER patients get dosage-modified exercises (67% sets, 80% reps) via `DosageModifier`.
- **ACL**: Milestone-based progression, stream-based exercise programs, weekly schedule is client-side (`AclScheduleData`), stream unlocking is backend-controlled via milestone
- **Lateral Ankle Sprain (LAS)**: CAIT severity grading (`LasSeverityGrade`: LEICHT ≥24 / MITTEL 12–23 / SCHWER ≤11), phase-based protocol with severity-keyed files (`lateral_ankle_sprain_{leicht|mittel|schwer}.json`), focus areas, micro-modules, rescreening via `LasScreeningView`

### Pain-Adaptive Phase Progression
After every progress log, backend returns `AdaptationResult` with potential phase change (PROGRESS/HOLD/REGRESS). Frontend shows `PhaseChangeAlert` overlay.

### Subtype-Conditional Features
- FAR: Fear hierarchy builder + exposure logging
- DER/EER: Pacing plans + baseline tracking + pacing timer with audio cues
- All LBP: Micro-modules (psychoeducation) — shown in EdukationTab via `LbpMicroModulesSection`
- Neck: Focus areas + NDI rescreening + neck micro-modules — shown in EdukationTab via `NeckMicroModulesView`
- Tension: Focus areas + TSI rescreening + tension micro-modules — shown in EdukationTab via `TensionMicroModulesView`
- Shoulder Impingement: Focus areas + QuickDASH rescreening + SI micro-modules — shown in EdukationTab via `SiMicroModulesView`
- Frozen Shoulder: Focus areas + SPADI rescreening + FS micro-modules — shown in EdukationTab via `FsMicroModulesView`
- Lateral Ankle Sprain: Focus areas + CAIT rescreening + LAS micro-modules — shown in EdukationTab via `LateralAnkleSprainMicroModulesView`
- Tendinopathy (no micro-modules): EdukationTab shows all `EducationCard`s for current phase via `WissenAllCardsView`

### Exercise Video Recording
Users can record or pick a video from their photo library for any exercise. Videos are stored locally in `Documents/ExerciseVideos/` (excluded from iCloud backup), keyed by exercise ID. `ExerciseVideoStore` (singleton) manages save/load/delete. Works across all programs (tendinopathy, LBP, neck, tension, ACL). The video replaces the exercise description in the detail view when present.

### ACL Program Architecture
ACL patients have a separate dashboard (`AclDashboardView`) with milestone-based progression instead of phase-based. Key differences from other conditions:
- **Streams** replace protocols — exercises are grouped into streams (e.g., range-of-motion, strengthening)
- **Schedule is client-side** — `AclScheduleData.swift` contains hardcoded schedule blocks mapped to weeks post-surgery
- **Stream unlocking** — Backend returns `403 Forbidden` if user's `currentMilestone` hasn't reached the stream's `unlockMilestone`
- **Exercise model** — `AclStreamExercise` (not `ExerciseWithPhase`): optional fields, German name/description variants (`nameDE`, `descriptionDE`), graft modifiers, concomitant precautions
- **Today's program** — `AclTodayProgramView` loads stream details in parallel via `withTaskGroup`, silently skips locked/failed streams

### Clinical Messaging
Patient-clinician messaging via threads. `MessagingViewModel` manages thread list, messages, and unread count with polling timers. Views in `Views/Channel/`: `MessagesTab`, `ThreadListView`, `ThreadDetailView`, `FlagConcernSheet`. `ExerciseQuestionButton` lets patients ask questions about specific exercises. Available to all conditions via the MessagesTab in DashboardView.

### Smart Day & Morning Check-in (Bridge)
Daily health check-in flow (`MorningCheckinView`) that feeds into the smart day system (`SmartDayView`). `SmartDayViewModel` loads today's check-in status and smart day recommendations from the backend. `SmartDayGateView` acts as the entry point. Views in `Views/Bridge/`. API routes under `/bridge/*`.

### Work Timer (Bewegungspause)
`WorkTimerViewModel` manages work-break cycle with UserDefaults persistence. Both work timer state AND break state are persisted — on app relaunch during a break, remaining time is recalculated from the persisted `breakStartedAt` timestamp. `handleForegroundReturn()` handles both work and break timer restoration when returning from background.

## Backend API (~60 endpoints)

| Route group | Prefix | Purpose |
|-------------|--------|---------|
| Auth | `/onboarding/*` | Login, token validation, registration |
| Patient | `/patient/*` | Profile, progress, phase status, education, schedule |
| AEM | `/aem/*` | AEM screening (LBP subtyping) |
| Neck | `/neck/*` | NDI screening, focus areas, micro-modules |
| Tension | `/tension/*` | TSI screening, focus areas, micro-modules |
| LBP | `/lbp-enhancements/*` | Fear hierarchy, pacing, micro-modules, analytics |
| Shoulder Impingement | `/shoulder-impingement/*` | QuickDASH screening, focus areas, micro-modules, history |
| Frozen Shoulder | `/frozen-shoulder/*` | SPADI screening, focus areas, micro-modules, history |
| Lateral Ankle Sprain | `/lateral-ankle-sprain/*` | CAIT screening, focus areas, micro-modules, history |
| ACL | `/acl/*` | Streams, milestones, schedule, KPI logging |
| Bridge | `/bridge/*` | Morning check-in, smart day recommendations |
| Clinical Channel | `/clinical-channel/*` | Messaging threads, messages |
| Work Timer | `/work-timer/*` | Settings, exercises, break logging, summary |
| Config | `/config/*` | Feature flags, health check |

All endpoint definitions are in `Services/Networking/APIEndpoints.swift`.

## Test Accounts

All passwords: `Test1234!`

- **LBP subtypes**: `FARtest@test.com`, `DERtest@test.com`, `EERtest@test.com`, `ARtest@test.com`
- **Neck**: `NECKtest@test.com`
- **Tension**: `TENSIONtest@test.com` (generic), or `TSIleichtTest@test.com`, `TSImittelTest@test.com`, `TSIschwerTest@test.com` (severity-specific)
- **Shoulder Impingement**: `SIleichtTest@test.com`, `SImittelTest@test.com`, `SIschwerTest@test.com`
- **Frozen Shoulder**: `FSleichtTest@test.com`, `FSmittelTest@test.com`, `FSschwerTest@test.com`
- **Tendinopathies**: `ACHtest@test.com` (Achilles), `PATtest@test.com` (Patellar), `TEtest@test.com` (Tennis Elbow), `GEtest@test.com` (Golfer's Elbow), `RCtest@test.com` (Rotator Cuff), `GLUtest@test.com` (Gluteal), `PHtest@test.com` (Plantar/Heel), `PFtest@test.com` (Plantar Fasciitis)

## Companion Web App

The backend lives at `../Physio-App/`:
- Backend: `server/` (Express + PostgreSQL, deployed on Railway)
- Frontend: `client/` (React + Vite, deployed on Vercel)
- Shared types: `shared/types/index.ts` (source of truth for domain enums)
- Protocol data: `client/src/data/mockProtocols.ts` → converted to JSON for iOS bundle
