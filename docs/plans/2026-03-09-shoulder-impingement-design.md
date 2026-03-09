# Schulter-Impingement (SAPS) — Feature Design

**Date:** 2026-03-09
**Status:** Approved
**Implementation order:** Physio-App (backend) → Physio-App (web client) → Reapptivate-iOS

---

## Overview

Add Subacromial Pain Syndrome (SAPS / Shoulder Impingement) as a new condition to Reapptivate. This is the first condition in a new "Orthopedic Upper Extremity" category, following the same architecture pattern as Neck Pain and Tension (own screening, own condition flag, own micro-modules).

Based on clinical practice guideline: *Shoulder Impingement Guideline* (Physio-App/docs/).

## Architecture

**New condition category (Option 2):** Each new condition gets its own:
- Condition enum value (`SHOULDER_IMPINGEMENT`)
- Screening flow (QuickDASH)
- Condition flag in AppState (`isShoulder`)
- Protocol files per severity
- Micro-modules and focus areas
- EdukationTab section

This follows the Neck/Tension pattern rather than extending the existing tendinopathy system.

## Screening: QuickDASH

**11 questions**, each scored 1–5. Total score: `((sum - 11) / 44) * 100` = 0–100 disability index.

### Severity Grading

| Grade | QuickDASH Score | Starting Phase | Dosage Modification |
|-------|----------------|----------------|---------------------|
| LEICHT | 0–40 | Phase 2 | Standard |
| MITTEL | 41–60 | Phase 1 | Standard |
| SCHWER | 61–100 | Phase 1 | Reduced (2x8-10 reps instead of 3x10-15) |

### QuickDASH Questions

1. Open a tight or new jar
2. Do heavy household chores (washing walls, floors)
3. Carry a shopping bag or briefcase
4. Wash your back
5. Cut food with a knife
6. Recreational activities with force/impact through arm/shoulder/hand
7. Interference with normal social activities (family, friends, neighbors)
8. Work or regular daily activities limited
9. Pain in arm, shoulder, or hand
10. Tingling (pins and needles) in arm, shoulder, or hand
11. Difficulty sleeping due to pain in arm, shoulder, or hand

All questions use the same 1–5 Likert scale: 1 = No difficulty/None, 5 = Unable/Extreme.

## Phase Structure & Exercises (Evidence-Based)

### Phase 1: Acute / Pain-Dominant (Weeks 0–2)

**Goal:** Pain reduction, restore passive ROM, scapular control

**Exercises:**
- Pendulum exercises (Codman)
- Passive/active-assisted ROM (flexion, abduction, external rotation)
- Scapular setting (retraction, depression)
- Isometric rotator cuff (submaximal, pain-free range)
- Thoracic spine mobility (extension, rotation)

**Dosage:** 2–3x/day, low load, pain must stay <=4/10
**Progression criteria:** Pain at rest <=3/10, passive ROM >=80% of uninvolved side

### Phase 2: Intermediate / Strength Recovery (Weeks 3–6)

**Goal:** Restore active ROM, begin strengthening, neuromuscular control

**Exercises:**
- Active ROM full range (flexion, abduction, ER/IR)
- Resistance band external/internal rotation
- Scapular strengthening (rows, serratus anterior punches, lower trap Y-raises)
- Closed kinetic chain (wall push-ups, table slides)
- Posterior shoulder stretching (cross-body, sleeper stretch)

**Dosage:** 3x10–15 reps, moderate load, 3–4x/week
**Progression criteria:** Full active ROM, pain-free resisted ER/IR at 0 degrees abduction

### Phase 3: Advanced Strengthening (Weeks 7–10)

**Goal:** Full strength, overhead function, sport/work-specific prep

**Exercises:**
- Progressive resisted ER/IR (side-lying, 90/90 position)
- Overhead pressing progression (dumbbell press, wall slides with resistance)
- Plyometric prep (ball catches, rhythmic stabilization)
- Scapular dynamic control (push-up plus, prone T/Y/W)
- Eccentric-focused rotator cuff (slow lowering ER)

**Dosage:** 3x8–12 reps, progressive overload, 3–4x/week
**Progression criteria:** Strength >=80% uninvolved side, pain-free overhead activities

