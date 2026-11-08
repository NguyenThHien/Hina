import json

from starlette.websockets import WebSocketDisconnect

from hina.gateway.protocol import Kind, decode_frame, encode_frame


def _collect(ws, until):
    """Đọc message tới khi `until(msgs)` đúng; trả về list (json dict | (kind, rid, bytes))."""
    msgs = []
    while not until(msgs):
        m = ws.receive()
        msgs.append(json.loads(m["text"]) if m.get("text") is not None else decode_frame(m["bytes"]))
    return msgs


def _types(msgs):
    return [m["type"] if isinstance(m, dict) else "audio" for m in msgs]


def test_ping_pong(client, session):
    with client.websocket_connect("/ws", headers=session["headers"]) as ws:
        ws.send_text('{"type":"ping"}')
        assert ws.receive_json() == {"type": "pong"}


def test_audio_without_image_asks_for_image(client, session):
    with client.websocket_connect("/ws", headers=session["headers"]) as ws:
        ws.send_bytes(encode_frame(Kind.AUDIO, 7, "đọc giúp tôi chữ".encode()))
        msgs = _collect(ws, lambda m: len(m) == 2)
    result = next(m for m in msgs if isinstance(m, dict))
    assert result["request_id"] == 7 and result["intent"] == "NO_IMAGE"


def test_read_text_with_image_returns_text_and_tts(client, session):
    with client.websocket_connect("/ws", headers=session["headers"]) as ws:
        ws.send_bytes(encode_frame(Kind.IMAGE, 1, b"jpeg"))
        ws.send_bytes(encode_frame(Kind.AUDIO, 2, "đọc giúp tôi chữ".encode()))
        msgs = _collect(ws, lambda m: {"alert", "result", "audio"} <= set(_types(m)))
    result = next(m for m in msgs if isinstance(m, dict) and m["type"] == "result")
    assert result["text"] == "Nhà thuốc"
    kind, rid, payload = next(m for m in msgs if not isinstance(m, dict))
    assert (kind, rid, payload) == (Kind.TTS, 2, "Nhà thuốc".encode())


def test_image_triggers_alert_independent_of_questions(client, session):
    with client.websocket_connect("/ws", headers=session["headers"]) as ws:
        ws.send_bytes(encode_frame(Kind.IMAGE, 1, b"jpeg"))
        alert = ws.receive_json()
    assert alert["type"] == "alert" and alert["label"] == "person"
    assert alert["direction"] == "ahead" and alert["distance_m"] == 1.5


def test_bad_frame_gets_error_and_connection_survives(client, session):
    with client.websocket_connect("/ws", headers=session["headers"]) as ws:
        ws.send_bytes(b"\x09\x00")
        assert ws.receive_json()["type"] == "error"
        ws.send_text('{"type":"ping"}')
        assert ws.receive_json() == {"type": "pong"}


def test_result_carries_intent_name_and_id(client, session):
    with client.websocket_connect("/ws", headers=session["headers"]) as ws:
        ws.send_bytes(encode_frame(Kind.IMAGE, 1, b"jpeg"))
        ws.send_bytes(encode_frame(Kind.AUDIO, 2, "đọc giúp tôi chữ".encode()))
        msgs = _collect(ws, lambda m: {"result"} <= set(_types(m)))
    result = next(m for m in msgs if isinstance(m, dict) and m["type"] == "result")
    assert result["intent"] == "READ_TEXT" and result["intent_id"] == 1


def test_end_session_closes_with_1000_and_deletes_session(client, session):
    with client.websocket_connect("/ws", headers=session["headers"]) as ws:
        ws.send_bytes(encode_frame(Kind.AUDIO, 9, "kết thúc phiên".encode()))
        result = ws.receive_json()
        assert result["intent"] == "END_SESSION" and result["intent_id"] == 4
        assert result["text"] == "Đã kết thúc phiên. Tạm biệt bạn."
        assert ws.receive()["bytes"]
        try:
            closed = ws.receive()
        except WebSocketDisconnect as e:
            assert e.code == 1000
        else:
            assert closed["type"] == "websocket.close" and closed["code"] == 1000
    assert client.app.state.container.store.get(session["id"]) is None


def test_unknown_intent_asks_to_repeat_and_keeps_connection(client, session):
    with client.websocket_connect("/ws", headers=session["headers"]) as ws:
        ws.send_bytes(encode_frame(Kind.AUDIO, 3, b"asdfgh qwerty"))
        assert ws.receive_json()["intent"] == "UNKNOWN"
        ws.receive()
        ws.send_text('{"type":"ping"}')
        assert ws.receive_json() == {"type": "pong"}
