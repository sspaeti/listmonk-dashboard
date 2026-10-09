---
title: Campaign Impact (unsubscribes & deliverability)
sidebar_position: 5
---

# Did this issue hurt the list?

Unsubscribes within **3 days** after a send on the lists the campaign went to, subscribers blocklisted because this send hard-bounced or got a complaint, plus bounces by type. Works for every campaign, open tracking or not. Rule of thumb: unsubscribe rate below 0.5 % per send is healthy, above 1 % deserves a look.

## Latest campaign

{% row %}
  {% big_value data="/queries/campaign_impact" value="max(sent)" title="Sent" fmt="num0" where="is_latest = 'yes'" /%}
  {% big_value data="/queries/campaign_impact" value="max(unsubscribes)" title="Unsubscribes (after send)" fmt="num0" where="is_latest = 'yes'" /%}
  {% big_value data="/queries/campaign_impact" value="max(unsubscribe_rate)" title="Unsubscribe rate" fmt="pct2" where="is_latest = 'yes'" /%}
  {% big_value data="/queries/campaign_impact" value="max(hard_bounces)" title="Hard bounces" fmt="num0" where="is_latest = 'yes'" /%}
  {% big_value data="/queries/campaign_impact" value="max(soft_bounces)" title="Soft bounces" fmt="num0" where="is_latest = 'yes'" /%}
  {% big_value data="/queries/campaign_impact" value="max(blocklisted)" title="Blocklisted" fmt="num0" where="is_latest = 'yes'" /%}
  {% big_value data="/queries/campaign_impact" value="max(list_loss_rate)" title="List loss rate" fmt="pct2" where="is_latest = 'yes'" /%}
{% /row %}

{% row %}
  {% line_chart data="/queries/campaign_impact" x="started_at" y=["max(unsubscribe_rate)", "max(hard_bounce_rate)"] title="Unsubscribe rate and hard-bounce rate per send" y_fmt="pct2" /%}
  {% bar_chart data="/queries/campaign_impact" x="campaign_label" y=["max(unsubscribes)", "max(blocklisted)"] stacked=true title="List loss per campaign: unsubscribes and blocklisted" x_sort="asc" /%}
{% /row %}

{% table data="/queries/campaign_impact" title="Per campaign" subtitle="Rates are per mail sent." page_size=100 search=true %}
  {% dimension value="campaign_label" title="Campaign" sort="desc" /%}
  {% measure value="max(sent)" title="Sent" fmt="num0" /%}
  {% measure value="max(unsubscribes)" title="Unsubs" fmt="num0" /%}
  {% measure value="max(unsubscribe_rate)" title="Unsub rate" fmt="pct2" /%}
  {% measure value="max(bounces)" title="Bounces" fmt="num0" /%}
  {% measure value="max(hard_bounces)" title="Hard" fmt="num0" /%}
  {% measure value="max(soft_bounces)" title="Soft" fmt="num0" /%}
  {% measure value="max(complaints)" title="Complaints" fmt="num0" /%}
  {% measure value="max(bounce_rate)" title="Bounce rate" fmt="pct2" /%}
  {% measure value="max(blocklisted)" title="Blocklisted" fmt="num0" /%}
  {% measure value="max(list_loss_rate)" title="List loss rate" fmt="pct2" /%}
{% /table %}

## Unsubscribes over time

{% row %}
  {% bar_chart data="/queries/unsubscribe_events" x="unsubscribed_at" y="count(*)" series="attribution" date_grain="month" stacked=true title="Unsubscribes per month: after a campaign vs organic" /%}
  {% bar_chart data="/queries/unsubscribe_events" x="unsubscribed_at" y="count(*)" series="tenure_bucket" date_grain="month" stacked="100%" title="How long had they been subscribed?" subtitle="Many short tenures = signup expectation mismatch." /%}
{% /row %}

{% row %}
  {% table data="/queries/unsubscribe_events" title="Unsubscribes by campaign and list" %}
    {% dimension value="attributed_campaign_label" title="Campaign" /%}
    {% dimension value="list_name" title="List" /%}
    {% measure value="count(*)" title="Unsubscribes" fmt="num0" sort="desc" /%}
    {% measure value="percentile_cont(0.5) within group (order by hours_after_send)" title="Median hours after send" fmt="num0" /%}
    {% measure value="percentile_cont(0.5) within group (order by days_subscribed)" title="Median days subscribed" fmt="num0" /%}
  {% /table %}
  {% bar_chart data="/queries/bounce_events" x="bounced_at" y="count(*)" series="type" date_grain="month" stacked=true title="Bounces per month by type" /%}
{% /row %}

{% callout type="info" title="How attribution works" %}
- An unsubscribe is attributed to the **most recent campaign sent to that list within 3 days before it**. Everything else is *organic*. The unsubscribe time is the list membership's last status change.
- *Blocklisted* = subscribers with a hard bounce or complaint on this campaign who are blocklisted now (listmonk's bounce setting: blocklist on the first hard bounce or complaint). Hard bounces are therefore not counted again in list loss.
- Bounces come from listmonk's bounce table and are tied to the campaign by listmonk itself.
{% /callout %}
