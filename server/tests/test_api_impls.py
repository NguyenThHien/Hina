"""FPT TTS: test bằng httpx.MockTransport, không cần key, không cần mạng."""

import asyncio
import time

import httpx
import pytest

from hina.ai.asr.stub import StubASR
from hina.ai.base import AiServices
from hina.ai.depth.stub import StubDepth
from hina.ai.detection.stub import StubDetector
from hina.ai.nlu.stub import StubNLU
from hina.ai.ocr.stub import StubOCR
from hina.ai.registry import build_services
from hina.ai.scheduler import SAFETY, GpuScheduler
from hina.ai.tts.fpt import FptTTS, TtsError
from hina.ai.tts.stub import StubTTS
from hina.ai.vlm.stub import StubVLM
from hina.config import Settings
from hina.orchestrator.router import Orchestrator

JPEG = b"\xff\xd8fake-jpeg"


def run_with(handler, fn):
    async def main():
        async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as http:
            return await fn(http)

    return asyncio.run(main())


# ---- FPT ----

def fpt_handler(pending_polls: int, audio: bytes = b"ID3-mp3"):
    calls = {"post": 0, "get": 0, "headers": None, "body": None}

    def handler(req: httpx.Request) -> httpx.Response:
        if req.method == "POST":
            calls["post"] += 1
            calls["headers"] = req.headers
            calls["body"] = req.content.decode()
            return httpx.Response(200, json={"error": 0, "async": "https://file.test/a.mp3", "message": "ok"})
        calls["get"] += 1
        if calls["get"] <= pending_polls:
            return httpx.Response(404)
        return httpx.Response(200, content=audio)

    return handler, calls


def test_fpt_polls_until_audio_ready():
    handler, calls = fpt_handler(pending_polls=2)
    audio = run_with(
        handler, lambda http: FptTTS(http, "fk", voice="leminh", poll_interval_s=0).synthesize("Nhà thuốc")
    )

    assert audio == b"ID3-mp3"
    assert calls["get"] == 3
    assert calls["body"] == "Nhà thuốc"
    assert calls["headers"]["api-key"] == "fk"
    assert calls["headers"]["voice"] == "leminh"


def test_fpt_raises_when_api_reports_error():
    def handler(req):
        return httpx.Response(200, json={"error": 1, "message": "invalid api key"})

    with pytest.raises(TtsError, match="invalid api key"):
        run_with(handler, lambda http: FptTTS(http, "bad", poll_interval_s=0).synthesize("x"))


def test_fpt_poll_is_bounded_by_caller_timeout():
    handler, _ = fpt_handler(pending_polls=10_000)

    async def call(http):
        async with asyncio.timeout(0.05):
            return await FptTTS(http, "fk", poll_interval_s=0.005).synthesize("x")

    with pytest.raises(TimeoutError):
        run_with(handler, call)


# ---- Registry ----

def test_fpt_without_key_fails_at_startup():
    settings = Settings(tts="fpt", fpt_api_key=None)

    async def main():
        async with httpx.AsyncClient() as http:
            build_services(settings, http)

    with pytest.raises(ValueError, match="HINA_FPT_API_KEY"):
        asyncio.run(main())


# ---- Orchestrator ----

class SlowTTS:
    async def synthesize(self, text):
        await asyncio.sleep(0.3)  # giả lập chờ API
        return b"mp3"


class FailingTTS:
    async def synthesize(self, text):
        raise RuntimeError("tts down")


def services(**overrides) -> AiServices:
    base = dict(
        asr=StubASR(), nlu=StubNLU(), ocr=StubOCR(), detector=StubDetector(),
        depth=StubDepth(), vlm=StubVLM(), tts=StubTTS(),
    )
    return AiServices(**{**base, **overrides})


def test_slow_tts_api_does_not_block_safety():
    async def main():
        scheduler = GpuScheduler(max_queue=8)
        scheduler.start()
        orch = Orchestrator(services(tts=SlowTTS()), scheduler)
        request = asyncio.create_task(orch.handle("mô tả giúp tôi".encode(), JPEG))
        await asyncio.sleep(0.05)  # TTS đang chờ "mạng"

        async def safety_job():
            return "checked"

        started = time.perf_counter()
        result = await scheduler.run(SAFETY, safety_job)
        safety_s = time.perf_counter() - started
        still_waiting = not request.done()
        reply = await request
        await scheduler.stop()
        return result, safety_s, still_waiting, reply

    result, safety_s, still_waiting, reply = asyncio.run(main())
    assert result == "checked" and safety_s < 0.1
    assert still_waiting
    assert reply.intent == "DESCRIBE_SCENE" and reply.audio == b"mp3"


def test_tts_failure_keeps_text_answer():
    async def main():
        scheduler = GpuScheduler(max_queue=8)
        scheduler.start()
        reply = await Orchestrator(services(tts=FailingTTS()), scheduler).handle(
            "đọc giúp tôi".encode(), JPEG
        )
        await scheduler.stop()
        return reply

    reply = asyncio.run(main())
    assert reply.text == "Nhà thuốc"
    assert reply.audio == b""
