"""Mock dbt operator (kept for parity with the original project's imports)."""

from __future__ import annotations

import logging

from airflow.models import BaseOperator
from airflow.utils.context import Context

log = logging.getLogger(__name__)


class DBTOperator(BaseOperator):
    """Run a dbt command (mock).

    In production, dbt runs as a Cloud Run job (see
    ``CloudRunExecuteJobOperator`` in the DAGs). This operator is a placeholder
    used only for local parsing/demo.
    """

    template_fields = ("select", "target", "dbt_vars")

    def __init__(self, select: str = "", target: str = "dev", dbt_vars: str = "{}", **kwargs) -> None:
        super().__init__(**kwargs)
        self.select = select
        self.target = target
        self.dbt_vars = dbt_vars

    def execute(self, context: Context) -> None:
        log.info(
            "[MOCK DBT] dbt run --target %s --select %s --vars %s",
            self.target,
            self.select,
            self.dbt_vars,
        )
