import { initializeApp, applicationDefault, cert } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import fs from 'node:fs';

const APPS_SCRIPT_URL = process.env.APPS_SCRIPT_URL;
const SOURCE_USER_ID =
  process.env.SOURCE_USER_ID || 'habit-app-primary-user';
const TARGET_UID = process.env.TARGET_UID;
const SERVICE_ACCOUNT_PATH = process.env.SERVICE_ACCOUNT_PATH;

if (!APPS_SCRIPT_URL || !TARGET_UID) {
  console.error(
    'Missing APPS_SCRIPT_URL or TARGET_UID. Example: APPS_SCRIPT_URL=... TARGET_UID=... npm run import'
  );
  process.exit(1);
}

const credential = SERVICE_ACCOUNT_PATH
  ? cert(JSON.parse(fs.readFileSync(SERVICE_ACCOUNT_PATH, 'utf8')))
  : applicationDefault();

initializeApp({ credential });

const db = getFirestore();

function svgToIconKey(svg = '') {
  if (svg.includes('M12 6.253v13')) return 'book';
  if (svg.includes('M14.828 14.828')) return 'mood';
  if (svg.includes('M3.055 11H5')) return 'public';
  if (svg.includes('M11 5H6a2 2')) return 'edit';
  if (svg.includes('M13 10V3')) return 'bolt';
  if (svg.includes('M7 8h10')) return 'chat';
  if (svg.includes('M13 7h8m0 0v8')) return 'trending';
  return 'book';
}

function normalizeFrequency(value) {
  if (value === '2x-weekly') return 'twiceWeekly';
  if (value === '3x-weekly') return 'thriceWeekly';
  if (value === 'weekly') return 'weekly';
  return 'daily';
}

function normalizeStatus(value) {
  if (value === 'archived') return 'archived';
  if (value === 'deleted') return 'deleted';
  return 'active';
}

function normalizeTasks(tasks) {
  return (tasks || []).map((task) => ({
    id: task.id,
    name: task.name || 'Untitled Habit',
    subtitle: task.time || '',
    iconKey: svgToIconKey(task.icon || ''),
    iconColor: task.iconColor || '#22d3ee',
    baseColor: task.baseColor || task.iconColor || '#0891b2',
    glowColor: task.glowColor || task.iconColor || '#22D3EE',
    xPct: typeof task.x === 'number' ? task.x : 50,
    yPct: typeof task.y === 'number' ? task.y : 50,
    frequency: normalizeFrequency(task.frequency),
    daysDue: Array.isArray(task.daysDue) ? task.daysDue : [0, 1, 2, 3, 4, 5, 6],
    scopeMode: task.mode || 'both',
    isCore: Boolean(task.isEssential),
    category: task.skill || 'Uncategorized',
    categoryColor: task.skillColor || '#94a3b8',
    status: normalizeStatus(task.status),
    createdAt: new Date(task.createdAt || Date.now()).toISOString(),
    archivedAt: task.archivedAt ? new Date(task.archivedAt).toISOString() : null,
    deletedAt: task.deletedAt ? new Date(task.deletedAt).toISOString() : null,
    updatedAt: new Date().toISOString()
  }));
}

function buildDailyLogs(taskHistory = {}) {
  const logs = new Map();
  for (const [habitId, timestamps] of Object.entries(taskHistory)) {
    for (const rawTs of timestamps || []) {
      const ts = Number(rawTs);
      if (!Number.isFinite(ts)) continue;
      const date = new Date(ts);
      const dateKey = date.toISOString().slice(0, 10);
      const current = logs.get(dateKey) || {
        dateKey,
        completedHabitIds: [],
        completedAtByHabit: {},
        updatedAt: new Date().toISOString()
      };
      if (!current.completedHabitIds.includes(habitId)) {
        current.completedHabitIds.push(habitId);
      }
      current.completedAtByHabit[habitId] = ts;
      logs.set(dateKey, current);
    }
  }
  return [...logs.values()];
}

async function main() {
  const url = `${APPS_SCRIPT_URL}?action=loadAll&userId=${encodeURIComponent(
    SOURCE_USER_ID
  )}`;
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`Apps Script load failed: ${response.status} ${response.statusText}`);
  }

  const payload = await response.json();
  const tasks = normalizeTasks(payload.tasks || []);
  const dailyLogs = buildDailyLogs(payload.taskHistory || {});
  const now = new Date().toISOString();

  await db.collection('users').doc(TARGET_UID).set(
    {
      displayName: 'Migrated User',
      email: '',
      photoUrl: null,
      timezone: 'UTC',
      themeMode: 'dark',
      onboardingState: 'completed',
      createdAt: now,
      updatedAt: now
    },
    { merge: true }
  );

  let batch = db.batch();
  let writes = 0;

  const commitIfNeeded = async () => {
    if (writes === 0) return;
    await batch.commit();
    batch = db.batch();
    writes = 0;
  };

  for (const task of tasks) {
    batch.set(db.collection('users').doc(TARGET_UID).collection('habits').doc(task.id), task);
    writes += 1;
    if (writes >= 400) await commitIfNeeded();
  }

  for (const log of dailyLogs) {
    batch.set(
      db.collection('users').doc(TARGET_UID).collection('dailyLogs').doc(log.dateKey),
      log
    );
    writes += 1;
    if (writes >= 400) await commitIfNeeded();
  }

  await commitIfNeeded();
  console.log(`Imported ${tasks.length} habits and ${dailyLogs.length} daily logs into ${TARGET_UID}.`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