### Phase 4: Return to Activity (Weeks 10–12+)

**Goal:** Sport/work-specific function, injury prevention

**Exercises:**
- Sport-specific overhead drills (throwing progression, swimming strokes)
- Plyometric training (medicine ball throws, push-up claps)
- Full kinetic chain integration (Turkish get-ups, overhead squats)
- Maintenance program (rotator cuff + scapular, 2–3x/week)

**Dosage:** Sport-specific volume, graded return
**Discharge criteria:** QuickDASH <=15, full pain-free function, strength >=90%

## Patient Education Micro-Modules

6 evidence-based modules from the clinical guideline:

1. **"Was ist Schulter-Impingement?"** — Anatomy, mechanism, prognosis
2. **"Warum Ubungen die beste Therapie sind"** — Exercise vs passive treatment evidence
3. **"Schmerz wahrend der Ubung — ist das ok?"** — Pain monitoring, 4/10 rule
4. **"Haltung und Ergonomie im Alltag"** — Workplace/sport posture tips
5. **"Geduld und Konsistenz"** — Recovery timeline expectations
6. **"Ruckkehr zu Sport und Arbeit"** — Graded return, maintenance program

## API Endpoints

| Method | Route | Purpose |
|--------|-------|---------|
| GET | `/shoulder/quickdash-config` | QuickDASH questions + scoring info |
| POST | `/shoulder/quickdash-submit` | Submit screening, get severity grade |
| GET | `/shoulder/quickdash-history` | Past QuickDASH scores over time |
| GET | `/shoulder/focus-areas` | Phase-specific focus areas |
| GET | `/shoulder/micro-modules` | Educational micro-modules |
| POST | `/shoulder/micro-modules/:id/read` | Mark module as read |

Reuses existing endpoints: `/patient/me`, `/patient/progress`, `/patient/phase-status`, `/patient/education`.

## Data Models (Backend)

```
ShoulderScreeningResult {
  id: UUID
  patientId: UUID
  answers: { q1..q11: number }    // 1-5 per question
  totalScore: number              // 0-100 (QuickDASH formula)
  severityGrade: LEICHT | MITTEL | SCHWER
  startingPhase: number
  createdAt: timestamp
}

ShoulderFocusArea {
  id: UUID
  name: string
  description: string
  phase: number
  sortOrder: number
}

ShoulderMicroModule {
  id: UUID
  title: string
  summary: string
  content: string (markdown)
  targetPhase: number
  sortOrder: number
  estimatedMinutes: number
}
```

New condition enum value: `SHOULDER_IMPINGEMENT`

Protocol files: `shoulder_impingement_leicht.json`, `shoulder_impingement_mittel.json`, `shoulder_impingement_schwer.json`

## Implementation Order

### 1. Backend (Physio-App/server)
- Add `SHOULDER_IMPINGEMENT` to condition type enum
- DB migrations: `shoulder_screening_results`, `shoulder_focus_areas`, `shoulder_micro_modules` tables
- Implement 6 API routes under `/shoulder/*`
- Seed data: QuickDASH questions, focus areas, micro-modules, exercise protocols
- Update `/patient/me` to return shoulder-specific fields when applicable

### 2. Web Client (Physio-App/client)
- QuickDASH screening flow (11-question form)
- Shoulder dashboard section (phase display, focus areas)
- Micro-modules viewer
- QuickDASH history/rescreening

### 3. iOS App (Reapptivate-iOS)
- Add `isShoulder` / `needsShoulderScreening` flags to AppState
- `ShoulderScreeningView` — QuickDASH flow (follows Neck/Tension pattern)
- Protocol JSON files (3 severity variants)
- `ShoulderMicroModulesView` in EdukationTab
- Update `RootView` navigation for shoulder screening gate
- Update `SharedTypes.swift` with new types

## Future Conditions (Prioritized)

After Shoulder Impingement, next conditions to add:
1. **Frozen Shoulder (Adhesive Capsulitis)** — reuses QuickDASH, different protocol
2. **Ankle Sprain** — Lower Extremity Function Scale (LEFS) screening
3. **Patellofemoral Pain** — Kujala score screening
4. **Meniscus Rehabilitation** — Lysholm score screening
