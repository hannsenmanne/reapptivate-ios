# Reapptivate iOS — Improvement Plan

**Created**: 2026-02-15
**Evaluated by**: 5-agent team (code-architect, ux-auditor, diagnostic-analyst, product-visionary, release-auditor)
**Scope**: 122 Swift files, 70+ views, 11 ViewModels, ~50 API endpoints, 93 tests

---

## Overall Scores

| Dimension | Score | Evaluator |
|-----------|-------|-----------|
| ViewModel / Architecture consistency | 9/10 | code-architect |
| API layer quality | 7/10 | code-architect |
| Concurrency safety (Swift 6.0) | 9/10 | code-architect |
| Test coverage | 6/10 | code-architect |
| UX design system adherence | 8.5/10 | ux-auditor |
| Accessibility | 4/10 | ux-auditor |
| Loading/error state coverage | 6/10 | ux-auditor |
| Diagnostic parity | 5/10 | diagnostic-analyst |
| Network resilience | GREEN | release-auditor |
| Security | GREEN | release-auditor |
| App Store readiness | RED | release-auditor |
| CI/CD maturity | YELLOW | release-auditor |

---

## CRITICAL — Must Fix Now

| # | Issue | Source |
|---|-------|--------|
| 1 | **Missing AppIcon** — asset catalog has no PNG. App Store will reject. | release-auditor |
| 2 | **Missing `PrivacyInfo.xcprivacy`** — required since Spring 2024 (UserDefaults usage). | release-auditor |
| 3 | **Empty `DEVELOPMENT_TEAM`** in project.yml — can't sign or submit. | release-auditor |
| 4 | **Failing test** — `SharedTypesTests.testTendinopathyTypeCount()` asserts 10 but there are now 11 cases. | code-architect |
| 5 | **Missing umlauts across entire NeckShoulder module** — "Mobilitat", "Ubung", "verfugbar" etc. | ux-auditor |

---

## IMPORTANT — Should Fix Before Release

| # | Issue | Source |
|---|-------|--------|
| 6 | **8 of 11 ViewModels have zero tests** — LbpEnhancementsVM (277 lines), all 3 screening VMs, ExerciseVM, PhaseVM, NstTrackingVM, NeckShoulderProgramVM. | code-architect |
| 7 | **CachedUser missing NST fields** — `neckShoulderScreeningCompleted` and `neckShoulderSeverity` not cached. | code-architect |
| 8 | **APIClient triple code duplication** — `request<T>()`, `requestVoid()`, `requestData()` repeat identical retry logic. | code-architect |
| 9 | **Accessibility is the biggest UX gap (4/10)** — Most views have zero VoiceOver labels, inconsistent @ScaledMetric. | ux-auditor |
| 10 | **Missing error states in data-loading views** — DashboardView, NstProgramTab, AnalyticsDashboardView silently fail. | ux-auditor |
| 11 | **No scene phase handling at app root** — No token re-validation on foreground, no state saving on background. | release-auditor |
| 12 | **NST gets wrong Wissen cards** — passes `isLbp: false, isNeck: false`, gets generic tendinopathy cards. | diagnostic-analyst |

---

## Diagnostic Parity Matrix

| Condition | API Endpoints | Unique Views | Model Richness | Overall Depth |
|-----------|--------------|--------------|----------------|---------------|
| LBP | 19 dedicated | 13 | 372 lines, 15+ types | Deepest |
| NST | 15 dedicated | 15 | Scattered in VMs | Rich but isolated |
| Neck Pain | 7 dedicated | 4 | 95 lines, 5 types | Thin |
| Tendinopathy | 0 dedicated | 0 | 0 dedicated types | Vanilla |

### Biggest Parity Gaps
- Tendinopathy has no micro-modules, no condition-specific analytics, no pain trend charts
- Neck Pain has no analytics dashboard, no session history, no adjustment tracking
- NST's InsightsTab is completely hidden — analytics depth is missing
- Only Tendinopathy shows phase readiness criteria — valuable for all conditions
- Only Neck Pain has rescreening — clinically important for all progressive conditions

