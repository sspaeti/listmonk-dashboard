---
title: List Overlap (list A vs list B)
sidebar_position: 4
---

# List A vs list B

Compares two lists (ids set in `queries/subscriber_segments.sql` and `queries/segment_timeline.sql`). "In a list" = confirmed subscription and subscriber enabled. Typical use: list A is your main newsletter, list B a product list, and you want everyone on B to also be on A, except people who unsubscribed from A.

{% row %}
  {% big_value data="/queries/subscriber_segments" value="count(*) filter (where in_list_a)" title="In list A" fmt="num0" /%}
  {% big_value data="/queries/subscriber_segments" value="count(*) filter (where in_list_b)" title="In list B" fmt="num0" /%}
  {% big_value data="/queries/subscriber_segments" value="count(*) filter (where in_list_a and in_list_b)" title="In both" fmt="num0" /%}
  {% big_value data="/queries/subscriber_segments" value="count(*) filter (where in_list_a and not in_list_b)" title="List A only" fmt="num0" /%}
  {% big_value data="/queries/subscriber_segments" value="count(*) filter (where in_list_b and not in_list_a)" title="List B only" fmt="num0" /%}
  {% big_value data="/queries/subscriber_segments" value="count(*) filter (where in_list_a and in_list_b)::numeric / nullif(count(*) filter (where in_list_b), 0)" title="Share of list B also in list A" fmt="pct1" /%}
{% /row %}

{% row %}
  {% big_value data="/queries/subscriber_segments" value="count(*) filter (where list_a_candidate)" title="List-B-only, never on list A (candidates)" fmt="num0" /%}
  {% big_value data="/queries/subscriber_segments" value="count(*) filter (where list_b_only_unsubscribed_list_a)" title="List-B-only, unsubscribed from list A (leave alone)" fmt="num0" /%}
{% /row %}

{% row %}
  {% pie_chart data="/queries/subscriber_segments" category="segment" value="count(*)" title="Current segments" legend=true /%}
  {% table data="/queries/subscriber_segments" title="Why is someone not in both? List A status × List B status" subtitle="'not on list' = never added." %}
    {% dimension value="list_a_status" title="List A status" /%}
    {% pivot value="list_b_status" /%}
    {% measure value="count(*)" title="Subscribers" fmt="num0" /%}
  {% /table %}
{% /row %}

## Over time

{% row %}
  {% area_chart data="/queries/segment_timeline" x="month" y="sum(subscribers)" series="segment" title="Subscribers per segment at month end" subtitle="Active subscriptions as of each month end; unsubscribes are back-dated via their last status change." /%}
  {% bar_chart data="/queries/subscriber_segments" x="first_subscribed_at" y="count(*)" series="segment" date_grain="month" stacked=true title="Current segment by month of first subscription" subtitle="Cohorts: where did people who joined in a given month end up today?" /%}
{% /row %}

{% row %}
  {% line_chart data="/queries/segment_timeline" x="month" y="sum(subscribers)" where="segment = 'List B only'" title="List B only over time" /%}
  {% line_chart data="/queries/segment_timeline" x="month" y="sum(subscribers)" where="segment = 'Both lists'" title="Both lists over time" /%}
{% /row %}

{% callout type="info" title="How to add the candidates in listmonk" %}
Subscribers → Advanced query, paste the query below with your list ids (B = source, A = target), select all → Manage lists → Add to list A. It matches enabled subscribers confirmed on list B who were **never** on list A, so opt-outs stay out.

```
subscribers.status = 'enabled'
AND EXISTS (SELECT 1 FROM subscriber_lists sl WHERE sl.subscriber_id = subscribers.id AND sl.list_id = LIST_B_ID AND sl.status = 'confirmed')
AND NOT EXISTS (SELECT 1 FROM subscriber_lists sl WHERE sl.subscriber_id = subscribers.id AND sl.list_id = LIST_A_ID)
```
{% /callout %}
