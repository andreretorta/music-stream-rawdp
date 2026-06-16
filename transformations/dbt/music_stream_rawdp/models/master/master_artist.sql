{{ config(
    materialized='incremental',
    post_hook="TRUNCATE TABLE {{ source('internal', 't_raw_artist') }}",
    alias='t_raw_artist'
) }}

select
    airflow_ds as day_part,
    ingestion_timestamp,
    _id as artist_id,
    ArtistId as artist_external_id,
    Created as created,
    Updated as updated,
    Name as name,
    Description as description,
    Country as country,
    ExtendedProperties as extended_properties,
    IconFile as icon_file,
    PosterFile as poster_file,
    Type as type
from {{ source('internal', 't_raw_artist') }}
