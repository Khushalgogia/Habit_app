# Android Releases

Store built Android release artifacts here so older app versions are easy to find later.

## Suggested Layout

```text
releases/android/mobile-v1.0.0/
  RELEASE.md
  app-release.apk
  app-release.aab
```

## RELEASE.md Template

```md
# mobile-v1.0.0

- Tag: `mobile-v1.0.0`
- Build date: `YYYY-MM-DD`
- Commit: `<git-sha>`
- Notes: short release summary
- Artifacts:
  - `app-release.apk`
  - `app-release.aab`
```

## Workflow

1. Build the app with `scripts/build_mobile_release.sh`.
2. Create a git tag for the release.
3. Create a versioned folder here.
4. Copy the APK/AAB into that folder.
5. Add a `RELEASE.md` file with the tag, date, commit, and notes.
