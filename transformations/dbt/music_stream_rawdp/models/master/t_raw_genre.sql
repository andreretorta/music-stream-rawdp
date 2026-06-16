{{ config(
    materialized='incremental',
    post_hook="TRUNCATE TABLE {{ source('internal', 't_raw_genre') }}",
    alias='t_raw_genre'
) }}

select
    airflow_ds as day_part,
    ingestion_timestamp,
    _id as genre_id,
    ParentGenre as parent_genre_id,
    Created as created,
    Updated as updated,
    Name as name,
    PictureFile as picture_file
from {{ source('internal', 't_raw_genre') }}
