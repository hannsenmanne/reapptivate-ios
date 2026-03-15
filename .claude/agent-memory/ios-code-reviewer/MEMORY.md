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
- SiScreeningResult.severityGrade uses SiSeverityGrade enum (not String) -- same pattern as FS
- education-cards.json needs SHOULDER_IMPINGEMENT entries or Wissen views show empty

## Frozen Shoulder Feature Review (2026-03-10, deep review)
- 9 new files + ~12 modified files; follows SI/Neck/Tension pattern closely
- FrozenShoulderMicroModulesView HAS targetCondition defensive filtering (good)
- FrozenShoulderMicroModulesView reuses TensionModuleCard (same as SI)
- FsScreeningView does NOT have `isEmbedded` property (corrected 2026-03-11)
- education-cards.json has NO FROZEN_SHOULDER entries -- BUT EdukationTab + OverviewTab correctly exclude WissenAllCardsView for FS
- FsProgressView rescreening: HAS `onDismiss` to reload history (IMPROVEMENT over SiProgressView/NdiProgressView/TsiProgressView which lack it)
- FsSeverityGrade.from(spadiScore:) thresholds: LEICHT<=34, MITTEL<=59, SCHWER>=60 -- matches spec
- ScreeningCompleteView: frozenShoulder case properly handled with SPADI-specific copy
- DashboardViewModel: fsSeverity population follows same pattern as SI/NDI/TSI
- ProtocolLoader: frozenShoulder mapped to `frozen_shoulder_{severity}.json` -- all 3 files exist
- FsScreeningResult.severityGrade uses FsSeverityGrade enum (not String) -- improvement over original SI pattern
- **All 3 protocol JSON files have IDENTICAL exercises** -- only id/name differ. DosageModifier `SCHWER` key present but same data in all files. No severity-differentiated dosage.
- No unit tests for FsSeverityGrade, FsHistoryEntry decoding, or FsScreeningViewModel
- SharedTypesTests.testTendinopathyTypeCount needs update from 14 to include frozenShoulder (now 14 including it)
- `isTendinopathy` correctly excludes frozenShoulder

## Lateral Ankle Sprain (LAS) Feature Review (2026-03-11)
- 8 new files + ~10 modified files; follows FS/SI pattern closely
- LateralAnkleSprainMicroModulesView HAS targetCondition defensive filtering (good)
- LateralAnkleSprainMicroModulesView reuses TensionModuleCard (same as SI/FS)
- LasProgressView rescreening: HAS `onDismiss` to reload history (same as FsProgressView)
- LasSeverityGrade.from(caitScore:) thresholds: LEICHT>=24, MITTEL>=12, SCHWER<12 -- inverted scale (higher=better)
- ScreeningCompleteView: lateralAnkleSprain case properly handled with CAIT-specific copy
- DashboardViewModel: lasSeverity population follows FS pattern (backend pref + client fallback)
- ProtocolLoader: lateralAnkleSprain mapped to `lateral_ankle_sprain_{severity}.json` -- all 3 files exist
- LasScreeningResult.severityGrade is NON-optional LasSeverityGrade (unlike FS which is optional)
- **All 3 protocol JSON files have IDENTICAL exercises** -- same as FS finding, no severity differentiation
- **No dosageModifier in any LAS protocol** -- SCHWER patients get same exercise dosage as LEICHT
- **German typo**: "Sprunggelenksverstauching" should be "Sprunggelenksverstauchung" in displayName + all 3 JSON files
- **No unit tests** for LasSeverityGrade, LasHistoryEntry decoding, or LasScreeningViewModel
- `isTendinopathy` correctly excludes lateralAnkleSprain
- SharedTypesTests.testTendinopathyTypeCount expects 15 -- correct with LAS added
- InsightsTab: LAS gets its own section (LateralAnkleSprainInsightsSection) with CAIT history + focus areas
- OverviewTab: LAS excluded from WissenCardView (correct -- micro-modules cover education)
- EdukationTab: LAS branch shows LateralAnkleSprainMicroModulesView (correct)
- SettingsView: LAS severity NOT displayed (pre-existing omission pattern -- SI/FS also missing)
- DashboardTabBar: LAS gets Insights tab (via showInsights flag)
- FsScreeningView does NOT have isEmbedded property (correcting earlier memory note)

