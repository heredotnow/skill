#!/usr/bin/env bash
set -euo pipefail

BASE_URL="https://here.now"
CREDENTIALS_FILE="$HOME/.herenow/credentials"
API_KEY="${HERENOW_API_KEY:-}"
SLUG=""
CLAIM_TOKEN=""
TITLE=""
DESCRIPTION=""
TTL=""
TARGET=""

usage() {
  cat <<'USAGE'
Usage: publish.sh <file-or-dir> [options]

Options:
  --api-key <key>         API key (or set $HERENOW_API_KEY)
  --slug <slug>           Update existing publish
  --claim-token <token>   Claim token for anonymous updates
  --title <text>          Viewer title
  --description <text>    Viewer description
  --ttl <seconds>         Expiry (authenticated only)
  --base-url <url>        API base (default: https://here.now)
USAGE
  exit 1
}

die() { echo "error: $1" >&2; exit 1; }

for cmd in curl jq file; do
  command -v "$cmd" >/dev/null 2>&1 || die "requires $cmd"
done

while [[ $# -gt 0 ]]; do
  case "$1" in
    --api-key)      API_KEY="$2"; shift 2 ;;
    --slug)         SLUG="$2"; shift 2 ;;
    --claim-token)  CLAIM_TOKEN="$2"; shift 2 ;;
    --title)        TITLE="$2"; shift 2 ;;
    --description)  DESCRIPTION="$2"; shift 2 ;;
    --ttl)          TTL="$2"; shift 2 ;;
    --base-url)     BASE_URL="$2"; shift 2 ;;
    --help|-h)      usage ;;
    -*)             die "unknown option: $1" ;;
    *)              [[ -z "$TARGET" ]] && TARGET="$1" || die "unexpected argument: $1"; shift ;;
  esac
done

[[ -n "$TARGET" ]] || usage
[[ -e "$TARGET" ]] || die "path does not exist: $TARGET"

# Load API key from credentials file if not provided via flag or env
if [[ -z "$API_KEY" && -f "$CREDENTIALS_FILE" ]]; then
  API_KEY=$(cat "$CREDENTIALS_FILE" | tr -d '[:space:]')
fi

BASE_URL="${BASE_URL%/}"
STATE_DIR=".herenow"
STATE_FILE="$STATE_DIR/state.json"

# Auto-load claim token from state file for anonymous updates
if [[ -n "$SLUG" && -z "$CLAIM_TOKEN" && -z "$API_KEY" && -f "$STATE_FILE" ]]; then
  CLAIM_TOKEN=$(jq -r --arg s "$SLUG" '.publishes[$s].claimToken // empty' "$STATE_FILE" 2>/dev/null || true)
fi

guess_content_type() {
  local f="$1"
  case "${f##*.}" in
    html|htm) echo "text/html; charset=utf-8" ;;
    css)      echo "text/css; charset=utf-8" ;;
    js|mjs)   echo "text/javascript; charset=utf-8" ;;
    json)     echo "application/json; charset=utf-8" ;;
    md|txt)   echo "text/plain; charset=utf-8" ;;
    svg)      echo "image/svg+xml" ;;
    png)      echo "image/png" ;;
    jpg|jpeg) echo "image/jpeg" ;;
    gif)      echo "image/gif" ;;
    webp)     echo "image/webp" ;;
    pdf)      echo "application/pdf" ;;
    mp4)      echo "video/mp4" ;;
    mov)      echo "video/quicktime" ;;
    mp3)      echo "audio/mpeg" ;;
    wav)      echo "audio/wav" ;;
    xml)      echo "application/xml" ;;
    woff2)    echo "font/woff2" ;;
    woff)     echo "font/woff" ;;
    ttf)      echo "font/ttf" ;;
    ico)      echo "image/x-icon" ;;
    *)
      local detected
      detected=$(file --brief --mime-type "$f" 2>/dev/null || echo "application/octet-stream")
      echo "$detected"
      ;;
  esac
}

# Build file manifest as JSON array
FILES_JSON="[]"

