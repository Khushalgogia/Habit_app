# mobile-v2.2.9-build14

- Build date: `2026-03-28`
- Source base commit: `82b357c`
- App version: `2.2.9`
- Build number: `14`
- Installed release label: `2.2.9 (14)`
- Artifacts:
  - `voice-growth-archipelago-v2.2.9-build14.apk`
  - `voice-growth-archipelago-v2.2.9-build14.aab`
- SHA-256:
  - `voice-growth-archipelago-v2.2.9-build14.apk`: `21f5ac749bd48142b9b18b2b93361b553a884b22b37c9418ee67dc6cfaa43fb3`
  - `voice-growth-archipelago-v2.2.9-build14.aab`: `56ef6e2de0802be72158a0fad3f488a78d00ae370ae17640ff17c73dc8566959`
- Validation:
  - `flutter test test/meditation_playback_controller_test.dart test/meditation_screen_test.dart test/app_bootstrap_test.dart test/progress_screen_test.dart` passed.
  - The release build script verified that both packaged artifacts include every meditation asset referenced by `assets/meditation/catalog.json`.
- Notes:
  - Fixes the meditation in-app control deadlock that was present in `v2.2.8 build 13`, where pause, seek, and skip actions could stop responding while notification controls still worked.
  - The playback controller now detaches the long-lived `play()` Future from its serialized operation queue, so in-app controls stay responsive during active playback.
  - Added regression coverage for pause, seek, and rapid play/pause interactions using a blocking `play()` fake that simulates the real player behavior.
