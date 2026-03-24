# Voice Growth Archipelago Mobile Repository

This repository is now organized around the Flutter Android app in `mobile_app/`.

The active product is the mobile app. Older web-era work is preserved in `archive/legacy-web/` so the root stays focused on the pieces you need for building, releasing, and maintaining the app.

## Active Folders

- `mobile_app/` - Flutter app source, tests, Android project, and app assets
- `scripts/` - helper scripts for release builds and Supabase configuration
- `supabase/` - database migrations, edge function, and Supabase project config
- `hosting/` - public legal pages used for privacy and delete-account support
- `releases/android/` - place to store dated APK/AAB releases and release notes

## Archived Material

`archive/legacy-web/` contains older work that is not part of the current mobile build path, including:

- the original single-file web app
- Google Apps Script sync notes
- old architecture docs and implementation notes
- Firebase/Firestore-era migration files
- the experimental `version2_meditation` prototype

See `archive/legacy-web/README.md` for details.

## Build The Mobile App

The signed Android release flow uses:

- `scripts/build_mobile_release.sh`
- `mobile_app/android/key.properties`
- `mobile_app/android/app/upload-keystore.jks`
- `supabase_cred.env`

The script reads Supabase values from `supabase_cred.env` and builds:

- `mobile_app/build/app/outputs/flutter-apk/app-release.apk`
- `mobile_app/build/app/outputs/bundle/release/app-release.aab`

Before running it, keep your signing files local and make sure Flutter, Java 17, and your Android toolchain are available.

## Backend And Support

The mobile app still depends on support files outside `mobile_app/`:

- `supabase/` for auth/database configuration and migrations
- `scripts/configure_supabase.sh` for linking and deploying backend changes
- `hosting/public/privacy.html` and `hosting/public/delete-account.html` for public legal/account-deletion pages

## Release History Workflow

Use two layers for version history:

1. Create a git tag for each source release, for example `mobile-v1.0.0`.
2. Save the built APK/AAB under `releases/android/<version-or-date>/`.

Suggested release folder contents:

```text
releases/android/mobile-v1.0.0/
  RELEASE.md
  app-release.apk
  app-release.aab
```

`RELEASE.md` should record:

- version name
- git tag
- build date
- important notes
- artifact names

## Git LFS For Large Assets

This repository stores large binaries (meditation audio, APK/AAB releases) via Git LFS. To clone everything successfully:

1. Install Git LFS and run `git lfs install`
2. Clone the repo normally
3. If needed, run `git lfs pull` to fetch large assets

Files tracked via LFS include `*.mp3`, `*.m4a`, `*.mp4`, `*.wav`, `*.apk`, and `*.aab`.

## Safety Notes

- Local secrets and signing files should remain untracked.
- Generated folders such as `mobile_app/build/`, `mobile_app/.dart_tool/`, and `supabase/.temp/` can be recreated and should not be treated as source.
- A safety tag named `pre-restructure-2026-03-22` was created before this cleanup, and patch backups of uncommitted work were saved in `/tmp/habit_app_safety`.