---

## Phase 1 — Fix & Polish (Pre-release)

- [ ] Fix failing test: `SharedTypesTests.testTendinopathyTypeCount()` (assert 10 -> 11)
- [ ] Fix missing umlauts across NeckShoulder module (systematic find-replace)
- [ ] Fix NST Wissen card filtering bug (`isNeck: false` -> `isNeck: true`)
- [ ] Update CachedUser for NST fields (`neckShoulderScreeningCompleted`, `neckShoulderSeverity`)
- [ ] Add AppIcon (1024x1024 PNG to asset catalog)
- [ ] Create `PrivacyInfo.xcprivacy` (declare UserDefaults API usage)
- [ ] Add error states to data-loading views (DashboardView, NstProgramTab, AnalyticsDashboardView, EdukationTab)
- [ ] Replace bare `ProgressView()` with contextual loading text (6 locations)
- [ ] Fix `.font(.title3)` system font leaks (4 files) -> `.appTitle3`
- [ ] Fix hardcoded hex in `PhaseChangeAlert.swift` -> use theme color
- [ ] Add `@Attribute(.unique)` to `PendingSync.syncId`
- [ ] Add `AppState` tests for `isNeckShoulderTension` and `needsNeckShoulderScreening`
- [ ] Personalized welcome screen after screening completion
- [ ] Skeleton loading states (shimmer placeholders for card content)
- [ ] Card entry animations (staggered fade-in on tab load)
- [ ] Rest day encouragement card on OverviewTab

---

## Phase 2 — Engagement & Visualization

