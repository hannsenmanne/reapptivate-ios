


## Claude Code iOS Team Review Prompt

```
You are the lead of a senior iOS review team for the REAPPTIVATE iOS app.
Read both CLAUDE.md files (iOS + web/backend) completely before starting.
You must understand the full architecture, design system, networking layer,
and all existing conditions (Tendinopathy, LBP/AEM, Neck, Tension, ACL)
before reviewing anything.

Spawn 6 parallel sub-agents: 5 specialist reviewers + 1 independent critic.
Each agent works simultaneously. The critic reviews all other agents' outputs
last and challenges their findings.

════════════════════════════════════════════════════════════════
AGENT 1 — SENIOR iOS ENGINEER (Architecture & Code Quality)
════════════════════════════════════════════════════════════════
You are a senior Swift 6.0 / SwiftUI engineer with 10+ years iOS experience.
Review the entire codebase for architectural correctness, Swift 6 compliance,
and long-term maintainability.

1. SWIFT 6 CONCURRENCY COMPLIANCE
   - Are ALL ViewModels `@Observable @MainActor final class`?
     Any missing @MainActor = potential data race in Swift 6 strict mode
   - Are all `@unchecked Sendable` usages justified?
     (TokenManager, ProtocolLoader, NetworkMonitor are known exceptions)
     Any unjustified use = suppressed concurrency warning hiding a real bug
   - Are there any `Task { @MainActor in ... }` hops that could be
     replaced with direct @MainActor annotations?
   - Check all `.task {}` blocks — are they cancellation-safe?
     Long-running tasks must check `Task.isCancelled` periodically

2. VIEWMODEL INSTANTIATION PATTERN
   - ALL ViewModels must use the `@State private var viewModel: VM? + .task`
     pattern. Exceptions: ExerciseViewModel (no APIClient dependency).
   - Find any ViewModel instantiated at view init (e.e. `@StateObject` or
     `@State var vm = SomeViewModel()`) — these cause multiple instances
     on SwiftUI re-renders and wasted API calls
   - Are ViewModels ever passed between views as parameters? They should
     be created locally or accessed via environment.

3. ENVIRONMENT INJECTION
   - Are AppState, APIClient, NetworkMonitor always accessed via
     @Environment — never via singletons inside ViewModels?
   - Is APIClient ever bypassed (direct URLSession calls in ViewModels)?
     All networking must go through APIClient for consistent error handling,
     token injection, and retry logic.
   - Are there any retained strong references to AppState inside
     ViewModels that could prevent deallocation?

4. SWIFTDATA USAGE
   - CachedUser, CachedProgress, PendingSync: are `@Attribute(.unique)`
     constraints properly set on IDs?
   - Is SyncService.setModelContext() always called before first use?
     (It's deferred — any early call crashes)
   - PendingSync max 5 retries: is this enforced? What happens to
     permanently failing syncs — are they ever cleaned up?
   - Is there any SwiftData query running on a background thread without
     a dedicated ModelContext?

5. MEMORY MANAGEMENT
   - Are there retain cycles in any closure captures?
     Check: `.task { [weak self] in ... }` — [weak self] is not needed
     in structured concurrency, but `self` captures in callbacks/timers need it
   - AudioService.shared: is the AVAudioSession properly deactivated
     after pacing timer use? Lingering sessions can block other apps' audio.
   - ProtocolLoader.shared: the in-memory cache is never invalidated.
     After 30 weeks of ACL rehab with 9 streams, how large does this cache get?

6. XCODEGENPROJECT.YML INTEGRITY
   - Are ALL new Swift files (AclTypes.swift, ACL ViewModels, ACL Views)
     included in the sources array?
   - Are all new resource files (JSON configs, if bundled) included with
     `buildPhase: resources`?
   - After adding ACL types to SharedTypes.swift: does xcodegen generate
     regenerate correctly without conflicts?

7. TEST COVERAGE
   - aclScoring.service equivalent logic in iOS: is milestone unlock
     logic unit tested? (This is clinical logic — must have tests)
   - AclTypes.swift decoding: are there unit tests for each Codable struct
     using TestFixtures? Especially:
       - Surgery date parsing (UTC timezone — known gotcha from CLAUDE.md)
       - LSI values decoding as Double (not Int — JSON may send both)
       - AclConcomitantInjury array decoding with unknown future values
   - Are there tests for the weeksPostSurgery calculation covering:
       - Exactly 12 weeks (boundary for Running unlock)
       - Timezone edge case (surgery at 23:00 local = different UTC day)
   - Current coverage: ~148 tests. How many new tests does the ACL module add?
     Target: every new Codable struct + every ViewModel method has a test.

8. DEAD CODE & TECH DEBT
   - `DashboardViewModel.availableTabs` is documented as unused in CLAUDE.md.
     Is it still present? Should it be removed or is it planned for future use?
   - Are there any TODO/FIXME comments in ACL code that indicate
     incomplete implementation?
   - Are there any force-unwraps (!) outside of @IBOutlet/known-safe contexts?

════════════════════════════════════════════════════════════════
AGENT 2 — SENIOR NETWORKING & DATA ENGINEER
════════════════════════════════════════════════════════════════
You specialize in iOS networking, Codable, offline-first architecture,
and data persistence. Every silent data loss bug is your responsibility.

1. ENCODING GOTCHA AUDIT (CRITICAL — document in CLAUDE.md as a known pitfall)
   Review EVERY new ACL request struct for the camelCase encoding requirement:
   - AclScreeningSubmission → surgeryDate, graftType, athleteLevel,
     concomitantInjuries, kneeSide
   - AclDailyKpiSubmission → painNrs, kneeFlexionDeg, extensionDeficitDeg,
     swellingGrade, quadsLag
   - AclWeeklyKpiSubmission → ikdcScore, tampaScore, thighCirc5cm, thighCirc10cm
   - AclLabAssessmentSubmission → quadLsi, hamstringLsi, hipAbdLsi, hipAddLsi,
     hipErLsi, calfLsi, dlCmjConcentricLsi, dlDjRsi, slDjRsi, etc.
   For each struct: are there CodingKeys where property name ≠ JSON key?
   Any mismatch = field sent as null = data silently not persisted on backend.

2. RESPONSE WRAPPER AUDIT
   Check EVERY new ACL endpoint's actual backend res.json() shape against
   the iOS APIResponses.swift wrapper structs:
   - GET /api/acl/streams → does backend return {streams: [...]} or [...] directly?
   - POST /api/acl/screening → {screening: {...}} or {user: {...}} or bare object?
   - GET /api/acl/milestone-status → wrapped or direct?
   - POST /api/acl/lab-assessment → what does backend return on success?
   - GET /api/acl/discharge-progress → structure of response?
   Any wrapper mismatch = silent decode failure = empty UI with no error shown.

3. SURGERY DATE — TIMEZONE CRITICAL PATH
   This is the most dangerous data point in the entire ACL module.
   An off-by-one-day error on surgery_date causes wrong weeksPostSurgery,
   which causes wrong stream unlocking — a clinical safety issue.
   - Is surgery_date encoded as "yyyy-MM-dd" using DateFormatters.dateOnly?
   - Is DateFormatters.dateOnly explicitly set to UTC timezone?
     (From CLAUDE.md: ALL DateFormatters must use explicit UTC timezone)
   - Is the date picker in AclScreeningView constrained to past dates only?
     (Future surgery date = negative weeks = crash or wrong unlock state)
   - When decoded from GET /api/acl/screening, is surgery_date parsed
     back correctly without timezone shift?
   - Write a specific unit test: surgery on "2025-06-15", device in
     UTC+2 (Berlin), check weeksPostSurgery at "2025-09-07" = exactly 12.

4. OFFLINE SUPPORT FOR ACL KPIs
   Daily KPI logging must work offline (patient may be at physiotherapy
   gym without wifi). Check:
   - Does POST /api/acl/daily-kpi failure queue a PendingSync entry?
   - When SyncService drains queue on reconnect, does it replay correctly?
   - Are daily KPIs displayed optimistically from local state before
     server confirmation, or does the UI show nothing until server confirms?
   - Weekly KPIs: same offline support needed?
   - Lab assessments (therapist): offline support less critical but check
     if a dropped connection mid-submit causes data loss.

5. API CLIENT RETRY BEHAVIOR
   From CLAUDE.md: APIClient retries once with 2s delay on network errors,
   NOT on 4xx/5xx. Verify:
   - A failed daily KPI submission on network error: is it retried once
     automatically, then queued in PendingSync on second failure?
   - A 403 (patient trying to submit lab values): does it correctly NOT
     retry and show an error immediately?
   - A 401 (token expired mid-session): is onTokenExpired callback
     triggered, or does it retry and compound the 401?

6. PROTOCOL LOADER — ACL PROTOCOL FILES
   - Are ACL exercise JSON files bundled in Resources/Protocols/?
   - Is the filename mapping correct for all 9 streams?
     (TendinopathyType.aclReconstruction + stream ID → filename)
   - What happens if a stream's exercise JSON file is missing from bundle?
     Does it crash, return empty, or show an error?
   - ProtocolLoader uses convertFromSnakeCase — are ACL exercise JSON files
     authored in snake_case to match this expectation?

7. KEYCHAIN & TOKEN EDGE CASES
   - Keychain persists across reinstalls. If a user reinstalls the app
     after 30 weeks, their ACL screening data is in the database but
     their keychain token is invalid. Does the app correctly detect
     this and prompt re-login (not crash)?
   - If JWT expires during a long lab entry form session (therapist
     filling in 20 LSI fields for 5 minutes), does the form handle
     the 401 gracefully or lose all entered data?

════════════════════════════════════════════════════════════════
AGENT 3 — SENIOR UI ENGINEER (SwiftUI & Design System)
════════════════════════════════════════════════════════════════
You are a SwiftUI expert who has shipped multiple App Store apps.
You enforce the design system, find layout bugs, and ensure the app
looks and feels excellent on every device.

1. DESIGN TOKEN COMPLIANCE
   Every new ACL view must use design tokens from DesignTokens enum
   and Color+Theme.swift. Check for violations:
   - Cards: 14px continuous corners + adaptive shadow (black 6% / white 4%)
   - Buttons: .primary (dark), .secondary (border), .accentFilled (emerald)
   - Inputs: .inputFieldStyle() modifier
   - Badges: 8px corners, color.opacity(0.1) background
   - Accent color: Color.accent (10B981 light / 34D399 dark)
   - Are any hardcoded hex colors or hardcoded padding values used in
     ACL views? These should be design token references.

2. DARK MODE AUDIT
   The most common shipping bug in new features. Check every ACL view:
   - `Color.textPrimary` used as text on `Color.cardBg` background — correct
   - `Color.textPrimary` used as background with white text — WRONG
     (From CLAUDE.md: textPrimary flips in dark mode, use appBg for adaptive bg)
   - Any Image assets: do they have dark mode variants in Assets.xcassets?
   - Lock/unlock status colors: are they using semantic adaptive colors or
     hardcoded hex that disappears in dark mode?
   - Run all ACL screens in both light AND dark mode:
     `xcrun simctl ui "iPhone 17 Pro" appearance dark`

3. DYNAMIC TYPE & ACCESSIBILITY SIZING
   - All ACL text must use semantic Font+Theme styles (.appHeadline, .appBody etc.)
     not hardcoded Font.system(size: 17). Hardcoded = breaks Dynamic Type.
   - @ScaledMetric on ALL icon container sizes in ACL components
     (milestone circles, stream status icons, KPI badges)
   - AclMilestoneTimeline: does the layout break when text size is XXL?
     Timeline dots and connecting lines must adapt.
   - AclDischargeProgress progress bars: does the percentage label fit
     at all Dynamic Type sizes, or does it clip?

4. DEVICE SIZE CLASSES
   Test all ACL screens on:
   - iPhone SE (smallest — 375pt wide): does AclStreamOverview compress
     gracefully? Are stream card labels truncated or clipped?
   - iPhone 17 Pro Max (largest): do cards stretch proportionally or
     leave excessive whitespace?
   - iPad (if supported): does the tab layout work on wider canvas?
   - Landscape mode: does AclDailyKpiLogger scroll correctly when
     keyboard appears in landscape?

5. KEYBOARD & SCROLL BEHAVIOR
   - AclDailyKpiLogger has multiple numeric inputs (pain NRS, ROM degrees,
     swelling grade). When keyboard appears:
     Does the active field scroll into view?
     Does `.scrollDismissesKeyboard(.interactively)` work correctly?
   - AclLabEntryForm: 15–20 fields in a form. Does it use Form {} or
     ScrollView + VStack? Form is preferred for grouped input UX.
   - Return key navigation between fields: does pressing Next move focus
     to the next input, or does the keyboard dismiss?

6. ANIMATION & TRANSITIONS
   - AclMilestoneTimeline: when milestone advances, is there an animated
     transition (e.g. circle fills green with spring animation)?
   - AclStreamOverview: when a stream unlocks, does the card transition
     from locked (gray) to active (colored) with animation?
   - AclDischargeProgress: do progress bars animate from old to new value?
   - All animations should use `.animation(.spring(response: 0.3))` per
     the existing pattern — check no deprecated `.animation()` calls.

7. NAVIGATION STACK CONSISTENCY
   - ACL views: do they use NavigationLink or programmatic navigation
     with @State + .navigationDestination?
   - Are NavigationTitle and .toolbar items consistent with existing
     PatientDashboard conventions?
   - Back button labels: are they localized in German or showing
     default "Back" in English?

8. LOCALIZATION (GERMAN)
   From CLAUDE.md context: the app targets German-speaking users.
   - Are ALL user-facing strings in ACL views in German?
   - Are there any English strings hardcoded in ACL views?
     (e.g., "Locked", "Unlock", "Stream", "Discharge Criteria")
     These should be: "Gesperrt", "Freischalten", etc.
   - Error messages: German, specific, reassuring (not generic English)
   - Date formatting: German locale (DD.MM.YYYY, not MM/DD/YYYY)
     Are surgery dates and milestone dates formatted with German locale?

9. EMPTY STATES & SKELETON LOADING
   - AclStreamOverview before first API response: skeleton cards or spinner?
   - AclMilestoneTimeline with 0 lab assessments: informative empty state?
   - AclDischargeProgress with no lab data: shows target thresholds with
     current = 0%, or hides until data exists?
   - Day 1 post-op dashboard: is there a "Willkommen — Was du heute tun kannst"
     card, or does the patient see mostly locked streams?

════════════════════════════════════════════════════════════════
AGENT 4 — SENIOR QA ENGINEER (Functional Testing)
════════════════════════════════════════════════════════════════
You are a senior QA engineer with experience in medical software validation.
You write test cases, find edge cases, and ensure every user journey works
end-to-end. You do not trust that "it probably works."

Run through each test scenario manually (or via UI tests) and document
pass/fail with exact reproduction steps.

1. HAPPY PATH — FULL ACL JOURNEY (Competitive Athlete, Hamstring Graft)
   Step 1: Login as ACLcomptest@test.com (Test1234!)
   Step 2: ACL screening shown → fill all fields → submit
           VERIFY: acl_screening_completed = true, surgery_date saved,
                   post-op precautions displayed immediately
   Step 3: Day 1 dashboard
           VERIFY: CLINICAL_ROM + MOTOR_CONTROL streams unlocked
           VERIFY: STRENGTH stream shows isometrics only
           VERIFY: Running/COD/Sports streams locked with criteria visible
           VERIFY: Conditioning stream unlocked (week 3–4 unlocks conditioning)
   Step 4: Log daily KPI
           VERIFY: pain NRS 5, flexion 90°, swelling 2 → saved correctly
           VERIFY: "Heute bereits geloggt" state shown after logging
   Step 5: Therapist logs in → opens ACLcomptest patient
           VERIFY: AclLabEntryForm available for Milestone 1 assessment
           VERIFY: Cannot access lab entry as patient (403 expected)
   Step 6: Therapist enters Milestone 1 values meeting criteria
           (quad_lsi: 72, knee_flexion: 136, swelling: 1, ikdc: 65)
           VERIFY: Milestone advances to 2
           VERIFY: Running stream unlocks
           VERIFY: Patient dashboard updates without manual refresh

2. EDGE CASES — CONCOMITANT INJURIES
   Test with MENISCAL_REPAIR concomitant injury:
   VERIFY: NWB precaution banner shown for first 4 weeks
   VERIFY: Weight-bearing exercises blocked in MOTOR_CONTROL stream
   VERIFY: Precaution banner automatically hidden after week 4
   VERIFY: Patient receives notification when precaution lifts

3. EDGE CASES — FAILING MILESTONE CRITERIA
   Therapist enters Milestone 1 values NOT meeting criteria:
   (quad_lsi: 65 — below 70% threshold)
   VERIFY: Milestone does NOT advance
   VERIFY: Clear feedback shown: "Kriterium nicht erfüllt: Quadrizeps LSI 65% / Ziel: 70%"
   VERIFY: Running stream remains locked
   VERIFY: Therapist can resubmit corrected values

4. EDGE CASES — RECREATIONAL vs COMPETITIVE THRESHOLDS
   - Log in as ACLrectest@test.com (recreational, 20 weeks post-op)
   VERIFY: Discharge criteria show RECREATIONAL thresholds
           (Hip ABD >30% BW, not 40%; Calf >150% BW, not 200%)
   VERIFY: No COD/Sports Specific discharge tests required for recreational
   VERIFY: Switching athlete_level via rescreening updates thresholds

5. OFFLINE BEHAVIOR
   Step 1: Enable airplane mode on simulator
   Step 2: Open ACL daily KPI logger → submit KPI entry
   VERIFY: Optimistic UI update shown (entry appears in history)
   VERIFY: PendingSync entry created (check SwiftData)
   Step 3: Disable airplane mode
   VERIFY: SyncService drains queue, KPI synced to backend
   VERIFY: No duplicate entries created

6. AUTHENTICATION EDGE CASES
   - Log in → fill half of ACL screening → kill app → reopen
   VERIFY: Screening resumes from correct state (not cleared, not resubmitted)
   - Token expires during lab entry form (simulate by manipulating JWT exp)
   VERIFY: Form shows error "Sitzung abgelaufen, bitte neu einloggen"
   VERIFY: Entered data preserved so user can re-login and resubmit
   - Patient attempts to call POST /api/acl/lab-assessment directly
   VERIFY: 403 Forbidden returned (not 500, not 200)

7. CONTENT CONTAMINATION TESTS
   - Log in as FARtest@test.com (LBP patient)
   VERIFY: No ACL streams, KPI logger, or milestone cards visible
   VERIFY: No ACL micro-modules in EdukationTab
   - Log in as ACLcomptest@test.com
   VERIFY: No LBP pacing plan, fear hierarchy, or AEM content visible
   VERIFY: No NDI/TSI rescreening options shown

8. TAMPA SCALE ALERT TRIGGER
   Submit weekly KPI with tampaScore: 38 (above 37 threshold)
   VERIFY: Therapist alert created in database
   VERIFY: Alert visible in therapist dashboard for this patient
   VERIFY: Patient receives psychoeducation micro-module about movement fear
   Submit tampaScore: 35 the following week
   VERIFY: Alert resolved/updated in therapist dashboard

9. DISCHARGE CRITERIA — NEAR-COMPLETE STATE
   Test with a patient meeting 11/12 discharge criteria (one failing):
   VERIFY: Progress view shows 11 green checks + 1 red with specific gap
   VERIFY: "Entlassung möglich" button/badge NOT shown
   Submit final failing criterion as met:
   VERIFY: All 12 green → "Entlassung möglich" state shown
   VERIFY: Celebration animation/haptic triggered
   VERIFY: Therapist receives discharge readiness notification

10. SEED SCRIPT VALIDATION
    node scripts/seed-acl-test-patients.js
    VERIFY: ACLcomptest@test.com — competitive, hamstring graft, ~10 weeks post-op
            milestone 1 already unlocked, running stream just unlocked
    VERIFY: ACLrectest@test.com — recreational, patellar tendon, ~20 weeks post-op
            milestone 3, COD + sports specific active, discharge progress visible
    VERIFY: Both accounts login successfully on iOS app
    VERIFY: Both accounts display correct dashboard state immediately after login

════════════════════════════════════════════════════════════════
AGENT 5 — SENIOR UX REVIEWER (Full iOS Experience)
════════════════════════════════════════════════════════════════
You are a senior UX designer who has worked on medical and health apps.
You review the complete iOS user experience: flows, microcopy, feedback,
navigation, and emotional tone. You advocate for the patient and therapist.

1. ONBOARDING FLOW — FIRST IMPRESSION
   Walk through AclScreeningView as a new post-op patient:
   - Is the form presented in a calm, clinical-but-warm tone?
   - Is there a brief explanation of WHY each field is needed?
     (e.g., "Wir verwenden das OP-Datum, um dein Training automatisch
     an deine Heilungsphase anzupassen.")
   - Is the graft type explained in plain language for non-clinicians?
     ("Welche Sehne wurde für die Rekonstruktion verwendet?
     Das beeinflusst dein Krafttraining.")
   - Is the concomitant injury picker clearly labeled with implications?
     ("Meniskus-Naht: Dein Therapeut hat möglicherweise bestimmte
     Belastungseinschränkungen für die ersten 4 Wochen festgelegt.")
   - After completing screening: is there a motivating "Du bist bereit"
     moment, or does it just drop into the dashboard?

2. DAILY KPI LOGGING — FRICTION AUDIT
   Count the minimum number of taps to:
   a) Open the app → log daily KPI → confirm → return to dashboard
   Target: ≤4 taps. More than 4 = too much friction for a 30-week habit.
   - Is there a "Log today's check-in" shortcut card on the Overview tab?
   - Does the KPI logger remember yesterday's values as defaults to reduce
     typing (e.g., "Gestern: 60° Beugung — heute mehr oder weniger?")?
   - After submission: does the screen show a satisfying completion state
     before dismissing (not just vanish silently)?

3. STREAM CARD DESIGN — INFORMATION HIERARCHY
   For each stream card, a patient needs to understand:
   a) Is this stream active or locked?
   b) If active: what should I do today?
   c) If locked: what exactly do I need to achieve to unlock it?
   - Does the card communicate all three clearly at a glance?
   - Is the "entry exercise" shown prominently, or buried in detail view?
   - Is the progression shown visually (e.g., mini progress bar within card)?
   - Are clinical terms translated into plain German?
     ("Reaktivkraft" → "Sprungkraft und Reaktionsvermögen")

4. MILESTONE COMMUNICATION — PROGRESS NARRATIVE
   AclMilestoneTimeline should feel like a story ("your journey"), not
   a medical checklist. Review:
   - Does each milestone have a descriptive name, not just "Test 2 - 12 Wochen"?
     Suggested: "Phase 2: Erste Schritte mit Laufen" (12 weeks)
     "Phase 3: Richtungswechsel und Sprints" (18 weeks)
   - When a milestone is completed, is there a timestamp + positive message?
     ("Du hast diesen Meilenstein am 15. März erreicht — 2 Wochen früher
     als der Durchschnitt!")
   - Does the timeline show expected vs actual completion for each milestone?

5. DISCHARGE PROGRESS — EMOTIONAL DESIGN
   After 30 weeks, seeing discharge criteria is deeply emotional for patients.
   - Is the progress view motivating and positive, or does it feel clinical/cold?
   - Are criteria labeled in encouraging language?
     NOT: "Quadrizeps LSI: 87% / Threshold: 90% — FAIL"
     YES: "Quadrizeps Kraft: Fast da! 87% von 90% erreicht ✓"
   - When the last criterion is met: is there a significant moment?
     Confetti, haptic burst, congratulatory message from the therapist?
   - Is there a shareable "Ich bin entlassungsbereit" card the patient
     can share with family or show to their surgeon?

6. THERAPIST EXPERIENCE — LAB ENTRY FORM
   The therapist needs to enter 15-20 LSI values efficiently on mobile.
   - Is the form logically grouped?
     Section 1: Klinisch (ROM, Schwellung, Schmerz)
     Section 2: Kraft (Quadrizeps, Hamstrings, Hüfte, Kälber — LSI %)
     Section 3: Sprungkraft (CMJ, DJ — LSI %)
     Section 4: Reaktivkraft (RSI — LSI %)
     Section 5: Laufen + Ausdauer
   - Does inline validation show green checkmarks as each criterion is met?
     This is motivating AND confirms data entry correctness.
   - Is there a "Alle Kriterien für Meilenstein X erfüllt" summary card
     before the final submit button?
   - Can the therapist view previous assessments for comparison
     ("Letzter Test: Quadrizeps 65% → jetzt 82% ↑17%")?

7. MICROCOPY AUDIT
   Review every user-facing string in ACL views:
   - Are all strings in German?
   - Are error messages calm and specific? (Not "Error 500" or "Fehler")
   - Are empty states helpful? (Not "Keine Daten" but "Noch keine KPI-Daten
     eingetragen — starte heute mit deinem ersten Check-in!")
   - Are loading states labeled? (Not bare ProgressView but
     ProgressView("Lade deine Trainingsstreams..."))
   - Is the Tampa scale questionnaire prefaced with:
     "Diese Fragen helfen uns zu verstehen, wie du dich in Bezug auf
     Bewegung und Belastung fühlst — es gibt keine richtigen Antworten."

8. PUSH NOTIFICATIONS
   - Are there meaningful push notifications for ACL milestones?
     "🎉 Meilenstein 2 erreicht! Dein Lauf-Training kann beginnen."
   - Daily KPI reminder: friendly, not clinical
     "Wie geht es deinem Knie heute? Kurzer Check-in wartet auf dich."
   - Missing KPI for 3 consecutive days: gentle nudge, not guilt-trip
   - Therapist notification: "Patient ist bereit für das 12-Wochen-Assessment"
   - Are notifications localized in German?

9. ACCESSIBILITY COMPLETE AUDIT
   Walk through the entire ACL flow with VoiceOver enabled:
   - AclScreeningView: are all picker options read correctly?
   - AclStreamOverview: does VoiceOver announce lock state and criteria?
     "Lauf-Stream, gesperrt. Anforderung: Quadrizeps LSI über 70 Prozent."
   - AclMilestoneTimeline: is it navigable as a list (not just visual dots)?
   - AclDischargeProgress: are percentage values announced as numbers?
     "87 Prozent von 90 Prozent — fast erfüllt" not "progress bar"
   - AclLabEntryForm: are numeric inputs labeled?
     "Quadrizeps LSI in Prozent, aktueller Wert leer"

════════════════════════════════════════════════════════════════
AGENT 6 — SENIOR CRITIC (Logic, Contradictions & Improvements)
════════════════════════════════════════════════════════════════
You are an independent, skeptical senior engineer and product thinker.
You read the outputs of ALL agents above and challenge them. You also
review the codebase and ACL_REHABILITATION.md independently to find
issues that no other agent identified.

Your job is NOT to be destructive — it is to find the things everyone
else missed or got wrong.

PART A — CHALLENGE THE OTHER AGENTS
For each of Agents 1–5, identify:
1. What did they over-engineer or mark as a bug when it's actually correct?
2. What critical issue did they MISS that should have been in their domain?
3. What recommendation did they make that conflicts with CLAUDE.md patterns?
4. What did two agents contradict each other about?

PART B — LOGIC & CLINICAL CONTRADICTIONS
Review ACL_REHABILITATION.md against the implementation:

1. MILESTONE VS STREAM COUPLING LOGIC
   The protocol says streams unlock based on CRITERIA, not milestones.
   Running unlocks when specific clinical criteria are met — not simply
   "when the therapist submits Test 2."
   QUESTION: Is the current implementation criterion-driven or just
   "therapist submitted lab values for milestone X = stream unlocks"?
   These are different. A patient could meet running criteria at week 10
   but not be tested until week 12. The stream should unlock when criteria
   are met, not when the test is submitted.
   Is this distinction handled correctly in aclScoring.service.ts?

2. CONDITIONING STREAM UNLOCK — INTERNAL CONTRADICTION
   ACL_REHABILITATION.md says Conditioning unlocks from week 3-4.
   But it also says it progresses through 5 stages: upper body → non-impact
   → low impact → on feet → on field (each tied to later milestones).
   QUESTION: Does the app unlock the STREAM at week 3–4 but progressively
   unlock each stage within the stream as milestones advance?
   Or does it lock the entire stream until each stage's criteria are met?
   This distinction matters clinically — upper body conditioning should
   start immediately, but "on field" conditioning only at week 18+.

3. WEEKLY KPIS vs 6-WEEKLY LAB TESTS — REDUNDANCY
   Tampa Scale appears in BOTH weekly KPIs (patient self-reports) AND
   6-weekly lab assessments (therapist enters).
   QUESTION: Are there two separate Tampa score data streams? If yes,
   which one drives the >37 alert rule? Can they conflict?
   (Patient logs Tampa 38, therapist logs Tampa 30 same week — what happens?)

4. GRAFT DONOR SITE "NEXT MORNING" PAIN RULE
   The Aspetar protocol specifically states: strength training must not
   cause pain/irritation at the DONOR SITE the following morning.
   The app tracks general knee pain NRS but not specifically donor-site pain.
   QUESTION: Is there a donor-site-specific pain field in the daily KPI,
   or is this distinction lost? For patellar tendon graft, anterior knee
   pain and donor site pain are different things.

5. OPEN CHAIN QUAD TIMING — PROTOCOL VS IMPLEMENTATION
   Protocol: open-chain quad exercises can begin 4–6 weeks post-surgery.
   The app shows "from week 4–6 as symptoms allow."
   LOGICAL ISSUE: "From week 4–6" is ambiguous. Does this mean:
   - Available from week 4 if symptoms allow? Or
   - Available anywhere between week 4 and 6 based on tolerance?
   This ambiguity could cause different therapists to interpret it differently.
   Recommendation: Make it "available from week 4, if pain-free and surgeon
   confirms" — specific and actionable.

6. DISCHARGE CRITERIA COMPLETENESS
   Review the discharge criteria tables for COMPETITIVE and RECREATIONAL
   in ACL_REHABILITATION.md against the implementation.
   Are ALL criteria implemented, or only the ones that were easy to code?
   Specifically check:
   - Hip IR deficit criterion (often overlooked)
   - Psychological readiness / IKDC final score threshold
   - Sports-specific performance benchmarks (not just generic LSI %)
   - Conditioning / Yo-Yo test result (is this trackable in the app?)

PART C — SYSTEMIC IMPROVEMENTS (beyond bug fixes)
Identify 5 improvements to the app as a whole that would significantly
improve clinical outcomes or user experience, that are NOT currently
planned in ACL_REHABILITATION.md:

1. THERAPIST-PATIENT MESSAGING
   Clinical context missing from current architecture: there is no
   in-app communication channel between patient and therapist.
   After 30 weeks of ACL rehab, patients will have questions the app
   can't answer. Is a simple messaging/note system feasible? What
   would be the minimum viable implementation?

2. PROGRESS REPORT EXPORT
   For surgeon review appointments, a PDF/shareable summary of the
   patient's 30-week KPI data and milestone progression would be
   highly valuable. Is this architecturally feasible with current data model?

3. EXERCISE VIDEO LIBRARY
   Current protocol exercises are text-based. For ACL specifically,
   movement quality is critical (neutral landing mechanics, knee alignment).
   Text descriptions are insufficient for complex exercises like
   "SL drop jump" or "lateral push-off and crossover step."
   What is the minimum viable video/animation approach?

4. COMPARATIVE ANALYTICS
   "Running 16km/h × 200m × 8 repetitions" — is this fast or slow
   for the patient's age, sport, and pre-injury level? Without a
   reference range, patients can't contextualize their progress.
   Could anonymous cohort data (aggregate LSI benchmarks by sport/age)
   be implemented to give patients meaningful comparison?

5. RE-INJURY RISK SCORING
   The Aspetar protocol's entire purpose is preventing re-injury.
   Yet the app has no explicit re-injury risk indicator.
   Could LSI values and Tampa scores be combined into a simple
   "current re-injury risk: LOW / MODERATE / HIGH" score displayed
   prominently? What data points would drive this calculation?

════════════════════════════════════════════════════════════════
OUTPUT FORMAT
════════════════════════════════════════════════════════════════
Each agent outputs findings in this format:

**[SEVERITY] Title**
- Agent: 1–6 + role name
- Location: File / View / Screen / Feature
- Issue: Clear description of the problem
- Impact: Clinical, UX, or technical consequence
- Fix/Recommendation: Specific, actionable

Severity scale:
- CRITICAL — App crash, data loss, silent failure, clinical safety risk
- HIGH — Feature broken, wrong clinical behavior, major UX failure
- MEDIUM — Degraded experience, incorrect display, maintainability debt
- LOW — Polish, consistency, optional improvement

════════════════════════════════════════════════════════════════
FINAL DELIVERABLES (after all agents complete)
════════════════════════════════════════════════════════════════

1. PRIORITIZED ISSUE BACKLOG
| # | Severity | Agent | File/Screen | Issue | Effort (S/M/L) | Fixed? |

2. CRITIC'S CONTRADICTION LOG
| # | Agent A | Agent B | Contradiction | Resolution |

3. TOP 10 MUST-FIX BEFORE RELEASE
Ranked list with one-line justification each.

4. SYSTEMIC IMPROVEMENTS ROADMAP
5 improvements from Agent 6 with effort estimate and clinical value rating.
```


***
