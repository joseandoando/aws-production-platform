from unittest.mock import Mock

import app.main as main

create_app = main.create_app


def test_root():
    response = create_app().test_client().get("/")
    assert response.status_code == 200
    assert response.json["service"] == "aws-production-platform-api"
    assert response.json["status"] == "running"


def test_health():
    response = create_app().test_client().get("/health")
    assert response.status_code == 200
    assert response.json["status"] == "healthy"


def test_ready():
    response = create_app().test_client().get("/ready")
    assert response.status_code == 200
    assert response.json == {"status": "ready"}


def test_ready_checks_configured_tcp_dependency(monkeypatch):
    connection = Mock()
    monkeypatch.setenv("READINESS_TCP_HOST", "database")
    monkeypatch.setenv("READINESS_TCP_PORT", "5432")
    monkeypatch.setattr(main.socket, "create_connection", Mock(return_value=connection))

    response = create_app().test_client().get("/ready")

    assert response.status_code == 200
    assert response.json == {"status": "ready"}
    main.socket.create_connection.assert_called_once_with(("database", 5432), timeout=1)
    connection.close.assert_called_once_with()


def test_ready_returns_503_when_dependency_is_unavailable(monkeypatch):
    monkeypatch.setenv("READINESS_TCP_HOST", "database")
    monkeypatch.setenv("READINESS_TCP_PORT", "5432")
    monkeypatch.setattr(main.socket, "create_connection", Mock(side_effect=OSError))

    response = create_app().test_client().get("/ready")

    assert response.status_code == 503
    assert response.json == {"dependency": "tcp", "status": "not_ready"}
