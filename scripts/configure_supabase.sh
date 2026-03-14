#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CRED_FILE="${ROOT_DIR}/supabase_cred.env"

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

SUPABASE_ACCESS_TOKEN="$(require_value "SUPABASE_ACCESS_TOKEN")"
SUPABASE_PROJECT_REF="$(require_value "SUPABASE_PROJECT_REF")"
SUPABASE_DB_PASSWORD="$(require_value "SUPABASE_DB_PASSWORD")"
SUPABASE_SERVICE_ROLE_KEY="$(require_value "service_role")"
SUPABASE_URL="$(require_value "SUPABASE_URL")"
SUPABASE_PUBLISHABLE_KEY="$(require_value "Publishable_key")"
GOOGLE_CLIENT_ID="$(require_value "GOOGLE_CLIENT_ID")"
GOOGLE_CLIENT_SECRET="$(require_value "GOOGLE_CLIENT_SECRET")"

export GOOGLE_CLIENT_ID
export GOOGLE_CLIENT_SECRET
export SUPABASE_URL
export SUPABASE_PUBLISHABLE_KEY

TEMP_WORKDIR="$(mktemp -d)"
TEMP_SUPABASE_DIR="${TEMP_WORKDIR}/supabase"

cleanup() {
  rm -rf "$TEMP_WORKDIR"
}

trap cleanup EXIT

cd "$ROOT_DIR"

mkdir -p "$TEMP_SUPABASE_DIR"
cp -R "${ROOT_DIR}/supabase/." "$TEMP_SUPABASE_DIR/"

python - "$TEMP_SUPABASE_DIR/config.toml" <<'PY'
from pathlib import Path
import os
import sys

path = Path(sys.argv[1])
text = path.read_text()

replacements = {
    'client_id = "env(GOOGLE_CLIENT_ID)"': f'client_id = "{os.environ["GOOGLE_CLIENT_ID"]}"',
    'secret = "env(GOOGLE_CLIENT_SECRET)"': f'secret = "{os.environ["GOOGLE_CLIENT_SECRET"]}"',
}

for old, new in replacements.items():
    if old not in text:
        raise SystemExit(f"Expected config entry not found: {old}")
    text = text.replace(old, new, 1)

path.write_text(text)
PY

supabase login --token "$SUPABASE_ACCESS_TOKEN" --no-browser --name "voice-growth-archipelago"
supabase link --project-ref "$SUPABASE_PROJECT_REF" --password "$SUPABASE_DB_PASSWORD"

supabase config push \
  --project-ref "$SUPABASE_PROJECT_REF" \
  --workdir "$TEMP_WORKDIR" \
  --yes

supabase secrets set \
  --project-ref "$SUPABASE_PROJECT_REF" \
  "VGA_SERVICE_ROLE_KEY=${SUPABASE_SERVICE_ROLE_KEY}"

supabase db push --password "$SUPABASE_DB_PASSWORD" --yes
supabase functions deploy delete-account --project-ref "$SUPABASE_PROJECT_REF" --use-api --yes

python - <<'PY'
from pathlib import Path
from urllib.parse import urlencode
from urllib.request import Request, urlopen
from urllib.error import HTTPError
import json
import os
import sys

supabase_url = os.environ["SUPABASE_URL"]
publishable_key = os.environ["SUPABASE_PUBLISHABLE_KEY"]
google_client_id = os.environ["GOOGLE_CLIENT_ID"]
redirect_to = "com.voicegrowth.archipelago://login-callback/"

settings_request = Request(
    f"{supabase_url}/auth/v1/settings",
    headers={
        "apikey": publishable_key,
        "Authorization": f"Bearer {publishable_key}",
    },
)

with urlopen(settings_request) as response:
    settings = json.loads(response.read().decode())

if not settings.get("external", {}).get("google"):
    raise SystemExit("Google provider is still disabled in live auth settings.")

authorize_url = (
    f"{supabase_url}/auth/v1/authorize?"
    f"{urlencode({'provider': 'google', 'redirect_to': redirect_to})}"
)

authorize_request = Request(authorize_url, method="GET")

try:
    with urlopen(authorize_request) as response:
        final_url = response.geturl()
except HTTPError as error:
    body = error.read().decode()
    raise SystemExit(
        f"Google authorize endpoint returned HTTP {error.code}: {body}"
    ) from error

if "provider is not enabled" in final_url:
    raise SystemExit("Google provider is still disabled on authorize endpoint.")

if "client_id=env(" in final_url:
    raise SystemExit("Google client ID placeholder is still active on authorize endpoint.")

if google_client_id not in final_url:
    raise SystemExit("Live Google authorize endpoint is not using the configured client ID.")

print("Supabase Google auth configuration verified.")
PY
