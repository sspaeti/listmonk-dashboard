-- One row per subscriber: membership in list A and list B. CHANGE THE TWO LIST IDS BELOW (2 and 4) to
-- your own listmonk list ids. "In" a list = confirmed subscription AND subscriber enabled.
-- list_a_candidate = in list B, never on list A (so not an opt-out).
WITH per_sub AS (
  SELECT
    sl.subscriber_id,
    max(s.status::text) AS subscriber_status,
    max(CASE WHEN sl.list_id = 2 THEN sl.status::text END) AS list_a_subscription,
    max(CASE WHEN sl.list_id = 4 THEN sl.status::text END) AS list_b_subscription,
    min(sl.created_at) AS first_subscribed_at
  FROM subscriber_lists sl JOIN subscribers s ON s.id = sl.subscriber_id
  GROUP BY 1
),
flagged AS (
  SELECT *,
    CASE WHEN subscriber_status <> 'enabled' THEN subscriber_status ELSE coalesce(list_a_subscription, 'not on list') END AS list_a_status,
    CASE WHEN subscriber_status <> 'enabled' THEN subscriber_status ELSE coalesce(list_b_subscription, 'not on list') END AS list_b_status,
    coalesce(subscriber_status = 'enabled' AND list_a_subscription = 'confirmed', false) AS in_list_a,
    coalesce(subscriber_status = 'enabled' AND list_b_subscription = 'confirmed', false) AS in_list_b
  FROM per_sub
)
SELECT *,
  CASE WHEN in_list_a AND in_list_b THEN 'Both lists'
       WHEN in_list_a THEN 'List A only'
       WHEN in_list_b THEN 'List B only'
       WHEN subscriber_status <> 'enabled' THEN 'Blocklisted / disabled'
       ELSE 'Neither (unsubscribed or unconfirmed)' END AS segment,
  (in_list_b AND NOT in_list_a AND list_a_subscription IS NULL) AS list_a_candidate,
  (in_list_b AND NOT in_list_a AND list_a_subscription = 'unsubscribed') AS list_b_only_unsubscribed_list_a
FROM flagged
