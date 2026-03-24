# Android Releases

Store built Android release artifacts here so older app versions are easy to find later.

## Suggested Layout

```text
releases/android/mobile-v2.1.1-build4/
  RELEASE.md
  voice-growth-archipelago-v2.1.1-build4.apk
  voice-growth-archipelago-v2.1.1-build4.aab
  screenshots/
```

## RELEASE.md Template

```md
# mobile-v2.1.1-build4

- Build date: `YYYY-MM-DD`
- Source base commit: `<git-sha>`
- App version: `2.1.1`
- Build number: `4`
- Installed release label: `2.1.1 (4)`
- Artifacts:
  - `voice-growth-archipelago-v2.1.1-build4.apk`
  - `voice-growth-archipelago-v2.1.1-build4.aab`
- SHA-256:
  - `voice-growth-archipelago-v2.1.1-build4.apk`: `<sha256>`
  - `voice-growth-archipelago-v2.1.1-build4.aab`: `<sha256>`
```

## Workflow

1. Build the app with `scripts/build_mobile_release.sh`.
2. The script reads the version from `mobile_app/pubspec.yaml`.
3. It creates a versioned release folder here automatically.
4. It copies the APK/AAB using human-readable versioned filenames.
5. It writes `RELEASE.md` with version, build number, commit, and SHA-256 checksums.
6. Optionally add screenshots or notes inside the release folder for visual proof.
