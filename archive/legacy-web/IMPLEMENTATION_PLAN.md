# Habit App Implementation Plan

Status legend:
- [ ] Not started
- [x] Done

## Goal
Make habit definitions and completions sync correctly across devices, and add per-habit calendar analysis with red/green day states.

## Phase 1: Confirm Current Behavior
- [x] Audit current persistence flow in `index.html`
- [x] Confirm what is stored in Google Sheets vs `localStorage`
- [x] Identify why habits differ across Mac/mobile

## Phase 2: Cross-Device Habit Sync (Google Sheets)
- [x] Extend backend schema to store habit definitions (not only completions)
- [x] Add frontend load for habit definitions on app startup
- [x] Add frontend save/update/delete sync for habit definitions
- [x] Add user identity key strategy (so your data is isolated)
- [x] Add fallback behavior if sheet is unavailable

## Phase 3: Local Data Model Cleanup
- [x] Replace `customTasks`-only storage with full persisted task state
- [x] Migrate existing `customTasks` data to new model
- [x] Ensure edits to default tasks persist
- [x] Ensure delete/archive behavior is explicitly defined and persisted

## Phase 4: Per-Habit Calendar (Red/Green)
- [x] Add habit selector to Activity Calendar (`All Habits` + each habit)
- [x] Implement per-day status calculation:
  - Due + completed = green
  - Due + not completed = red
  - Not due = neutral
- [x] Render updated legend and tooltips for selected habit
- [x] Update calendar summary metrics for selected habit

## Phase 5: Verification
- [ ] Verify same habits on desktop + mobile after refresh
- [ ] Verify completions still sync and render correctly
- [x] Verify calendar colors for due/non-due/completed cases
- [x] Verify no regressions in add/edit/delete flows

## Notes
- If you want true user accounts and auth later, Supabase is cleaner long-term.
- Fastest path right now is to complete Google Sheets sync for habit definitions first.
- Cross-device verification depends on deploying `GOOGLE_APPS_SCRIPT_V2.md` to your Apps Script URL.

---

## Usability Plan (Pending Review)

### U1. Calendar must follow selected period (7 / 30 / 90 days)
- [x] Make Activity Calendar read `g_appState.currentPeriod` and render exactly that many days.
- [x] Recompute date range labels and month markers based on selected period.
- [x] Scale cell sizing and layout automatically:
  - 7d: larger day cells + full weekday/date labels.
  - 30d: medium cells + week markers.
  - 90d: compact cells + month anchors.
- [x] Keep both modes compatible:
  - All Habits intensity view
  - Single-habit done/missed/not-due view
- [x] Ensure this re-renders instantly when period filter changes.

### U2. Habit category must be user-defined (not hard-coded)
- [x] Add category selector in Add/Edit Habit modal.
- [x] Include category in data model and persistence (local + cloud sync payload).
- [x] Ship sensible defaults and allow custom categories.
- [x] Update analytics to derive sections/charts from actual user categories.
- [x] Remove assumptions that only Mindfulness/Discipline/Learning exist.

### U3. Product flow cleanup (creation -> tracking -> analytics)
- [x] During habit creation, make category selection explicit and required.
- [x] Add lightweight helper text: category affects analytics grouping.
- [x] In analytics, show category legend built from current user categories.
- [x] Handle deleted/renamed categories without data loss.

### U4. Validation and UX acceptance
- [ ] Verify calendar period transitions are correct on desktop/mobile.
- [ ] Verify per-habit red/green/neutral states remain correct for all periods.
- [ ] Verify category edits immediately reflect in Habit Deep Dive and charts.
- [x] Verify backward compatibility for existing habits without category values.
