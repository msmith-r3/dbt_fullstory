{{
    config(
        unique_key='full_session_id'
    )
}}
select
    {{ dbt.concat(["events.device_id", "':'", "events.session_id"]) }} as full_session_id,
    {{ dbt.any_value("users.user_id") }} as user_id,
    {{ dbt.any_value("events.device_id") }} as device_id,
    {{ dbt.any_value("events.session_id") }} as session_id,
    min(events.event_time) as start_time,
    max(events.event_time) as end_time,
    max(events.updated_time) as updated_time,
    {{- dbt.datediff("min(event_time)::timestamp", "max(event_time)::timestamp", "second") -}} as duration,
    count(distinct events.event_id) as total_events,
    count(
        distinct case when events.event_type = 'navigate' then events.event_id end
    ) as total_page_views,
    count(
        distinct case when events.event_type = 'navigate' then events.source_properties.url_full_url end
    ) as total_unique_urls,
    {{ dbt.concat([
        get_replay_url_path(),
        dbt.any_value("events.device_id"),
        "':'",
        dbt.any_value("events.session_id"),
        "'?url_source=DD'"
    ]) }} as replay_url,
    {% for type in var("fullstory_event_types") -%}
    count(case when events.event_type = '{{ type }}' then 1 end) as total_{{ type }}_events{% if not loop.last %},{% endif %}
    {% endfor %},
    count(case when events.source_type = 'web' then 1 end) as total_web_events,
    count(case when events.source_type = 'mobile_app' then 1 end) as total_mobile_app_events
from {{ ref("events") }} as events
left outer join
    {{ ref("stg_events__user_keys") }} as users on
        users.desc_row_num = 1 and
        events.device_id = users.device_id
where
    events.device_id is not null and events.session_id is not null
    {# {% if is_incremental() %} #}
    and {{ dbt.cast("events.event_time", api.Column.translate_type("datetime")) }} >= {{ dbt.dateadd(datepart="hour", interval=-1 * var("fullstory_incremental_interval_hours", 7 * 24), from_date_or_timestamp=dbt.current_timestamp()) }}
    {# {% endif %} #}    
group by {{ dbt.concat(["events.device_id", "':'", "events.session_id"]) }}
