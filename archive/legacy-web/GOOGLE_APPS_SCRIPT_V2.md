# Google Apps Script V2 (Habits + Completions)

Use this if you want cross-device sync for both:
- task completions
- habit definitions (add/edit/delete habits)

Lifecycle note:
- The frontend now persists habit lifecycle inside `tasks_json` with fields like:
  - `status: "active" | "archived" | "deleted"`
  - `createdAt`, `archivedAt`, `deletedAt`
- This script remains backward compatible because it stores raw JSON as-is.

Your current frontend now sends:
- `entity: "completion"` with `action: "add" | "remove"` for check/uncheck
- `entity: "tasks"` with `action: "saveTasks"` and full `tasks` array
- `userId` on all requests

It now loads with:
- `GET ?action=loadBootstrap&userId=<id>&days=120` for startup
- `GET ?action=loadHistoryRange&userId=<id>&from=YYYY-MM-DD&to=YYYY-MM-DD` for older custom ranges
- `GET ?action=loadAll&userId=<id>` remains backward compatible

Frontend note:
- Default `userId` is `habit-app-primary-user` (single-user mode).
- You can override with URL param `?uid=<your-id>`.

## Tasks JSON schema expectations

`tasks_json` can contain both legacy and new fields. The backend should not validate/strip fields.

Example task object:

```json
{
  "id": "custom-123",
  "name": "Morning Walk",
  "frequency": "daily",
  "daysDue": [0,1,2,3,4,5,6],
  "isEssential": true,
  "skill": "Fitness",
  "skillColor": "#34d399",
  "status": "active",
  "createdAt": 1762450000000
}
```

## Apps Script code

