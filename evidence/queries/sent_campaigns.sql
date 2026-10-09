-- One row per sent regular campaign (opt-in confirmation campaigns excluded), labelled by subject.
SELECT
  c.id AS campaign_id,
  c.subject,
  c.name AS listmonk_name,
  to_char(c.started_at, 'YYYY-MM-DD') || ' · ' || c.subject AS campaign_label,
  c.status::text AS status,
  c.started_at,
  c.to_send,
  c.sent,
  coalesce((SELECT string_agg(cl.list_name, ', ' ORDER BY cl.list_name) FROM campaign_lists cl WHERE cl.campaign_id = c.id), '') AS list_names,
  CASE WHEN c.started_at = max(c.started_at) OVER () THEN 'yes' ELSE 'no' END AS is_latest
FROM campaigns c
WHERE c.started_at IS NOT NULL
  AND c.type = 'regular'
  AND c.sent > 0
  AND c.status IN ('finished', 'running', 'paused')
