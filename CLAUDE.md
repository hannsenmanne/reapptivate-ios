# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

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

**93 unit tests** in `Reapptivate/Tests/ReapptivateTests/` covering Models, Services, ViewModels, and AppState. CI runs on GitHub Actions (`.github/workflows/test.yml`) on every push/PR to main.

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

Three shared `@Observable` objects injected via SwiftUI environment from `ReapptivateApp`:
- `AppState` — auth state, current user, computed flags: `isLbp`, `isNeck`, `needsAemScreening`, `needsNeckScreening`
- `APIClient` — networking with auto JWT injection, 401 detection + logout callback, 1 retry on network failure
- `NetworkMonitor` — NWPathMonitor wrapper for connectivity

SwiftData `ModelContainer` is configured at `WindowGroup` level (not in AppState): `.modelContainer(for: [CachedUser.self, CachedProgress.self, PendingSync.self])`. `SyncService` receives its `ModelContext` via a deferred `setModelContext()` call — not at init — because the context comes from the view environment.

### Navigation Flow (RootView)

```
RootView
├── LoadingView (isCheckingAuth)
├── LoginView (not authenticated)
├── AemScreeningView (LBP + screening needed)
├── NeckScreeningView (Neck + screening needed)
└── DashboardView (authenticated + screened)
    ├── OverviewTab — Phase status, Wissen daily card, condition info
    ├── ProgramTab — Exercise list + LBP enhancements
    ├── EdukationTab — Micro-modules (LBP/Neck) or Wissen cards (tendinopathy)
    ├── ProgressTab — Pain history, statistics
    └── InsightsTab — Analytics (LBP/Neck only)
```

EdukationTab is always visible. InsightsTab only appears for LBP/Neck patients. Tab visibility is controlled by `DashboardTabBar.tabs` computed property (not by `DashboardViewModel.availableTabs`, which is unused).

### Networking

`APIEndpoints` enum: static methods returning `URLRequest` with 30-second timeout. Base URL switches on `#if DEBUG`:
- DEBUG: `http://localhost:3000/api`
- RELEASE: `https://physio-app-server-production.up.railway.app/api`

`APIClient` has three request methods:
- `request<T: Decodable>()` — decodes response to `T`
- `requestVoid()` — ignores response body
- `requestData()` — returns raw `Data`

All requests: Bearer token injection, snake_case → camelCase **decoding only** (uploads use standard camelCase encoding — no `convertToSnakeCase`), ISO8601 date parsing (with/without fractional seconds), 401 → `onTokenExpired` callback, 1 retry with 2s delay **only on network errors** (not on 4xx/5xx).

**Encoding gotcha**: Most backend controllers destructure camelCase from `req.body` (e.g., `exerciseId`, `painLevel`), but some use snake_case (e.g., `schedule.controller.ts` expects `available_days`). When a request fails silently (data not persisted), check the backend controller's destructuring. Fix with `CodingKeys` on the request struct.

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

Protocol key mapping: `TendinopathyType` → filename (e.g., `.achilles` → `achilles.json`, `.lbpNonspecific` + `.FAR` → `lbp_far.json`).

## Key Gotchas

- **`adaptivePhase` in `UserProfile`** is optional and NOT populated from `/patient/me`. It comes from the separate `/patient/phase-status` endpoint. `currentPhase` computed property defaults to `1`.
- **`ExerciseWithPhase`** has a custom decoder that handles both nested (`{"exercise": {...}, "phase": 1}`) and flat (`{"id": "...", "name": "...", "phase": 1}`) JSON formats from protocol files.
- **`AnyCodable`** helper in `LbpTypes.swift` wraps dynamic JSON values (used for `ExposureLog.performedDose` which can be String, Int, Double, Bool, or nested).
- **`UserProfile.id` is `String`**, not UUID.
- **`@unchecked Sendable`** is used on `TokenManager`, `ProtocolLoader`, and `NetworkMonitor` for cross-actor access in Swift 6.0 strict concurrency mode.
- **Dev token must come from local backend** — local and production JWT secrets differ, so a production token won't work with `localhost:3000` and vice versa.
- **`Color.textPrimary` flips in dark mode** (light→1A1A1A, dark→F2F2F7). Don't use it as a background with hardcoded `.white` text — use `Color.appBg` for the text instead so both adapt together. Same applies to any adaptive color used as a bg.
- **`AnalyticsSummary` has a custom decoder** — backend sends `adjustmentStats: {total, applied}` (nested) and `triggerFireCount: {ruleId: count}` (dict), but the model exposes flat `totalAdjustments`/`appliedAdjustments` and `triggerFires: [TriggerFireCount]` (array). Don't add simple `CodingKeys` — the custom `init(from:)` handles the shape transformation.

