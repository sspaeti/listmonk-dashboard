---
title: Newsletter Health
sidebar_position: 1
---

# Newsletter health

Queried live from listmonk's Postgres. Open rate = unique openers / sent, the "opened %" other newsletter tools report. Open rates exist only for campaigns with open tracking (see [Campaign Analytics](/campaign-analytics)); lists and growth are in [Lists & Subscribers](/lists-subscribers).

## Latest campaign

{% row %}
  {% big_value data="/queries/campaign_summary" value="max(sent)" title="Sent" fmt="num0" where="is_latest = 'yes'" /%}
  {% big_value data="/queries/campaign_summary" value="max(unique_openers)" title="Unique openers" fmt="num0" where="is_latest = 'yes'" /%}
  {% big_value data="/queries/campaign_summary" value="max(open_rate)" title="Open rate" fmt="pct1" where="is_latest = 'yes'" /%}
  {% big_value data="/queries/campaign_summary" value="max(open_rate_excl_early)" title="Open rate excl. early" fmt="pct1" where="is_latest = 'yes'" /%}
  {% big_value data="/queries/campaign_summary" value="max(bounces)" title="Bounces" fmt="num0" where="is_latest = 'yes'" /%}
{% /row %}

## List health

{% row %}
  {% big_value data="/queries/list_health" value="max(reachable)" title="Reachable (enabled + confirmed)" fmt="num0" /%}
  {% big_value data="/queries/list_health" value="max(enabled)" title="Enabled" fmt="num0" /%}
  {% big_value data="/queries/list_health" value="max(blocklisted)" title="Blocklisted" fmt="num0" /%}
  {% big_value data="/queries/list_health" value="max(dead_weight)" title="Dead weight (no open in tracked campaigns)" fmt="num0" /%}
{% /row %}

## All regular campaigns

{% dropdown id="tracking" data="/queries/campaign_summary" value_column="tracking_status" title="Tracking" clear=true /%}

{% table data="/queries/campaign_summary" filters=["tracking"] page_size=100 search=true %}
  {% dimension value="campaign_label" title="Campaign" sort="desc" /%}
  {% dimension value="tracking_status" title="Tracking" /%}
  {% measure value="max(sent)" title="Sent" fmt="num0" /%}
  {% measure value="max(total_views)" title="Views (all pixel loads)" fmt="num0" /%}
  {% measure value="max(unique_openers)" title="Unique openers" fmt="num0" /%}
  {% measure value="max(open_rate)" title="Open rate" fmt="pct1" /%}
  {% measure value="max(bounces)" title="Bounces" fmt="num0" /%}
  {% measure value="max(hard_bounces)" title="Hard" fmt="num0" /%}
  {% measure value="max(bounce_rate)" title="Bounce rate" fmt="pct2" /%}
{% /table %}

{% bar_chart data="/queries/campaign_summary" x="campaign_label" y=["max(sent)", "max(bounces)"] title="Sent and bounces per campaign" x_sort="asc" y_fmt="num0" height=360 /%}

## Reconciliation: listmonk's numbers vs raw events

Listmonk's campaign list counts every pixel load (*Views*). Its Analytics page counts each subscriber once on their first-open day plus one group for anonymous views (*First opens*). *Unique openers* is what the rates use.

{% table data="/queries/campaign_summary" where="tracking_status <> 'no tracking data'" %}
  {% dimension value="campaign_label" title="Campaign" sort="desc" /%}
  {% measure value="max(total_views)" title="Views (listmonk list)" fmt="num0" /%}
  {% measure value="max(anonymous_views)" title="Anonymous views" fmt="num0" /%}
  {% measure value="max(raw_first_opens_sum)" title="First opens (Analytics page)" fmt="num0" /%}
  {% measure value="max(unique_openers)" title="Unique openers" fmt="num0" /%}
  {% measure value="max(total_clicks)" title="Clicks" fmt="num0" /%}
  {% measure value="max(bounces)" title="Bounces" fmt="num0" /%}
{% /table %}

{% callout type="info" title="Known limitations" %}
- **"Early" is not bot detection.** An early opener had every view within 2 minutes of campaign start: Apple Mail prefetch, a scanner, or a person on a notification. Listmonk stores no user agent, so read *open rate excl. early* as a lower bound. Sends take ~10 minutes, and `started_at` is the campaign start, not each recipient's send time.
- **Pixel opens lie in both directions.** Privacy prefetch and scanners inflate them; blocked images and spam folders hide real reads. Click tracking has never recorded an event on this instance.
- **Per-subscriber events exist only since 2026-08-06.** Earlier campaigns show totals but no unique openers, so their rates stay blank rather than 0 %.
- **Opt-in confirmation campaigns are excluded** everywhere (campaign type `optin`).
{% /callout %}
