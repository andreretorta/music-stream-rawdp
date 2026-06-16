{{ config(
    materialized='incremental',
    post_hook="TRUNCATE TABLE {{ source('internal', 't_raw_track') }}",
    alias='t_raw_track'
) }}

select
    airflow_ds as day_part,
    ingestion_timestamp,
    _id as track_id,
    Created as created,
    Updated as updated,
    Title as title,
    Artist as artist_id,
    DurationMs as duration_ms,
    Album as album,
    ReleaseYear as release_year,
    Explicit as explicit,
    Isrc as isrc,
    TrackGenres as track_genres,
    Popularity as popularity,
    Composers as composers,
    MetadataTag as metadata_tag
from {{ source('internal', 't_raw_track') }}
