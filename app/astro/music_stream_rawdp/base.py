# --- general -----------------------------------------------------------------

import os

# environment (replaced at deploy time by the CI/CD pipeline, e.g. 'dev'/'prd')
ENV = 'VARREP_ENV'

# project id — set these via Airflow/Astronomer environment variables so the
# same code works against your real GCP projects (created by the bootstrap
# Terraform stack). Defaults are placeholders to be replaced.
PROJECT_DEV = os.environ.get('GCP_PROJECT_DEV', 'REPLACE-ME-music-stream-dev')
PROJECT_PRD = os.environ.get('GCP_PROJECT_PRD', 'REPLACE-ME-music-stream-prd')
PROJECT = PROJECT_DEV if ENV == 'dev' else PROJECT_PRD

# region
REGION = os.environ.get('GCP_REGION', 'europe-west1')

# orchestration SA
ORCHESTRATOR_SA = f'sa-astronomer@{PROJECT}.iam.gserviceaccount.com'


# --- cloudrun (dbt) ----------------------------------------------------------
JOB_DEV = "gcr-music-stream-rawdp-d-europe-west1-dbt"
JOB_PRD = "gcr-music-stream-rawdp-p-europe-west1-dbt"
JOB = JOB_DEV if ENV == "dev" else JOB_PRD


# --- ingestion (custom MongoDB -> GCS) ---------------------------------------

# operational MongoDB source database
MONGO_DATABASE = "music_streaming"

