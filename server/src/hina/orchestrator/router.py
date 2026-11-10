import asyncio
import logging
import time
from collections.abc import Callable
from dataclasses import dataclass
from functools import partial

from hina.aggregator.compose import NO_IMAGE, Result, compose
from hina.ai.base import AiServices, Intent
from hina.ai.scheduler import USER, GpuScheduler
from hina.geometry import area
from hina.preprocess.image import CropError, crop

log = logging.getLogger(__name__)

_NEEDS_IMAGE = frozenset({Intent.READ_TEXT, Intent.DESCRIBE_SCENE, Intent.ANSWER_VISUAL_QUESTION})
MAX_READ_BOXES = 3
MIN_BOX_CONFIDENCE = 0.5

Note = Callable[..., None]  # note(stage, **data): ghi một bước cho trang /debug


def _noop(stage: str, **data: object) -> None:
    pass


@dataclass(frozen=True)
class Reply:
    intent: Intent | str
    text: str
    audio: bytes  # rỗng nếu TTS lỗi: vẫn trả câu trả lời dạng chữ
    end_session: bool = False


class Orchestrator:
    """audio -> ASR -> NLU -> route theo intent -> Aggregator -> TTS.

    Model chạy trên GPU của nhóm (ASR, OCR, Detection, Depth, VLM tự fine-tune) đi qua
    GpuScheduler để Safety được ưu tiên. NLU, TTS và VLM qua API (impl có `remote = True`, vd
    Gemini) gọi thẳng: scheduler chạy tuần tự, chờ mạng ở đó sẽ chặn Safety.
    """

    def __init__(
        self,
        ai: AiServices,
        scheduler: GpuScheduler,
        *,
        tts_timeout_s: float = 20,
        vlm_timeout_s: float = 15,
    ) -> None:
        self._ai = ai
        self._gpu = partial(scheduler.run, USER)
        self._tts_timeout_s = tts_timeout_s
        self._vlm_timeout_s = vlm_timeout_s

    async def handle(self, audio: bytes, image: bytes | None, note: Note = _noop) -> Reply:
        ai = self._ai
        t = time.perf_counter()
        text = await self._gpu(partial(ai.asr.transcribe, audio))
        note("asr", text=text, ms=_ms(t))
        t = time.perf_counter()
        nlu = await ai.nlu.parse(text)
        note("nlu", intent=nlu.intent.name, intent_id=int(nlu.intent), ms=_ms(t))
        t = time.perf_counter()
        result = await self._route(nlu.intent, text, image)
        reply_text = compose(result)
        intent_name = result.intent.name if isinstance(result.intent, Intent) else result.intent
        note("route", intent=intent_name, text=reply_text, ms=_ms(t))
        t = time.perf_counter()
        audio_out = await self._speak(reply_text)
        note("tts", bytes=len(audio_out), ok=bool(audio_out), ms=_ms(t))
        return Reply(result.intent, reply_text, audio_out, end_session=nlu.intent is Intent.END_SESSION)

    async def _route(self, intent: Intent, text: str, image: bytes | None) -> Result:
        if intent in _NEEDS_IMAGE and image is None:
            return Result(NO_IMAGE)
        match intent:
            case Intent.READ_TEXT:
                return Result(intent, await self._read_text(image))
            case Intent.DESCRIBE_SCENE:
                return Result(intent, await self._vlm(image, None))  # captioning
            case Intent.ANSWER_VISUAL_QUESTION:
                return Result(intent, await self._vlm(image, text))  # VQA
            case Intent.END_SESSION:
                return Result(intent)
            case _:
                return Result(Intent.UNKNOWN)

    async def _read_text(self, image: bytes) -> str:
        ai = self._ai
        dets = await self._gpu(partial(ai.detector.detect, image))
        boxes = [
            d.box
            for d in sorted(dets, key=lambda d: area(d.box), reverse=True)
            if d.confidence >= MIN_BOX_CONFIDENCE
        ][:MAX_READ_BOXES]
        crops: list[bytes] = []
        for box in boxes:
            try:
                crops.append(await asyncio.to_thread(crop, image, box))
            except (CropError, OSError):
                log.warning("crop failed for box %s", box, exc_info=True)
        if not crops:
            return await self._gpu(partial(ai.ocr.read, image))
        texts = await asyncio.gather(*(self._gpu(partial(ai.ocr.read, c)) for c in crops))
        parts = [t.strip() for t in texts if t.strip()]
        if len(parts) == 1:
            return parts[0]
        return "\n".join(f"{i}) {t}" for i, t in enumerate(parts, 1))

    async def _vlm(self, image: bytes, question: str | None) -> str:
        vlm = self._ai.vlm
        if getattr(vlm, "remote", False):
            async with asyncio.timeout(self._vlm_timeout_s):
                return await vlm.answer(image, question)
        return await self._gpu(partial(vlm.answer, image, question))

    async def _speak(self, text: str) -> bytes:
        try:
            async with asyncio.timeout(self._tts_timeout_s):
                return await self._ai.tts.synthesize(text)
        except Exception:
            log.warning("tts failed; sending text only", exc_info=True)
            return b""


def _ms(start: float) -> int:
    return round((time.perf_counter() - start) * 1000)
