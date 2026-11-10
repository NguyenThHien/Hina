import asyncio
import json
import logging
from collections.abc import Callable
from functools import partial

from fastapi import APIRouter, WebSocket
from starlette.websockets import WebSocketDisconnect

from hina.ai.base import Intent
from hina.ai.scheduler import Busy
from hina.container import Container
from hina.gateway.auth import AuthError, bearer, verify
from hina.gateway.protocol import Kind, ProtocolError, decode_frame, encode_frame
from hina.safety.monitor import SafetyMonitor

log = logging.getLogger(__name__)
router = APIRouter()
WS_POLICY_VIOLATION = 1008
WS_NORMAL_CLOSURE = 1000


class _Outbox:
    """Nhiều task gửi chung 1 socket: khóa để không xen kẽ, bỏ qua khi client đã đi."""

    def __init__(self, ws: WebSocket, on_json: Callable[[dict], None]) -> None:
        self._ws = ws
        self._lock = asyncio.Lock()
        self._on_json = on_json

    async def json(self, obj: dict) -> None:
        self._on_json(obj)
        await self._send(self._ws.send_text, json.dumps(obj, ensure_ascii=False))

    async def bytes(self, data: bytes) -> None:
        await self._send(self._ws.send_bytes, data)

    async def close(self, code: int) -> None:
        async with self._lock:
            try:
                await self._ws.close(code=code)
            except (WebSocketDisconnect, RuntimeError):
                pass

    async def _send(self, send, payload) -> None:
        async with self._lock:
            try:
                await send(payload)
            except (WebSocketDisconnect, RuntimeError):
                pass


@router.websocket("/ws")
async def ws_endpoint(ws: WebSocket) -> None:
    c: Container = ws.app.state.container
    try:
        sid = verify(bearer(ws.headers.get("authorization")), c.settings.jwt_secret)
        if c.store.get(sid) is None:
            raise AuthError("unknown session")
    except AuthError:
        await ws.close(code=WS_POLICY_VIOLATION)
        return
    await ws.accept()
    dbg = c.debug
    dbg.add(sid, None, "connect")
    out = _Outbox(ws, lambda obj: dbg.add(sid, obj.get("request_id"), f"send:{obj.get('type')}", **obj))
    safety = SafetyMonitor(c.ai.detector, c.ai.depth, c.scheduler, out.json)
    background = {asyncio.create_task(safety.run())}
    latest_image: bytes | None = None
    try:
        while True:
            msg = await ws.receive()
            if msg["type"] == "websocket.disconnect":
                break
            if msg.get("bytes") is not None:
                try:
                    kind, rid, payload = decode_frame(msg["bytes"])
                except ProtocolError as e:
                    await out.json({"type": "error", "message": str(e)})
                    continue
                if kind is Kind.IMAGE:
                    latest_image = payload
                    safety.submit(payload)
                    dbg.frame(sid, payload)
                elif kind is Kind.AUDIO:
                    image_bytes = len(latest_image) if latest_image else 0
                    dbg.add(sid, rid, "recv:audio", bytes=len(payload), image_bytes=image_bytes)
                    task = asyncio.create_task(_answer(c, out, sid, rid, payload, latest_image))
                    background.add(task)
                    task.add_done_callback(background.discard)
                else:
                    await out.json({"type": "error", "message": "unexpected frame kind"})
            elif msg.get("text") is not None:
                await _control(out, msg["text"])
    finally:
        dbg.add(sid, None, "disconnect")
        dbg.forget(sid)
        for t in background:
            t.cancel()
        await asyncio.gather(*background, return_exceptions=True)


async def _control(out: _Outbox, text: str) -> None:
    try:
        data = json.loads(text)
    except json.JSONDecodeError:
        data = None
    if isinstance(data, dict) and data.get("type") == "ping":
        await out.json({"type": "pong"})
    else:
        await out.json({"type": "error", "message": "unknown control message"})


async def _answer(
    c: Container, out: _Outbox, sid: str, rid: int, audio: bytes, image: bytes | None
) -> None:
    try:
        reply = await c.orchestrator.handle(audio, image, partial(c.debug.add, sid, rid))
    except Busy:
        await out.json({"type": "error", "request_id": rid, "message": "server busy"})
        return
    except Exception as e:
        log.exception("request %s failed", rid)
        c.debug.add(sid, rid, "fail", error=f"{type(e).__name__}: {e}")
        await out.json({"type": "error", "request_id": rid, "message": "internal error"})
        return
    # IntEnum: str() trả "1" ở Python 3.11+, nên luôn gửi tên cho mobile.
    intent = reply.intent.name if isinstance(reply.intent, Intent) else reply.intent
    body = {"type": "result", "request_id": rid, "intent": intent, "text": reply.text}
    if isinstance(reply.intent, Intent):
        body["intent_id"] = int(reply.intent)
    # Audio gửi TRƯỚC result: mobile nhận result là biết ngay có MP3 hay phải tự đọc text.
    if reply.audio:
        await out.bytes(encode_frame(Kind.TTS, rid, reply.audio))
        c.debug.add(sid, rid, "send:tts", bytes=len(reply.audio))
    await out.json(body)
    if reply.end_session:
        await out.close(WS_NORMAL_CLOSURE)
        c.store.delete(sid)
