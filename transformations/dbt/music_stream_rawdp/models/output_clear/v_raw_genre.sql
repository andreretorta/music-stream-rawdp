{{ config(
    schema='output_clear',
    alias='v_raw_genre',
) }}

select {{ dbt_utils.star(from=ref('t_raw_genre')) }}
from {{ ref('t_raw_genre') }}
