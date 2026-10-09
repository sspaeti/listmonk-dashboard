-- One row per (campaign, subscriber) that opened: first/last open, open count, minutes to first open,
-- first-open bucket and early/later flag. Early = every view within 2 minutes of the campaign start
-- (prefetcher or instant open; listmonk stores no user agent to tell them apart).
WITH c AS (
  SELECT id AS campaign_id, subject, to_char(started_at, 'YYYY-MM-DD') || ' · ' || subject AS campaign_label, started_at
  FROM campaigns
  WHERE started_at IS NOT NULL AND type = 'regular' AND sent > 0 AND status IN ('finished', 'running', 'paused')
),
v AS (
  SELECT campaign_id, subscriber_id, min(created_at) AS first_view_at, max(created_at) AS last_view_at, count(*) AS n_views
  FROM campaign_views WHERE subscriber_id IS NOT NULL GROUP BY 1, 2
)
SELECT
  c.campaign_id, c.campaign_label, c.started_at, v.subscriber_id, v.first_view_at, v.last_view_at, v.n_views,
  extract(epoch FROM v.first_view_at - c.started_at) / 60.0 AS minutes_to_first_open,
  CASE
    WHEN v.first_view_at < c.started_at + interval '2 minutes'  THEN '0-2 min'
    WHEN v.first_view_at < c.started_at + interval '10 minutes' THEN '2-10 min'
    WHEN v.first_view_at < c.started_at + interval '60 minutes' THEN '10-60 min'
    WHEN v.first_view_at < c.started_at + interval '24 hours'   THEN '1-24 h'
    ELSE '> 24 h' END AS first_open_bucket,
  CASE WHEN v.last_view_at < c.started_at + interval '2 minutes' THEN 'early' ELSE 'later' END AS opener_kind,
  CASE WHEN v.first_view_at < c.started_at THEN '<0'
       WHEN v.first_view_at < c.started_at + interval '60 minutes'
         THEN lpad(floor(extract(epoch FROM v.first_view_at - c.started_at) / 60)::int::text, 2, '0')
       ELSE '60+' END AS first_open_minute,
  CASE WHEN v.first_view_at < c.started_at THEN '<0'
       WHEN v.first_view_at < c.started_at + interval '48 hours'
         THEN lpad(floor(extract(epoch FROM v.first_view_at - c.started_at) / 3600)::int::text, 2, '0')
       ELSE '48+' END AS first_open_hour
FROM v JOIN c ON c.campaign_id = v.campaign_id
