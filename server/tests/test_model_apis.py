"""Client cho các model tự host (*-api): test bằng httpx.MockTransport, không cần mạng/key thật."""

import asyncio
import io
import json
import time
import wave
from functools import partial

import httpx
import pytest

from hina.ai.asr.phowhisper import PhoWhisperASR
from hina.ai.asr.stub import StubASR
from hina.ai.base import AiServices, Detection
from hina.ai.depth.none import NoDepth
from hina.ai.detection.ppocr import PpocrTextDetector
from hina.ai.detection.stub import StubDetector
from hina.ai.detection.yolo import YoloDetector
from hina.ai.http_api import ModelApiError
from hina.ai.nlu.stub import StubNLU
from hina.ai.ocr.vietocr import VietOCR
from hina.ai.registry import build_services
from hina.ai.scheduler import SAFETY, GpuScheduler
from hina.ai.tts.mms import MmsTTS
from hina.ai.tts.stub import StubTTS
from hina.ai.vlm.smolvlm import SmolVLM
from hina.ai.vlm.stub import StubVLM
from hina.config import Settings
from hina.orchestrator.router import Orchestrator
from hina.preprocess.audio import prepare_audio
from hina.safety.monitor import SafetyMonitor

KEY = "k" * 20
JPEG = b"\xff\xd8fake-jpeg"


def call(handler, fn):
    async def main():
        async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as http:
            return await fn(http)

    return asyncio.run(main())


def recorder(response: httpx.Response):
    seen: list[httpx.Request] = []

    def handler(req: httpx.Request) -> httpx.Response:
        req.read()
        seen.append(req)
        return response

    return handler, seen


# ---- audio ----

def test_prepare_audio_wraps_raw_pcm_as_16k_mono_wav():
    pcm = b"\x01\x00" * 1600 + b"\x07"  # byte lẻ cuối bị bỏ
    with wave.open(io.BytesIO(prepare_audio(pcm))) as w:
        assert (w.getnchannels(), w.getsampwidth(), w.getframerate(), w.getnframes()) == (1, 2, 16000, 1600)


def test_prepare_audio_keeps_existing_wav():
    wav = prepare_audio(b"\x00\x00" * 10)
    assert prepare_audio(wav) == wav


# ---- từng client ----

def test_phowhisper_sends_wav_with_api_key():
    handler, seen = recorder(httpx.Response(200, json={"text": " xin chào "}))
    text = call(handler, lambda h: PhoWhisperASR(h, "http://stt/", KEY, 5).transcribe(b"\x00\x00" * 100))
    assert text == "xin chào"
    req = seen[0]
    assert str(req.url) == "http://stt/transcribe" and req.headers["x-api-key"] == KEY
    assert b"RIFF" in req.content and b'name="file"' in req.content


def test_ppocr_normalizes_polygons_to_boxes():
    body = {"width": 200, "height": 100, "boxes": [
        {"polygon": [[20, 10], [120, 12], [118, 40], [22, 38]], "score": 0.88},
    ]}
    handler, _ = recorder(httpx.Response(200, json=body))
    dets = call(handler, lambda h: PpocrTextDetector(h, "http://det", KEY, 5).detect(JPEG))
    assert dets == [Detection("text", (0.1, 0.1, 0.6, 0.4), 0.88)]


def test_yolo_normalizes_boxes_and_sends_conf():
    body = {"width": 100, "height": 50, "boxes": [
        {"class_id": 0, "name": "person", "confidence": 0.9, "box": [10, 5, 50, 60]},
    ]}
    handler, seen = recorder(httpx.Response(200, json=body))
    dets = call(handler, lambda h: YoloDetector(h, "http://yolo", KEY, 5, 0.35).detect(JPEG))
    assert dets == [Detection("person", (0.1, 0.1, 0.5, 1.0), 0.9)]  # tràn biên bị clamp
    assert b'name="conf"' in seen[0].content and b"0.35" in seen[0].content


def test_vietocr_returns_text():
    handler, _ = recorder(httpx.Response(200, json={"text": "Nhà thuốc ", "confidence": 0.9}))
    assert call(handler, lambda h: VietOCR(h, "http://ocr", KEY, 5).read(JPEG)) == "Nhà thuốc"


@pytest.mark.parametrize(("question", "expected"), [(None, b"Describe"), ("what color?", b"what color?")])
def test_smolvlm_caption_or_question(question, expected):
    handler, seen = recorder(httpx.Response(200, json={"answer": "A red cup."}))
    answer = call(handler, lambda h: SmolVLM(h, "http://vlm", KEY, 48).answer(JPEG, question))
    assert answer == "A red cup."
    assert expected in seen[0].content and b"48" in seen[0].content


def test_mms_posts_json_and_returns_wav():
    handler, seen = recorder(httpx.Response(200, content=b"RIFF....WAVE"))
    audio = call(handler, lambda h: MmsTTS(h, "http://tts", KEY).synthesize("x" * 1500))
    assert audio.startswith(b"RIFF")
    assert len(json.loads(seen[0].content)["text"]) == 1000


def test_api_error_raises_without_leaking_key():
    handler, _ = recorder(httpx.Response(500, json={"detail": "boom"}))
    with pytest.raises(ModelApiError) as e:
        call(handler, lambda h: VietOCR(h, "http://ocr", KEY, 5).read(JPEG))
    assert "500" in str(e.value) and KEY not in str(e.value)


