"""Validate the (non-DIA) ingestion contracts and their consistency.

These tests run without Airflow, MongoDB or GCP — they only inspect the
declarative JSON files, so they are safe to run anywhere (and in CI).
"""

import json
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
SOURCES_DIR = ROOT / "app" / "ingestion" / "sources"
CONNECTIONS_DIR = ROOT / "app" / "ingestion" / "connections"

EXPECTED_ENTITIES = {"genre", "artist", "track", "stream"}
EXPECTED_COLLECTIONS = {
    "genre": "Genre_ViewDP",
    "artist": "Artist_ViewDP",
    "track": "Track_ViewDP",
    "stream": "Stream_ViewDP",
}


def _load(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def test_source_files_exist():
    files = list(SOURCES_DIR.glob("*.json"))
    assert len(files) == len(EXPECTED_ENTITIES)


@pytest.mark.parametrize("path", sorted(SOURCES_DIR.glob("*.json")))
def test_ingestion_contract_is_valid(path: Path):
    cfg = _load(path)
    for key in ("name", "entity", "source", "sink", "partition", "write_mode"):
        assert key in cfg, f"{path.name} missing '{key}'"

    source = cfg["source"]
    assert source["type"] == "mongodb"
    assert source["connection"] == "connection-mongodb-music-stream"
    assert source["database"] == "music_streaming"
    assert source["collection"] == EXPECTED_COLLECTIONS[cfg["entity"]]

    sink = cfg["sink"]
    assert sink["format"] == "NEWLINE_DELIMITED_JSON"
    assert sink["bq_table"] == f"internal.t_raw_{cfg['entity']}"


def test_entities_match_expected():
    entities = {_load(p)["entity"] for p in SOURCES_DIR.glob("*.json")}
    assert entities == EXPECTED_ENTITIES


def test_no_proprietary_platform_references():
    """Ensure DIA / TransferZone are not used anywhere in the ingestion configs."""
    blob = "\n".join(
        p.read_text(encoding="utf-8").lower()
        for p in list(SOURCES_DIR.glob("*.json")) + list(CONNECTIONS_DIR.glob("*.json"))
    )
    assert "dia" not in blob
    assert "transferzone" not in blob


def test_connection_uses_secrets_not_plaintext():
    cfg = _load(CONNECTIONS_DIR / "connection-mongodb-music-stream.json")
    conn = cfg["connection_string"]
    # Credentials must be referenced via secrets, never hard-coded.
    assert "${secrets.MONGO_USER}" in conn
    assert "${secrets.MONGO_PW}" in conn
