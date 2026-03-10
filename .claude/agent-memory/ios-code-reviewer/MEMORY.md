# iOS Code Reviewer Memory

## Project Structure
- Entry: `Reapptivate/App/ReapptivateApp.swift` + `Reapptivate/App/AppState.swift`
- Models in `Reapptivate/Models/Domain/`, SwiftData in `Models/SwiftData/`
- API responses: `Reapptivate/Models/APIResponses.swift`
- ViewModels: `Reapptivate/ViewModels/` (20 files total)
- Networking: `Reapptivate/Services/Networking/` (APIClient, APIEndpoints, APIError, TokenManager, NetworkMonitor)
- Other services: AudioService, SyncService, ProtocolLoader, MilestoneService, NotificationService, RatingService, ExerciseVideoStore
- Video views: `Views/Video/` (VideoCaptureView, VideoLibraryPicker)
- Utils: `Reapptivate/Utils/` (KeychainHelper, Logger, DateFormatters, Extensions)
- Tests: `Reapptivate/Tests/ReapptivateTests/` (21 test files) + 1 UI test file

## Confirmed Patterns (Full Review 2026-03-08)
- All 20 VMs use `@Observable @MainActor final class` consistently
- `ExerciseViewModel` is the sole VM exception: optional APIClient, uses ProtocolLoader.shared
- Lazy optional `@State + .task` pattern confirmed across all view usages
- `TokenManager` is `@MainActor Sendable` (plain, not @unchecked) -- uses KeychainHelper stateless enum
- Four `@unchecked Sendable` singletons: ProtocolLoader (NSLock), EducationCardLoader (NSLock), NetworkMonitor (DispatchQueue), QuoteLoader (NSLock)
- `nonisolated(unsafe)` on 2 ISO8601 formatters in DateFormatters + MockURLProtocol only
- API retry: 1 retry with 2s delay on network errors only (not 4xx/5xx)
- German UI strings throughout, not localized
- ConditionalHapticModifier uses sensoryFeedback condition closure (correct pattern)

## Key Service Architecture Findings (2026-03-08)
- **SyncService incomplete**: Only cache/clear. No queue drain for PendingSync. Model has maxRetries but never enqueued.
- **SyncService takes ModelContext at init** (CLAUDE.md says deferred setModelContext -- doc outdated)
- **DateFormatters.apiDecoder** missing `convertFromSnakeCase` key decoding -- differs from APIClient.decoder
- **ExerciseVideoStore videos**: FIXED -- `deleteAllVideos()` called in `handleLogout()`
- **onTokenExpired race**: Set in `.onAppear` on WindowGroup content, but `.task` in RootView may fire first -- callback could be nil during auto-login 401
- **ProtocolLoader does sync file I/O** on main actor -- mitigated by caching + small bundle files
- **APIEndpoints.get() silently falls back to baseURL** when URLComponents fails

## ViewModel Layer Issues (Full Review 2026-03-08)
### Critical
- **MessagingVM Timer leak**: FIXED -- deinit now present, invalidates both timers
- **WorkTimerVM cancelPendingNotifications()**: FIXED -- now filters by `work_timer_break_` prefix
- **NotificationDelegate data race**: Callback closures are unprotected mutable state on @unchecked Sendable type
- **WorkTimerBreakView micro-break auto-complete**: Races with manual complete button, can double-count breaks

### High
- **AemScreeningVM/NeckScreeningVM**: selectResponse spawns untracked Tasks
- **DashboardVM.loadSafely**: FIXED -- now sets `self.error` on first failure
- **WorkTimerVM formatTime()/applySettings()**: FIXED -- now uses static DateFormatter with POSIX locale
- **WorkTimerVM snoozesUsed**: FIXED -- now persisted and restored from UserDefaults
- **WorkTimerVM autoStopWorkday()**: Untracked Task can fire multiple times from consecutive ticks
- **WorkTimerVM expired break during background**: FIXED -- micro-breaks auto-complete, regular breaks count as skipped
- **WorkTimerCard notification callbacks**: Stale VM reference if view recreated; never cleared
- **PhaseViewModel.loadPhaseStatus**: Error logged but no user-facing error state
- **WorkTimerVM clearPersistedState()**: FIXED -- now clears autoStart and snoozesUsed

## ACL Findings (2026-02-24)
- **CRITICAL**: AclCompletedModulesResponse type mismatch -- backend returns string[], iOS expects objects
- **CRITICAL**: KPI logger views ORPHANED -- no navigation
- **CRITICAL**: Precaution/graft modifier display UNFILTERED
- Tampa chart Y-axis domain 17...68 incorrect -- TSK-11 range is 11-44
- DischargeCriterionCard.progressPercent ignores operator field

## Test Coverage (confirmed 2026-03-08, 21 test files)
- Covered: SharedTypes, TensionTypes, AclTypes, WorkTimerTypes, UserProfile, CodableRoundTrip, PhaseAdaptation, APIClient, APIEndpoints, TokenManager, MilestoneService, RatingService, AppState, AuthVM, DashboardVM, ProgressVM, TsiScreeningVM, WorkTimerVM, AclVMs
- NOT covered: SyncService, ProtocolLoader, EducationCardLoader, NetworkMonitor, NotificationService, AudioService, ExerciseVideoStore, DateFormatters, View layer

