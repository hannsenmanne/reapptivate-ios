

## Claude Code Enhancement Questionnaire Prompt — ACL Reha Review

```
You are a senior multi-disciplinary review team for the REAPPTIVATE ACL
Rehabilitation module. The current implementation is documented in
ACL-Reha.md. Read ALSO both CLAUDE.md files (iOS + backend) and the
Aspetar-ACL-rehabilitation-protocol.pdf before starting.

Your task is NOT to implement anything. Your task is to ask targeted,
structured questions that surface gaps, weaknesses, and improvement
opportunities across every layer of the current implementation.

For each question: explain WHY it matters clinically, technically, or
from a UX perspective. After all questions are answered, a separate
implementation session will follow.

Spawn 5 parallel agents. Each asks questions in their domain.

════════════════════════════════════════════════════════════════
AGENT 1 — CLINICAL PROTOCOL FIDELITY
════════════════════════════════════════════════════════════════
You are a senior physiotherapist and clinical reviewer.
Cross-reference ACL-Reha.md against the Aspetar protocol and ask
targeted questions about clinical gaps. Do not assume anything is
correctly implemented — verify by asking.

Ask the following questions and document the answers:

1. MILESTONE TIMING vs. CRITERIA-BASED PROGRESSION
   The Aspetar protocol is explicitly criteria-driven, not time-driven.
   The current implementation shows milestones tied to week ranges
   (M1: Woche 0–6, M2: Woche 7–12, etc.).
   
   QUESTION: Are milestone transitions currently purely time-based,
   purely criteria-based (LSI thresholds + lab values), or a hybrid?
   If hybrid: what happens when a patient meets criteria BEFORE the
   time window ends? Can the milestone advance early?
   What happens when a patient does NOT meet criteria when the time
   window ends? Does the app keep them in the old milestone indefinitely,
   or does it auto-advance? Which is clinically correct per Aspetar?

2. CONDITIONING STREAM STAGING
   The Aspetar protocol defines 5 internal stages within Conditioning:
   Upper body (week 3–4) → Non-impact → Low impact → On feet → On field.
   Each stage corresponds to a different milestone.
   
   QUESTION: Does the current CONDITIONING stream show all exercises
   from the start, or does it progressively unlock internal sub-stages
   as milestones advance? If it shows all exercises from M2 unlock,
   is a patient in M2 seeing exercises intended only for M4?

3. STRENGTH TRAINING PHASES
   Aspetar defines 3 explicit phases: General Strength (12–15 reps) →
   Hypertrophy (8–12 reps) → Max Strength (<5 reps).
   
   QUESTION: Does the current STRENGTH stream communicate which
   training phase applies to each exercise based on current milestone?
   Are set/rep parameters dynamically adjusted per phase, or are they
   static values in the exercise JSON regardless of where the patient
   is in their recovery?

4. DONOR SITE PAIN TRACKING
   The Aspetar protocol specifically states: strength training must not
   cause irritation at the GRAFT DONOR SITE the following morning.
   Donor site pain is clinically distinct from general knee pain.
   
   QUESTION: Does the current daily KPI logging distinguish between
   general knee pain NRS and donor-site-specific pain? If not, how is
   a therapist supposed to know whether post-exercise pain is joint-related
   or graft-donor-site irritation? Which clinical decision depends on
   this distinction?

5. PRE-OP PHASE (M0) CONTENT
   The Aspetar protocol dedicates significant attention to pre-operative
   preparation: achieving full extension, >120° flexion, minimal swelling,
   no quad lag, and familiarizing patients with post-op exercises.
   
   QUESTION: What does the app currently show a patient in M0 (before
   surgery)? Is there an active pre-op checklist or exercise program?
   Or is M0 simply a label on the milestone timeline with no content?

6. RUNNING STREAM — HYDROTHERAPY & ALTER-G
   The Aspetar protocol requires pool running → Alter-G → ground running
   as a specific progression for returning to running.
   
   QUESTION: Does the current RUNNING stream account for whether the
   patient has access to hydrotherapy or an anti-gravity treadmill?
   If a patient has no pool access, does the app offer a validated
   alternative land-based progression? Or does it assume all patients
   have clinic-level equipment?

7. LSI COLOR THRESHOLDS — CONTEXT SENSITIVITY
   Currently: LSI colors are fixed at Rot <70%, Amber 70–85%, Grün ≥85%.
   The Aspetar protocol uses different thresholds in different contexts:
   >70% for running unlock, >80% for sports-specific unlock,
   >90% for competitive discharge.
   
   QUESTION: When a patient is preparing for discharge and sees their
   Quad LSI at 85% colored green — is that accurate? 85% is green by
   the current scheme, but the discharge criterion requires 90%.
   Does the color coding correctly reflect the relevant threshold
   for the current clinical context, or could it mislead the patient
   into thinking they are "good" when they haven't met discharge criteria?

8. ACL-RSI — PSYCHOLOGICAL READINESS
   The ACL Return-to-Sport Injury questionnaire (ACL-RSI) is a validated
   12-item psychological readiness tool, distinct from the Tampa Scale.
   It measures emotions, confidence, and risk appraisal specifically
   for returning to sport.
   
   QUESTION: Is the ACL-RSI questionnaire currently implemented?
   The Tampa Scale measures kinesiophobia generally — is that considered
   sufficient for psychological RTS readiness, or is the ACL-RSI needed
   as a complement? At which milestone should it be administered?

════════════════════════════════════════════════════════════════
AGENT 2 — BACKEND ARCHITECTURE & DATA INTEGRITY
════════════════════════════════════════════════════════════════
You are a senior backend engineer. Ask questions that surface
potential data integrity risks, performance issues, and architectural
weaknesses in the current backend implementation.

1. MILESTONE UNLOCK — TRANSACTION SAFETY
   When a therapist submits lab assessment values, the system must
   (a) insert the lab assessment AND (b) update users.acl_current_milestone.
   
   QUESTION: Are these two writes wrapped in a database transaction?
   If step (b) fails after step (a) succeeds, the milestone silently
   stays at the old value while the lab data is saved. On the next
   therapist login, the old lab values would be overwritten by a
   re-submission. How is this handled currently?

2. WEEKS POST-SURGERY CALCULATION
   weeksPostSurgery is central to the entire module — it drives stream
   unlocking, milestone timing, and notification triggers.
   
   QUESTION: Where exactly is weeksPostSurgery calculated?
   Is it computed in a single server-side helper function, or is it
   re-calculated independently in multiple controllers?
   If multiple endpoints calculate it differently (different timezone
   handling, different rounding), could two requests return different
   milestone states for the same patient on the same day?

3. UNBOUNDED QUERY RESULTS
   After 30 weeks of ACL rehabilitation, a patient will have:
   ~210 daily KPI entries, ~30 weekly KPI entries, ~5 lab assessments.
   
   QUESTION: Do the GET /api/acl/daily-kpi and GET /api/acl/weekly-kpi
   endpoints apply a LIMIT clause, or do they return all records
   ever logged? For the analytics view, does the backend aggregate
   data server-side, or does it send all raw entries and let the iOS
   app calculate trends locally?

4. RATE LIMITING ON NEW ENDPOINTS
   The existing app applies readLimiter (100/min), writeLimiter (50/min),
   and analyticsLimiter (30/min) on LBP enhancement endpoints.
   
   QUESTION: Are the 18 ACL endpoints rate-limited?
   Specifically: POST /api/acl/daily-kpi (could be spammed),
   POST /api/acl/lab-assessment (triggers milestone unlock logic),
   GET /api/acl/analytics (expensive aggregation query).
   If not rate-limited, what is the risk of a runaway client?

5. TAMPA ALERT — DUAL DATA STREAMS
   Tampa Score appears in TWO places: weekly KPI (patient self-reports)
   AND lab assessments (therapist enters).
   
   QUESTION: When the Tampa >37 alert rule fires, which data source
   triggers it — patient-reported weekly KPI, therapist lab entry, or
   both? If a patient reports Tampa 38 in their weekly KPI but the
   therapist enters Tampa 30 in the same week's lab assessment,
   which value does the system act on? Can these two streams conflict
   and produce contradictory alert states?

6. CONTENT CONTAMINATION DEFENSE
   Other conditions (LBP, Neck, Tension) have both server-side and
   client-side filtering to prevent wrong content appearing for wrong
   patients.
   
   QUESTION: Do ACL micro-modules have targetCondition = "ACL_RECONSTRUCTION"
   in the JSON config? Does the backend filter by this field before
   sending, AND does the iOS client also filter defensively?
   What happens if a future developer adds a new micro-module without
   setting targetCondition — would it appear for all patients?

7. INPUT VALIDATION
   QUESTION: What server-side validation exists for ACL input fields?
   Specifically:
   - surgery_date: is it validated as a real date, not a future date?
     (Future surgery date = negative weeksPostSurgery = wrong unlocks)
   - swelling_grade: validated as integer 0–3, not 0–10 or negative?
   - LSI values: validated as 0–200 range?
   - knee_flexion_deg: validated as 0–160 range?
   If these are not validated server-side, what is the worst case
   a malformed request could cause in the milestone unlock logic?

════════════════════════════════════════════════════════════════
AGENT 3 — iOS ARCHITECTURE & CODE QUALITY
════════════════════════════════════════════════════════════════
You are a senior Swift 6.0 / SwiftUI engineer. Ask questions about
architectural correctness, concurrency safety, and long-term
maintainability of the iOS implementation.

1. VIEWMODEL PATTERN COMPLIANCE
   CLAUDE.md specifies: ALL ViewModels must use the
   `@State private var viewModel: VM? + .task {}` pattern.
   ExerciseViewModel is the only documented exception.
   
   QUESTION: Do all 6 new ACL ViewModels follow this pattern exactly?
   Are there any ViewModels instantiated at view init (e.g., as
   `@State var vm = AclDashboardViewModel()`)? If so, what is the
   risk in SwiftUI's rendering lifecycle — can multiple instances
   of the same ViewModel be created, each triggering separate API calls?

2. FLEXIBLE NUMERIC DECODING
   ACL-Reha.md documents a custom flexibleDouble() / flexibleInt()
   extension handling PostgreSQL numeric-as-string.
   
   QUESTION: Is this extension defined once in a shared location
   (e.g., a Decodable+Extensions.swift file) or is it duplicated
   across the 7 structs that need it? If duplicated, what is the
   maintenance risk when the backend changes the column types?
   Does the existing codebase (LBP, Neck types) have a similar
   pattern that could be unified?

3. SWIFT 6 CONCURRENCY
   QUESTION: Do all 6 ACL ViewModels declare @MainActor?
   Are there any async operations in ACL code that capture self
   without @MainActor isolation — for example, callbacks or
   NotificationCenter observers that update @Published properties
   from a background thread? Have you verified the ACL module
   compiles without any Swift 6 concurrency warnings in strict mode?

4. TEST COVERAGE GAPS
   Current: ~115 unit tests covering AclTypes.swift and ViewModels.
   QUESTION: Are the following specific cases tested?
   - Surgery date "2025-06-15" decoded in UTC+2 timezone →
     weeksPostSurgery at "2025-09-07" = exactly 12 weeks?
   - LSI values arriving as String from PostgreSQL correctly
     decoded as Double via flexibleDouble()?
   - AclConcomitantInjury array containing an unknown future value
     (graceful fallback, no crash)?
   - AclMilestoneStatus with nextMilestoneUnlockCriteria = [] (empty)?
   - A ViewModel method called when the network is offline (error state,
     not crash)?

5. OFFLINE SUPPORT
   QUESTION: What happens when a patient in an area without wifi
   (e.g., at a sports facility) tries to log their daily KPI?
   Does the POST /api/acl/daily-kpi failure queue a PendingSync entry
   like other conditions do? Is the entry shown optimistically in the
   UI while waiting for sync, or does it disappear until confirmed
   by the server?

6. DESIGN SYSTEM COMPLIANCE
   QUESTION: Do all 11 ACL views use ONLY the existing design tokens?
   Specifically:
   - Are there any hardcoded hex colors that don't adapt to dark mode?
   - Are there any hardcoded Font.system(size: X) instead of
     semantic .appHeadline / .appBody styles?
   - Are there any custom error banner components instead of
     the shared InlineErrorView?
   - Are there any custom loading indicators instead of the
     shared skeleton loading pattern used on the dashboard?

7. LOCALIZATION COMPLETENESS
   QUESTION: Are ALL user-facing strings in the 11 ACL views in German?
   Are there any English strings remaining (e.g. stream names like
   "RUNNING", "CHANGE_OF_DIRECTION" shown directly to users)?
   Are error messages specific and in German, or are there generic
   English placeholders ("Something went wrong", "Error")?
   Are dates formatted in German locale (TT.MM.JJJJ, not MM/DD/YYYY)?

════════════════════════════════════════════════════════════════
AGENT 4 — UX & PATIENT EXPERIENCE
════════════════════════════════════════════════════════════════
You are a senior UX designer specializing in medical and health apps.
Ask questions about the patient experience, therapist experience,
emotional design, and accessibility. Focus on what a real post-op
patient would encounter across 30 weeks of daily app use.

1. DAY 1 EMPTY STATE
   A patient who just completed screening on Day 1 post-op sees
   mostly locked streams. This is the highest dropout risk moment —
   if the app feels overwhelming or empty, they will disengage.
   
   QUESTION: What does the AclDashboardView show on Day 1 post-op?
   Is there a "Getting Started" guide explaining what to do first?
   Is there a clear primary action visible without scrolling
   ("Starte heute mit: Quadrizeps-Aktivierung")? Or does the patient
   see a timeline of locked streams with no clear next step?

2. DAILY KPI LOGGING FRICTION
   For a habit that must be maintained for 30 weeks, minimum friction
   is critical. Count the exact number of taps required:
   
   QUESTION: From the app home screen, how many taps does it take to:
   (a) Open the daily KPI logger
   (b) Enter pain NRS = 3, swelling = 1, flexion = 90°
   (c) Submit and return to dashboard
   Target is ≤4 taps for the entire flow. What is the current count?
   Is there a shortcut card on the Overview tab, or must the patient
   navigate to a specific screen first?

3. MILESTONE CELEBRATION
   Milestone advances are the most significant motivational moments
   in a 30-week rehabilitation. Section 12 lists "Meilenstein-Feiern"
   as not yet implemented.
   
   QUESTION: What currently happens in the app when a therapist
   submits lab values that advance the patient's milestone?
   Does the patient see any notification, animation, or celebration?
   Or does the milestone counter simply increment silently?
   If the patient is not in the app when the milestone advances,
   do they receive a push notification?

4. THERAPIST LAB ENTRY FORM UX
   Entering 15–20 LSI numeric values on a mobile screen is tedious
   and error-prone. Incorrect values directly affect milestone unlock.
   
   QUESTION: How is AclLabEntryForm currently structured?
   Are the fields grouped by clinical category (Kraft / Explosivität /
   Reaktivkraft / Laufen / Klinisch)?
   Is there inline validation showing whether each entered value meets
   the milestone criteria as the therapist types?
   Can a therapist save a partial draft and continue later, or is
   all progress lost if they leave the form mid-entry?

5. LOCKED STREAM INFORMATION
   When a stream is locked, the patient needs to understand exactly
   what they need to achieve to unlock it — not just "gesperrt."
   
   QUESTION: What information is currently shown on a locked stream card?
   Does it show the specific criteria (e.g., "Benötigt: Quadrizeps LSI
   >70% — aktuell: 65%")? Or does it just show a lock icon and a
   milestone label ("Verfügbar ab M2")?
   If current LSI values are shown, how does the card get this data —
   does it pull from the most recent lab assessment?

6. DISCHARGE PROGRESS EMOTIONAL DESIGN
   After 30 weeks, the Entlassungskriterien view is where the patient
   sees how close they are to finishing. This moment is deeply emotional.
   
   QUESTION: What is the visual and emotional tone of
   AclDischargeProgressView? Are criteria shown as:
   (a) Clinical pass/fail checklist ("Quadrizeps LSI: 87% — NICHT ERFÜLLT")
   (b) Progress-oriented positive framing ("Quadrizeps Kraft: 87% von 90%")
   When all criteria are met, is there a significant celebration moment,
   or does the view simply show all green checkmarks?

7. ACCESSIBILITY
   QUESTION: Have the ACL views been tested with VoiceOver enabled?
   Specifically:
   - Does VoiceOver announce stream lock status and unlock criteria?
   - Is the milestone timeline navigable without relying on visual position?
   - Are progress bar percentages read as numbers ("87 Prozent")
     or as visual elements that VoiceOver cannot interpret?
   - Are all numeric input fields labeled descriptively
     ("Quadrizeps LSI in Prozent") not just by field position?

8. EMPTY ANALYTICS STATE
   On first login (Day 1), the analytics view has zero data.
   
   QUESTION: What does AclAnalyticsView show when there is no KPI
   history yet? Are empty charts shown (confusing), or is there an
   informative empty state explaining what data will appear and when?
   Is there a motivational framing ("Nach 7 Tagen siehst du hier
   deinen ersten Schmerztrend")?

════════════════════════════════════════════════════════════════
AGENT 5 — MISSING FEATURES & FUTURE ROADMAP
════════════════════════════════════════════════════════════════
You are a senior product manager and technical architect.
Ask questions about the features listed as missing in Section 12
of ACL-Reha.md, and probe for feasibility, priority, and approach.

1. PUSH NOTIFICATIONS
   Section 12 lists push notifications as not yet implemented.
   The backend has VAPID web push infrastructure for other conditions.
   
   QUESTION: Are the following notification types planned or already
   partially implemented?
   (a) Daily KPI reminder (if not yet logged today)
   (b) Training day reminder (on scheduled training days)
   (c) Milestone unlock notification (patient, when therapist advances)
   (d) Assessment readiness alert (therapist, when time criteria met)
   (e) Red-flag alerts (therapist, pain spike / swelling surge / Tampa >37)
   For the red-flag alerts specifically: is there any current mechanism
   that notifies therapists of urgent patient events, or is the therapist
   only informed during a scheduled appointment?

2. FEAR HIERARCHY FOR ACL RTS
   Section 12 mentions "Fear Hierarchy speziell für ACL" as missing.
   The LBP-FAR fear hierarchy infrastructure already exists in the app.
   
   QUESTION: How similar is an ACL Return-to-Sport fear hierarchy to
   the existing LBP fear hierarchy? Could the existing infrastructure
   be reused/adapted, or does RTS require fundamentally different
   scenario types, progression logic, and UI?
   At which milestone should RTS fear hierarchy be introduced?
   Should it only appear for patients with high Tampa scores, or
   for all ACL patients regardless of kinesiophobia level?

3. DAILY TIPS UI
   Section 12 states: "Daily Tips — Backend-Daten vorhanden in
   acl-daily-tips.json, UI noch nicht integriert."
   
   QUESTION: What is currently in acl-daily-tips.json?
   Are tips organized by milestone, by stream, or by week?
   What is the intended display location — a card on the dashboard,
   a section in the program tab, or a notification?
   Is there a design precedent in the existing app
   (e.g., the Wissen/Education card pattern) that could be reused?

4. STREAK MECHANICS
   Section 12 mentions streaks with a safety mechanism against overtraining.
   The existing streak system tracks exercise sessions.
   
   QUESTION: Should ACL streaks count:
   (a) Only exercise sessions (like existing conditions)?
   (b) KPI logging (which is equally important for ACL)?
   (c) A combination of both?
   What is the safety mechanism for overtraining — should the app
   warn a patient logging 7+ consecutive training days, or should
   it enforce rest days by not counting them toward streak goals?

5. VIDEO DEMONSTRATIONS
   Section 12: "Video-Demonstrationen für Übungen" as missing.
   
   QUESTION: What level of video support is realistic?
   (a) External links to YouTube/Vimeo (lowest complexity)
   (b) Bundled GIF animations for key exercises (medium complexity)
   (c) In-app video player with hosted content (high complexity)
   Which exercises most critically need visual demonstration — where
   does a text description genuinely fail to communicate correct
   technique? (Hint: SL drop jump landing mechanics, lateral push-off,
   COD footwork are candidates)

6. COMPLIANCE DASHBOARD FOR THERAPISTS
   Section 12: "Compliance-Dashboard für Therapeut:innen" as missing.
   
   QUESTION: What compliance metrics would be most useful for therapists?
   At minimum: KPI adherence rate (days logged / days elapsed) and
   training adherence (sessions completed / sessions planned).
   Is there any existing therapist dashboard that could be extended,
   or would this require a new dedicated view?
   Should compliance data be visible in the therapist's patient list
   (overview level) or only in the individual patient detail view?

7. ACL-RSI QUESTIONNAIRE
   The ACL Return-to-Sport Injury questionnaire is a validated 12-item
   psychological readiness tool. Currently only Tampa Scale is used.
   
   QUESTION: Is the Tampa Scale alone sufficient for psychological RTS
   readiness assessment, or is the ACL-RSI needed as a complement?
   If both are used, is there a risk of questionnaire fatigue for
   patients completing Tampa weekly AND ACL-RSI every 6 weeks?
   Should the ACL-RSI replace Tampa at later milestones (M3+), or
   run alongside it?

════════════════════════════════════════════════════════════════
OUTPUT FORMAT
════════════════════════════════════════════════════════════════

Each agent produces:
1. The QUESTION (as written above)
2. The CURRENT STATE (what the code/implementation currently does)
3. THE GAP (difference between current state and ideal/protocol)
4. IMPACT (clinical, technical, or UX consequence of the gap)
5. PRIORITY (Critical / High / Medium / Low)

Format per finding:
---
**[PRIORITY] Question Title**
Current State: [what exists now]
Gap: [what is missing or wrong]
Impact: [consequence if not addressed]
---

Final output: Ranked improvement backlog
| # | Priority | Agent | Topic | Gap Summary | Estimated Effort |
```


***


