# Voice Growth Archipelago

A gamified habit and skill tracker web app, visualizing your daily tasks as islands on an archipelago map. Track streaks, analyze progress, and celebrate your growth—all synced with Google Sheets for persistence.

---

## Features

### 🏝️ Archipelago Map (Today Tab)
- **Habit Islands:** Each habit/task is an island, positioned on a map.
- **Icons & Labels:** Custom SVG icons, names, and frequency labels.
- **Completion:** Click an island to mark as complete; completed islands glow.
- **Constellation Celebration:** Complete all essential tasks to trigger constellation lines and confetti.

### 🚦 Flow Modes
- **Full Voyage:** Shows all tasks due today.
- **Short Trip:** Shows only essential tasks for a quick routine.
- **Toggle:** Switch modes with the Flow Mode Toggle.

### 📊 Progress Dashboard
- **Current Streak:** Days in a row with all essential tasks completed.
- **Total Completions:** Number of tasks completed in the selected period.
- **Activity Calendar:** 90-day heatmap of daily completions.
- **Skill Cadence:** Line chart for Mindfulness, Discipline, Learning.
- **Skill Focus Donut:** Donut chart visualizing skill distribution.
- **Skill Web Radar:** Radar chart for skill levels.
- **Habit Deep Dive:** List of habits with streaks and sparklines.
- **Habit Spotlight:** Highlights top performer and habit needing focus.

### 📝 Task Management
- **Add/Edit/Delete Tasks:** Via Task Manager modal.
- **Customization:** Choose icon, name, frequency, days, essential status.
- **Persistence:** Full habit state saved in localStorage (max 20 tasks), with optional Google Sheets V2 sync.

### 🔗 Google Sheets Integration
- **Sync:** Task completions are logged to Google Sheets via Apps Script.
- **Cross-device habits:** Habit definitions can also sync (requires V2 Apps Script endpoint).
- **Load:** Data fetched from the sheet on app start.

### 🎉 Celebration & Animation
- **Constellation Lines:** Drawn between completed essential islands.
- **Confetti & Sparkles:** Visual celebration when all essential tasks are done.
- **Animated Backgrounds:** Nebula (dark) and water caustics (light).
- **Theme Toggle:** Switch between dark and light modes.

---

## Technical Details

- **Frontend:** Pure HTML, Tailwind CSS (via CDN), and JavaScript.
- **Charts:** Chart.js for line and radar charts; SVG for donut and sparklines.
- **Data Model:** All tasks in `TASK_DEFINITIONS`; global state in `g_appState`.
- **Persistence:** LocalStorage fallback + Google Apps Script backend.
- **Responsive:** Mobile-first design.

---

## How It Works

1. **Initialization:** Loads habits from local state (and cloud when available), then loads completion data.
2. **Daily Tracking:** Map view shows islands for tasks due today. Click to mark complete.
3. **Progress Analytics:** Switch to Progress tab for charts and stats. Filter by 7, 30, or 90 days.
4. **Task Management:** Add/edit/delete tasks in Task Manager modal.
5. **Celebration:** Completing all essential tasks triggers constellation and confetti.

---

## Customization

- **Google Apps Script URL:** Set in `GOOGLE_SCRIPT_URL` at the top of the HTML file.
- **Sync User ID:** Default is `habit-app-primary-user` for personal cross-device sync.
  - Optional: append `?uid=your-id` to the app URL to isolate a specific user.
- **Default Tasks:** Modify `getDefaultTasks()` for initial islands.
- **Icons:** Add SVGs to `ICON_LIBRARY` for more choices.

---

## Setup

1. **Google Sheets Backend**
   - For completions-only behavior, existing Apps Script is enough.
   - For cross-device habit add/edit/delete sync, use `GOOGLE_APPS_SCRIPT_V2.md`.
   - Paste your Apps Script URL in the `GOOGLE_SCRIPT_URL` constant.

2. **Local Development**
   - Open `index.html` in your browser.
   - Manage tasks via the Task Manager.

---

## File Structure

- `index.html` — Main app file (all logic, styles, markup).
- `GOOGLE_APPS_SCRIPT_V2.md` — Apps Script endpoint supporting both tasks + completions sync.

---

## Troubleshooting

- **Data Not Loading:** Check your Apps Script URL and permissions.
- **Task Limit:** Max 20 tasks (custom + default).
- **UI/Chart Issues:** Check browser console for errors.

---

## Credits

- **Icons:** [Heroicons](https://heroicons.com/)
- **Charts:** [Chart.js](https://www.chartjs.org/)
- **CSS:** [Tailwind CSS](https://tailwindcss.com/)

---

**For backend setup, see `GOOGLE_SHEETS_SETUP.md` and `GOOGLE_APPS_SCRIPT.md`.**
