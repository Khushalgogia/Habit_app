# Voice Growth Archipelago Mobile App

This folder contains the Flutter Android rebuild of the existing `index.html` app.

## Current state

- The app now targets `Supabase + Google OAuth` for the production backend path.
- Demo mode still exists for local UI work without backend credentials.
- Android release signing is configured through `android/key.properties` and `android/app/upload-keystore.jks`.

## Production setup

The repo includes:

- `../scripts/configure_supabase.sh`
  - logs into Supabase CLI
  - links the remote project
  - pushes auth config
  - applies database migrations
  - deploys the `delete-account` edge function
- `../scripts/build_mobile_release.sh`
  - builds the signed APK and AAB with the required Supabase `--dart-define` values

The scripts expect credentials in `../supabase_cred.env`.

## Build outputs

- `build/app/outputs/flutter-apk/app-release.apk`
- `build/app/outputs/bundle/release/app-release.aab`
