# iOS Code Reviewer Memory

## Project Structure
- Entry: `Reapptivate/App/ReapptivateApp.swift` + `Reapptivate/App/AppState.swift`
- Models in `Reapptivate/Models/Domain/`, SwiftData in `Models/SwiftData/`
- API responses: `Reapptivate/Models/APIResponses.swift`
- ViewModels: `Reapptivate/ViewModels/` (reduced after NST removal)
- Networking: `Reapptivate/Services/Networking/` (APIClient, APIEndpoints, APIError, TokenManager, NetworkMonitor)
- Other services: AudioService, SyncService, ProtocolLoader, MilestoneService, NotificationService, RatingService
- Utils: `Reapptivate/Utils/` (KeychainHelper, Logger, DateFormatters, Extensions)
- Tests: `Reapptivate/Tests/ReapptivateTests/` + 1 UI test file

## Confirmed Patterns
- All VMs use `@Observable @MainActor final class` consistently
- `ExerciseViewModel` is the sole VM exception: optional APIClient, uses ProtocolLoader.shared
- Lazy optional `@State + .task` pattern used in DashboardView, LbpEnhancementsView, EdukationTab, TsiScreeningView
- `TokenManager` is `Sendable` (plain, not @unchecked) -- uses KeychainHelper stateless enum methods
- Four `@unchecked Sendable` singletons: ProtocolLoader (NSLock), EducationCardLoader (NSLock), NetworkMonitor (DispatchQueue), QuoteLoader (NSLock)
- `nonisolated(unsafe)` used in DateFormatters (4 static formatters) and MockURLProtocol
- API retry: 1 retry with 2s delay on network errors only (not 4xx/5xx)
- APIClient has 3 request methods with identical retry pattern (code duplication)
- German UI strings throughout, not localized
- Haptic system: `ConditionalHapticModifier` with `hapticsEnabled` EnvironmentKey
- CoachMark system: `@AppStorage("coachmark_<key>_seen")` -- persists per-key, NOT cleared on logout
- Self-loading views pattern: Tension/Neck views (FocusAreas, MicroModules, TsiProgress, NdiProgress) each load own data via .task

## Known Issues (Architecture Review 2026-02-15, updated 2026-02-17)
- PendingSync.syncId missing @Attribute(.unique)
- NotificationService/AudioService use singleton .shared pattern vs environment injection
- `DateFormatters.apiDecoder` is duplicate of `APIClient.decoder` setup
- DispatchQueue.main.asyncAfter in AudioService.playDoubleKnock/playTripleBeep
- Multiple silent error swallows in LbpEnhancementsViewModel
- ProtocolLoader fallback key "neck_shoulder_tension" (no severity) removed -- now uses severity-based keys

## Phase 2 Review Findings (2026-02-15)
- `ConditionalHapticModifier` uses if/else branching -- different view tree identity
- ComplianceCalendarCard has 3 force unwraps on calendar date arithmetic
- PainTrendChart creates new DateFormatter on every computed property access
- QuoteLoader.shared accessed directly in OverviewTab view body (not via environment)
- MilestoneService stores dates as JSON-encoded string in @AppStorage
- DataPrivacyView "delete account" button is a no-op (TODO comment)

## TSI/Tension Review Findings (2026-02-17, updated with deep review)
- NeckShoulder* files fully removed (~3650 LOC net reduction), replaced by TSI/Tension implementation
- `TsiScreeningViewModel.selectResponse` spawns unstructured Task for auto-advance delay
- `TensionMicroModulesView.markRead` silently swallows errors
- onLogout simplified: no longer resets hasSeenWelcome/hasSeenWalkthrough (correct per CLAUDE.md)
- `showInsights` changed from negation to positive list -- tension now included in Insights tab
- Schedule model refactored: UserSchedule -> ScheduleResponse/ScheduleUpdateRequest with proper weekday conventions
- **MAJOR DEBT**: Copy-paste duplication across Neck/Tension views (see detailed-findings.md)
- EducationCardLoader.cardsForPhase accumulates boolean params: isLbp, isNeck, isTension
- markRead two-step API call (start + complete) has no partial-failure recovery
- Protocol JSON files exist for all 3 severity levels (leicht/mittel/schwer)

## Test Coverage
- Well covered: TensionTypes, TsiScreeningViewModel, SharedTypes (TsiSeverityGrade), AppState (isTension/needsTsiScreening)
- NOT covered: ExerciseViewModel, PhaseViewModel, AemScreeningViewModel, NeckScreeningViewModel, LbpEnhancementsViewModel, SyncService, ProtocolLoader, EducationCardLoader, NetworkMonitor

## Release Readiness (2026-02-15)
- AppIcon.png added, PrivacyInfo.xcprivacy added (prior commit)
- No .strings files -- all UI strings hardcoded in German
- DEVELOPMENT_TEAM empty in project.yml
- No certificate pinning
