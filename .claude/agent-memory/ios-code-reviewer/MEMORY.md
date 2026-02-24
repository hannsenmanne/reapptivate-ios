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
- All VMs use `@Observable @MainActor final class` consistently (including all 6 ACL VMs)
- `ExerciseViewModel` is the sole VM exception: optional APIClient, uses ProtocolLoader.shared
- Lazy optional `@State + .task` pattern used in DashboardView, LbpEnhancementsView, EdukationTab, TsiScreeningView, and all ACL views
- `TokenManager` is `Sendable` (plain, not @unchecked) -- uses KeychainHelper stateless enum methods
- Four `@unchecked Sendable` singletons: ProtocolLoader (NSLock), EducationCardLoader (NSLock), NetworkMonitor (DispatchQueue), QuoteLoader (NSLock)
- `nonisolated(unsafe)` used in DateFormatters (4 static formatters) and MockURLProtocol
- API retry: 1 retry with 2s delay on network errors only (not 4xx/5xx)
- APIClient has 3 request methods with identical retry pattern (code duplication)
- German UI strings throughout, not localized
- Haptic system: `ConditionalHapticModifier` with `hapticsEnabled` EnvironmentKey
- CoachMark system: `@AppStorage("coachmark_<key>_seen")` -- persists per-key, NOT cleared on logout
- Self-loading views pattern: Tension/Neck views and all ACL views each load own data via .task

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

## ACL Functional Review Findings (2026-02-24, updated with critic review)
- **CRITICAL**: AclCompletedModulesResponse type mismatch -- backend getCompletedModules returns `string[]` but iOS expects `[MicroModuleCompletion]` (objects). Decoding always fails, all modules appear unread.
- **CRITICAL**: KPI logger views (Daily, Weekly) and KPI history are ORPHANED -- no navigation to them
- **CRITICAL (NEW)**: Precaution/graft modifier display UNFILTERED -- backend sends filtered `graftNote`/`precautions` strings, but iOS model lacks these fields and reads raw unfiltered dicts instead. Shows ALL injury warnings to ALL patients.
- No client-side targetCondition filtering in AclMicroModulesView (relies solely on backend)
- Tampa chart Y-axis domain 17...68 incorrect -- TSK-11 range is 11-44 (backend validates 11-44)
- AclKpiHistoryView creates new DateFormatters per formattedDate() call
- AclKpiHistoryView.task loads 3 histories sequentially instead of with async let
- streamIcon(for:) duplicated in AclDashboardView and AclStreamOverviewView
- streamIcon mapping misses 5 of 8 actual stream IDs (MOTOR_CONTROL, EXPLOSIVENESS, REACTIVE_STRENGTH, CHANGE_OF_DIRECTION, CONDITIONING)
- DischargeCriterionCard.progressPercent ignores `operator` field -- shows 100% green for failing `<=` criteria (swelling)
- ScreeningCompleteView default case shows "3-Phasen" tendinopathy info to ACL patients
- .textFieldStyle(.roundedBorder) used in KPI loggers instead of .inputFieldStyle()
- Seed accounts: ACLcomptest@test.com (Competitive M2), ACLrectest@test.com (Recreational M3)

## ACL Backend Logic Notes (2026-02-24)
- ACL exercises come from streams API, NOT ProtocolLoader -- correct separation (not dead code)
- Milestone 0->1 has no lab criteria (implicit: surgery occurred)
- `isReadyForLab` formula: `weeksPostSurgery >= nextMilestone * 6` (simplistic but acceptable)
- Tampa in both weekly KPIs (patient self-report) AND lab assessments (therapist) -- clinically appropriate, not redundant
- Discharge criteria purely physical -- no psychological readiness component (gap vs literature)
- `enrichExercisesWithModifiers` adds `graftNote` + `precautions` flat strings that iOS model discards
- `filterExercisesByMilestone` enforces both milestone AND weekRange (correct for tissue healing timelines)

## Test Coverage
- Well covered: TensionTypes, TsiScreeningViewModel, SharedTypes (TsiSeverityGrade, isAcl), AppState
- NOT covered: All 6 ACL VMs, ExerciseViewModel, PhaseViewModel, AemScreeningViewModel, NeckScreeningViewModel, LbpEnhancementsViewModel, SyncService, ProtocolLoader, EducationCardLoader, NetworkMonitor

## Release Readiness (2026-02-15)
- AppIcon.png added, PrivacyInfo.xcprivacy added (prior commit)
- No .strings files -- all UI strings hardcoded in German
- DEVELOPMENT_TEAM empty in project.yml
- No certificate pinning

## Reviewer Notes
- SwiftUI Slider has built-in VoiceOver adjustable action -- no custom implementation needed
- ScreeningCompleteView uses ASCII-only German (fuer, Uebungen, etc.) -- pre-existing pattern, not regression
