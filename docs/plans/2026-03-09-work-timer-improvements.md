# Work Timer Improvements Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make the Arbeitszeit-Timer practical for office workers by adding snooze, auto-stop, actionable notifications, micro-breaks, weekly history, and auto-start.

**Architecture:** All changes extend the existing WorkTimerViewModel + WorkTimer views. Notification delegate handling added to ReapptivateApp. Weekly history uses the existing `getWorkTimerHistory()` endpoint.

**Tech Stack:** SwiftUI, @Observable, UserNotifications, existing APIClient

---

### Task 1: Snooze Button

Add a "Später" (snooze) button to the break view that postpones the break by 5 minutes without counting as a skip. Max 2 snoozes per break.

**Files:**
- Modify: `Reapptivate/ViewModels/WorkTimerViewModel.swift`
- Modify: `Reapptivate/Views/WorkTimer/WorkTimerBreakView.swift`

**WorkTimerViewModel additions:**
- `var snoozesUsed: Int = 0` state
- `private static let maxSnoozes = 2`
- `var canSnooze: Bool { snoozesUsed < Self.maxSnoozes }`
- `func snoozeBreak()` — dismiss break sheet, delay next break by 5 min, increment snoozesUsed, don't log as skip, reschedule notification

**WorkTimerBreakView changes:**
- Add "Später (5 Min.)" button between "Pause abgeschlossen" and "Überspringen"
- Show remaining snooze count: "Noch X Mal verschieben"
- Disable when `!viewModel.canSnooze`

---

### Task 2: Auto-Stop at End Time

Automatically stop the workday when the configured end time is reached.

**Files:**
- Modify: `Reapptivate/ViewModels/WorkTimerViewModel.swift`

**Changes:**
- In `workTimerTick()`, check `isWithinWorkHours`. If false and `isRunning`, trigger auto-stop.
- Add `private func autoStopWorkday()` — same as `stopWorkday()` but async, called from tick.
- Edge case: if user is mid-break at end time, let the break finish first, then auto-stop.

---

### Task 3: Actionable Notifications

Handle notification actions so users can complete/snooze/skip breaks without opening the app.

**Files:**
- Modify: `Reapptivate/App/ReapptivateApp.swift` — add SNOOZE_BREAK action, set delegate
- Create: `Reapptivate/App/NotificationDelegate.swift` — UNUserNotificationCenterDelegate
- Modify: `Reapptivate/ViewModels/WorkTimerViewModel.swift` — add static/shared reference for delegate access

**Notification actions (update existing category):**
- "Erledigt" (START_BREAK → complete, foreground)
- "Später" (SNOOZE_BREAK, background) — new
- "Überspringen" (SKIP_BREAK, background)

**NotificationDelegate:**
- Handle `didReceive response` for the 3 action identifiers
- Post a Notification (NotificationCenter) that WorkTimerViewModel observes
- Or use a simple static callback/closure

---

### Task 4: Micro-Breaks

Alternate between short micro-breaks (30s, 1 exercise) and full breaks. Every other break is a micro-break.

**Files:**
- Modify: `Reapptivate/ViewModels/WorkTimerViewModel.swift`
- Modify: `Reapptivate/Views/WorkTimer/WorkTimerBreakView.swift`

**WorkTimerViewModel additions:**
- `var isMicroBreak: Bool` — computed: `currentBreakNumber % 2 == 1` (odd = micro, even = full)
- In `triggerBreak()`: set `breakSecondsRemaining` based on `isMicroBreak` (30s vs full duration)
- In `selectBreakExercises()`: select 1 exercise for micro, 3 for full

**WorkTimerBreakView changes:**
- Show "Kurze Pause" header for micro-breaks, "Bewegungspause" for full
- Smaller ring for micro-breaks
- Auto-complete micro-breaks when timer reaches 0 (no manual "complete" needed)

---

### Task 5: Weekly Adherence History

Show a simple weekly bar chart of break adherence in a new history view.

**Files:**
- Create: `Reapptivate/Views/WorkTimer/WorkTimerHistoryView.swift`
- Modify: `Reapptivate/ViewModels/WorkTimerViewModel.swift` — add `loadHistory()`
- Modify: `Reapptivate/Views/WorkTimer/WorkTimerCard.swift` — add history button
- Modify: `Reapptivate/Views/WorkTimer/WorkTimerSummarySheet.swift` — add "Verlauf anzeigen" link

**WorkTimerViewModel additions:**
- `var weekHistory: [WorkTimerDaySummary] = []`
- `var showingHistory = false`
- `func loadHistory() async` — calls `getWorkTimerHistory()`, stores result

**WorkTimerHistoryView:**
- Bar chart showing adherence % for each day (last 7 days)
- Below: streak counter (consecutive days with >0% adherence)
- Summary stats: avg adherence, total breaks completed this week

---

### Task 6: Auto-Start Within Work Hours

Automatically start the timer when the app opens during configured work hours (if enabled and not already running).

**Files:**
- Modify: `Reapptivate/ViewModels/WorkTimerViewModel.swift`
- Modify: `Reapptivate/Views/WorkTimer/WorkTimerCard.swift`
- Modify: `Reapptivate/Views/WorkTimer/WorkTimerSettingsSheet.swift`

**WorkTimerViewModel additions:**
- `var autoStartEnabled: Bool` — persisted in UserDefaults
- `func checkAutoStart()` — if `autoStartEnabled && isWithinWorkHours && !isRunning && settings != nil`, call `startWorkday()`

**WorkTimerCard changes:**
- Call `vm.checkAutoStart()` after `restoreTimerState()` in `.task`

**WorkTimerSettingsSheet changes:**
- Add toggle: "Automatisch starten" with footer explaining behavior