TABLES = {
    "genre": {
        "ingestion_name": "music-stream-rawdp-genre",
        "mongo_database": MONGO_DATABASE,
        "mongo_collection": "Genre_ViewDP",
        "priority_weight": 1,
        "timeout": 3600,
        "bucket": "music-stream-rawdp-ingestion",
        "bq_table": f"{PROJECT}.internal.t_raw_genre",
        "source_format": "NEWLINE_DELIMITED_JSON",
        "file_format": "json",
        "schema_fields": [
            {"name": "_id", "type": "STRING", "mode": "NULLABLE"},
            {"name": "ParentGenre", "type": "STRING", "mode": "NULLABLE"},
            {"name": "Created", "type": "TIMESTAMP", "mode": "NULLABLE"},
            {"name": "Updated", "type": "TIMESTAMP", "mode": "NULLABLE"},
            {"name": "Name", "type": "STRING", "mode": "NULLABLE"},
            {"name": "PictureFile", "type": "STRING", "mode": "NULLABLE"},
            {"name": "ingestion_timestamp", "type": "TIMESTAMP", "mode": "NULLABLE"},
            {"name": "airflow_ds", "type": "DATE", "mode": "NULLABLE"},
        ],
    },
    "artist": {
        "ingestion_name": "music-stream-rawdp-artist",
        "mongo_database": MONGO_DATABASE,
        "mongo_collection": "Artist_ViewDP",
        "priority_weight": 1,
        "timeout": 3600,
        "bucket": "music-stream-rawdp-ingestion",
        "bq_table": f"{PROJECT}.internal.t_raw_artist",
        "source_format": "NEWLINE_DELIMITED_JSON",
        "file_format": "json",
        "schema_fields": [
            {"name": "_id", "type": "INTEGER", "mode": "NULLABLE"},
            {"name": "ArtistId", "type": "INTEGER", "mode": "NULLABLE"},
            {"name": "Created", "type": "TIMESTAMP", "mode": "NULLABLE"},
            {"name": "Updated", "type": "TIMESTAMP", "mode": "NULLABLE"},
            {"name": "Name", "type": "STRING", "mode": "NULLABLE"},
            {"name": "Description", "type": "STRING", "mode": "NULLABLE"},
            {"name": "Country", "type": "STRING", "mode": "NULLABLE"},
            {"name": "ExtendedProperties", "type": "RECORD", "mode": "REPEATED", "fields": [
                {"name": "Context", "type": "STRING", "mode": "NULLABLE"},
                {"name": "PropertyName", "type": "STRING", "mode": "NULLABLE"},
                {"name": "PropertyValue", "type": "STRING", "mode": "NULLABLE"},
            ]},
            {"name": "IconFile", "type": "STRING", "mode": "NULLABLE"},
            {"name": "PosterFile", "type": "STRING", "mode": "NULLABLE"},
            {"name": "Type", "type": "INTEGER", "mode": "NULLABLE"},
            {"name": "ingestion_timestamp", "type": "TIMESTAMP", "mode": "NULLABLE"},
            {"name": "airflow_ds", "type": "DATE", "mode": "NULLABLE"},
        ],
    },
    "track": {
        "ingestion_name": "music-stream-rawdp-track",
        "mongo_database": MONGO_DATABASE,
        "mongo_collection": "Track_ViewDP",
        "priority_weight": 1,
        "timeout": 3600,
        "bucket": "music-stream-rawdp-ingestion",
        "bq_table": f"{PROJECT}.internal.t_raw_track",
        "source_format": "NEWLINE_DELIMITED_JSON",
        "file_format": "json",
        "schema_fields": [
            {"name": "_id", "type": "INTEGER", "mode": "NULLABLE"},
            {"name": "Created", "type": "TIMESTAMP", "mode": "NULLABLE"},
            {"name": "Updated", "type": "TIMESTAMP", "mode": "NULLABLE"},
            {"name": "Title", "type": "STRING", "mode": "NULLABLE"},
            {"name": "Artist", "type": "INTEGER", "mode": "NULLABLE"},
            {"name": "DurationMs", "type": "INTEGER", "mode": "NULLABLE"},
            {"name": "Album", "type": "STRING", "mode": "NULLABLE"},
            {"name": "ReleaseYear", "type": "INTEGER", "mode": "NULLABLE"},
            {"name": "Explicit", "type": "BOOLEAN", "mode": "NULLABLE"},
            {"name": "Isrc", "type": "STRING", "mode": "NULLABLE"},
            {"name": "TrackGenres", "type": "STRING", "mode": "REPEATED"},
            {"name": "Popularity", "type": "INTEGER", "mode": "NULLABLE"},
            {"name": "Composers", "type": "STRING", "mode": "REPEATED"},
            {"name": "MetadataTag", "type": "RECORD", "mode": "NULLABLE", "fields": [
                {"name": "_id", "type": "STRING", "mode": "NULLABLE"},
                {"name": "Name", "type": "STRING", "mode": "NULLABLE"},
            ]},
            {"name": "ingestion_timestamp", "type": "TIMESTAMP", "mode": "NULLABLE"},
            {"name": "airflow_ds", "type": "DATE", "mode": "NULLABLE"},
        ],
    },
    "stream": {
        "ingestion_name": "music-stream-rawdp-stream",
        "mongo_database": MONGO_DATABASE,
        "mongo_collection": "Stream_ViewDP",
        "priority_weight": 1,
        "timeout": 3600,
        "bucket": "music-stream-rawdp-ingestion",
        "bq_table": f"{PROJECT}.internal.t_raw_stream",
        "source_format": "NEWLINE_DELIMITED_JSON",
        "file_format": "json",
        "schema_fields": [
            {"name": "_id", "type": "INTEGER", "mode": "NULLABLE"},
            {"name": "Created", "type": "TIMESTAMP", "mode": "NULLABLE"},
            {"name": "Updated", "type": "TIMESTAMP", "mode": "NULLABLE"},
            {"name": "UtcBeginDate", "type": "TIMESTAMP", "mode": "NULLABLE"},
            {"name": "UtcEndDate", "type": "TIMESTAMP", "mode": "NULLABLE"},
            {"name": "DurationMs", "type": "INTEGER", "mode": "NULLABLE"},
            {"name": "Track", "type": "INTEGER", "mode": "NULLABLE"},
            {"name": "UserId", "type": "STRING", "mode": "NULLABLE"},
            {"name": "Device", "type": "STRING", "mode": "NULLABLE"},
            {"name": "Country", "type": "STRING", "mode": "NULLABLE"},
            {"name": "Completed", "type": "BOOLEAN", "mode": "NULLABLE"},
            {"name": "Shuffle", "type": "BOOLEAN", "mode": "NULLABLE"},
            {"name": "SkipReason", "type": "STRING", "mode": "NULLABLE"},
            {"name": "ingestion_timestamp", "type": "TIMESTAMP", "mode": "NULLABLE"},
            {"name": "airflow_ds", "type": "DATE", "mode": "NULLABLE"},
        ],
    },
}


# --- quality -----------------------------------------------------------------

QUALITY_SA = f'gsa-gdp-dataquality@{PROJECT}.iam.gserviceaccount.com'

RULES = []

INGESTION_GROUP_ID = "music-stream-ingestion"
DAG_NAME = 'music-stream-rawdp-etl'

# GCP connection id used by the Google Airflow providers (standard, not DIA).
GCP_CONN_ID = "google_cloud_default"
