-- One snapshot row. Dead weight = enabled subscribers with no open in the last 10 campaigns that have
-- tracking data. Reachable = enabled + confirmed on at least one list (the number published on the blog).
WITH tracked AS (
  SELECT campaign_id FROM campaign_views GROUP BY 1 ORDER BY max(created_at) DESC LIMIT 10
),
viewed AS (
  SELECT DISTINCT subscriber_id FROM campaign_views WHERE subscriber_id IS NOT NULL AND campaign_id IN (SELECT campaign_id FROM tracked)
)
SELECT
  now() AS snapshot_at,
  count(*) AS total_subscribers,
  count(*) FILTER (WHERE status = 'enabled') AS enabled,
  count(*) FILTER (WHERE status = 'disabled') AS disabled,
  count(*) FILTER (WHERE status = 'blocklisted') AS blocklisted,
  (SELECT count(DISTINCT subscriber_id) FROM subscriber_lists sl JOIN subscribers s2 ON s2.id = sl.subscriber_id
    WHERE s2.status = 'enabled' AND sl.status = 'confirmed') AS reachable,
  count(*) FILTER (WHERE status = 'enabled' AND id NOT IN (SELECT subscriber_id FROM viewed)) AS dead_weight,
  (SELECT count(*) FROM tracked) AS tracked_campaigns_considered
FROM subscribers
