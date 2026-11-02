import asyncio
import json
import logging

from fastapi import APIRouter, WebSocket
from starlette.websockets import WebSocketDisconnect

from hina.ai.scheduler import Busy
from hina.container import Container
from hina.gateway.auth import AuthError, bearer, verify
from hina.gateway.protocol import Kind, ProtocolError, decode_frame, encode_frame
from hina.safety.monitor import SafetyMonitor

log = logging.getLogger(__name__)
router = APIRouter()
WS_POLICY_VIOLATION = 1008


class _Outbox:
    """Nhiều task gửi chung 1 socket: khóa để không xen kẽ, bỏ qua khi client đã đi."""

    def __init__(self, ws: WebSocket) -> None:
        self._ws = ws
        self._lock = asyncio.Lock()

    async def json(self, obj: dict) -> None:
        await self._send(self._ws.send_text, json.dumps(obj, ensure_ascii=False))

    async def bytes(self, data: bytes) -> None:
        await self._send(self._ws.send_bytes, data)

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

    out = _Outbox(ws)
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
                elif kind is Kind.AUDIO:
                    task = asyncio.create_task(_answer(c, out, rid, payload, latest_image))
                    background.add(task)
                    task.add_done_callback(background.discard)
                else:
                    await out.json({"type": "error", "message": "unexpected frame kind"})
            elif msg.get("text") is not None:
                await _control(out, msg["text"])
    finally:
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
    c: Container, out: _Outbox, rid: int, audio: bytes, image: bytes | None
) -> None:
    try:
        reply = await c.orchestrator.handle(audio, image)
    except Busy:
        await out.json({"type": "error", "request_id": rid, "message": "server busy"})
        return
    except Exception:
        log.exception("request %s failed", rid)
        await out.json({"type": "error", "request_id": rid, "message": "internal error"})
        return
    await out.json(
        {"type": "result", "request_id": rid, "intent": reply.intent, "text": reply.text}
    )
    await out.bytes(encode_frame(Kind.TTS, rid, reply.audio))
