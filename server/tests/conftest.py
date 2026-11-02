import os

os.environ.setdefault("HINA_JWT_SECRET", "test-secret-not-for-prod-0123456789abcdef")

import pytest  # noqa: E402
from fastapi.testclient import TestClient  # noqa: E402

from hina.main import create_app  # noqa: E402


@pytest.fixture
def client():
    with TestClient(create_app()) as c:
        yield c


@pytest.fixture
def session(client):
    body = client.post("/sessions").json()
    return {"id": body["session_id"], "headers": {"Authorization": f"Bearer {body['token']}"}}
