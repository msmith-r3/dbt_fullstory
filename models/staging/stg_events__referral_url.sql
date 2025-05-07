select
    {{ dbt.concat(["device_id", "':'", "session_id"]) }} as full_session_id,
    source_properties.url.full_url as landing_page,
    source_properties.initial_referrer.full_url as referral_url,
    row_number() over (
        partition by {{ dbt.concat(["device_id", "':'", "session_id"]) }}
        order by
            event_time,
            updated_time,
            processed_time
    ) as asc_row_num
from {{ ref("events") }}
