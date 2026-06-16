"""Custom MongoDB -> GCS ingestion operator.

This replaces the proprietary managed ingestion platform used by the original
corporate project. It is a real, self-contained operator that:

    1. Connects to a MongoDB collection (the operational source).
    2. Extracts the documents and enriches them with ingestion metadata
       (``airflow_ds`` and ``ingestion_timestamp``).
    3. Writes them as newline-delimited JSON.
    4. Uploads the result to a GCS prefix partitioned by ingest date.

It is intentionally simple but fully functional against the local fake
MongoDB defined in ``docker-compose.yml`` (and any real MongoDB / GCS).
"""

from __future__ import annotations

import json
import logging
import os
import tempfile
from datetime import datetime, timezone
from typing import Any

from airflow.models import BaseOperator
from airflow.utils.context import Context

log = logging.getLogger(__name__)


class MongoToGCSIngestionOperator(BaseOperator):
    """Extract a MongoDB collection and land it in GCS as NDJSON."""

    template_fields = ("gcs_prefix",)

    def __init__(
        self,
        *,
        mongo_database: str,
        mongo_collection: str,
        bucket: str,
        gcs_prefix: str,
        mongo_uri: str | None = None,
        gcp_conn_id: str = "google_cloud_default",
        query: dict[str, Any] | None = None,
        object_name: str = "part-00000.json",
        **kwargs,
    ) -> None:
        super().__init__(**kwargs)
        self.mongo_database = mongo_database
        self.mongo_collection = mongo_collection
        self.bucket = bucket
        self.gcs_prefix = gcs_prefix
        self.mongo_uri = mongo_uri
        self.gcp_conn_id = gcp_conn_id
        self.query = query or {}
        self.object_name = object_name

    def _extract(self, ds: str) -> list[dict]:
        from pymongo import MongoClient

        uri = self.mongo_uri or os.environ.get(
            "MONGO_URI", "mongodb://localhost:27017/?authSource=admin"
        )
        log.info(
            "[INGESTION] Extracting %s.%s from MongoDB",
            self.mongo_database,
            self.mongo_collection,
        )
        client = MongoClient(uri, serverSelectionTimeoutMS=10000)
        try:
            collection = client[self.mongo_database][self.mongo_collection]
            ingestion_ts = datetime.now(timezone.utc).replace(microsecond=0).isoformat()
            docs: list[dict] = []
            for doc in collection.find(self.query):
                doc.pop("__v", None)
                doc["airflow_ds"] = ds
                doc.setdefault("ingestion_timestamp", ingestion_ts)
                docs.append(doc)
            log.info("[INGESTION] Extracted %s documents", len(docs))
            return docs
        finally:
            client.close()

    def _write_ndjson(self, docs: list[dict]) -> str:
        tmp = tempfile.NamedTemporaryFile(
            mode="w", suffix=".json", delete=False, encoding="utf-8"
        )
        with tmp:
            for doc in docs:
                tmp.write(json.dumps(doc, default=str) + "\n")
        return tmp.name

    def _upload(self, local_path: str) -> str:
        from airflow.providers.google.cloud.hooks.gcs import GCSHook

        object_name = f"{self.gcs_prefix}/{self.object_name}"
        hook = GCSHook(gcp_conn_id=self.gcp_conn_id)
        hook.upload(
            bucket_name=self.bucket,
            object_name=object_name,
            filename=local_path,
        )
        uri = f"gs://{self.bucket}/{object_name}"
        log.info("[INGESTION] Uploaded landing file to %s", uri)
        return uri

    def execute(self, context: Context) -> str:
        ds = context["ds"]
        docs = self._extract(ds)
        local_path = self._write_ndjson(docs)
        try:
            return self._upload(local_path)
        finally:
            try:
                os.remove(local_path)
            except OSError:
                pass
