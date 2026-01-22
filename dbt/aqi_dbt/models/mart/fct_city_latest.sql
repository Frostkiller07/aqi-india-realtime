with x as (
    select
        city,
        state,
        country,
        pollutant_id,
        observed_at,
        avg_value,
        min_value,
        max_value,
        row_number() over (
            partition by city, state, pollutant_id
            order by observed_at desc
        ) as rn
    from {{ ref('fct_air_quality') }}
    where observed_at is not null
      and avg_value is not null
)
select
    city,
    state,
    country,
    pollutant_id,
    observed_at,
    avg_value,
    min_value,
    max_value
from x
where rn = 1
