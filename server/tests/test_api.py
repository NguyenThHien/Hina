import pytest
from starlette.websockets import WebSocketDisconnect


def test_health(client):
    assert client.get("/health").json() == {"status": "ok"}


def test_delete_requires_matching_token(client, session):
    url = f"/sessions/{session['id']}"
    assert client.delete(url).status_code == 401
    other = client.post("/sessions").json()
    assert client.delete(url, headers={"Authorization": f"Bearer {other['token']}"}).status_code == 403
    assert client.delete(url, headers=session["headers"]).status_code == 204


def test_ws_rejects_missing_token_and_deleted_session(client, session):
    with pytest.raises(WebSocketDisconnect), client.websocket_connect("/ws"):
        pass
    client.delete(f"/sessions/{session['id']}", headers=session["headers"])
    with pytest.raises(WebSocketDisconnect), client.websocket_connect("/ws", headers=session["headers"]):
        pass
