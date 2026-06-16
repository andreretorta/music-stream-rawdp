"""Monitoring / data-quality DAG for the music-stream-rawdp data product."""

import pendulum
from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.utils.task_group import TaskGroup

import music_stream_rawdp.base as config
from airflow.providers.google.cloud.operators.cloud_run import CloudRunExecuteJobOperator


def monitoring() -> TaskGroup:
    with TaskGroup("monitoring", tooltip="Monitoring") as transforms:
        CloudRunExecuteJobOperator(
            task_id="monitoring",
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
                            "--select", "monitoring",
                            "--vars", "{'monitoring': 'true'}",
                        ],
                    }
                ],
                "task_count": 1,
                "timeout": "3600s",
            },
            deferrable=True,
            impersonation_chain=config.ORCHESTRATOR_SA,
        )
    return transforms


default_args = {
    'start_date': pendulum.datetime(2025, 2, 20, tz='Europe/Lisbon'),
    'owner': 'joao-dataeng',
    'retries': 0 if config.ENV == 'dev' else 2,
    'weight_rule': 'absolute',
}


with DAG(
    dag_display_name='music-stream-rawdp-monitoring',
    dag_id='music-stream-rawdp-monitoring',
    default_args=default_args,
    description=("Monitoring Execute (" f"{'QUA' if config.ENV == 'dev' else 'PRD'})"),
    schedule_interval=None if config.ENV == 'dev' else '30 4/12 * * *',
    max_active_tasks=1 if config.ENV == 'dev' else 3,
    catchup=False,
    tags=[
        'data-domain:media',
        'datasubdomain:music-streaming',
        'data-product:music-stream-rawdp',
        'type:incremental',
    ],
) as dag:
    start = EmptyOperator(task_id='start')
    finish = EmptyOperator(task_id='finish')

    monitoring_build = monitoring()

    start >> monitoring_build >> finish
