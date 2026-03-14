#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CRED_FILE="${ROOT_DIR}/supabase_cred.env"
APP_DIR="${ROOT_DIR}/mobile_app"

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

SUPABASE_URL="$(require_value "SUPABASE_URL")"
SUPABASE_PUBLISHABLE_KEY="$(require_value "Publishable_key")"

JAVA_HOME="/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"
export JAVA_HOME
export PATH="/opt/homebrew/opt/openjdk@17/bin:${PATH}"

cd "$APP_DIR"

flutter build apk --release \
  --dart-define=USE_DEMO_BACKEND=false \
  --dart-define=SUPABASE_URL="${SUPABASE_URL}" \
  --dart-define=SUPABASE_PUBLISHABLE_KEY="${SUPABASE_PUBLISHABLE_KEY}" \
  --dart-define=SUPABASE_REDIRECT_SCHEME=com.voicegrowth.archipelago \
  --dart-define=SUPABASE_REDIRECT_HOST=login-callback

flutter build appbundle --release \
  --dart-define=USE_DEMO_BACKEND=false \
  --dart-define=SUPABASE_URL="${SUPABASE_URL}" \
  --dart-define=SUPABASE_PUBLISHABLE_KEY="${SUPABASE_PUBLISHABLE_KEY}" \
  --dart-define=SUPABASE_REDIRECT_SCHEME=com.voicegrowth.archipelago \
  --dart-define=SUPABASE_REDIRECT_HOST=login-callback
