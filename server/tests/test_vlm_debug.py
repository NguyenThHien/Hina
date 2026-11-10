"""Gemini VLM (httpx.MockTransport, không cần key/mạng), chia caption/VQA, trang /debug."""

import asyncio
import base64
import json

import httpx
import pytest

from hina.ai.asr.stub import StubASR
from hina.ai.base import AiServices, Intent, NluResult
from hina.ai.depth.stub import StubDepth
from hina.ai.detection.stub import StubDetector
from hina.ai.ocr.stub import StubOCR
from hina.ai.registry import build_services
from hina.ai.scheduler import GpuScheduler
from hina.ai.tts.stub import StubTTS
from hina.ai.vlm.gemini import CAPTION_PROMPT, GeminiVLM, VlmError
from hina.config import Settings
from hina.gateway.protocol import Kind, encode_frame

JPEG = b"\xff\xd8fake-jpeg"


def gemini(handler) -> str:
    async def main():
        async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as http:
            vlm = GeminiVLM(http, "k-test", "gemini-test", "https://gemini.test/v1beta/")
            return await vlm.answer(JPEG, None)

    return asyncio.run(main())


def ok(text: str):
    return httpx.Response(200, json={"candidates": [{"content": {"parts": [{"text": text}]}}]})


def test_gemini_sends_image_and_caption_prompt():
    seen = {}

    def handler(req: httpx.Request) -> httpx.Response:
        seen["url"] = str(req.url)
        seen["key"] = req.headers["x-goog-api-key"]
        seen["body"] = json.loads(req.content)
        return ok("  Phía trước là cửa hàng.  ")

    assert gemini(handler) == "Phía trước là cửa hàng."
    assert seen["url"] == "https://gemini.test/v1beta/models/gemini-test:generateContent"
    assert seen["key"] == "k-test"
    parts = seen["body"]["contents"][0]["parts"]
    assert base64.b64decode(parts[0]["inline_data"]["data"]) == JPEG
    assert parts[1]["text"] == CAPTION_PROMPT


@pytest.mark.parametrize(
    "response",
    [
        httpx.Response(200, json={"promptFeedback": {"blockReason": "SAFETY"}}),
        httpx.Response(200, json={"candidates": [{"content": {"parts": [{"text": " "}]}}]}),
        httpx.Response(429, json={"error": {"message": "quota"}}),
    ],
)
def test_gemini_errors_raise(response):
    with pytest.raises(VlmError):
        gemini(lambda req: response)


def test_registry_gemini_requires_key():
    async def main():
        async with httpx.AsyncClient() as http:
            build_services(Settings(vlm="gemini", gemini_api_key=None), http)

    with pytest.raises(ValueError, match="HINA_GEMINI_API_KEY"):
        asyncio.run(main())


def test_registry_gemini_requires_base_url():
    async def main():
        async with httpx.AsyncClient() as http:
            build_services(Settings(vlm="gemini", gemini_api_key="k", gemini_base_url=None), http)

    with pytest.raises(ValueError, match="HINA_GEMINI_BASE_URL"):
        asyncio.run(main())


class _RecordingVLM:
    remote = True

    def __init__(self) -> None:
        self.questions: list[str | None] = []

    async def answer(self, image: bytes, question: str | None) -> str:
        self.questions.append(question)
        return "mô tả"


class _FixedNLU:
    def __init__(self, intent: Intent) -> None:
        self.intent = intent

    async def parse(self, text: str) -> NluResult:
        return NluResult(self.intent)


@pytest.mark.parametrize(
    ("intent", "question"),
    [(Intent.DESCRIBE_SCENE, None), (Intent.ANSWER_VISUAL_QUESTION, "cái này màu gì")],
)
def test_describe_is_caption_and_visual_question_passes_text(intent, question):
    from hina.orchestrator.router import Orchestrator

    vlm = _RecordingVLM()
    ai = AiServices(StubASR(), _FixedNLU(intent), StubOCR(), StubDetector(), StubDepth(), vlm, StubTTS())
    notes: list[str] = []

    async def main():
        scheduler = GpuScheduler(4)
        scheduler.start()
        try:
            orch = Orchestrator(ai, scheduler)
            return await orch.handle("cái này màu gì".encode(), JPEG, lambda stage, **d: notes.append(stage))
        finally:
            await scheduler.stop()

    reply = asyncio.run(main())
    assert reply.text == "mô tả"
    assert vlm.questions == [question]
    assert notes == ["asr", "nlu", "route", "tts"]


def test_debug_page_shows_request_flow(client, session):
    assert client.get("/debug").status_code == 200
    with client.websocket_connect("/ws", headers=session["headers"]) as ws:
        ws.send_bytes(encode_frame(Kind.IMAGE, 1, JPEG))
        ws.send_bytes(encode_frame(Kind.AUDIO, 2, "đọc giúp tôi chữ".encode()))
        while True:
            m = ws.receive()
            if m.get("text") and json.loads(m["text"])["type"] == "result":
                break
        data = client.get("/debug/events").json()
        assert client.get(f"/debug/frame/{session['id']}").content == JPEG

    stages = [e["stage"] for e in data["events"] if e["rid"] == 2]
    assert stages == ["recv:audio", "asr", "nlu", "route", "tts", "send:tts", "send:result"]
    assert data["sessions"][session["id"]]["count"] == 1


def test_debug_disabled_returns_404(monkeypatch):
    from fastapi.testclient import TestClient

    from hina.main import create_app

    monkeypatch.setenv("HINA_DEBUG", "false")
    with TestClient(create_app()) as c:
        assert c.get("/debug").status_code == 404
        assert c.get("/debug/events").status_code == 404
