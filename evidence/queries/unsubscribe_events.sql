-- One row per unsubscribed list membership, attributed to the most recent campaign sent to that list
-- within 3 days before the unsubscribe; otherwise 'organic'.
WITH u AS (
  SELECT sl.subscriber_id, sl.list_id, l.name AS list_name, sl.created_at AS subscribed_at, sl.updated_at AS unsubscribed_at
  FROM subscriber_lists sl JOIN lists l ON l.id = sl.list_id
  WHERE sl.status = 'unsubscribed' AND sl.updated_at IS NOT NULL
),
c AS (
  SELECT id AS campaign_id, to_char(started_at, 'YYYY-MM-DD') || ' · ' || subject AS campaign_label, started_at
  FROM campaigns WHERE started_at IS NOT NULL AND type = 'regular' AND sent > 0 AND status IN ('finished', 'running', 'paused')
),
candidates AS (
  SELECT u.subscriber_id, u.list_id, c.campaign_id, c.campaign_label, c.started_at,
         row_number() OVER (PARTITION BY u.subscriber_id, u.list_id ORDER BY c.started_at DESC) AS rn
  FROM u
  JOIN campaign_lists cl ON cl.list_id = u.list_id
  JOIN c ON c.campaign_id = cl.campaign_id
   AND u.unsubscribed_at >= c.started_at AND u.unsubscribed_at < c.started_at + interval '3 days'
)
SELECT
  u.subscriber_id, u.list_id, u.list_name, u.subscribed_at, u.unsubscribed_at,
  extract(day FROM u.unsubscribed_at - u.subscribed_at)::int AS days_subscribed,
  CASE WHEN c.campaign_id IS NULL THEN 'organic' ELSE 'after campaign' END AS attribution,
  c.campaign_id AS attributed_campaign_id,
  coalesce(c.campaign_label, 'organic / unknown') AS attributed_campaign_label,
  extract(epoch FROM u.unsubscribed_at - c.started_at) / 3600.0 AS hours_after_send,
  CASE WHEN u.unsubscribed_at - u.subscribed_at < interval '7 days' THEN '0 < 1 week'
       WHEN u.unsubscribed_at - u.subscribed_at < interval '30 days' THEN '1 < 1 month'
       WHEN u.unsubscribed_at - u.subscribed_at < interval '180 days' THEN '2 1-6 months'
       WHEN u.unsubscribed_at - u.subscribed_at < interval '365 days' THEN '3 6-12 months'
       ELSE '4 > 1 year' END AS tenure_bucket
FROM u
LEFT JOIN candidates c ON c.subscriber_id = u.subscriber_id AND c.list_id = u.list_id AND c.rn = 1
