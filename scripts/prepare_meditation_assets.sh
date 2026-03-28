#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_DIR="${MEDITATION_SOURCE_DIR:-/Users/khushal/Documents/Python/Habit_app/meditation_tab/Meditation tab}"
ASSET_DIR="${ROOT_DIR}/mobile_app/assets/meditation"
AUDIO_DIR="${ASSET_DIR}/audio"
ARTWORK_DIR="${ASSET_DIR}/artwork"
CATALOG_FILE="${ASSET_DIR}/catalog.json"
PLACEHOLDER_IMAGE="${ARTWORK_DIR}/_placeholder.jpg"

LIMITER_LINEAR="0.841395" # -1.5 dBFS

if [[ ! -d "${SOURCE_DIR}" ]]; then
  echo "Meditation source directory not found: ${SOURCE_DIR}" >&2
  exit 1
fi

mkdir -p "${AUDIO_DIR}" "${ARTWORK_DIR}"
rm -f "${AUDIO_DIR}"/*.mp3 "${ARTWORK_DIR}"/*.jpg

ffmpeg -hide_banner -nostdin -loglevel error -y \
  -f lavfi -i "color=c=0x1A2E44:s=1200x1200" \
  -frames:v 1 "${PLACEHOLDER_IMAGE}"

declare -a CATALOG_ROWS=()
declare -a PENDING_ARTWORK=()

extract_cover_frame() {
  local src="$1"
  local dst="$2"
  if ffmpeg -hide_banner -nostdin -loglevel error -y -i "${src}" -map 0:v:0 -frames:v 1 "${dst}" >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

cover_url_from_tags() {
  local src="$1"
  local cover_uri
  local referrer_url
  local youtube_id
  cover_uri="$(
    ffprobe -v error -show_format "${src}" 2>/dev/null \
      | sed -n 's/^TAG:#\$cover_uri=//p' \
      | head -n1
  )"
  if [[ -n "${cover_uri}" ]]; then
    printf '%s\n' "${cover_uri}"
    return 0
  fi

  referrer_url="$(
    ffprobe -v error -show_format "${src}" 2>/dev/null \
      | sed -n 's/^TAG:#\$referrer_url=//p' \
      | head -n1
  )"
  youtube_id="$(
    printf '%s' "${referrer_url}" \
      | sed -nE 's#.*(v=|youtu\.be/)([A-Za-z0-9_-]{6,}).*#\2#p'
  )"
  if [[ -n "${youtube_id}" ]]; then
    printf 'https://i1.ytimg.com/vi/%s/sddefault.jpg\n' "${youtube_id}"
    return 0
  fi

  return 1
}

download_thumbnail_from_search() {
  local query="$1"
  local dst="$2"
  local thumb_url
  thumb_url="$(
    yt-dlp "ytsearch1:${query}" --skip-download --print thumbnail 2>/dev/null \
      | head -n1
  )"
  if [[ -z "${thumb_url}" ]]; then
    return 1
  fi
  curl -fsSL "${thumb_url}" -o "${dst}" >/dev/null 2>&1
}

process_audio() {
  local src="$1"
  local dst="$2"
  local mode="$3"
  local gain_db="$4"

  case "${mode}" in
    gain_limit)
      ffmpeg -hide_banner -nostdin -loglevel error -y \
        -i "${src}" -vn -sn -dn \
        -af "volume=${gain_db}dB,alimiter=limit=${LIMITER_LINEAR}" \
        -c:a libmp3lame -b:a 192k "${dst}"
      ;;
    convert_only)
      ffmpeg -hide_banner -nostdin -loglevel error -y \
        -i "${src}" -vn -sn -dn \
        -c:a libmp3lame -b:a 192k "${dst}"
      ;;
    copy_original)
      cp "${src}" "${dst}"
      ;;
    *)
      echo "Unknown processing mode: ${mode}" >&2
      exit 1
      ;;
  esac
}

duration_seconds_for() {
  local file="$1"
  ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "${file}" \
    | awk '{printf "%.0f", $1}'
}

build_catalog_row() {
  local id="$1"
  local title="$2"
  local category="$3"
  local audio_asset="$4"
  local artwork_asset="$5"
  local duration_seconds="$6"
  local source_name="$7"
  local mode="$8"
  local gain_db="$9"
  local artwork_pending="${10}"

  cat <<EOF
    {
      "id": "${id}",
      "title": "${title}",
      "category": "${category}",
      "audioAssetPath": "${audio_asset}",
      "artworkAssetPath": "${artwork_asset}",
      "durationSeconds": ${duration_seconds},
      "sourceFileName": "${source_name}",
      "processingMode": "${mode}",
      "gainDb": ${gain_db},
      "limiterDbfs": -1.5,
      "artworkPending": ${artwork_pending}
    }
EOF
}

TRACKS="$(cat <<'EOF'
10 min NSDR Huberman.m4a|nsdr_huberman_10|Huberman NSDR (10 min)|NSDR / Yoga Nidra|gain_limit|0.0|10 Minute NSDR Huberman
10 min NSDR KellyBoys.mp3|nsdr_kellyboys_10|Kelly Boys NSDR (10 min)|NSDR / Yoga Nidra|gain_limit|1.5|10 Minute NSDR KellyBoys
20 Min Huberman NSDR.mp3|nsdr_huberman_20|Huberman NSDR (20 min)|NSDR / Yoga Nidra|gain_limit|-0.4|20 Minute NSDR Huberman
21 Days Visualisation Challenge with Mitesh Khatri _ LOA Tools That Work(M4A_128K).m4a|visualisation_mitesh_21_days|21-Day Visualisation Challenge|Affirmations / Manifestation|gain_limit|-1.3|Mitesh Khatri 21 Days Visualisation
40hz _Focus _ Change your Mood_  with Dr. Andrew Huberman(MP3_160K).mp3|binaural_huberman_40hz|Huberman 40 Hz Focus|Focus / Binaural|copy_original|0.0|40 HZ Focus Change Your Mood Andrew Huberman
Dr. K - Shoonya Meditation - HealthyGamerGG [10 Minute Duration](480P).mp4|shoonya_drk_10|Dr. K Shoonya Meditation|Guided Meditation|gain_limit|10.0|Dr K Shoonya Meditation 10 Minute
Quick Afternoon Practice with Kelly Boys - Relax Physical_ Emotional_ and Mental Tension--(MP3_160K).mp3|kellyboys_quick_afternoon|Kelly Boys Afternoon NSDR|NSDR / Yoga Nidra|gain_limit|0.2|Quick Afternoon Practice Kelly Boys Relax Emotional Mental Tension
Yoga Nidra for Sleep (8 minute NSDR practice)(MP3_160K).mp3|yoga_nidra_sleep_8|Yoga Nidra for Sleep (8 min)|NSDR / Yoga Nidra|copy_original|0.0|Yoga Nidra for Sleep 8 minute NSDR practice
hooponopono_mithesh (1).mp3|hooponopono_mithesh|Hooponopono with Mitesh|Affirmations / Manifestation|gain_limit|2.6|Hooponopono Mithesh Khatri
money_affirmations.mp3|money_affirmations|Money Affirmations|Affirmations / Manifestation|gain_limit|4.4|Money Affirmations Guided
EOF
)"

while IFS='|' read -r source_name track_id title category mode gain_db thumb_query; do
  [[ -n "${source_name}" ]] || continue
  src="${SOURCE_DIR}/${source_name}"
  if [[ ! -f "${src}" ]]; then
    echo "Missing source file: ${src}" >&2
    exit 1
  fi

  output_audio="${AUDIO_DIR}/${track_id}.mp3"
  output_artwork="${ARTWORK_DIR}/${track_id}.jpg"
  audio_asset_path="assets/meditation/audio/${track_id}.mp3"
  artwork_asset_path="assets/meditation/artwork/${track_id}.jpg"

  process_audio "${src}" "${output_audio}" "${mode}" "${gain_db}"
  duration_seconds="$(duration_seconds_for "${output_audio}")"

  artwork_pending="false"
  if ! extract_cover_frame "${src}" "${output_artwork}"; then
    cover_url="$(cover_url_from_tags "${src}" || true)"
    if [[ -n "${cover_url:-}" ]]; then
      if ! curl -fsSL "${cover_url}" -o "${output_artwork}" >/dev/null 2>&1; then
        rm -f "${output_artwork}"
      fi
    fi
  fi

  if [[ ! -f "${output_artwork}" ]]; then
    if ! download_thumbnail_from_search "${thumb_query}" "${output_artwork}"; then
      cp "${PLACEHOLDER_IMAGE}" "${output_artwork}"
      artwork_pending="true"
      PENDING_ARTWORK+=("${source_name}")
    fi
  fi

  CATALOG_ROWS+=(
    "$(build_catalog_row \
      "${track_id}" \
      "${title}" \
      "${category}" \
      "${audio_asset_path}" \
      "${artwork_asset_path}" \
      "${duration_seconds}" \
      "${source_name}" \
      "${mode}" \
      "${gain_db}" \
      "${artwork_pending}")"
  )
done <<< "${TRACKS}"

{
  echo "{"
  echo "  \"generatedAt\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\","
  echo "  \"sourceDirectory\": \"${SOURCE_DIR}\","
  echo "  \"tracks\": ["
  for index in "${!CATALOG_ROWS[@]}"; do
    echo "${CATALOG_ROWS[index]}"
    if [[ "${index}" -lt "$(( ${#CATALOG_ROWS[@]} - 1 ))" ]]; then
      echo ","
    fi
  done
  echo "  ]"
  echo "}"
} > "${CATALOG_FILE}"

echo "Meditation assets prepared:"
echo "  Audio: ${AUDIO_DIR}"
echo "  Artwork: ${ARTWORK_DIR}"
echo "  Catalog: ${CATALOG_FILE}"

if [[ "${#PENDING_ARTWORK[@]}" -gt 0 ]]; then
  echo
  echo "Artwork fallback placeholders were used for:"
  for pending in "${PENDING_ARTWORK[@]}"; do
    echo "  - ${pending}"
  done
fi
