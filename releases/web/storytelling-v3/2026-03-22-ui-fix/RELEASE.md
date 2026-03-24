# storytelling-v3 2026-03-22-ui-fix

- Snapshot date: `2026-03-22`
- Source base commit: `ff503ae`
- Source state: working tree snapshot
- File:
  - `version3_storytelling.html`
- Notes:
  - duration options now match the shared engine (`1, 3, 5, 6, 8, 10 min`)
  - old custom `30/30/25/15` rule set removed
  - silence guarantee added for all supported durations above 1 minute
  - constraint injection removed so behavior matches Android and `neurostory_web`
