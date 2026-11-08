import asyncio
import logging
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


@dataclass(frozen=True)
class Reply:
    intent: Intent | str
    text: str
    audio: bytes  # rỗng nếu TTS lỗi: vẫn trả câu trả lời dạng chữ
    end_session: bool = False


class Orchestrator:
    """audio -> ASR -> NLU -> route theo intent -> Aggregator -> TTS.

    Model chạy trên GPU của nhóm (ASR, OCR, Detection, Depth, VLM tự fine-tune) đi qua
    GpuScheduler để Safety được ưu tiên. NLU và TTS là API bên ngoài nên gọi thẳng: scheduler
    chạy tuần tự, chờ mạng ở đó sẽ chặn Safety.
    """

    def __init__(self, ai: AiServices, scheduler: GpuScheduler, *, tts_timeout_s: float = 20) -> None:
        self._ai = ai
        self._gpu = partial(scheduler.run, USER)
        self._tts_timeout_s = tts_timeout_s

    async def handle(self, audio: bytes, image: bytes | None) -> Reply:
        ai = self._ai
        text = await self._gpu(partial(ai.asr.transcribe, audio))
        nlu = await ai.nlu.parse(text)
        result = await self._route(nlu.intent, text, image)
        reply_text = compose(result)
        return Reply(
            result.intent,
            reply_text,
            await self._speak(reply_text),
            end_session=nlu.intent is Intent.END_SESSION,
        )

    async def _route(self, intent: Intent, text: str, image: bytes | None) -> Result:
        ai = self._ai
        if intent in _NEEDS_IMAGE and image is None:
            return Result(NO_IMAGE)
        match intent:
            case Intent.READ_TEXT:
                return Result(intent, await self._read_text(image))
            case Intent.DESCRIBE_SCENE | Intent.ANSWER_VISUAL_QUESTION:
                return Result(intent, await self._gpu(partial(ai.vlm.answer, image, text)))
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

    async def _speak(self, text: str) -> bytes:
        try:
            async with asyncio.timeout(self._tts_timeout_s):
                return await self._ai.tts.synthesize(text)
        except Exception:
            log.warning("tts failed; sending text only", exc_info=True)
            return b""