## Navigation/Dashboard Review (2026-03-09)
- **hasSeenWelcome/hasSeenWalkthrough not user-scoped**: Global @AppStorage keys bleed between accounts on shared devices
- **DataPrivacyView.deleteAccount**: dismiss() before performLogout() causes sheet ordering issues
- **ScheduleEditorView/TrainingScheduleCard**: Reminder time not persisted, resets on view recreation
- **ProgramTab**: Tension patients get TendinopathyProfileQuickCard (no TsiProfileQuickCard exists)
- **LoginView creates its own AuthViewModel**: Separate from RootView's AuthViewModel -- no shared state issues but wasteful
- **MessagingVM deinit**: CONFIRMED FIXED -- both timers invalidated in deinit
- **DashboardVM.loadSafely error**: CONFIRMED partially fixed -- sets self.error on first failure but generic message

## Exercise/Progress/Education Review (2026-03-09)
- **ExerciseCardView refactored**: Compact row layout replaces old card. Cognitive cues and protocol videoUrl thumbnails removed from card (only in detail view now)
- **CustomExerciseLogSheet hardcodes maxPainLevel: 3**: Should use appState.currentUser?.aemSubtype?.maxPainLevel ?? 3
- **ExerciseCardView video thumbnail stale after re-record**: .task(id: exercise.id) won't re-trigger; needs video version dependency
- **ExerciseSessionView double-tap on "Satz fertig"**: No debounce/disabled guard on set completion button
- **ExerciseSessionView background/foreground timer race**: completeSet() can fire from both tick() and scenePhase handler
- **SuccessBanner .animation(value: true)**: No-op, transition works via conditional rendering
- **WissenCardView/EducationCardLoader duplicate rotation logic**: dayOfYear % count computed in both places
- **EdukationTab tension without tsiSeverity**: Perpetual loading spinner for micro-modules section
- **ProgressLogRequest clamping**: Confirmed -- init clamps painLevel to 0-10
- **PainSliderView**: Thorough accessibility (adjustableAction, label, value, hint)
- **ExerciseVideoStore.deleteAllVideos()**: Exists, previously confirmed called on logout

## Condition-Specific Views Review (2026-03-09)
- **FIXED**: NeckMicroModulesView + TensionMicroModulesView NOW HAVE targetCondition defensive filtering
- **CRITICAL**: ExposureLogSheet hardcodes prePain=0 instead of collecting from user -- corrupts FAR clinical data
- **WorkTimerBreakView micro-break auto-complete**: Still races with manual button (unchanged since last review)
- **WorkTimerCard notification callbacks**: Still never cleared on disappear (unchanged)
- **FearHierarchyView**: N parallel API calls for exposures (one per hierarchy item)
- **PacingTimerView**: Timer completion does not auto-log activity to backend
- **AemScreeningView**: Dead refreshProfile code with disconnected alert binding
- **NeckScreeningVM rescreening progress**: Denominator includes Part A items even when skipped
- **AclDashboardVM.loadSafely**: Silently swallows errors after first one
- **Screening flows overall**: Good pattern -- proper error surfacing, accessible, correct NDI/TSI/AEM scoring
- **ACL schedule weekday**: Correct ISO Mon=0 convention via `(weekday+5)%7`
- **AclTodayProgramVM**: Good optimistic toggle with revert-on-failure

## Shoulder Impingement (SAPS) Feature Review (2026-03-10)
- 10 new files + 14 modified files; follows Neck/Tension pattern closely
- ShoulderMicroModulesView HAS targetCondition defensive filtering (good)
- ShoulderMicroModulesView reuses TensionModuleCard (no separate card view)
- SiScreeningView has dead refreshProfile/refreshError code (from AemScreeningView)
- ScreeningCompleteView missing shoulder-specific conditionDescription/expectations (falls to generic default)
- SiScreeningResult.severityGrade is String (not SiSeverityGrade) -- client derives from score, potential mismatch
- education-cards.json needs SHOULDER_IMPINGEMENT entries or Wissen views show empty

## Frozen Shoulder Feature Review (2026-03-10)
- 9 new files + 17 modified files; follows SI/Neck/Tension pattern closely
- FrozenShoulderMicroModulesView HAS targetCondition defensive filtering (good)
- FrozenShoulderMicroModulesView reuses TensionModuleCard (same as SI)
- FsScreeningView has unused `isEmbedded` property (consistent with SiScreeningView)
- education-cards.json has NO FROZEN_SHOULDER entries -- WissenAllCardsView falls back to `condition == nil` (generic tendinopathy cards)
- FsProgressView rescreening: No `onDismiss` to reload history after rescreening (same bug as SiProgressView)
- FsSeverityGrade.from(spadiScore:) thresholds used in sparkline dot colors -- potential client/server mismatch
- ScreeningCompleteView: frozenShoulder case properly handled with SPADI-specific copy
- DashboardViewModel: fsSeverity population follows same pattern as SI/NDI/TSI
- ProtocolLoader: frozenShoulder mapped to `frozen_shoulder_{severity}.json` -- all 3 files exist
- FsScreeningResult.severityGrade uses FsSeverityGrade enum (not String) -- improvement over original SI pattern

## Reviewer Notes
- SwiftUI Slider has built-in VoiceOver adjustable action
- ScreeningCompleteView uses ASCII-only German -- pre-existing pattern
- PendingSync.syncId @Attribute(.unique) was fixed (no longer an issue)
