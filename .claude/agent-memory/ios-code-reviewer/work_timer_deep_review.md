---
name: Work Timer Deep Review (2026-03-20, updated after fix pass)
description: Comprehensive findings from full review of WorkTimerViewModel, all 5 WorkTimer views, types, tests, and related infrastructure
type: project
---

## Critical (status after 2026-03-20 second fix pass)
- **UTC/local timezone mismatch**: FIXED -- `todayDateString()` now uses local-timezone `localDateFormatter`.
- **Untracked Task in restoreTimerState()**: PARTIALLY FIXED -- `isRestoringState` guard prevents synchronous re-entry, but fire-and-forget Task (line 546) can still duplicate.
- **stopWorkday() phantom skip**: FIXED -- Uses `isSnoozePending` flag instead of `snoozesUsed > 0`. `completeBreak()` and `skipBreak()` reset both `snoozesUsed` and `isSnoozePending`.

**Why:** These affect clinical data accuracy for the physiotherapy platform.
**How to apply:** When reviewing changes to timer persistence or break logging, verify timezone consistency and guard against re-entrancy.

## High (status after 2026-03-20 second fix pass)
- **All notification callback fixes**: FIXED -- .onDisappear removed, callbacks in .task with [weak vm], cleared on logout.
- **triggerBreak() double-trigger**: FIXED -- `guard !isOnBreak else { return }`.
- **Three-way break completion race**: FIXED -- VM is sole completion authority.
- **Settings change while running (#8)**: FIXED -- `saveSettings()` now calls `calculateNextBreak`, `saveTimerState`, `scheduleBreakNotification` when `isRunning`.
- **selectBreakExercises() filtering (#12)**: FIXED -- Filters by `targetConditions` and `minPhase` with fallback.
- **autoStopWorkday() defer**: FIXED -- `defer { self?.isAutoStopping = false }` before `await stopWorkday()`.

## Remaining issues (2026-03-20 second fix pass)
- **isSnoozePending not persisted**: If app killed during snooze, restored trigger creates new break instead of snooze continuation.
- **Notification triggerBreak() alarm flash**: `onBreakSnooze`/`onBreakComplete`/`onBreakSkip` callbacks call `triggerBreak()` which plays alarm and flashes break UI before immediate action.
- **restoreTimerState() expired break log message stale**: Says "completed" but behavior is "skipped" (#13).
- **currentStreak malformed date tolerance**: Unparseable dates silently skip gap check.
- **selectBreakExercises() nil patientCondition**: Exercises with targetConditions pass filter when patientCondition is nil.
- **Break log API failures not queued for retry** (PendingSync not used).
- `getWorkTimerTodaySummary()` endpoint defined but never called (dead code).
- `stopWorkday()` snoozed break `next > Date()` check has narrow edge-case miss window.

## Observations
- WorkTimerCard limited to LBP/Neck/Tension -- SI/FS/ACL/LAS excluded (intentional per product)
- `stopWorkday()` mixes UTC (break log date) and local (summary date) -- minor but inconsistent
- NotificationDelegate is now `@MainActor` (not @unchecked Sendable) -- data race resolved
- Test coverage: 82 VM tests (up from 65), 8 type tests.
