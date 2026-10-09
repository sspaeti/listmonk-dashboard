-- (campaign, day, type, count) from raw events. 'first_opens' = each subscriber once on their first-open
-- day (+1 group for anonymous views), which is exactly what listmonk's Analytics page charts as views.
WITH c AS (
  SELECT id AS campaign_id, to_char(started_at, 'YYYY-MM-DD') || ' · ' || subject AS campaign_label
  FROM campaigns WHERE type = 'regular'
),
long AS (
  SELECT campaign_id, date_trunc('day', created_at)::date AS day, 'views' AS type, count(*) AS count
  FROM campaign_views GROUP BY 1, 2
  UNION ALL
  SELECT campaign_id, date_trunc('day', first_view)::date, 'first_opens', count(*)
  FROM (SELECT campaign_id, subscriber_id, min(created_at) AS first_view FROM campaign_views GROUP BY 1, 2) x
  GROUP BY 1, 2
  UNION ALL
  SELECT campaign_id, date_trunc('day', created_at)::date, 'clicks', count(*) FROM link_clicks GROUP BY 1, 2
  UNION ALL
  SELECT campaign_id, date_trunc('day', created_at)::date, 'bounces', count(*) FROM bounces WHERE campaign_id IS NOT NULL GROUP BY 1, 2
)
SELECT l.campaign_id, c.campaign_label, l.day, l.type, l.count
FROM long l JOIN c ON c.campaign_id = l.campaign_id
