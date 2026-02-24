# iOS Implementer Memory

## Build & Project
- After creating new .swift files, must run `xcodegen generate` before building — new files won't be picked up otherwise
- Concurrent builds cause "database is locked" errors — wait a few seconds and retry
- Pre-existing build errors may exist from other agents' in-progress work; filter with grep to isolate your errors

## Codebase Patterns Confirmed
- `RootView` is in `Reapptivate/App/ReapptivateApp.swift` (not Views/Root/)
- `AppState` is in `Reapptivate/App/AppState.swift` (not Services/State/)
- `@AppStorage` flags in `RootView` work for gating navigation (e.g., `hasSeenWelcome`)
- Logout cleanup: `appState.onLogout` closure in RootView is the place to reset `@AppStorage` flags
- `UserSchedule.availableDays` uses Calendar weekday format: 1=Sunday, 2=Monday, ..., 7=Saturday
- `TrainingScheduleCard` loads schedule independently via `APIEndpoints.getSchedule()`
- `DashboardViewModel` loads dashboard data in parallel with `async let` + `loadSafely()` pattern

## Haptic Feedback Pattern
- All haptics go through `.conditionalHaptic()` modifier (in `View+ConditionalHaptic.swift`)
- Environment key `hapticsEnabled` injected from `ReapptivateApp`, persisted via `@AppStorage("hapticsEnabled")`
- Toggle in SettingsView under "Darstellung" section
- `AudioService.swift` still uses `UIImpactFeedbackGenerator` directly (intentional — tied to audio cues)

## Coach Mark / Tooltip Pattern
- `CoachMarkView` + `CoachMarkModifier` in `Views/Common/CoachMarkView.swift`
- Usage: `.coachMark(key: "unique_key", message: "...", edge: .top/.bottom)`
- Persisted via `@AppStorage("coachmark_<key>_seen")` — shows once per user

## Error State Pattern
- Views use `@State private var errorMessage: String?`
- Load functions: `errorMessage = nil` at start, `errorMessage = "German message."` in catch
- Body: `if let error = errorMessage { InlineErrorView(message: error) { Task { await reload() } } }`
- Reference: `NeckMicroModulesView` (Views/Neck/), `NeckFocusAreasView` (Views/Neck/)
- InlineErrorView is in `Views/Common/InlineErrorView.swift`

## View Directory Notes
- Neck views: `Views/Neck/` (NeckMicroModulesView, NeckFocusAreasView, NdiProgressView, NeckProfileView)
- Tension views: `Views/Tension/` (TensionMicroModulesView, TensionFocusAreasView, TsiProgressView, TensionProfileView)
- Screening views: `Views/Screening/` (TsiScreeningView, TsiQuestionView, TsiResultView alongside Neck/AEM equivalents)
- Common views: `Views/Common/` (EmptyStateView, InlineErrorView, SkeletonView, LoadingView)

## Design System Notes
- `Color.gray200`/`Color.gray100` are adaptive — good for skeleton shimmer
- `AnyShape` available iOS 16+ — safe for shape erasure in SkeletonView
- ViewModifiers: struct + extension pattern (see CardEntryAnimation, CardStyle)
- Card entry animation: `.easeOut(duration: 0.35)` + `.delay(index * 0.06)` for stagger
- `DesignTokens` is a flat enum — use `DesignTokens.cardRadius` (not `.Cards.cornerRadius`), `.buttonRadius`, `.inputRadius`, `.badgeRadius`, `.smallRadius`
- Complex SwiftUI view builders with ForEach + conditional styling cause "unable to type-check" errors — extract option rows into separate private structs

## Naming Collisions
- `PainDataPoint` already exists in `Models/Domain/LbpTypes.swift` (used by `AnalyticsSummary.painTrend`) — use `PainTrendDataPoint` or similar for chart-specific types in other files
- Even `private` structs in Swift can collide with public types of the same name in the same module
- `FlowLayout` exists in `Views/Exercise/ExerciseCardView.swift` — reuse it, do not redeclare

