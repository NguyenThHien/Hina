"""FPT TTS: test bằng httpx.MockTransport, không cần key, không cần mạng."""

import asyncio
import io
import json
import time

import httpx
import pytest
from PIL import Image

from hina.ai.asr.stub import StubASR
from hina.ai.base import AiServices, Detection, Intent, NluResult
from hina.ai.depth.stub import StubDepth
from hina.ai.detection.stub import StubDetector
from hina.ai.nlu.http import HttpNLU
from hina.ai.nlu.stub import StubNLU
from hina.ai.ocr.stub import StubOCR
from hina.ai.registry import build_services
from hina.ai.scheduler import SAFETY, GpuScheduler
from hina.ai.tts.fpt import FptTTS, TtsError
from hina.ai.tts.stub import StubTTS
from hina.ai.vlm.stub import StubVLM
from hina.config import Settings
from hina.orchestrator.router import Orchestrator
from hina.preprocess.image import CropError

JPEG = b"\xff\xd8fake-jpeg"


def png(w: int, h: int) -> bytes:
    buf = io.BytesIO()
    Image.new("RGB", (w, h), (200, 30, 30)).save(buf, format="PNG")
    return buf.getvalue()


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
    assert reply.intent is Intent.DESCRIBE_SCENE and reply.audio == b"mp3"


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


# ---- HttpNLU ----

def nlu_handler(status: int = 200, label_id: int = 1, calls: list | None = None):
    calls = calls if calls is not None else []

    def handler(req: httpx.Request) -> httpx.Response:
        assert req.url.path == "/v1/predict"
        calls.append(json.loads(req.content))
        if status != 200:
            return httpx.Response(status, json={"detail": "boom"})
        return httpx.Response(200, json={"label_id": label_id, "confidence": 0.99})

    return handler


@pytest.mark.parametrize(
    ("label_id", "expected"),
    [
        (1, Intent.READ_TEXT),
        (2, Intent.DESCRIBE_SCENE),
        (3, Intent.ANSWER_VISUAL_QUESTION),
        (4, Intent.END_SESSION),
        (5, Intent.UNKNOWN),
    ],
)
def test_http_nlu_maps_label_id(label_id, expected):
    result = run_with(
        nlu_handler(label_id=label_id), lambda http: HttpNLU(http, "https://nlu.test").parse("xin chào")
    )
    assert result.intent is expected


@pytest.mark.parametrize("status", [422, 500])
def test_http_nlu_errors_become_unknown(status):
    result = run_with(
        nlu_handler(status=status), lambda http: HttpNLU(http, "https://nlu.test").parse("xin chào")
    )
    assert result.intent is Intent.UNKNOWN


def test_http_nlu_unknown_label_becomes_unknown():
    result = run_with(
        nlu_handler(label_id=99), lambda http: HttpNLU(http, "https://nlu.test").parse("xin chào")
    )
    assert result.intent is Intent.UNKNOWN


def test_http_nlu_timeout_becomes_unknown():
    def timeout(req):
        raise httpx.ConnectTimeout("too slow")

    result = run_with(
        timeout, lambda http: HttpNLU(http, "https://nlu.test", timeout_s=0.01).parse("xin chào")
    )
    assert result.intent is Intent.UNKNOWN


def test_http_nlu_truncates_to_500_chars():
    calls: list = []
    run_with(
        nlu_handler(calls=calls),
        lambda http: HttpNLU(http, "https://nlu.test").parse("a" * 800),
    )
    assert len(calls[0]["text"]) == 500


def test_http_nlu_skips_blank_text_without_request():
    calls: list = []
    result = run_with(
        nlu_handler(calls=calls), lambda http: HttpNLU(http, "https://nlu.test").parse("   ")
    )
    assert result.intent is Intent.UNKNOWN and calls == []


