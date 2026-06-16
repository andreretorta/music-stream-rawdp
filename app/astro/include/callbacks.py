"""Mock DAG/task callbacks (replacement for the proprietary orchestration hub).

The corporate project reported task/DAG state to a central orchestration
service. Here we simply log the event.
"""

from __future__ import annotations

import logging

log = logging.getLogger(__name__)


def orchestration_callback(context) -> None:
    """Log task/DAG lifecycle events instead of calling a real service."""
    task_instance = context.get("task_instance")
    dag_run = context.get("dag_run")
    state = getattr(task_instance, "state", "unknown")
    task_id = getattr(task_instance, "task_id", "unknown")
    dag_id = getattr(dag_run, "dag_id", "unknown")
    log.info("[MOCK ORCHESTRATION] dag=%s task=%s state=%s", dag_id, task_id, state)
