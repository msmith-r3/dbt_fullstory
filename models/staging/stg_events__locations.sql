select
    {{ dbt.concat(["device_id", "':'", "session_id"]) }} as full_session_id,
    session_id,
    device_id,
    view_id,
    event_time,
    updated_time,
    processed_time,
    source_properties.geo_ip_address::varchar(65535),
    source_properties.geo_country::varchar(65535),
    source_properties.geo_region::varchar(65535),
    source_properties.geo_city::varchar(65535),
    source_properties.geo_lat_long::varchar(65535),
    row_number() over (
        partition by {{ dbt.concat(["device_id", "':'", "session_id"]) }}
        order by
            event_time desc,
            updated_time desc,
            processed_time desc
    ) as desc_row_num
from {{ ref("events") }}
