#!/usr/bin/env bash
# Sanity checks against the running local Rill instance (`make start`).
#  1. For every campaign: unique_openers <= sent and the first-open buckets sum to unique_openers
#  2. Campaigns with views but no per-subscriber data are flagged "unique n/a", not 0 %
#  3. Optional: CAMPAIGN_ID=<id> EXPECTED_VIEWS=<n> compares the campaign's first-open count with the
#     number listmonk's Analytics page shows for it (listmonk counts each subscriber once, on their
#     first-open day).
set -euo pipefail
cd "$(dirname "$0")/.."
q() { rill query --local --format csv --sql "$1"; }

echo "## 1. violations (expect 0 rows)"
q "SELECT campaign_id, sent, unique_openers, first_open_0_2m + first_open_2_10m + first_open_10_60m + first_open_1_24h + first_open_24h_plus AS bucket_sum
   FROM campaign_summary WHERE unique_openers > sent OR bucket_sum <> unique_openers"

echo "## 2. tracking status per campaign"
q "SELECT tracking_status, count(*) AS campaigns, sum(total_views) AS views FROM campaign_summary GROUP BY 1 ORDER BY 1"

if [ -n "${CAMPAIGN_ID:-}" ]; then
  echo "## 3. campaign ${CAMPAIGN_ID}: listmonk Analytics-page views vs raw first opens (expected ${EXPECTED_VIEWS:-?})"
  q "SELECT api_daily_views_sum AS listmonk_analytics_views, raw_first_opens_sum, unique_openers, total_views FROM campaign_summary WHERE campaign_id = ${CAMPAIGN_ID}"
fi

echo "## tracked campaigns"
q "SELECT campaign_id, left(subject, 40) AS subject, sent, api_views, unique_openers, early_openers, round(open_rate, 3) AS open_rate, round(open_rate_excl_early, 3) AS open_rate_excl_early FROM campaign_summary WHERE tracking_status = 'tracked' ORDER BY started_at DESC"