if [[ -f "$TARGET" ]]; then
  sz=$(wc -c < "$TARGET" | tr -d ' ')
  ct=$(guess_content_type "$TARGET")
  bn=$(basename "$TARGET")
  FILES_JSON=$(jq -n --arg p "$bn" --argjson s "$sz" --arg c "$ct" \
    '[{"path":$p,"size":$s,"contentType":$c}]')
  FILE_MAP=$(jq -n --arg p "$bn" --arg a "$(cd "$(dirname "$TARGET")" && pwd)/$(basename "$TARGET")" \
    '{($p):$a}')
elif [[ -d "$TARGET" ]]; then
  FILE_MAP="{}"
  while IFS= read -r -d '' f; do
    rel="${f#$TARGET/}"
    [[ "$rel" == ".DS_Store" ]] && continue
    [[ "$(basename "$rel")" == ".DS_Store" ]] && continue
    sz=$(wc -c < "$f" | tr -d ' ')
    ct=$(guess_content_type "$f")
    abs=$(cd "$(dirname "$f")" && pwd)/$(basename "$f")
    FILES_JSON=$(echo "$FILES_JSON" | jq --arg p "$rel" --argjson s "$sz" --arg c "$ct" \
      '. + [{"path":$p,"size":$s,"contentType":$c}]')
    FILE_MAP=$(echo "$FILE_MAP" | jq --arg p "$rel" --arg a "$abs" '. + {($p):$a}')
  done < <(find "$TARGET" -type f -print0 | sort -z)
else
  die "not a file or directory: $TARGET"
fi

file_count=$(echo "$FILES_JSON" | jq 'length')
[[ "$file_count" -gt 0 ]] || die "no files found"

# Build request body
BODY=$(echo "$FILES_JSON" | jq '{files: .}')

if [[ -n "$TTL" ]]; then
  BODY=$(echo "$BODY" | jq --argjson t "$TTL" '.ttlSeconds = $t')
fi

if [[ -n "$TITLE" || -n "$DESCRIPTION" ]]; then
  viewer="{}"
  [[ -n "$TITLE" ]] && viewer=$(echo "$viewer" | jq --arg t "$TITLE" '.title = $t')
  [[ -n "$DESCRIPTION" ]] && viewer=$(echo "$viewer" | jq --arg d "$DESCRIPTION" '.description = $d')
  BODY=$(echo "$BODY" | jq --argjson v "$viewer" '.viewer = $v')
fi

if [[ -n "$CLAIM_TOKEN" && -n "$SLUG" && -z "$API_KEY" ]]; then
  BODY=$(echo "$BODY" | jq --arg ct "$CLAIM_TOKEN" '.claimToken = $ct')
fi

# Determine endpoint and method
if [[ -n "$SLUG" ]]; then
  URL="$BASE_URL/api/v1/publish/$SLUG"
  METHOD="PUT"
else
  URL="$BASE_URL/api/v1/publish"
  METHOD="POST"
fi

# Build auth header
AUTH_ARGS=()
if [[ -n "$API_KEY" ]]; then
  AUTH_ARGS=(-H "authorization: Bearer $API_KEY")
fi

# Step 1: Create/update publish
echo "creating publish ($file_count files)..." >&2
RESPONSE=$(curl -sS -X "$METHOD" "$URL" \
  "${AUTH_ARGS[@]+"${AUTH_ARGS[@]}"}" \
  -H "content-type: application/json" \
  -d "$BODY")

# Check for errors
if echo "$RESPONSE" | jq -e '.error' >/dev/null 2>&1; then
  err=$(echo "$RESPONSE" | jq -r '.error')
  details=$(echo "$RESPONSE" | jq -r '.details // empty')
  die "$err${details:+ ($details)}"
fi

OUT_SLUG=$(echo "$RESPONSE" | jq -r '.slug')
VERSION_ID=$(echo "$RESPONSE" | jq -r '.upload.versionId')
FINALIZE_URL=$(echo "$RESPONSE" | jq -r '.upload.finalizeUrl')
SITE_URL=$(echo "$RESPONSE" | jq -r '.siteUrl')
UPLOAD_COUNT=$(echo "$RESPONSE" | jq '.upload.uploads | length')

