-- One row per (subscriber, list) membership. No personal data.
SELECT
  sl.subscriber_id,
  l.id AS list_id,
  l.name AS list_name,
  l.type::text AS list_type,
  sl.status::text AS subscription_status,
  s.status::text AS subscriber_status,
  sl.created_at AS subscribed_at,
  sl.updated_at AS status_changed_at,
  (s.status = 'enabled' AND sl.status = 'confirmed') AS reachable
FROM subscriber_lists sl
JOIN lists l ON l.id = sl.list_id
JOIN subscribers s ON s.id = sl.subscriber_id
