with base as (
    select *
    from {{ ref('stg_air_quality') }}
    where observed_at is not null
),

dedup as (
    select
        station,
        city,
        state,
        country,
        pollutant_id,
        latitude,
        longitude,
        observed_at,
        avg_value,
        min_value,
        max_value,
        ingested_at
    from (
        select
            *,
            row_number() over (
                partition by station, city, state, pollutant_id, observed_at
                order by ingested_at desc
            ) as rn
        from base
    ) t
    where rn = 1
)

select
    station,
    city,
    state,
    country,
    pollutant_id,
    latitude,
    longitude,
    observed_at,
    avg_value,
    min_value,
    max_value,
    ingested_at,
    case
        when avg_value is null then 'missing'
        when avg_value < 0 then 'invalid_negative'
        else 'ok'
    end as dq_flag
from dedup
