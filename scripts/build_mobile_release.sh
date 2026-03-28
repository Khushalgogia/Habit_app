#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CRED_FILE="${ROOT_DIR}/supabase_cred.env"
APP_DIR="${ROOT_DIR}/mobile_app"
PUBSPEC_FILE="${APP_DIR}/pubspec.yaml"
RELEASES_DIR="${ROOT_DIR}/releases/android"
MEDITATION_PREP_SCRIPT="${ROOT_DIR}/scripts/prepare_meditation_assets.sh"

value_for() {
  local key="$1"
  awk -F' = ' -v key="$key" '$1 == key { print $2 }' "$CRED_FILE"
}

require_value() {
  local key="$1"
  local value
  value="$(value_for "$key")"
  if [[ -z "$value" ]]; then
    echo "Missing required key in ${CRED_FILE}: ${key}" >&2
    exit 1
  fi
  printf '%s' "$value"
}

pubspec_value() {
  local key="$1"
  awk -F': ' -v key="$key" '$1 == key { print $2 }' "$PUBSPEC_FILE"
}

catalog_asset_paths() {
  python3 - "${APP_DIR}/assets/meditation/catalog.json" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as handle:
    payload = json.load(handle)

print("assets/meditation/catalog.json")
for track in payload.get("tracks", []):
    print(track["audioAssetPath"])
    print(track["artworkAssetPath"])
PY
}

validate_local_meditation_assets() {
  local missing=0
  while IFS= read -r asset_path; do
    [[ -n "${asset_path}" ]] || continue
    if [[ ! -f "${APP_DIR}/${asset_path}" ]]; then
      echo "Missing meditation asset before build: ${APP_DIR}/${asset_path}" >&2
      missing=1
    fi
  done < <(catalog_asset_paths)

  if [[ "${missing}" -ne 0 ]]; then
    exit 1
  fi
}

validate_packaged_meditation_assets() {
  local archive_path="$1"
  local label="$2"
  local archive_listing
  local archive_prefix="assets/flutter_assets"
  local missing=0

  if [[ "${archive_path}" == *.aab ]]; then
    archive_prefix="base/assets/flutter_assets"
  fi

  archive_listing="$(unzip -Z1 "${archive_path}")"

  while IFS= read -r asset_path; do
    [[ -n "${asset_path}" ]] || continue
    if ! grep -Fxq "${archive_prefix}/${asset_path}" <<< "${archive_listing}"; then
      echo "Missing meditation asset in ${label}: ${asset_path}" >&2
      missing=1
    fi
  done < <(catalog_asset_paths)

  if [[ "${missing}" -ne 0 ]]; then
    exit 1
  fi
}

SUPABASE_URL="$(require_value "SUPABASE_URL")"
SUPABASE_PUBLISHABLE_KEY="$(require_value "Publishable_key")"
RAW_VERSION="$(pubspec_value "version")"
APP_VERSION="${RAW_VERSION%%+*}"
APP_BUILD_NUMBER="${RAW_VERSION#*+}"

if [[ -z "$APP_VERSION" || -z "$APP_BUILD_NUMBER" || "$RAW_VERSION" == "$APP_VERSION" ]]; then
  echo "Unable to parse version from ${PUBSPEC_FILE}: ${RAW_VERSION}" >&2
  exit 1
fi

VERSION_SLUG="v${APP_VERSION}-build${APP_BUILD_NUMBER}"
RELEASE_DIR="${RELEASES_DIR}/mobile-${VERSION_SLUG}"
APK_SOURCE="${APP_DIR}/build/app/outputs/flutter-apk/app-release.apk"
AAB_SOURCE="${APP_DIR}/build/app/outputs/bundle/release/app-release.aab"
APK_NAME="voice-growth-archipelago-${VERSION_SLUG}.apk"
AAB_NAME="voice-growth-archipelago-${VERSION_SLUG}.aab"
APK_TARGET="${RELEASE_DIR}/${APK_NAME}"
AAB_TARGET="${RELEASE_DIR}/${AAB_NAME}"

JAVA_HOME="/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"
export JAVA_HOME
export PATH="/opt/homebrew/opt/openjdk@17/bin:${PATH}"

if [[ -x "${MEDITATION_PREP_SCRIPT}" ]]; then
  "${MEDITATION_PREP_SCRIPT}"
fi

validate_local_meditation_assets

cd "$APP_DIR"

flutter build apk --release \
  --dart-define=APP_VERSION="${APP_VERSION}" \
  --dart-define=APP_BUILD_NUMBER="${APP_BUILD_NUMBER}" \
  --dart-define=USE_DEMO_BACKEND=false \
  --dart-define=SUPABASE_URL="${SUPABASE_URL}" \
  --dart-define=SUPABASE_PUBLISHABLE_KEY="${SUPABASE_PUBLISHABLE_KEY}" \
  --dart-define=SUPABASE_REDIRECT_SCHEME=com.voicegrowth.archipelago \
  --dart-define=SUPABASE_REDIRECT_HOST=login-callback

flutter build appbundle --release \
  --dart-define=APP_VERSION="${APP_VERSION}" \
  --dart-define=APP_BUILD_NUMBER="${APP_BUILD_NUMBER}" \
  --dart-define=USE_DEMO_BACKEND=false \
  --dart-define=SUPABASE_URL="${SUPABASE_URL}" \
  --dart-define=SUPABASE_PUBLISHABLE_KEY="${SUPABASE_PUBLISHABLE_KEY}" \
  --dart-define=SUPABASE_REDIRECT_SCHEME=com.voicegrowth.archipelago \
  --dart-define=SUPABASE_REDIRECT_HOST=login-callback

validate_packaged_meditation_assets "${APK_SOURCE}" "apk"
validate_packaged_meditation_assets "${AAB_SOURCE}" "aab"

mkdir -p "${RELEASE_DIR}"
cp "${APK_SOURCE}" "${APK_TARGET}"
cp "${AAB_SOURCE}" "${AAB_TARGET}"

APK_SHA="$(shasum -a 256 "${APK_TARGET}" | awk '{print $1}')"
AAB_SHA="$(shasum -a 256 "${AAB_TARGET}" | awk '{print $1}')"
BUILD_DATE="$(date +%F)"
SOURCE_COMMIT="$(git -C "${ROOT_DIR}" rev-parse --short HEAD)"

cat > "${RELEASE_DIR}/RELEASE.md" <<EOF
# mobile-${VERSION_SLUG}

- Build date: \`${BUILD_DATE}\`
- Source base commit: \`${SOURCE_COMMIT}\`
- App version: \`${APP_VERSION}\`
- Build number: \`${APP_BUILD_NUMBER}\`
- Installed release label: \`${APP_VERSION} (${APP_BUILD_NUMBER})\`
- Artifacts:
  - \`${APK_NAME}\`
  - \`${AAB_NAME}\`
- SHA-256:
  - \`${APK_NAME}\`: \`${APK_SHA}\`
  - \`${AAB_NAME}\`: \`${AAB_SHA}\`
- Notes:
  - Meditation now uses a Spotify-style local library with continue-listening and recent-session sections
  - The shared Aura default now uses a green-led accent across Meditation and Breathe neutral states
  - The Breathe favorite button was removed and Story setup spacing was tightened without changing feature behavior
  - Meditation remains the app's only background-enabled audio player, so lock-screen controls stay reliable
EOF

echo "Release artifacts archived in ${RELEASE_DIR}"
