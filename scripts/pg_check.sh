#!/usr/bin/env bash
# Connectivity check: attach the listmonk Postgres via the DuckDB postgres extension and print
# table row counts. Uses the same credentials as the Rill models. Prints no secrets.
set -euo pipefail
cd "$(dirname "$0")/.."
. scripts/lib.sh; load_env .env
export PGPASSWORD="$LISTMONK_PGPASSWORD" PGHOST="$LISTMONK_PG_HOST" \
       PGPORT="$LISTMONK_PORT" PGUSER="$LISTMONK_USER" PGDATABASE="$LISTMONK_DATABASE"
duckdb -c "
INSTALL postgres; LOAD postgres;
ATTACH '' AS lm (TYPE postgres, READ_ONLY);
SELECT 'campaigns' AS tbl, count(*) AS rows FROM lm.public.campaigns
UNION ALL SELECT 'campaign_views', count(*) FROM lm.public.campaign_views
UNION ALL SELECT 'link_clicks', count(*) FROM lm.public.link_clicks
UNION ALL SELECT 'bounces', count(*) FROM lm.public.bounces
UNION ALL SELECT 'subscribers', count(*) FROM lm.public.subscribers
UNION ALL SELECT 'subscriber_lists', count(*) FROM lm.public.subscriber_lists
UNION ALL SELECT 'lists', count(*) FROM lm.public.lists;
"
