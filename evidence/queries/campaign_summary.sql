-- Per campaign: listmonk's totals, raw-event totals, unique openers, early vs later openers,
-- rates comparable to other newsletter tools and first-open buckets. Rates are NULL without per-subscriber tracking.
WITH c AS (
  SELECT c.id AS campaign_id, c.subject, c.name AS listmonk_name,
         to_char(c.started_at, 'YYYY-MM-DD') || ' · ' || c.subject AS campaign_label,
         c.started_at, c.sent,
         CASE WHEN c.started_at = max(c.started_at) OVER () THEN 'yes' ELSE 'no' END AS is_latest
  FROM campaigns c
  WHERE c.started_at IS NOT NULL AND c.type = 'regular' AND c.sent > 0
    AND c.status IN ('finished', 'running', 'paused')
),
per_sub AS (
  SELECT v.campaign_id, v.subscriber_id,
         min(v.created_at) AS first_view_at, max(v.created_at) AS last_view_at, count(*) AS n_views
  FROM campaign_views v WHERE v.subscriber_id IS NOT NULL GROUP BY 1, 2
),
s AS (
  SELECT p.campaign_id,
         count(*) AS unique_openers,
         count(*) FILTER (WHERE p.last_view_at < c.started_at + interval '2 minutes') AS early_openers,
         count(*) FILTER (WHERE p.first_view_at < c.started_at + interval '2 minutes')  AS first_open_0_2m,
         count(*) FILTER (WHERE p.first_view_at >= c.started_at + interval '2 minutes'  AND p.first_view_at < c.started_at + interval '10 minutes') AS first_open_2_10m,
         count(*) FILTER (WHERE p.first_view_at >= c.started_at + interval '10 minutes' AND p.first_view_at < c.started_at + interval '60 minutes') AS first_open_10_60m,
         count(*) FILTER (WHERE p.first_view_at >= c.started_at + interval '60 minutes' AND p.first_view_at < c.started_at + interval '24 hours')   AS first_open_1_24h,
         count(*) FILTER (WHERE p.first_view_at >= c.started_at + interval '24 hours') AS first_open_24h_plus,
         percentile_cont(0.5) WITHIN GROUP (ORDER BY extract(epoch FROM p.first_view_at - c.started_at) / 60.0) AS median_minutes_to_first_open
  FROM per_sub p JOIN c ON c.campaign_id = p.campaign_id
  GROUP BY 1
),
raw_views AS (
  SELECT campaign_id, count(*) AS total_views, count(*) FILTER (WHERE subscriber_id IS NULL) AS anonymous_views
  FROM campaign_views GROUP BY 1
),
first_opens AS (
  SELECT campaign_id, count(*) AS raw_first_opens_sum
  FROM (SELECT campaign_id, subscriber_id FROM campaign_views GROUP BY 1, 2) x GROUP BY 1
),
clicks AS (
  SELECT campaign_id, count(*) AS total_clicks, count(DISTINCT subscriber_id) AS unique_clickers FROM link_clicks GROUP BY 1
),
bounces AS (
  SELECT campaign_id, count(*) AS bounces, count(*) FILTER (WHERE type = 'hard') AS hard_bounces FROM bounces GROUP BY 1
),
base AS (
  SELECT c.*,
         coalesce(rv.total_views, 0) AS total_views,
         coalesce(rv.anonymous_views, 0) AS anonymous_views,
         coalesce(s.unique_openers, 0) AS unique_openers,
         coalesce(s.early_openers, 0) AS early_openers,
         coalesce(s.unique_openers, 0) - coalesce(s.early_openers, 0) AS later_openers,
         coalesce(k.unique_clickers, 0) AS unique_clickers,
         coalesce(k.total_clicks, 0) AS total_clicks,
         coalesce(b.bounces, 0) AS bounces,
         coalesce(b.hard_bounces, 0) AS hard_bounces,
         fo.raw_first_opens_sum,
         coalesce(s.first_open_0_2m, 0) AS first_open_0_2m,
         coalesce(s.first_open_2_10m, 0) AS first_open_2_10m,
         coalesce(s.first_open_10_60m, 0) AS first_open_10_60m,
         coalesce(s.first_open_1_24h, 0) AS first_open_1_24h,
         coalesce(s.first_open_24h_plus, 0) AS first_open_24h_plus,
         s.median_minutes_to_first_open
  FROM c
  LEFT JOIN s  ON s.campaign_id  = c.campaign_id
  LEFT JOIN raw_views rv ON rv.campaign_id = c.campaign_id
  LEFT JOIN first_opens fo ON fo.campaign_id = c.campaign_id
  LEFT JOIN clicks k ON k.campaign_id = c.campaign_id
  LEFT JOIN bounces b ON b.campaign_id = c.campaign_id
),
flagged AS (
  SELECT *,
         CASE WHEN total_views = 0 THEN 'no tracking data'
              WHEN unique_openers = 0 THEN 'unique n/a'
              ELSE 'tracked' END AS tracking_status
  FROM base
)
SELECT *,
       CASE WHEN tracking_status = 'tracked' THEN unique_openers::numeric / sent END AS open_rate,
       CASE WHEN tracking_status = 'tracked' THEN later_openers::numeric / sent END AS open_rate_excl_early,
       CASE WHEN tracking_status = 'tracked' THEN unique_clickers::numeric / sent END AS click_rate,
       CASE WHEN unique_openers > 0 THEN unique_clickers::numeric / unique_openers END AS ctor,
       CASE WHEN unique_openers > 0 THEN total_views::numeric / unique_openers END AS views_per_opener,
       CASE WHEN unique_openers > 0 THEN early_openers::numeric / unique_openers END AS early_share,
       bounces::numeric / sent AS bounce_rate,
       CASE WHEN tracking_status = 'tracked'
             AND started_at = max(CASE WHEN tracking_status = 'tracked' THEN started_at END) OVER ()
            THEN 'yes' ELSE 'no' END AS is_latest_tracked
FROM flagged
ORDER BY started_at DESC