# ---- registry ----

def test_registry_wires_self_hosted_models():
    settings = Settings(
        asr="phowhisper", text_detector="ppocr", ocr="vietocr", detector="yolo", depth="none",
        vlm="smolvlm", tts="mms", phowhisper_api_key=KEY, ppocr_api_key=KEY, vietocr_api_key=KEY,
        yolo_api_key=KEY, smolvlm_api_key=KEY, mms_api_key=KEY,
    )

    async def main():
        async with httpx.AsyncClient() as http:
            return build_services(settings, http)

    ai = asyncio.run(main())
    assert isinstance(ai.asr, PhoWhisperASR) and isinstance(ai.text_detector, PpocrTextDetector)
    assert isinstance(ai.detector, YoloDetector) and isinstance(ai.depth, NoDepth)
    assert isinstance(ai.vlm, SmolVLM) and isinstance(ai.tts, MmsTTS)


def test_registry_missing_key_fails_at_startup():
    settings = Settings(ocr="vietocr", vietocr_api_key=None)

    async def main():
        async with httpx.AsyncClient() as http:
            build_services(settings, http)

    with pytest.raises(ValueError, match="HINA_VIETOCR_API_KEY"):
        asyncio.run(main())


# ---- routing ----

class Tagged:
    def __init__(self, label: str) -> None:
        self.label = label
        self.calls = 0

    async def detect(self, image):
        self.calls += 1
        return [Detection(self.label, (0.0, 0.0, 0.5, 0.5), 0.9)]


def services(**overrides) -> AiServices:
    base = dict(
        asr=StubASR(), nlu=StubNLU(), ocr=VietOCRStub(), detector=StubDetector(), depth=NoDepth(),
        vlm=StubVLM(), tts=StubTTS(), text_detector=StubDetector(),
    )
    return AiServices(**{**base, **overrides})


class VietOCRStub:
    async def read(self, image):
        return "chữ"


def test_read_text_uses_text_detector_not_safety_detector():
    text_det, safety_det = Tagged("text"), Tagged("person")

    async def main():
        scheduler = GpuScheduler(8)
        scheduler.start()
        try:
            orch = Orchestrator(services(text_detector=text_det, detector=safety_det), scheduler)
            return await orch.handle("đọc giúp tôi".encode(), JPEG)
        finally:
            await scheduler.stop()

    asyncio.run(main())
    assert (text_det.calls, safety_det.calls) == (1, 0)


class SlowRemoteASR:
    remote = True

    async def transcribe(self, audio):
        await asyncio.sleep(0.3)  # chờ API
        return "kết thúc phiên"


def test_slow_remote_model_does_not_block_safety():
    async def main():
        scheduler = GpuScheduler(8)
        scheduler.start()
        try:
            orch = Orchestrator(services(asr=SlowRemoteASR()), scheduler)
            task = asyncio.create_task(orch.handle(b"x", None))
            await asyncio.sleep(0.05)
            t = time.perf_counter()
            await scheduler.run(SAFETY, partial(StubDetector().detect, JPEG))
            waited = time.perf_counter() - t
            await task
            return waited
        finally:
            await scheduler.stop()

    assert asyncio.run(main()) < 0.1


def test_remote_safety_detector_bypasses_scheduler():
    alerts: list[dict] = []

    class RemoteYolo:
        remote = True

        async def detect(self, image):
            return [Detection("person", (0.3, 0.1, 0.7, 0.95), 0.9)]  # bbox lớn, depth None -> warning

    async def emit(alert):
        alerts.append(alert)

    async def main():
        scheduler = GpuScheduler(1)  # không start: nếu đi qua scheduler sẽ treo
        monitor = SafetyMonitor(RemoteYolo(), NoDepth(), scheduler, emit)
        task = asyncio.create_task(monitor.run())
        monitor.submit(JPEG)
        await asyncio.sleep(0.05)
        task.cancel()

    asyncio.run(main())
    assert alerts and alerts[0]["level"] == "warning" and "distance_m" not in alerts[0]


class SignDetector:
    async def detect(self, image):  # thứ tự theo diện tích, như ppocr thật trả về
        return [
            Detection("text", (0.11, 0.50, 0.61, 0.68), 0.87),  # LONG CHÂU
            Detection("text", (0.30, 0.25, 0.60, 0.41), 0.95),  # THUỐC
            Detection("text", (0.11, 0.236, 0.31, 0.42), 0.89),  # NHÀ
        ]


def test_read_text_follows_reading_order():
    import io as _io

    from PIL import Image as _Image

    buf = _io.BytesIO()
    _Image.new("RGB", (900, 500)).save(buf, format="PNG")
    seen: list[tuple[int, int]] = []

    class SizeOCR:
        async def read(self, image):
            w, _ = _Image.open(_io.BytesIO(image)).size
            seen.append(w)
            return {180: "NHÀ", 270: "THUỐC", 450: "LONG CHÂU"}[w]

    async def main():
        scheduler = GpuScheduler(8)
        scheduler.start()
        try:
            orch = Orchestrator(services(text_detector=SignDetector(), ocr=SizeOCR()), scheduler)
            return await orch.handle("đọc giúp tôi".encode(), buf.getvalue())
        finally:
            await scheduler.stop()

    assert asyncio.run(main()).text == "1) NHÀ\n2) THUỐC\n3) LONG CHÂU"
