{{ config(
    schema='output_clear',
    alias='v_raw_artist',
) }}

select {{ dbt_utils.star(from=ref('t_raw_artist')) }}
from {{ ref('t_raw_artist') }}
