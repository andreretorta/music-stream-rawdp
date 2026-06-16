{{ config(
    schema='output_clear',
    alias='v_raw_genre',
) }}

select {{ dbt_utils.star(from=ref('master_genre')) }}
from {{ ref('master_genre') }}
