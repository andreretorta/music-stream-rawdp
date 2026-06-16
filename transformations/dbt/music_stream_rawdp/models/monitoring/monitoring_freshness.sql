-- Freshness / volume monitoring across the internal raw tables.
-- One row per (entity, day_part) with row counts and ingestion lag in hours.

{{ config(
    materialized='incremental',
    schema='monitoring',
    alias='t_freshness',
    incremental_strategy='insert_overwrite'
) }}

{% set entities = [
    ('genre', 't_raw_genre'),
    ('artist', 't_raw_artist'),
    ('track', 't_raw_track'),
    ('stream', 't_raw_stream')
] %}

with unioned as (
    {% for entity_name, table_name in entities %}
    select
        '{{ entity_name }}' as entity,
        day_part,
        ingestion_timestamp,
        current_timestamp() as checked_at
    from {{ ref('master_' ~ entity_name) }}
    {% if not loop.last %}union all{% endif %}
    {% endfor %}
)

select
    entity,
    day_part,
    count(*) as row_count,
    max(ingestion_timestamp) as last_ingestion_timestamp,
    timestamp_diff(current_timestamp(), max(ingestion_timestamp), hour) as ingestion_lag_hours,
    current_timestamp() as checked_at
from unioned
group by entity, day_part
