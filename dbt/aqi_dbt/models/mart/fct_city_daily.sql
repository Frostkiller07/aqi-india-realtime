with x as (
    select
        city,
        state,
        country,
        pollutant_id,
        date(observed_at) as day,
        avg_value
    from {{ ref('fct_air_quality') }}
    where observed_at is not null
      and avg_value is not null
),
r as (
    select
        city,
        state,
        country,
        pollutant_id,
        day,
        avg_value,
        row_number() over (
            partition by city, state, pollutant_id, day
            order by avg_value
        ) as rn,
        count(*) over (
            partition by city, state, pollutant_id, day
        ) as cnt
    from x
)
select
    city,
    state,
    country,
    pollutant_id,
    day,
    avg(avg_value) as avg_value_day,
    max(case when rn = ceiling(0.95 * cnt) then avg_value end) as p95_value_day,
    count(*) as n_obs
from r
group by city, state, country, pollutant_id, day
