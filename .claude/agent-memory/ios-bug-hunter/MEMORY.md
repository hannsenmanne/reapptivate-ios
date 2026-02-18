# Agent Memory - iOS Bug Hunter

## Project Status
- Build succeeds with zero warnings/errors (as of 2026-02-13)
- Swift 6.0 strict concurrency compiles clean
- No force unwraps anywhere in user code (well-guarded)
- 89 Swift files total in Reapptivate/

## Known Issue Areas
- See `bugs-found.md` for full audit results
- `APIEndpoints.swift` has 2 force unwraps in request builders (lines 265, 269)
- `TrainingScheduleCard.swift` has a force unwrap via `firstIndex(of:)!` (line 112)
- `WissenCardView.swift` and `EducationCard.swift` have force unwrap on date calc (line 17, line 51)
- `TokenManager` is `Sendable` but uses mutable Keychain (safe, but semantically misleading)
- `ExerciseSessionView` timer closures mutate `@State` off main thread
- `PacingTimerView` same issue with Timer closures
- `EdukationTab` shows empty view for non-LBP/non-Neck tendinopathy when ndiSeverity is nil
- `DashboardView.loadAll()` recreates AuthViewModel on every .task call

## Resolved Bugs
- **Screening "freeze" bug (2026-02-17)**: All three screening views (AEM, Neck, TSI) called `dismiss()` when embedded inline in RootView's conditional Group -- `dismiss()` is a no-op in that context. Navigation depended entirely on `refreshProfile()` succeeding. Fix: optimistic local state update after successful screening submission. See `screening-freeze-bug.md`.

## Debugging Patterns
- When a view uses `@Environment(\.dismiss)` but is rendered inline (not sheet/navigation push), `dismiss()` is a no-op -- always verify presentation context
- RootView uses conditional rendering based on AppState computed properties -- navigation changes require state updates, not `dismiss()`
- Screening views have `isEmbedded` parameter but it's unused in view body

## Key File Paths
- Entry: `/Reapptivate/App/ReapptivateApp.swift`
- State: `/Reapptivate/App/AppState.swift`
- API: `/Reapptivate/Services/Networking/APIClient.swift`, `APIEndpoints.swift`, `APIError.swift`
- Models: `/Reapptivate/Models/Domain/` (UserProfile, LbpTypes, NeckTypes, etc.)
- Responses: `/Reapptivate/Models/APIResponses.swift`
- ViewModels: `/Reapptivate/ViewModels/`
- SwiftData: `/Reapptivate/Models/SwiftData/`
