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

## Naming Collisions
- `PainDataPoint` already exists in `Models/Domain/LbpTypes.swift` (used by `AnalyticsSummary.painTrend`) — use `PainTrendDataPoint` or similar for chart-specific types in other files
- Even `private` structs in Swift can collide with public types of the same name in the same module

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

## Missing Definitions Found & Fixed
- `Color.textTertiary` was missing from Color+Theme.swift — added as `adaptive(light: "9CA3AF", dark: "636366")`
- `ProtocolLoader.protocolKey()` was missing `.neckShoulderTension` case — added `"neck_shoulder_tension"`
