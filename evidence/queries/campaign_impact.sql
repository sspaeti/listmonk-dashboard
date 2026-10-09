-- Per campaign: unsubscribes within 3 days after the send (on its lists), subscribers blocklisted by its
-- hard bounces/complaints, bounces by type, list-loss rate. Works for every campaign.
WITH c AS (
  SELECT id AS campaign_id, subject, to_char(started_at, 'YYYY-MM-DD') || ' · ' || subject AS campaign_label, started_at, sent,
         CASE WHEN started_at = max(started_at) OVER () THEN 'yes' ELSE 'no' END AS is_latest
  FROM campaigns WHERE started_at IS NOT NULL AND type = 'regular' AND sent > 0 AND status IN ('finished', 'running', 'paused')
),
unsubs AS (
  SELECT campaign_id, count(DISTINCT subscriber_id) AS unsubscribes FROM (
    SELECT sl.subscriber_id, c.campaign_id,
           row_number() OVER (PARTITION BY sl.subscriber_id, sl.list_id ORDER BY c.started_at DESC) AS rn
    FROM subscriber_lists sl
    JOIN campaign_lists cl ON cl.list_id = sl.list_id
    JOIN c ON c.campaign_id = cl.campaign_id
     AND sl.updated_at >= c.started_at AND sl.updated_at < c.started_at + interval '3 days'
    WHERE sl.status = 'unsubscribed'
  ) x WHERE rn = 1 GROUP BY 1
),
bl AS (
  SELECT b.campaign_id, count(DISTINCT b.subscriber_id) AS blocklisted
  FROM bounces b JOIN subscribers s ON s.id = b.subscriber_id AND s.status = 'blocklisted'
  WHERE b.type IN ('hard', 'complaint') GROUP BY 1
),
b AS (
  SELECT campaign_id, count(*) AS bounces,
         count(*) FILTER (WHERE type = 'hard') AS hard_bounces,
         count(*) FILTER (WHERE type = 'soft') AS soft_bounces,
         count(*) FILTER (WHERE type = 'complaint') AS complaints
  FROM bounces GROUP BY 1
),
base AS (
  SELECT c.*, coalesce(u.unsubscribes, 0) AS unsubscribes, coalesce(bl.blocklisted, 0) AS blocklisted,
         coalesce(b.bounces, 0) AS bounces, coalesce(b.hard_bounces, 0) AS hard_bounces,
         coalesce(b.soft_bounces, 0) AS soft_bounces, coalesce(b.complaints, 0) AS complaints
  FROM c LEFT JOIN unsubs u ON u.campaign_id = c.campaign_id
  LEFT JOIN bl ON bl.campaign_id = c.campaign_id
  LEFT JOIN b ON b.campaign_id = c.campaign_id
)
SELECT *,
  unsubscribes::numeric / sent AS unsubscribe_rate,
  bounces::numeric / sent AS bounce_rate,
  hard_bounces::numeric / sent AS hard_bounce_rate,
  unsubscribes + blocklisted AS list_loss,
  (unsubscribes + blocklisted)::numeric / sent AS list_loss_rate
FROM base
