"""ETL DAG for the music-stream-rawdp data product.

Flow per entity (genre, artist, track, stream):
    MongoDB extract -> GCS landing -> GCS-to-BigQuery load -> cleanup -> dbt.

Ingestion is performed by a custom ``MongoToGCSIngestionOperator`` (see
app/astro/include/), which reads directly from the operational MongoDB. No
proprietary ingestion platform or managed transfer service is used.
"""

import pendulum
from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.utils.task_group import TaskGroup
from datetime import timedelta

# custom config + ingestion operator
import music_stream_rawdp.base as config
from include.mongo_ingestion_operator import MongoToGCSIngestionOperator
from include.callbacks import orchestration_callback

# GCS & BigQuery
from airflow.providers.google.cloud.transfers.gcs_to_bigquery import GCSToBigQueryOperator
from airflow.providers.google.cloud.operators.gcs import GCSDeleteObjectsOperator
from airflow.providers.google.cloud.operators.cloud_run import CloudRunExecuteJobOperator


def entity_group(entity_name, ingestion_parameters):
    inner_group_id = entity_name

    with TaskGroup(group_id=inner_group_id) as ingestion_stages:
        params = config.TABLES[entity_name]
        gcs_prefix = (
            f"{config.ENV}/internal/internal/t_raw_{entity_name}/ingest_part={{{{ ds }}}}"
        )

        extract = MongoToGCSIngestionOperator(
            task_id="extract",
            retries=4,
            retry_delay=timedelta(seconds=15),
            mongo_database=params["mongo_database"],
            mongo_collection=params["mongo_collection"],
            bucket=params["bucket"],
            gcs_prefix=gcs_prefix,
            gcp_conn_id=config.GCP_CONN_ID,
            priority_weight=params.get("priority_weight", 1),
        )

        bq_load = GCSToBigQueryOperator(
            task_id="gcs_to_bq",
            bucket=params["bucket"],
            source_objects=[f"{gcs_prefix}/*.{params['file_format']}"],
            destination_project_dataset_table=params["bq_table"],
            source_format=params["source_format"],
            write_disposition="WRITE_TRUNCATE",
            autodetect=False,
            schema_fields=params["schema_fields"],
            gcp_conn_id=config.GCP_CONN_ID,
            impersonation_chain=config.ORCHESTRATOR_SA,
            ignore_unknown_values=True,
        )

        delete_files = GCSDeleteObjectsOperator(
            task_id="delete_gcs_files",
            bucket_name=params["bucket"],
            prefix=f"{gcs_prefix}/",
            gcp_conn_id=config.GCP_CONN_ID,
            impersonation_chain=config.ORCHESTRATOR_SA,
        )

        transformation_operator = CloudRunExecuteJobOperator(
            task_id="transformation_and_quality",
            project_id=config.PROJECT,
            region=config.REGION,
            job_name=config.JOB,
            overrides={
                "container_overrides": [
                    {
                        "name": "dbt-runner",
                        "args": [
                            "run",
                            "--target", config.ENV,
                            "--select", f"+output_clear_{entity_name.lower()}",
                            "--exclude", "monitoring",
                            "--vars", str(ingestion_parameters),
                        ],
                    }
                ],
                "task_count": 1,
                "timeout": "3600s",
            },
            deferrable=True,
            impersonation_chain=config.ORCHESTRATOR_SA,
            on_success_callback=orchestration_callback,
            on_failure_callback=orchestration_callback,
        )

        extract >> bq_load >> delete_files >> transformation_operator
    return ingestion_stages


def ingestion_group(ingestion_parameters):
    with TaskGroup(group_id=config.INGESTION_GROUP_ID, tooltip="Data Ingestion App") as ingestion:
        for ingestion_name in config.TABLES.keys():
            entity_group(ingestion_name, ingestion_parameters)
    return ingestion


default_args = {
    'owner': 'joao-dataeng',
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 0 if config.ENV == 'dev' else 2,
    'weight_rule': 'upstream',
    'dataproduct_id': config.PROJECT,
    'impersonation_chain': config.ORCHESTRATOR_SA,
    'environment': config.ENV,
}

with DAG(
    dag_display_name='music-stream-rawdp-etl',
    dag_id='music-stream-rawdp-etl',
    default_args=default_args,
    description='Raw ingestion + transformation for the music streaming data product.',
    schedule_interval='0 7 * * *',
    max_active_tasks=1,
    max_active_runs=1,
    start_date=pendulum.datetime(2025, 2, 20, tz='Europe/Lisbon'),
    catchup=False,
    tags=[
        'data-domain:media',
        'datasubdomain:music-streaming',
        'data-product:music-stream-rawdp',
        'type:incremental',
    ],
    on_success_callback=orchestration_callback,
    on_failure_callback=orchestration_callback,
) as dag:

    ingestion_parameters = {
        "initial_filter_date": "{{ data_interval_start.to_datetime_string() }}",
        "end_filter_date": "{{ data_interval_end.to_datetime_string() }}",
    }

    start = EmptyOperator(task_id='start')
    finish = EmptyOperator(task_id='finish')

    ingestion_task = ingestion_group(ingestion_parameters)

    start >> ingestion_task >> finish