## Domain Models (Models/Domain/)

- `SharedTypes.swift` — All shared enums: `TendinopathyType` (10 cases), `ExerciseType`, `AdaptationDecision`, `AemSubtype`, `NdiSeverityGrade`, `SymptomResponse`
- `LbpTypes.swift` — Largest model file: fear hierarchies, exposure logs, pacing plans/templates/logs, plan adjustments, micro-modules, analytics types, `AnyCodable`
- `NeckTypes.swift` — NDI screening config/results, focus areas, NDI history
- `AemTypes.swift` — AEM screening config/results/submission
- `AuthTypes.swift` — Login/onboarding request/response types
- `APIResponses.swift` — All backend response wrappers (`{user:}`, `{plan:}`, `{hierarchy:}`, etc.)
- `EducationCard.swift` — Education card model + `EducationCardLoader` singleton (loads bundled `education-cards.json`, filters by phase/condition, daily rotation via day-of-year modulo)
- `CustomExercise.swift` — Custom exercises added by users (displayed in ProgramTab alongside protocol exercises)
- `UserSchedule.swift` — Training schedule data

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
- Contextual loading labels: `ProgressView("Nacken-Module laden...")` instead of bare `ProgressView()`

### Error Handling in Views
Views that load data from API use a consistent pattern:
```swift
@State private var errorMessage: String?
// In catch block: errorMessage = "Descriptive German message."
// In body: if let error = errorMessage { InlineErrorView(message: error) { Task { await reload() } } }
```

## Key Domain Concepts

### Conditions & Subtypes
- **Tendinopathies** (8 types): 3-phase progression (Isometric → HSR → Eccentric)
- **LBP**: AEM subtyping → FAR (fear hierarchy + exposure), DER/EER (pacing plans + timer), AR (standard)
- **Neck Pain**: NDI severity (LEICHT/MITTEL/SCHWER), 4-phase progression

### Pain-Adaptive Phase Progression
After every progress log, backend returns `AdaptationResult` with potential phase change (PROGRESS/HOLD/REGRESS). Frontend shows `PhaseChangeAlert` overlay.

### Subtype-Conditional Features
- FAR: Fear hierarchy builder + exposure logging
- DER/EER: Pacing plans + baseline tracking + pacing timer with audio cues
- All LBP: Micro-modules (psychoeducation) — shown in EdukationTab via `LbpMicroModulesSection`
- Neck: Focus areas + NDI rescreening + neck micro-modules — shown in EdukationTab via `NeckMicroModulesView`
- Tendinopathy (no micro-modules): EdukationTab shows all `EducationCard`s for current phase via `WissenAllCardsView`

## Backend API (~50 endpoints)

| Route group | Prefix | Purpose |
|-------------|--------|---------|
| Auth | `/onboarding/*` | Login, token validation, registration |
| Patient | `/patient/*` | Profile, progress, phase status, education, schedule |
| AEM | `/aem/*` | AEM screening (LBP subtyping) |
| Neck | `/neck/*` | NDI screening, focus areas, micro-modules |
| LBP | `/lbp-enhancements/*` | Fear hierarchy, pacing, micro-modules, analytics |
| Config | `/config/*` | Feature flags, health check |

All endpoint definitions are in `Services/Networking/APIEndpoints.swift`.

## Test Accounts

Same as web app: `FARtest@test.com` / `DERtest@test.com` / `EERtest@test.com` / `ARtest@test.com` — Password: `Test1234!`

## Companion Web App

The backend lives at `../Physio-App/`:
- Backend: `server/` (Express + PostgreSQL, deployed on Railway)
- Frontend: `client/` (React + Vite, deployed on Vercel)
- Shared types: `shared/types/index.ts` (source of truth for domain enums)
- Protocol data: `client/src/data/mockProtocols.ts` → converted to JSON for iOS bundle
