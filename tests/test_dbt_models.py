"""Validate dbt model and BigQuery schema coverage for all entities."""

from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
DBT = ROOT / "transformations" / "dbt" / "music_stream_rawdp" / "models"
SCHEMAS = ROOT / "infrastructure" / "projects" / "resources" / "schemas"

ENTITIES = ["genre", "artist", "track", "stream"]


@pytest.mark.parametrize("entity", ENTITIES)
def test_master_model_exists(entity):
    assert (DBT / "master" / f"t_raw_{entity}.sql").is_file()


@pytest.mark.parametrize("entity", ENTITIES)
def test_output_clear_model_exists(entity):
    assert (DBT / "output_clear" / f"v_raw_{entity}.sql").is_file()


@pytest.mark.parametrize("entity", ENTITIES)
def test_bigquery_schema_exists(entity):
    assert (SCHEMAS / f"t_raw_{entity}.json").is_file()


def test_monitoring_model_exists():
    assert (DBT / "monitoring" / "monitoring_freshness.sql").is_file()
