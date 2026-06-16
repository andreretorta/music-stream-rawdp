{{ config(
    schema='output_clear',
    alias='v_raw_track',
) }}

select {{ dbt_utils.star(from=ref('t_raw_track')) }}
from {{ ref('t_raw_track') }}
