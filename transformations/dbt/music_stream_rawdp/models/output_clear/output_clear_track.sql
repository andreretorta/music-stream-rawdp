{{ config(
    schema='output_clear',
    alias='v_raw_track',
) }}

select {{ dbt_utils.star(from=ref('master_track')) }}
from {{ ref('master_track') }}
