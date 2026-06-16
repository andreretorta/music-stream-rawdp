{{ config(
    schema='output_clear',
    alias='v_raw_artist',
) }}

select {{ dbt_utils.star(from=ref('master_artist')) }}
from {{ ref('master_artist') }}