- [ ] Post-login feature walkthrough (3-5 screen carousel, shown once)
- [ ] "Today's Plan" summary card on OverviewTab
- [ ] Pain trend charts using Swift Charts (replace bare sparkline)
- [ ] Expand milestone system (14-day/30-day streak, 25/50/100 sessions, phase completions)
- [ ] Achievement gallery / trophy case view
- [ ] Weekly compliance calendar (GitHub-style heatmap)
- [ ] Home Screen Widget — small (streak + status)
- [ ] Home Screen Widget — medium (today's exercises checklist)
- [ ] Contextual first-use tooltips (coach marks per tab)
- [ ] Guided first exercise session walkthrough
- [ ] Exercise completion celebration animation
- [ ] Phase change celebration enhancement (particles, haptic patterns)
- [ ] Pain slider enhanced feedback (scale/bounce animation)
- [ ] About / credits section in Settings
- [ ] Share milestone achievements (iOS share sheet)
- [ ] Motivational quotes/affirmations (daily rotation, CBT-based)
- [ ] Haptic feedback toggle in Settings
- [ ] Data & privacy section in Settings (GDPR)
- [ ] Missing haptics on common interactions (exercise start, schedule toggle, screening selection)
- [ ] Sheet dismiss protection on data-entry sheets
- [ ] Define `DesignTokens.progressBarRadius` and use consistently

---

## Phase 3 — Platform & Communication

- [ ] Exercise demonstration images (static illustrations per exercise)
- [ ] Exercise instruction videos (15-30 sec clips in ExerciseDetailView)
- [ ] Live Activity for exercise sessions (Lock Screen/Dynamic Island)
- [ ] Live Activity for pacing timer (DER/EER patients)
- [ ] HealthKit integration (pain data, exercise sync)
- [ ] Progress export as PDF (for sharing with therapist)
- [ ] Therapist messaging foundation (in-app text messaging)
- [ ] Notes to therapist on progress log (with reply capability)
- [ ] Session history list for all conditions (not just NST)
- [ ] Pain diary with context (location, type, triggers, sleep quality)
- [ ] Guided audio cues during exercise ("Hold... 5, 4, 3, 2, 1... Release")
- [ ] Streak recovery grace period (partial credit system)
- [ ] Education content bookmarking
- [ ] Weekly summary notification (push)
- [ ] Goal setting feature
- [ ] Reset education progress in Settings
- [ ] Font size override in Settings

---

## Phase 4 — Future Vision

- [ ] Apple Watch companion app
- [ ] Siri / Shortcuts integration (AppIntents)
- [ ] iPad optimized layout (NavigationSplitView, sidebar)
- [ ] Behavioral nudge engine ("You tend to skip Thursdays...")
- [ ] Body map visualization (silhouette with pain overlay)
- [ ] Bring Tendinopathy up to LBP/NST feature depth (micro-modules, analytics)
- [ ] Bring Neck Pain up to LBP/NST feature depth (analytics dashboard, session history)
- [ ] Pain education quiz (self-check after education modules)
- [ ] Notification tone customization
- [ ] Preferred exercise order customization
- [ ] Custom rest timer duration per exercise
- [ ] Interactive education cards (pull-quotes, diagrams, highlights)
- [ ] Adherence insights with behavioral nudges

---

## Architecture Improvements (Cross-phase)

- [ ] Refactor APIClient to eliminate triple retry code duplication
- [ ] Move AppState mutations out of DashboardViewModel into AppState methods
- [ ] Consider environment injection for NotificationService and AudioService (testability)
- [ ] Store Task in `handleScannedCode` for proper cancellation
- [ ] Add `LazyVStack` for potentially long lists (progress history, exposure logs)
- [ ] Replace `Timer.scheduledTimer` in NstSessionPlayerView with `Timer.publish`
- [ ] Replace `DispatchQueue.main.asyncAfter` with structured concurrency (5 locations)
- [ ] Add scene phase handling at root level (token re-validation on foreground)
- [ ] Add background refresh via BGTaskScheduler for PendingSync
- [ ] Add SwiftLint or static analysis to CI
- [ ] Add UI test automation to CI pipeline
- [ ] Add coverage reporting to CI pipeline

---

## Test Coverage Gaps (Cross-phase)

Untested ViewModels (0 tests each):
- [ ] ExerciseViewModel
- [ ] PhaseViewModel
- [ ] AemScreeningViewModel
- [ ] NeckScreeningViewModel
- [ ] NeckShoulderScreeningViewModel
- [ ] NeckShoulderProgramViewModel
- [ ] NstTrackingViewModel
- [ ] LbpEnhancementsViewModel (277 lines, ~15 methods — highest priority)

Untested Services:
- [ ] SyncService
- [ ] ProtocolLoader
- [ ] NetworkMonitor
- [ ] EducationCardLoader

---

## UX Consistency Findings (Reference)

### Design Token Issues
- 5 hardcoded corner radii in progress bars (NeckFocusAreasView, EdukationTab, WissenCardView, NstProgressView, NstComplianceView)

### Color Issues
- 1 hardcoded hex: PhaseChangeAlert.swift line 42 — `Color(hex: "1F2937")`
- WissenExpandableCard stroke (`Color.gray200`) may be barely visible in dark mode

### Typography Issues
- 35+ system font leaks (`.font(.system(size:...))`) — most justified for monospaced/rounded timer displays
- 4 raw `.title3` usages (system font, not Outfit): CustomExerciseCardView, ExerciseCardView, ProgressTab, DashboardView

### Empty State Inconsistencies
- PacingAdjustmentHistoryView, NstAdjustmentHistoryView, EdukationTab, NstProgressView use inline text instead of EmptyStateView

### Navigation Issues
- Nested NavigationStack inside Settings sheet (ScheduleEditorView, NotificationPrefsView pushed inside sheet)
- No sheet detents used anywhere
- Missing dismiss confirmation on data-entry sheets (ExposureLogSheet, PacingActivityLogSheet)

### Missing German Umlauts (NeckShoulder module)
- "Mobilitat" -> "Mobilitat" (8+ occurrences)
- "Ubungsprogramm" -> "Ubungsprogramm"
- "Ubung uberspringen" -> "Ubung uberspringen"
- "Ubungen" -> "Ubungen"
- "verfugbar" -> "verfugbar"
- "Fruhe Exp." / "Spate Exp." -> "Fruhe" / "Spate"