## Condition Integration Checklist (when adding new condition types)
When adding a new condition (like neckShoulderTension), update ALL of these:
1. `TendinopathyType` enum in SharedTypes.swift (raw value, displayName, boolean flag, update isTendinopathy)
2. `UserProfile` (new optional fields, maxPhase)
3. `CachedUser` (new fields, init params, update(from:) method)
4. `APIResponses.swift` (new response wrappers)
5. `APIEndpoints.swift` (new endpoint methods)
6. `ProtocolLoader` (protocolKey, phaseName, protocolFor params)
7. `EducationCardLoader` (cardsForPhase/todaysCard parameters)
8. `Color+Theme.swift` (overloaded severityColor helper)
9. `AppState` (is/needs computed properties)
10. `RootView` screening gate in ReapptivateApp.swift
11. `DashboardView` tab bar (showInsights condition)
12. `DashboardViewModel` (severity loading block)
13. `EdukationTab`, `InsightsTab`, `OverviewTab`, `WissenCardView`, `WissenAllCardsView`
14. `ScreeningCompleteView` (icon, description, expectations switches)
15. `ExerciseViewModel` (protocolFor call params)
16. `TestFixtures` (userProfile factory method params)
17. Test count assertions (SharedTypesTests.testTendinopathyTypeCount)

## Protocol JSON Files
- All protocol JSONs live in `Reapptivate/Resources/Protocols/`
- XcodeGen bundles them flat (app root), ProtocolLoader falls back from Protocols/ subdirectory to root
- Tension protocols: `neck_shoulder_tension_leicht.json`, `neck_shoulder_tension_mittel.json`, `neck_shoulder_tension_schwer.json`
- Exercise `type` field must be a valid `ExerciseType` raw value: ISOMETRIC, HSR, ECCENTRIC, CONCENTRIC, MOTOR_CONTROL, BODY_AWARENESS, PACING, GRADED_ACTIVITY
- Flat exercise format in JSON (id/name/type/sets/reps/etc. at same level as phase/phase_title/phase_goal) — custom decoder in ExerciseWithPhase handles both flat and nested
- `cognitiveCues` is an object with FAR/DER/EER/AR keys (LBP-specific), not relevant for tension/neck protocols

## ACL Reconstruction Feature
- ACL types live in `Models/Domain/AclTypes.swift` (enums, screening, KPIs, milestones, streams, analytics)
- ACL uses milestone-based progression (0-5), not phase-based — `maxPhase` returns 5 for ACL
- ACL exercises come from backend streams, not bundled protocol JSON — ProtocolLoader not used for ACL
- ACL screening is a surgical intake form (date, graft type, athlete level, etc.), not a questionnaire like AEM/NDI/TSI
- Backend routes at `/api/acl/*` — 18 endpoints covering screening, streams, KPIs, milestones, discharge, analytics, micro-modules
- `AclScreeningView` fully implemented in `Views/Screening/` with `AclScreeningViewModel` in `ViewModels/`
- ACL screening has 6 steps: date picker, 3 radio steps (graft type, athlete level, knee side), 1 checkbox step (concomitant injuries), 1 text step (sport)
- Radio steps auto-advance after 500ms; date/checkbox/text steps use explicit "Weiter" button
- `LoginUser` in AuthTypes.swift has optional ACL fields (decoded from backend, used transiently before /me fetch)
- `CachedUser` SwiftData model updated with ACL fields for offline support
- `APIResponses.swift` lives at `Models/APIResponses.swift` (not Models/Domain/)
- `SharedTypesTests.testTendinopathyTypeCount` expects 12 (was 11 before ACL was added to enum)
- ACL Dashboard: `AclDashboardView` replaces OverviewTab, `AclStreamOverviewView` replaces ProgramTab, `AclDischargeProgressView` replaces ProgressTab for ACL patients
- DashboardView `loadAll()` early-returns for ACL patients (they have their own data loading in each ACL view)
- `AclGraftType.shortName` extension added in `AclDashboardView.swift` for compact stat card display
- ACL milestone timeline: 6 nodes (Pre-OP, M1-M4, Entlassung) with week ranges from backend data
- Stream icons mapped from stream IDs via `streamIcon(for:)` helper in `AclDashboardView.swift` and `AclStreamOverviewView.swift`

