-- Month-end snapshots of subscribers per list-overlap segment. CHANGE THE LIST IDS (2 and 4) to yours. A subscription counts as active from
-- its creation until its status left 'confirmed' (approximated by updated_at).
WITH s AS (
  SELECT subscriber_id, list_id, status::text AS subscription_status, created_at AS subscribed_at, updated_at AS status_changed_at
  FROM subscriber_lists WHERE list_id IN (2, 4)
),
months AS (
  SELECT generate_series(date_trunc('month', (SELECT min(subscribed_at) FROM s)), date_trunc('month', now()), interval '1 month') AS month
),
state AS (
  SELECT m.month, s.subscriber_id,
    bool_or(s.list_id = 2 AND (s.subscription_status = 'confirmed' OR s.status_changed_at >= m.month + interval '1 month')) AS in_list_a,
    bool_or(s.list_id = 4 AND (s.subscription_status = 'confirmed' OR s.status_changed_at >= m.month + interval '1 month')) AS in_list_b
  FROM months m JOIN s ON s.subscribed_at < m.month + interval '1 month'
  GROUP BY 1, 2
)
SELECT month::date AS month,
  CASE WHEN in_list_a AND in_list_b THEN 'Both lists'
       WHEN in_list_a THEN 'List A only'
       WHEN in_list_b THEN 'List B only'
       ELSE 'Neither' END AS segment,
  count(*) AS subscribers
FROM state GROUP BY 1, 2
