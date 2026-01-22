with src as (
    select
        ingested_at,
        record_hash,

        json_unquote(json_extract(record, '$.country')) as country,
        json_unquote(json_extract(record, '$.state')) as state,
        json_unquote(json_extract(record, '$.city')) as city,
        json_unquote(json_extract(record, '$.station')) as station,
        json_unquote(json_extract(record, '$.pollutant_id')) as pollutant_id,
        json_unquote(json_extract(record, '$.last_update')) as last_update_raw,

        json_unquote(json_extract(record, '$.latitude')) as latitude_raw,
        json_unquote(json_extract(record, '$.longitude')) as longitude_raw,

        json_unquote(json_extract(record, '$.avg_value')) as avg_value_raw,
        json_unquote(json_extract(record, '$.min_value')) as min_value_raw,
        json_unquote(json_extract(record, '$.max_value')) as max_value_raw

    from {{ source('raw', 'raw_air_quality_observations') }}
),

typed as (
    select
        ingested_at,
        record_hash,
        country,
        state,
        city,
        station,
        pollutant_id,

        -- safe latitude/longitude (only cast if numeric)
        case
            when latitude_raw regexp '^-?[0-9]+(\\.[0-9]+)?$' then cast(latitude_raw as decimal(10,6))
            else null
        end as latitude,

        case
            when longitude_raw regexp '^-?[0-9]+(\\.[0-9]+)?$' then cast(longitude_raw as decimal(10,6))
            else null
        end as longitude,

        -- safe datetime parsing (two formats)
        case
            when last_update_raw is null or last_update_raw = '' then null
            when last_update_raw regexp '^[0-9]{4}-[0-9]{2}-[0-9]{2} ' then
                str_to_date(last_update_raw, '%Y-%m-%d %H:%i:%s')
            when last_update_raw regexp '^[0-9]{2}-[0-9]{2}-[0-9]{4} ' then
                str_to_date(last_update_raw, '%d-%m-%Y %H:%i:%s')
            else null
        end as observed_at,

        -- safe numeric parsing for values (only cast if numeric)
        case
            when avg_value_raw regexp '^-?[0-9]+(\\.[0-9]+)?$' then cast(avg_value_raw as decimal(12,4))
            else null
        end as avg_value,

        case
            when min_value_raw regexp '^-?[0-9]+(\\.[0-9]+)?$' then cast(min_value_raw as decimal(12,4))
            else null
        end as min_value,

        case
            when max_value_raw regexp '^-?[0-9]+(\\.[0-9]+)?$' then cast(max_value_raw as decimal(12,4))
            else null
        end as max_value

    from src
)

select *
from typed
