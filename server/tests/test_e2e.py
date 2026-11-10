import asyncio
import dataclasses
import json

from starlette.websockets import WebSocketDisconnect

from hina.ai.base import Intent, NluResult
from hina.ai.nlu.stub import StubNLU
from hina.gateway.protocol import Kind, decode_frame, encode_frame
from hina.orchestrator.router import Orchestrator


def _use_nlu(client, nlu):
    """Thay NLU trong container đang chạy (dùng cho test độ trễ, vẫn là stub)."""
    c = client.app.state.container
    ai = dataclasses.replace(c.ai, nlu=nlu)
    orchestrator = Orchestrator(ai, c.scheduler, tts_timeout_s=c.settings.tts_timeout_s)
    client.app.state.container = dataclasses.replace(c, ai=ai, orchestrator=orchestrator)


class SlowNLU:
    def __init__(self, inner: StubNLU, delay_s: float) -> None:
        self._inner = inner
        self._delay_s = delay_s

    async def parse(self, text: str) -> NluResult:
        await asyncio.sleep(self._delay_s)
        return await self._inner.parse(text)


def _collect(ws, until):
    msgs = []
    while not until(msgs):
        m = ws.receive()
        msgs.append(json.loads(m["text"]) if m.get("text") is not None else decode_frame(m["bytes"]))
    return msgs


def _types(msgs):
    return [m["type"] if isinstance(m, dict) else "audio" for m in msgs]


def _result(msgs):
    return next(m for m in msgs if isinstance(m, dict) and m["type"] == "result")


def test_read_text_returns_text_and_tts(client, session):
    with client.websocket_connect("/ws", headers=session["headers"]) as ws:
        ws.send_bytes(encode_frame(Kind.IMAGE, 1, b"jpeg"))
        ws.send_bytes(encode_frame(Kind.AUDIO, 2, "đọc giúp tôi chữ trên tờ giấy".encode()))
        msgs = _collect(ws, lambda m: {"alert", "result", "audio"} <= set(_types(m)))

    result = _result(msgs)
    assert (result["intent"], result["intent_id"]) == ("READ_TEXT", int(Intent.READ_TEXT))
    assert result["text"] == "Nhà thuốc"
    assert next(m for m in msgs if not isinstance(m, dict))[2] == "Nhà thuốc".encode()


def test_visual_question_uses_vlm(client, session):
    with client.websocket_connect("/ws", headers=session["headers"]) as ws:
        ws.send_bytes(encode_frame(Kind.IMAGE, 1, b"jpeg"))
        ws.send_bytes(encode_frame(Kind.AUDIO, 2, "cái này màu gì".encode()))
        msgs = _collect(ws, lambda m: {"result"} <= set(_types(m)))

    result = _result(msgs)
    assert (result["intent"], result["intent_id"]) == (
        "ANSWER_VISUAL_QUESTION",
        int(Intent.ANSWER_VISUAL_QUESTION),
    )
    assert "con đường" in result["text"]


def test_describe_scene_uses_vlm(client, session):
    with client.websocket_connect("/ws", headers=session["headers"]) as ws:
        ws.send_bytes(encode_frame(Kind.IMAGE, 1, b"jpeg"))
        ws.send_bytes(encode_frame(Kind.AUDIO, 2, "mô tả cảnh trước mặt".encode()))
        msgs = _collect(ws, lambda m: {"result"} <= set(_types(m)))

    result = _result(msgs)
    assert (result["intent"], result["intent_id"]) == ("DESCRIBE_SCENE", int(Intent.DESCRIBE_SCENE))


def test_end_session_returns_goodbye_then_closes_1000(client, session):
    with client.websocket_connect("/ws", headers=session["headers"]) as ws:
        ws.send_bytes(encode_frame(Kind.AUDIO, 9, "kết thúc phiên".encode()))
        assert ws.receive()["bytes"]  # TTS tới trước result
        result = ws.receive_json()
        assert (result["intent"], result["intent_id"]) == ("END_SESSION", int(Intent.END_SESSION))
        try:
            closed = ws.receive()
        except WebSocketDisconnect as exc:
            assert exc.code == 1000
        else:
            assert closed["type"] == "websocket.close" and closed["code"] == 1000

    assert client.app.state.container.store.get(session["id"]) is None


def test_unknown_intent_keeps_connection(client, session):
    with client.websocket_connect("/ws", headers=session["headers"]) as ws:
        ws.send_bytes(encode_frame(Kind.AUDIO, 3, b"asdfgh qwerty"))
        ws.receive()  # khung TTS
        result = ws.receive_json()
        assert (result["intent"], result["intent_id"]) == ("UNKNOWN", int(Intent.UNKNOWN))
        ws.send_text('{"type":"ping"}')
        assert ws.receive_json() == {"type": "pong"}


def test_alert_is_emitted_while_nlu_is_slow(client, session):
    _use_nlu(client, SlowNLU(StubNLU(), delay_s=0.4))
    with client.websocket_connect("/ws", headers=session["headers"]) as ws:
        ws.send_bytes(encode_frame(Kind.IMAGE, 1, b"jpeg"))
        ws.send_bytes(encode_frame(Kind.AUDIO, 2, "mô tả cảnh trước mặt".encode()))
        msgs = _collect(ws, lambda m: {"alert", "result"} <= set(_types(m)))

    types = _types(msgs)
    assert types.index("alert") < types.index("result")
