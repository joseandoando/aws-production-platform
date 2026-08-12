"""Minimal API used to demonstrate ECS deployment and health signalling."""

from __future__ import annotations

import logging
import os
import time
from datetime import datetime, timezone

from flask import Flask, jsonify


def create_app() -> Flask:
    app = Flask(__name__)
    started_at = time.monotonic()
    app_env = os.getenv("APP_ENV", "development")

    logging.basicConfig(
        level=os.getenv("LOG_LEVEL", "INFO").upper(),
        format="%(asctime)s %(levelname)s %(name)s %(message)s",
    )

    @app.get("/")
    def index():
        return jsonify(
            service="aws-production-platform-api",
            environment=app_env,
            status="running",
            timestamp=datetime.now(timezone.utc).isoformat(),
        )

    @app.get("/health")
    def health():
        """Liveness: the process can serve requests."""
        return jsonify(status="healthy", uptime_seconds=round(time.monotonic() - started_at, 3))

    @app.get("/ready")
    def ready():
        """Readiness: this stateless example is ready after application startup."""
        return jsonify(status="ready")

    return app


app = create_app()
