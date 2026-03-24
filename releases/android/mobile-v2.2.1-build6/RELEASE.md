# mobile-v2.2.1-build6

- Build date: `2026-03-24`
- Source base commit: `ff503ae`
- App version: `2.2.1`
- Build number: `6`
- Installed release label: `2.2.1 (6)`
- Artifacts:
  - `voice-growth-archipelago-v2.2.1-build6.apk`
  - `voice-growth-archipelago-v2.2.1-build6.aab`
- SHA-256:
  - `voice-growth-archipelago-v2.2.1-build6.apk`: `26967afc8fc0125a1344d97ca804c6f6735a1c526e71856e1f1b9319310cef2e`
  - `voice-growth-archipelago-v2.2.1-build6.aab`: `5975cb6f4255fd0126fd7fdfc547df8749819138bb75b2e6f3b55e72c76b225f`
- Notes:
  - Hotfix for the Android white-screen startup regression after meditation background audio integration
  - Background audio initialization now degrades safely so the app still opens even if lock-screen controls are unavailable
  - Main activity now uses the audio-service compatible Android activity class for startup stability
  - Settings shows the installed version/build so the running APK is easy to confirm