```javascript
const COMPLETIONS_SHEET = 'Completions';
const TASKS_SHEET = 'TaskDefinitions';

function doGet(e) {
  const action = (e.parameter.action || '').trim();
  const userId = (e.parameter.userId || '').trim();

  if (action === 'loadAll' && userId) {
    const payload = {
      taskHistory: buildTaskHistoryForUser_(userId),
      tasks: getTasksForUser_(userId)
    };
    return jsonResponse_(payload);
  }

  // Legacy fallback: returns only task history (all users mixed if no userId is passed)
  if (userId) {
    return jsonResponse_(buildTaskHistoryForUser_(userId));
  }
  return jsonResponse_(buildTaskHistoryLegacy_());
}

function doPost(e) {
  try {
    const body = e.postData && e.postData.contents ? JSON.parse(e.postData.contents) : {};
    const entity = (body.entity || '').trim();
    const action = (body.action || '').trim();
    const userId = (body.userId || '').trim();

    if (entity === 'tasks' && action === 'saveTasks' && userId) {
      saveTasksForUser_(userId, body.tasks || []);
      return jsonResponse_({ ok: true });
    }

    // Completion writes (supports both new + legacy payload shape)
    if (action === 'add' || action === 'remove') {
      const taskId = (body.taskId || '').trim();
      const timestamp = Number(body.timestamp);
      if (!taskId || !Number.isFinite(timestamp)) {
        return jsonResponse_({ error: 'Invalid task completion payload' });
      }
      appendCompletionRow_(userId || 'anonymous', taskId, timestamp, action);
      return jsonResponse_({ ok: true });
    }

    return jsonResponse_({ error: 'Unsupported request payload' });
  } catch (err) {
    return jsonResponse_({ error: err.message || String(err) });
  }
}

function appendCompletionRow_(userId, taskId, timestamp, action) {
  const sheet = getOrCreateSheet_(COMPLETIONS_SHEET, ['user_id', 'task_id', 'timestamp', 'action', 'created_at']);
  sheet.appendRow([userId, taskId, timestamp, action, new Date().toISOString()]);
}

function buildTaskHistoryForUser_(userId) {
  const sheet = getOrCreateSheet_(COMPLETIONS_SHEET, ['user_id', 'task_id', 'timestamp', 'action', 'created_at']);
  const values = sheet.getDataRange().getValues();
  const history = {};

  for (let i = 1; i < values.length; i++) {
    const rowUserId = String(values[i][0] || '').trim();
    if (rowUserId !== userId) continue;
    const taskId = String(values[i][1] || '').trim();
    const ts = Number(values[i][2]);
    const action = String(values[i][3] || '').trim();
    if (!taskId || !Number.isFinite(ts)) continue;

    history[taskId] = history[taskId] || [];
    if (action === 'add') {
      history[taskId].push(ts);
    } else if (action === 'remove') {
      const idx = history[taskId].indexOf(ts);
      if (idx !== -1) history[taskId].splice(idx, 1);
    }
  }
  return history;
}

function buildTaskHistoryLegacy_() {
  const sheet = getOrCreateSheet_(COMPLETIONS_SHEET, ['user_id', 'task_id', 'timestamp', 'action', 'created_at']);
  const values = sheet.getDataRange().getValues();
  const history = {};
  for (let i = 1; i < values.length; i++) {
    const taskId = String(values[i][1] || '').trim();
    const ts = Number(values[i][2]);
    const action = String(values[i][3] || '').trim();
    if (!taskId || !Number.isFinite(ts)) continue;
    history[taskId] = history[taskId] || [];
    if (action === 'add') history[taskId].push(ts);
    if (action === 'remove') {
      const idx = history[taskId].indexOf(ts);
      if (idx !== -1) history[taskId].splice(idx, 1);
    }
  }
  return history;
}

function getTasksForUser_(userId) {
  const sheet = getOrCreateSheet_(TASKS_SHEET, ['user_id', 'tasks_json', 'updated_at']);
  const values = sheet.getDataRange().getValues();
  for (let i = values.length - 1; i >= 1; i--) {
    const rowUserId = String(values[i][0] || '').trim();
    if (rowUserId !== userId) continue;
    const raw = String(values[i][1] || '').trim();
    if (!raw) return [];
    try {
      return JSON.parse(raw);
    } catch (_err) {
      return [];
    }
  }
  return [];
}

function saveTasksForUser_(userId, tasks) {
  const sheet = getOrCreateSheet_(TASKS_SHEET, ['user_id', 'tasks_json', 'updated_at']);
  const values = sheet.getDataRange().getValues();
  const tasksJson = JSON.stringify(tasks || []);
  const nowIso = new Date().toISOString();

  for (let i = 1; i < values.length; i++) {
    const rowUserId = String(values[i][0] || '').trim();
    if (rowUserId === userId) {
      sheet.getRange(i + 1, 2).setValue(tasksJson);
      sheet.getRange(i + 1, 3).setValue(nowIso);
      return;
    }
  }
  sheet.appendRow([userId, tasksJson, nowIso]);
}

function getOrCreateSheet_(name, headers) {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  let sheet = ss.getSheetByName(name);
  if (!sheet) {
    sheet = ss.insertSheet(name);
  }
  if (sheet.getLastRow() === 0) {
    sheet.appendRow(headers);
  }
  return sheet;
}

function jsonResponse_(obj) {
  return ContentService
    .createTextOutput(JSON.stringify(obj))
    .setMimeType(ContentService.MimeType.JSON);
}
```

## Deployed web app

Current production endpoint:

`https://script.google.com/macros/s/AKfycbw-2KjfaTRvQJhyBBfyUJYYN3iQKgrABYNYMWZlwlny1PyOwvhupDmi7YjuvTJgWKaQLw/exec`

## Frontend usage notes

- Startup should use `loadBootstrap`, not `loadAll`.
- Presets `7d`, `30d`, `90d` should rely on the bootstrap history window.
- Older custom ranges should call `loadHistoryRange` and merge the returned history into local cache.
- The frontend should point `GOOGLE_SCRIPT_URL` at the endpoint above.

## Deploy steps
1. Open Apps Script linked to your Google Sheet.
2. Replace code with the script above.
3. Deploy as Web App:
   - Execute as: `Me`
   - Who has access: `Anyone`
4. Keep `GOOGLE_SCRIPT_URL` in `index.html` pointed to the deployed endpoint above.
