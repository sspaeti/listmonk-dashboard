---
title: Campaign Analytics (tracked only)
sidebar_position: 2
---

# Campaign analytics

Only campaigns with open tracking enabled. Open rate = unique openers / sent. *Excl. early* removes openers whose every view came within 2 minutes of the send start (prefetchers or instant opens): a lower bound.

## Latest tracked campaign

{% row %}
  {% big_value data="/queries/campaign_summary" value="max(sent)" title="Sent" fmt="num0" where="is_latest_tracked = 'yes'" /%}
  {% big_value data="/queries/campaign_summary" value="max(unique_openers)" title="Unique openers" fmt="num0" where="is_latest_tracked = 'yes'" /%}
  {% big_value data="/queries/campaign_summary" value="max(open_rate)" title="Open rate" fmt="pct1" where="is_latest_tracked = 'yes'" /%}
  {% big_value data="/queries/campaign_summary" value="max(open_rate_excl_early)" title="Open rate excl. early" fmt="pct1" where="is_latest_tracked = 'yes'" /%}
  {% big_value data="/queries/campaign_summary" value="max(early_share)" title="Early share of openers" fmt="pct1" where="is_latest_tracked = 'yes'" /%}
  {% big_value data="/queries/campaign_summary" value="max(views_per_opener)" title="Views per opener" fmt="num2" where="is_latest_tracked = 'yes'" /%}
{% /row %}

## All tracked campaigns

{% table data="/queries/campaign_summary" where="tracking_status = 'tracked'" %}
  {% dimension value="campaign_label" title="Campaign" sort="desc" /%}
  {% measure value="max(sent)" title="Sent" fmt="num0" /%}
  {% measure value="max(total_views)" title="Views" fmt="num0" /%}
  {% measure value="max(unique_openers)" title="Unique openers" fmt="num0" /%}
  {% measure value="max(early_openers)" title="Early openers" fmt="num0" /%}
  {% measure value="max(open_rate)" title="Open rate" fmt="pct1" /%}
  {% measure value="max(open_rate_excl_early)" title="Excl. early" fmt="pct1" /%}
  {% measure value="max(views_per_opener)" title="Views / opener" fmt="num2" /%}
  {% measure value="max(unique_clickers)" title="Clickers" fmt="num0" /%}
  {% measure value="max(ctor)" title="CTOR" fmt="pct1" /%}
  {% measure value="max(median_minutes_to_first_open)" title="Median min to open" fmt="num0" /%}
{% /table %}

{% row %}
  {% line_chart data="/queries/campaign_summary" x="started_at" y=["max(open_rate)", "max(open_rate_excl_early)"] where="tracking_status = 'tracked'" title="Open rate vs open rate excl. early opens" y_fmt="pct0" /%}
  {% bar_chart data="/queries/campaign_summary" x="campaign_label" y=["max(first_open_0_2m)", "max(first_open_2_10m)", "max(first_open_10_60m)", "max(first_open_1_24h)", "max(first_open_24h_plus)"] where="tracking_status = 'tracked'" stacked="100%" title="When do people first open? (share of openers)" x_sort="asc" /%}
{% /row %}

## Time to first open

{% row %}
  {% bar_chart data="/queries/subscriber_campaign" x="first_open_minute" y="count(*)" series="campaign_label" title="First opens per minute after send start (first hour)" subtitle="The ramp over the first ~10 minutes is the send itself (~5 mails/s)." x_sort="asc" /%}
  {% bar_chart data="/queries/subscriber_campaign" x="first_open_hour" y="count(*)" series="campaign_label" title="First opens per hour after send start (first two days)" x_sort="asc" /%}
{% /row %}

{% row %}
  {% line_chart data="/queries/daily_activity" x="day" y="sum(count)" series="campaign_label" where="type = 'first_opens'" title="Daily first opens per campaign (listmonk's Analytics-page view)" /%}
  {% table data="/queries/subscriber_campaign" title="Openers by campaign and kind" %}
    {% dimension value="campaign_label" title="Campaign" /%}
    {% dimension value="opener_kind" title="Kind" /%}
    {% dimension value="first_open_bucket" title="First open" /%}
    {% measure value="count(*)" title="Openers" fmt="num0" sort="desc" /%}
    {% measure value="sum(n_views) / count(*)" title="Views / opener" fmt="num2" /%}
  {% /table %}
{% /row %}
