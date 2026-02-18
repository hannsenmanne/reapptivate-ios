# Screening "Freeze" Bug (2026-02-17)

## Symptom
User taps "Weiter zum Dashboard" after completing screening -- nothing happens, screen appears frozen.

## Root Cause
All three screening views (AemScreeningView, NeckScreeningView, TsiScreeningView) use `dismiss()` when they are rendered **inline** in RootView's conditional Group (with `isEmbedded: true`). In SwiftUI, `@Environment(\.dismiss)` only works when the view was presented via sheet, fullScreenCover, or navigation push. When rendered inline in a conditional body, `dismiss()` is a silent no-op.

The only actual navigation mechanism was `refreshProfile()` -- a background network call to `/patient/me` that updates `AppState.currentUser`. If the returned user has `neckScreeningCompleted == true` (or equivalent), the computed property `needsNeckScreening` becomes false and RootView switches views.

If `refreshProfile()` fails (network error, timeout, stale data), the user is permanently stuck.

## Affected Files
- `Reapptivate/Views/Screening/NeckScreeningView.swift` lines 21-28
- `Reapptivate/Views/Screening/AemScreeningView.swift` lines 20-27
- `Reapptivate/Views/Screening/TsiScreeningView.swift` lines 21-28
- `Reapptivate/App/ReapptivateApp.swift` line 51-55 (embedded rendering in RootView)
- `Reapptivate/App/AppState.swift` lines 26-36 (needsXxxScreening computed properties)

## Fix
Optimistic local state update: after successful screening submission, immediately update `appState.currentUser` to mark screening as completed. This makes `needsXxxScreening` return false instantly, causing RootView to navigate away. The `refreshProfile()` call becomes a non-blocking background refresh.

## Key Takeaway
In this codebase, navigation from screening/onboarding flows is driven by AppState computed properties, not by `dismiss()`. Any view rendered inline in RootView's conditional Group must update AppState directly to trigger navigation.
