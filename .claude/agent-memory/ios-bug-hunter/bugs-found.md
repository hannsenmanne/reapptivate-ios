# Bug Audit

Full codebase scan of all 89 Swift files. Build succeeds with 0 warnings/errors.

## Screening Dismiss Race Condition (2026-02-17)

**Affected files:**
- `Reapptivate/Views/Screening/AemScreeningView.swift` (lines 20-27)
- `Reapptivate/Views/Screening/NeckScreeningView.swift` (lines 21-28)
- `Reapptivate/Views/Screening/TsiScreeningView.swift` (lines 21-28)

**Root cause:** All three screening views call `dismiss()` before updating `appState.currentUser` screening flags. Since these views are rendered conditionally in RootView (not as sheets), `dismiss()` is a no-op. The `refreshProfile()` that would update the flag runs in a background `Task` after dismiss, creating a race where RootView re-evaluates before the flag is updated, causing the screening to appear "frozen" in an infinite loop.

**Fix:** Optimistic state update on `appState.currentUser` before dismiss:
- `aemScreeningCompleted = true` (+ `aemSubtype`)
- `neckScreeningCompleted = true`
- `tsiScreeningCompleted = true`

**Pattern to remember:** When views are conditionally rendered (not presented as sheets), `@Environment(\.dismiss)` is a no-op. State must be updated directly to trigger navigation changes.

## Previously Known Issues (2026-02-13)
- `APIEndpoints.swift` has 2 force unwraps in request builders (lines 265, 269)
- `TrainingScheduleCard.swift` has a force unwrap via `firstIndex(of:)!` (line 112)
- `WissenCardView.swift` and `EducationCard.swift` have force unwrap on date calc (line 17, line 51)
- `TokenManager` is `Sendable` but uses mutable Keychain (safe, but semantically misleading)
- `ExerciseSessionView` timer closures mutate `@State` off main thread
- `PacingTimerView` same issue with Timer closures
- `EdukationTab` shows empty view for non-LBP/non-Neck tendinopathy when ndiSeverity is nil
- `DashboardView.loadAll()` recreates AuthViewModel on every .task call
