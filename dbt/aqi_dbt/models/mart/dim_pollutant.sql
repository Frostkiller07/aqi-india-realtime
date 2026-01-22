select
    distinct pollutant_id,
    pollutant_id as pollutant_label
from {{ ref('fct_air_quality') }}
where pollutant_id is not null