def test_registry_wires_http_nlu():
    async def main():
        async with httpx.AsyncClient() as http:
            return build_services(Settings(jwt_secret="x" * 32, nlu="http"), http)

    services_ = asyncio.run(main())
    assert isinstance(services_.nlu, HttpNLU)


# ---- Router: READ_TEXT crop + END_SESSION ----

class TwoBoxDetector:
    def __init__(self):
        self.calls = 0

    async def detect(self, image):
        self.calls += 1
        return [
            Detection("a", (0.0, 0.0, 0.4, 0.4), 0.9),
            Detection("b", (0.5, 0.5, 0.9, 0.9), 0.9),
        ]


class EmptyDetector:
    async def detect(self, image):
        return []


class LowConfDetector:
    async def detect(self, image):
        return [Detection("a", (0.0, 0.0, 0.4, 0.4), 0.4)]


class SizeOCR:
    def __init__(self):
        self.sizes = []

    async def read(self, image):
        self.sizes.append(Image.open(io.BytesIO(image)).size)
        return f"text{len(self.sizes)}"


class SlowNLU:
    async def parse(self, text):
        await asyncio.sleep(0.3)
        return NluResult(Intent.DESCRIBE_SCENE)


def run_orch(audio: str, image: bytes | None, **overrides):
    async def main():
        scheduler = GpuScheduler(max_queue=8)
        scheduler.start()
        try:
            return await Orchestrator(services(**overrides), scheduler).handle(audio.encode(), image)
        finally:
            await scheduler.stop()

    return asyncio.run(main())


def test_read_text_ocrs_each_crop_and_numbers_results():
    ocr = SizeOCR()
    reply = run_orch("đọc giúp tôi", png(100, 100), detector=TwoBoxDetector(), ocr=ocr)
    assert ocr.sizes == [(40, 40), (40, 40)]
    assert reply.text == "1) text1\n2) text2"


def test_read_text_falls_back_to_full_frame_without_boxes():
    ocr = SizeOCR()
    reply = run_orch("đọc giúp tôi", png(100, 100), detector=EmptyDetector(), ocr=ocr)
    assert ocr.sizes == [(100, 100)] and reply.text == "text1"


def test_read_text_filters_low_confidence_boxes():
    ocr = SizeOCR()
    run_orch("đọc giúp tôi", png(100, 100), detector=LowConfDetector(), ocr=ocr)
    assert ocr.sizes == [(100, 100)]


def test_read_text_crop_failure_falls_back(monkeypatch):
    def boom(image, box, **kwargs):
        raise CropError("cannot crop")

    monkeypatch.setattr("hina.orchestrator.router.crop", boom)
    reply = run_orch("đọc giúp tôi", png(100, 100), detector=TwoBoxDetector(), ocr=SizeOCR())
    assert reply.text == "text1"


def test_end_session_needs_no_image_and_flags_reply():
    reply = run_orch("kết thúc phiên", None)
    assert reply.intent is Intent.END_SESSION and reply.end_session
    assert reply.text == "Đã kết thúc phiên. Tạm biệt bạn."


def test_unknown_intent_asks_to_repeat():
    reply = run_orch("asdfgh", None)
    assert reply.intent is Intent.UNKNOWN and not reply.end_session


def test_slow_nlu_api_does_not_block_safety():
    async def main():
        scheduler = GpuScheduler(max_queue=8)
        scheduler.start()
        orch = Orchestrator(services(nlu=SlowNLU()), scheduler)
        request = asyncio.create_task(orch.handle("mô tả giúp tôi".encode(), JPEG))
        await asyncio.sleep(0.05)

        started = time.perf_counter()
        await scheduler.run(SAFETY, lambda: asyncio.sleep(0))
        safety_s = time.perf_counter() - started
        still_waiting = not request.done()
        reply = await request
        await scheduler.stop()
        return safety_s, still_waiting, reply

    safety_s, still_waiting, reply = asyncio.run(main())
    assert safety_s < 0.1 and still_waiting
    assert reply.intent is Intent.DESCRIBE_SCENE
