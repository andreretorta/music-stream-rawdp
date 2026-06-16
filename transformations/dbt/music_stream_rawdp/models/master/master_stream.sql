{{ config(
    materialized='incremental',
    post_hook="TRUNCATE TABLE {{ source('internal', 't_raw_stream') }}",
    alias='t_raw_stream'
) }}

select
    airflow_ds as day_part,
    ingestion_timestamp,
    _id as stream_id,
    Created as created,
    Updated as updated,
    UtcBeginDate as utc_begin_date,
    UtcEndDate as utc_end_date,
    DurationMs as duration_ms,
    Track as track_id,
    UserId as user_id,
    Device as device,
    Country as country,
    Completed as completed,
    Shuffle as shuffle,
    SkipReason as skip_reason
from {{ source('internal', 't_raw_stream') }}
