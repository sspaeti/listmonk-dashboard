---
title: Lists & Subscribers
sidebar_position: 3
---

# Lists & subscribers

Who is actually reachable, how lists grow, and how much dead weight sits on them.

{% row %}
  {% big_value data="/queries/list_health" value="max(total_subscribers)" title="Total subscribers" fmt="num0" /%}
  {% big_value data="/queries/list_health" value="max(reachable)" title="Reachable (enabled + confirmed)" fmt="num0" /%}
  {% big_value data="/queries/list_health" value="max(enabled)" title="Enabled" fmt="num0" /%}
  {% big_value data="/queries/list_health" value="max(blocklisted)" title="Blocklisted" fmt="num0" /%}
  {% big_value data="/queries/list_health" value="max(dead_weight)" title="Dead weight" fmt="num0" /%}
  {% big_value data="/queries/list_health" value="max(dead_weight) / max(enabled)" title="Dead weight share" fmt="pct1" /%}
{% /row %}

**Dead weight** = enabled subscribers with no open in the last tracked campaigns (only campaigns with open tracking count, so this is an upper bound).

{% dropdown id="list" data="/queries/subscriptions" value_column="list_name" title="List" clear=true /%}

{% row %}
  {% table data="/queries/subscriptions" filters=["list"] title="Per list" %}
    {% dimension value="list_name" title="List" /%}
    {% measure value="count(*)" title="Subscriptions" fmt="num0" /%}
    {% measure value="count(*) filter (where subscription_status = 'confirmed' and subscriber_status = 'enabled')" title="Confirmed & enabled" fmt="num0" /%}
    {% measure value="count(*) filter (where subscription_status = 'unconfirmed')" title="Unconfirmed" fmt="num0" /%}
    {% measure value="count(*) filter (where subscription_status = 'unsubscribed')" title="Unsubscribed" fmt="num0" /%}
    {% measure value="count(*) filter (where subscription_status = 'unsubscribed')::numeric / count(*)" title="Unsub share" fmt="pct1" /%}
  {% /table %}
  {% bar_chart data="/queries/subscriptions" filters=["list"] x="list_name" y="count(*)" series="subscription_status" stacked=true title="Subscriptions per list by status" /%}
{% /row %}

## Growth

{% row %}
  {% bar_chart data="/queries/subscriptions" filters=["list"] x="subscribed_at" y="count(*)" series="list_name" date_grain="month" stacked=true title="New subscriptions per month by list" date_range={ range="last 24 months" date="subscribed_at" } /%}
  {% bar_chart data="/queries/subscriptions" filters=["list"] x="subscribed_at" y="count(*)" series="subscription_status" date_grain="month" stacked="100%" title="Of the people who subscribed each month, how many are still confirmed?" date_range={ range="last 24 months" date="subscribed_at" } /%}
{% /row %}

{% line_chart data="/queries/subscriptions" filters=["list"] x="subscribed_at" y="count(*) filter (where reachable)" date_grain="month" title="Confirmed & enabled subscriptions gained per month" /%}
