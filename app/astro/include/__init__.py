"""Local Airflow helpers for the music-stream-rawdp portfolio project.

The original (corporate) project relied on a proprietary Airflow provider and a
managed ingestion/transfer platform. Those are **not** publicly available, so
this package provides self-contained, runnable replacements:

- ``mongo_ingestion_operator`` — a real MongoDB -> GCS ingestion operator.
- ``callbacks`` — lightweight logging callbacks (instead of a central hub).
- ``dbt_operator`` — a simple placeholder dbt operator.
"""
