import asyncio
import logging
from dataclasses import dataclass
from functools import partial

from hina.aggregator.compose import NO_IMAGE, Result, compose
from hina.ai.base import AiServices, Intent
from hina.ai.scheduler import USER, GpuScheduler

log = logging.getLogger(__name__)

_NEEDS_IMAGE = frozenset(
    {Intent.READ_TEXT, Intent.DESCRIBE_SCENE, Intent.DETECT_OBJECT, Intent.VISUAL_QUESTION}
)
MAX_REPORTED_OBJECTS = 3


@dataclass(frozen=True)
class Reply:
    intent: str
    text: str
    audio: bytes  # rỗng nếu TTS lỗi: vẫn trả câu trả lời dạng chữ


class Orchestrator:
    """audio -> ASR -> NLU -> route theo intent -> Aggregator -> TTS.

    Model chạy trên GPU của nhóm (ASR, NLU, OCR, Detection, Depth, VLM tự fine-tune) đi qua
    GpuScheduler để Safety được ưu tiên. TTS là API bên ngoài (FPT.AI) nên gọi thẳng: scheduler
    chạy tuần tự, chờ mạng ở đó sẽ chặn Safety.
    """

    def __init__(self, ai: AiServices, scheduler: GpuScheduler, *, tts_timeout_s: float = 20) -> None:
        self._ai = ai
        self._gpu = partial(scheduler.run, USER)
        self._tts_timeout_s = tts_timeout_s

    async def handle(self, audio: bytes, image: bytes | None) -> Reply:
        ai = self._ai
        text = await self._gpu(partial(ai.asr.transcribe, audio))
        nlu = await self._gpu(partial(ai.nlu.parse, text))
        result = await self._route(nlu.intent, text, image)
        reply_text = compose(result)
        return Reply(result.intent, reply_text, await self._speak(reply_text))

    async def _route(self, intent: Intent, text: str, image: bytes | None) -> Result:
        ai = self._ai
        if intent in _NEEDS_IMAGE and image is None:
            return Result(NO_IMAGE)
        match intent:
            case Intent.READ_TEXT:
                return Result(intent, await self._gpu(partial(ai.ocr.read, image)))
            case Intent.DESCRIBE_SCENE | Intent.VISUAL_QUESTION:
                question = text if intent is Intent.VISUAL_QUESTION else None
                return Result(intent, await self._gpu(partial(ai.vlm.answer, image, question)))
            case Intent.DETECT_OBJECT:
                dets = (await self._gpu(partial(ai.detector.detect, image)))[:MAX_REPORTED_OBJECTS]
                dists = await asyncio.gather(
                    *(self._gpu(partial(ai.depth.distance_m, image, d.box)) for d in dets)
                )
                return Result(intent, found=tuple(zip(dets, dists, strict=True)))
            case _:
                return Result(Intent.UNKNOWN)

    async def _speak(self, text: str) -> bytes:
        try:
            async with asyncio.timeout(self._tts_timeout_s):
                return await self._ai.tts.synthesize(text)
        except Exception:
            log.warning("tts failed; sending text only", exc_info=True)
            return b""
