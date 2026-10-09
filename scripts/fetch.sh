#!/usr/bin/env bash
# Fetch what listmonk itself reports (campaign totals + daily analytics) via the REST API into data/.
# Rill reads these JSON files with DuckDB read_json and reconciles them against the raw Postgres tables.
#
# Idempotent: files are built in a temp dir and atomically moved into place. Safe to run daily via cron.
#
# Required .env keys: LM_URL, LM_USER, LM_TOKEN  (read-only listmonk API user)
# Optional env:       RATE_SLEEP (default 0.2) seconds between per-campaign calls (~5 req/s)
#
# NOTE: the analytics endpoint accepts several `id` params at once, but then returns wrong per-campaign
# numbers (verified: campaign 109 drops from 1414 to 672 views). Always query one campaign per call.
set -euo pipefail
cd "$(dirname "$0")/.."
. scripts/lib.sh
load_env .env

: "${LM_URL:?missing in .env}" "${LM_USER:?missing in .env}" "${LM_TOKEN:?missing in .env}"
RATE_SLEEP="${RATE_SLEEP:-0.2}"

DATA=data
mkdir -p "$DATA"
TMP="$(mktemp -d "${DATA}/.tmp.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

log() { printf '%s %s\n' "$(date +%T)" "$*" >&2; }

# GET helper: fails loudly if listmonk returns an error instead of data.
api() {
  local out
  out="$(lm -G "$LM_URL/api/$1" "${@:2}")"
  if [ "$(jq -r '.data // empty' <<<"$out")" = "" ] && [ "$(jq -r '.message // empty' <<<"$out")" != "" ]; then
    log "API error on $1: $(jq -r .message <<<"$out")"; return 1
  fi
  printf '%s' "$out"
}

# ---------------------------------------------------------------- 1. campaigns (metadata + listmonk's totals)
log "campaigns"
api campaigns --data-urlencode per_page=all --data-urlencode no_body=true \
  | jq '.data.results' > "$TMP/campaigns.json"
log "  $(jq length "$TMP/campaigns.json") campaigns"

FROM="$(jq -r '[.[] | select(.started_at != null) | .started_at] | min | .[0:10]' "$TMP/campaigns.json")"
TO="$(date -u -d '+1 day' +%F)"
log "  analytics window $FROM .. $TO"

# ---------------------------------------------------------------- 2. daily analytics + per-link clicks, one call per campaign
for t in views clicks bounces links; do : > "$TMP/$t.ndjson"; done

while IFS= read -r id; do
  for t in views clicks bounces; do
    api "campaigns/analytics/$t" --data-urlencode "id=$id" \
      --data-urlencode "from=$FROM" --data-urlencode "to=$TO" \
      | jq -c '.data[]' >> "$TMP/$t.ndjson"
  done
  api campaigns/analytics/links --data-urlencode "id=$id" \
    --data-urlencode "from=$FROM" --data-urlencode "to=$TO" \
    | jq -c --argjson cid "$id" '.data[] | . + {campaign_id: $cid}' >> "$TMP/links.ndjson"
  sleep "$RATE_SLEEP"
done < <(jq -r '.[].id' "$TMP/campaigns.json")

for t in views clicks bounces; do
  jq -s '.' "$TMP/$t.ndjson" > "$TMP/daily_$t.json"
  log "  daily $t: $(wc -l < "$TMP/$t.ndjson") rows"
done
jq -s '.' "$TMP/links.ndjson" > "$TMP/links.json"
log "  links: $(wc -l < "$TMP/links.ndjson") rows"

# ---------------------------------------------------------------- 3. lists (listmonk's subscriber counts per list)
log "lists"
api lists --data-urlencode per_page=all | jq '.data.results' > "$TMP/lists.json"

# ---------------------------------------------------------------- publish atomically
for f in campaigns.json daily_views.json daily_clicks.json daily_bounces.json links.json lists.json; do
  mv -f "$TMP/$f" "$DATA/$f"
done
log "done -> $DATA/"
