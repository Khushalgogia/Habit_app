# Voice Growth Archipelago

A habit and skill tracker web app that visualizes routines as islands. It supports cross-device sync through Google Sheets + Apps Script, dynamic category analytics, archive-safe habit lifecycle, and custom date analysis.

## Features

### Today View
- Island-based habit tracking with one-tap complete/uncomplete.
- Undo toast for quick recovery from accidental taps.
- Day scopes:
  - `Standard Day`: all active due habits.
  - `Lite Day`: only core due habits.
- Constellation celebration when all core due habits are completed.

### Progress Overview
- Preset windows: `7`, `30`, `90` days.
- Custom date range (`From` / `To`) across all analytics.
- Scope filter: `All Habits` vs `Core Habits`.
- Optional `Include archived` toggle.
- Activity Calendar:
  - All-habits intensity mode.
  - Single-habit done/missed/not-due mode.
  - 3-letter weekdays (`Sun Mon Tue ...`).
  - Month paging for large custom ranges.
- Category analytics:
  - Category Cadence (line chart)
  - Category Mix (donut)
  - Category Radar
- Habit Breakdown and spotlight cards.

### Habit Lifecycle
- Add/edit habits with frequency, days, category, and color.
- Remove is two-step and safe:
  - Archive habit (default)
  - Delete permanently
- Re-adding a habit with the same name as an archived one offers restore.
- Archived history is preserved and can be included in analytics.

### Sync and Persistence
- LocalStorage fallback for tasks, history, and progress filters.
- Google Apps Script sync:
  - Completion events (`add` / `remove`)
  - Habit definitions (`saveTasks`)
- User isolation via `?uid=<your-id>`.

## Data Model Notes

Each habit task now supports lifecycle fields:
- `status`: `active | archived | deleted`
- `createdAt`, `archivedAt`, `deletedAt`

Backward compatibility is preserved:
- Missing status defaults to `active`.
- Missing category defaults to `Uncategorized`.

## Setup

1. Deploy Apps Script web app (see `GOOGLE_APPS_SCRIPT_V2.md`).
2. Set `GOOGLE_SCRIPT_URL` in `index.html`.
3. Open `index.html` in a browser.

## File Structure

- `index.html` — Main app (UI + state + rendering + task lifecycle).
- `GOOGLE_APPS_SCRIPT_V2.md` — Backend script contract for tasks/completions sync.

## Troubleshooting

- Data mismatch across devices:
  - Verify same `uid` is used.
  - Verify the same Apps Script deployment URL is configured.
- Custom date not updating charts:
  - Ensure `From <= To` and end date is not in the future.
- Habit missing after removal:
  - Check if it was archived (toggle `Include archived` in Progress).

## Credits

- Icons: [Heroicons](https://heroicons.com/)
- Charts: [Chart.js](https://www.chartjs.org/)
- CSS: [Tailwind CSS](https://tailwindcss.com/)