## InlineErrorView Init Gotcha
- `InlineErrorView` has 3 inits (onRetry, onDismiss, both). Trailing closure syntax is AMBIGUOUS — always use explicit `onRetry:` or `onDismiss:` labels
- Similarly, `Task { await ... }` inside closures can be ambiguous — use `Task<Void, Never> { ... }` if compiler complains

## ACL KPI Views
- Daily KPI logger: `Views/ACL/AclDailyKpiLoggerView.swift` (sheet, pain NRS slider, ROM steppers, swelling segmented, quads lag toggle)
- Weekly KPI logger: `Views/ACL/AclWeeklyKpiLoggerView.swift` (sheet, IKDC/Tampa text inputs, thigh circumference decimal inputs)
- KPI history: `Views/ACL/AclKpiHistoryView.swift` (segmented: daily/weekly/lab, expandable cards, LSI color coding)
- ViewModels: `AclDailyKpiViewModel`, `AclWeeklyKpiViewModel`, `AclLabAssessmentViewModel` (all in ViewModels/)
- Validation ranges: Daily: painNrs 0-10, flexion 0-160, ext.deficit 0-30, swelling 0-3. Weekly: IKDC 0-100, Tampa 11-44, thigh 20-80cm

## ACL Micro-Modules & Analytics Views
- Micro-modules view: `Views/ACL/AclMicroModulesView.swift` (expandable card list, progress bar, mark-as-read)
- Analytics view: `Views/ACL/AclAnalyticsView.swift` (Swift Charts: pain, ROM, swelling, IKDC, Tampa, thigh circ, LSI bars)
- ACL completed modules response returns `MicroModuleCompletion` objects (not string keys) — extract keys via `completions.map(\.moduleKey)`
- `AclCompletedModulesResponse` has both `completions` and `completedModules` fields (nullable) — coalesce with `??`
- ACL micro-modules use `AclMicroModule` type (has `targetMilestone: [Int]?`), not generic `MicroModule`
- `MetricCard` already defined in `Views/Analytics/AnalyticsDashboardView.swift` — reuse, don't redefine
- EdukationTab: ACL branch shows `AclMicroModulesView` only (no Wissen cards — content is backend-driven)
- InsightsTab: ACL branch shows `AclAnalyticsView`
- DashboardTabBar: `showInsights` condition updated to include `appState.isAcl`

## Testing Notes
- MockURLProtocol: `request.httpBody` is nil for POST requests intercepted by URLProtocol — use `httpBodyStream` to read body data, or simply verify endpoint/method instead
- Multiple XCTest classes in a single file work fine (e.g., AclViewModelTests.swift has 5 classes)
- `xcodebuild test` may report "TEST FAILED" due to stale xcresult cache — `xcodegen generate` + clean build fixes it
- ACL test fixtures in TestFixtures.swift use camelCase JSON keys (works with `convertFromSnakeCase` decoder)
- ACL test count: 92 tests across AclTypesTests (26), AclDailyKpiViewModelTests (12), AclWeeklyKpiViewModelTests (19), AclDashboardViewModelTests (8), AclScreeningViewModelTests (24), AclStreamViewModelTests (3)

## Missing Definitions Found & Fixed
- `Color.textTertiary` was missing from Color+Theme.swift — added as `adaptive(light: "9CA3AF", dark: "636366")`
- `ProtocolLoader.protocolKey()` was missing `.neckShoulderTension` case — added `"neck_shoulder_tension"`