## Localization (DE/EN Bilingual) Review (2026-03-12)
- **LanguageManager**: `@Observable @MainActor final class`, stores in UserDefaults "appLanguage"
- **Two localization patterns coexist**: (1) Localizable.xcstrings for SwiftUI `Text("literal")`, (2) inline `isEnglishLocale ? "en" : "de"` ternaries for non-literal String contexts
- **EducationCardLoader cache bug**: Caches cards on first load, never invalidates on language switch -- user sees stale language
- **ProtocolLoader cache**: Correctly uses locale-aware cache keys (`key_en_cache` vs `key`)
- **AppearanceMode.label bug**: Returns raw String, used via `Text(mode.label)` which does NOT invoke LocalizedStringKey lookup
- **Accept-Language header**: Sends bare "de"/"en" (valid but minimal RFC 7231)
- **Info.plist permission strings**: German-only in project.yml, no InfoPlist.strings for English
- **Inconsistent localization**: Values localized but labels not (e.g., "Haltezeit", "Wiederholungen" labels still German)
- **Accessibility strings partially missed**: Some .accessibilityLabel/.accessibilityHint still German while .accessibilityValue localized
- **micro-modules_en.json**: All entries have `"locale": "de"` instead of `"en"` (backend seed file, not iOS runtime issue)
- **Pattern**: File-private `isEnglishLocale` computed var reads UserDefaults directly; works because locale environment change triggers full re-render

## Liquid Glass Design Refresh Review (2026-03-14)
- **CardStyle/AccentCardStyle**: Now use `ultraThinMaterial + cardBg.opacity(0.72)` overlay + `glassStroke` border
- **Button styles**: Primary/Accent use gradient fill + inner highlight stroke; Secondary uses `ultraThinMaterial`
- **CardEntryAnimation**: Added `reduceMotion` check and `scaleEffect` to stagger animation
- **AppBackgroundModifier**: RadialGradient accent glow (0.06 opacity) behind `appBg`
- **GlassSheetModifier**: `.presentationCornerRadius(28) + .presentationBackground(.regularMaterial) + .presentationDragIndicator(.visible)` applied to ~30 sheets
- **GlowingIconContainer**: Reusable component with filled/unfilled modes, gradient fill, optional inner stroke, colored shadow
- **FloatingTabBar**: New file, replaces DashboardTabBar. Floating capsule with `.regularMaterial`, `matchedGeometryEffect` indicator, `reduceMotion` support
- **Messages moved**: From tab to toolbar button + fullScreenCover with dismiss button
- **DashboardTab.messages**: Now dead code (never selectable), returns EmptyView
- **accentDeep**: Defined but unused
- **Inconsistency**: ExerciseCardView, MicroModuleCard, WissenExpandableCard still use solid `Color.cardBg` (not glass material)
- **Glow rings**: TodaysPlanCard + WorkTimerCard use `blur(radius: 6)` on trimmed circles for ambient glow
- **hasSeenWelcome/hasSeenWalkthrough**: FIXED -- no longer cleared on logout (was previously flagged)
- **DashboardVM.loadSafely error**: Still German-only ("Daten konnten nicht geladen werden.")

## Reviewer Notes
- SwiftUI `Text(stringVariable)` uses String init, NOT LocalizedStringKey -- no automatic xcstrings lookup
- SwiftUI `Text("literal")` uses LocalizedStringKey init -- automatic xcstrings lookup
- SwiftUI Slider has built-in VoiceOver adjustable action
- ScreeningCompleteView uses ASCII-only German -- pre-existing pattern
- PendingSync.syncId @Attribute(.unique) was fixed (no longer an issue)
- `glassStroke` file-level `let` with `Color(UIColor{...})` IS reactive to trait changes -- UIColor closure re-evaluates on render
- `.id(selectedTab)` on tab content causes full subtree teardown/rebuild on tab switch (scroll pos lost, .task re-fires)
