# iOS UX Architect - Memory

## Project Structure
- Design tokens: `/Reapptivate/Utils/Extensions/ViewModifiers+Design.swift` (combined DesignTokens enum + modifiers)
- Colors: `/Reapptivate/Utils/Extensions/Color+Theme.swift`
- Fonts: `/Reapptivate/Utils/Extensions/Font+Theme.swift`
- Shared components: `/Reapptivate/Views/Common/` (LoadingView, ErrorView, EmptyStateView, InlineErrorView)
- App is entirely in German, targeting physiotherapy patients
- 70+ view files across Views/ directory

## Key Patterns Found
- Custom tab bar (not system TabView) at top of DashboardView with horizontal scroll
- All tabs share a single ScrollView in DashboardView.body
- Sheet pattern: `activeSheet: SomeSheet?` enum with `sheet(item:)` for multiple sheet types
- ViewModel optional pattern: `@State private var viewModel: SomeVM?` created in `.task`
- `.cardStyle()` used 100+ times, `.accentCardStyle()` used for condition-specific cards
- Three button styles: `.primary`, `.secondary`, `.accentFilled` — consistently applied
- Haptic pattern: `@State private var hapticTrigger = false` + `.sensoryFeedback(.success, trigger:)`
- 18 sensoryFeedback instances across the codebase

## Design System (Corrected from prior notes)
- Dark mode IS supported via `Color.adaptive(light:dark:)` helper — works well
- Font scale DOES use `relativeTo:` for Dynamic Type scaling
- 4 instances of raw `.font(.title3)` instead of `.font(.appTitle3)`
- 35+ `.font(.system(size:))` for icons/timers — many justified (.monospaced/.rounded)
- Missing `DesignTokens.progressBarRadius` — 5 views use hardcoded small radii (2-4px)
- PhaseChangeAlert has 1 hardcoded hex: Color(hex: "1F2937")

## Accessibility (Critical Gap - Score 4/10)
- Only ~15 views out of 70+ have any accessibility annotations
- Best: PainSliderView (full VoiceOver), StreakCard (combine+label), DashboardTabBar (.isSelected)
- 8 @ScaledMetric usages but many hardcoded icon sizes remain
- No `.accessibilityLabel` on most card buttons and stat displays

## Missing Umlauts (NeckShoulder module)
- "Ubungsprogramm", "Mobilitat", "Ubung", "verfugbar", "Fruhe", "Spate"
- Affects 7+ NST views and AnalyticsDashboardView

## Error Handling Gaps
- DashboardView.loadAll() — no error handling
- NstDashboardOverview, NstProgramTab — no error states
- NstAdjustmentHistoryView silently swallows errors
- 6+ bare ProgressView() without loading context text

## Navigation
- 5 tabs: Ubersicht, Programm, Edukation, Fortschritt, Insights (conditional)
- NST patients get different tab content via `nstTabContent` branch
- Settings as sheet, exercises/progress as sheets
- No sheet detents or dismiss protection used anywhere

## Engagement Features Present
- StreakCard: current/longest streak, freeze tokens
- MilestoneService: only 5 milestones (firstTraining, 3/7-day streak, 10 sessions, phaseUp)
- MilestoneAlert: polished spring + confetti animation
- RatingService: App Store review after 10 sessions+70% compliance, or 7-day streak, or 25 sessions
- TrainingScheduleCard: auto-save debounce on OverviewTab
- WelcomeCard: shown only when totalSessions == 0

## Missing Platform Features
- No WidgetKit, WatchKit, or ActivityKit integrations
- No HealthKit, Shortcuts/AppIntents
- No iPad-specific layout (no NavigationSplitView, no horizontalSizeClass checks)

## Key Improvement Opportunities (from Task #4 analysis)
- No first-run walkthrough or feature tour (critical gap)
- No exercise demonstration images or videos (critical for physio app)
- No "Today's Plan" focused daily action card
- Milestone system underbuilt — only 5, could expand to 15+ with existing infrastructure
- PainSparklineView very basic — needs Swift Charts upgrade
- No skeleton loading states (bare ProgressView() everywhere)
- No session history list (only aggregate stats)
- No therapist-patient communication channel
- No progress data export for clinical sharing
- SettingsView minimal: no GDPR/privacy section, no haptic toggle, no about page
