-- Bounce events with campaign label and the subscriber's current status.
SELECT b.id, b.subscriber_id, b.campaign_id,
  coalesce(to_char(c.started_at, 'YYYY-MM-DD') || ' · ' || c.subject, 'no campaign') AS campaign_label,
  b.type::text AS type, b.source, b.created_at AS bounced_at, s.status::text AS subscriber_status_now
FROM bounces b
LEFT JOIN campaigns c ON c.id = b.campaign_id
LEFT JOIN subscribers s ON s.id = b.subscriber_id
