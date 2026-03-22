# mobile-v2.1.0 (Build 3)

**Date:** 2026-03-22

## Changes

### Bug Fixes
- **Pause overlay blocks resume** — Tapping the pause overlay now resumes the session; added "TAP TO RESUME" hint text

### Improvements
- **User-provided prompt data** — Objects (32) and emotions (10 with vocal cues) loaded from JSON assets instead of hardcoded lists
- **Emotion vocal cue display** — Emotion prompts show the name large and the vocal cue in a styled italic pill below
- **Removed constraints** — Only 3 prompt types remain: Object (50%), Emotion (40%), Silence (10%)
- **Screen wakelock** — Screen stays on during Story and Breathe sessions (wakelock_plus)
- **Story tab edge-to-edge** — Story screen renders without shell backdrop; nav bar matches neon yellow theme
- **More durations** — Added 6M and 8M options (total: 1M, 3M, 5M, 6M, 8M, 10M)

## Artifacts
- `app-release.apk` — Direct install APK
- `app-release.aab` — Google Play App Bundle
