from app.main import create_app


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