[[ "$OUT_SLUG" != "null" ]] || die "unexpected response: $RESPONSE"

# Step 2: Upload files in parallel
echo "uploading $UPLOAD_COUNT files..." >&2
upload_errors=0

for i in $(seq 0 $((UPLOAD_COUNT - 1))); do
  upload_path=$(echo "$RESPONSE" | jq -r ".upload.uploads[$i].path")
  upload_url=$(echo "$RESPONSE" | jq -r ".upload.uploads[$i].url")
  upload_ct=$(echo "$RESPONSE" | jq -r ".upload.uploads[$i].headers[\"Content-Type\"] // empty")

  if [[ -f "$TARGET" && ! -d "$TARGET" ]]; then
    local_file="$TARGET"
  else
    local_file=$(echo "$FILE_MAP" | jq -r --arg p "$upload_path" '.[$p]')
  fi

  if [[ ! -f "$local_file" ]]; then
    echo "warning: missing local file for $upload_path" >&2
    upload_errors=$((upload_errors + 1))
    continue
  fi

  ct_args=()
  [[ -n "$upload_ct" ]] && ct_args=(-H "Content-Type: $upload_ct")

  http_code=$(curl -sS -o /dev/null -w "%{http_code}" -X PUT "$upload_url" \
    "${ct_args[@]+"${ct_args[@]}"}" \
    --data-binary "@$local_file")

  if [[ "$http_code" -lt 200 || "$http_code" -ge 300 ]]; then
    echo "warning: upload failed for $upload_path (HTTP $http_code)" >&2
    upload_errors=$((upload_errors + 1))
  fi
done &
wait

[[ "$upload_errors" -eq 0 ]] || die "$upload_errors file(s) failed to upload"

# Step 3: Finalize
echo "finalizing..." >&2
FIN_RESPONSE=$(curl -sS -X POST "$FINALIZE_URL" \
  "${AUTH_ARGS[@]+"${AUTH_ARGS[@]}"}" \
  -H "content-type: application/json" \
  -d "{\"versionId\":\"$VERSION_ID\"}")

if echo "$FIN_RESPONSE" | jq -e '.error' >/dev/null 2>&1; then
  err=$(echo "$FIN_RESPONSE" | jq -r '.error')
  die "finalize failed: $err"
fi

# Save state
mkdir -p "$STATE_DIR"
if [[ -f "$STATE_FILE" ]]; then
  STATE=$(cat "$STATE_FILE")
else
  STATE='{"publishes":{}}'
fi

entry=$(jq -n --arg s "$SITE_URL" '{siteUrl: $s}')

RESPONSE_CLAIM_TOKEN=$(echo "$RESPONSE" | jq -r '.claimToken // empty')
RESPONSE_CLAIM_URL=$(echo "$RESPONSE" | jq -r '.claimUrl // empty')
RESPONSE_EXPIRES=$(echo "$RESPONSE" | jq -r '.expiresAt // empty')

[[ -n "$RESPONSE_CLAIM_TOKEN" ]] && entry=$(echo "$entry" | jq --arg v "$RESPONSE_CLAIM_TOKEN" '.claimToken = $v')
[[ -n "$RESPONSE_CLAIM_URL" ]] && entry=$(echo "$entry" | jq --arg v "$RESPONSE_CLAIM_URL" '.claimUrl = $v')
[[ -n "$RESPONSE_EXPIRES" ]] && entry=$(echo "$entry" | jq --arg v "$RESPONSE_EXPIRES" '.expiresAt = $v')

STATE=$(echo "$STATE" | jq --arg slug "$OUT_SLUG" --argjson e "$entry" '.publishes[$slug] = $e')
echo "$STATE" | jq '.' > "$STATE_FILE"

# Output
echo "$SITE_URL"

if [[ -n "$RESPONSE_CLAIM_TOKEN" ]]; then
  echo "" >&2
  echo "anonymous publish (expires in 24h)" >&2
  echo "claim URL: $RESPONSE_CLAIM_URL" >&2
  echo "claim token saved to $STATE_FILE" >&2
fi
