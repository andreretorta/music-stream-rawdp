{{ config(
    schema='output_clear',
    alias='v_raw_stream',
) }}

select {{ dbt_utils.star(from=ref('master_stream')) }}
from {{ ref('master_stream') }}
