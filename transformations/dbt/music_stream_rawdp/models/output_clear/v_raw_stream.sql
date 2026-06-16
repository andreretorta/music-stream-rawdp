{{ config(
    schema='output_clear',
    alias='v_raw_stream',
) }}

select {{ dbt_utils.star(from=ref('t_raw_stream')) }}
from {{ ref('t_raw_stream') }}
