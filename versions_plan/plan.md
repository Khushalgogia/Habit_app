# Fix: Meditation Player In-App Controls Unresponsive

## Context

In **v2.2.8 build 13** (confirmed: `pubspec.yaml` version `2.2.8+13`, matching `releases/android/mobile-v2.2.8-build13/`), the meditation player's in-app controls (pause button, seek slider, skip buttons) are completely unresponsive. However, the same audio's notification panel controls (Android media notification) work perfectly — pause, seek, and close all function from the notification.

## Root Cause: Operation Queue Deadlock

The `JustAudioMeditationPlaybackController` serializes all operations through an `_enqueue` queue to prevent race conditions. The bug is that `await _player.play()` is called inside enqueued actions, and **since just_audio v0.9.0, `AudioPlayer.play()` returns a Future that only completes when playback ENDS** (paused, stopped, or track finished).

**Deadlock chain:**
1. User taps a track → `playTrackById()` enqueues an action containing `await _player.play()` (line 330)
2. That enqueued action blocks — waiting for playback to end
3. User taps pause in-app → `pause()` calls `_enqueue(...)` → queued behind the blocked play action → **STUCK**
4. Same for seek, skip next/previous — all go through `_enqueue` → all blocked
5. Notification controls bypass the Dart queue entirely (the `audio_service` framework directly calls the underlying `AudioPlayer`) → **WORK FINE**

**Why existing tests don't catch this:** The test fake `_FakeMeditationAudioPlayer.play()` returns immediately, so the queue never deadlocks in tests.

## Fix

### Step 1: Don't await `_player.play()` in controller (2 lines changed)

**File:** `mobile_app/lib/src/features/meditation/data/meditation_playback_controller.dart`

**Line 228** (inside `play()` method):
```dart
// Before:
await _player.play();

// After:
unawaited(_player.play().catchError((Object _) {}));
```

**Line 330** (inside `_playTrackAtIndex()` method):
```dart
// Before:
await _player.play();

// After:
unawaited(_player.play().catchError((Object _) {}));
```

`dart:async` (which exports `unawaited`) is already imported. The `.catchError` prevents unhandled async errors from the detached Future. Errors from the actual player are already surfaced through `playerStateStream`.

### Step 2: Add deadlock regression tests

**File:** `mobile_app/test/meditation_playback_controller_test.dart`

Add a `_BlockingPlayMeditationAudioPlayer` that extends the existing fake but overrides `play()` to return a never-completing Future (simulating real just_audio behavior). Then add 3 tests:

1. **"pause completes promptly even while play future is pending"** — start playback, verify pause resolves within 2s
2. **"seek completes while play future is pending"** — start playback, verify seek resolves within 2s
3. **"rapid play-pause sequence does not deadlock"** — play/pause/play/pause, all with 2s timeouts

## Why this is safe

- **State is stream-driven.** The UI uses `StreamBuilder` on `playerStateStream`, `positionStream`, etc. — no code path reads the return value of `play()` for state.
- **Setup still serialized.** The queue still serializes `_ensurePlaylistPrepared` and `seek` before firing `play()`. Only the open-ended `play()` Future is detached.
- **Notification behavior unchanged.** The `audio_service` bridge is unaffected.
- **Existing tests pass.** The fake `play()` already resolves immediately, so detaching it changes nothing in test behavior.

## Verification

```bash
cd mobile_app && flutter test test/meditation_playback_controller_test.dart test/meditation_screen_test.dart
```

Then build and test on a physical Android device:
1. Open meditation tab, tap any audio track
2. Verify pause button responds immediately
3. Verify seek slider (drag and tap) responds immediately
4. Verify skip next/previous buttons respond
5. Verify notification controls still work
6. Verify rapid play/pause toggling works smoothly
