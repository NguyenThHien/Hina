import asyncio
from dataclasses import dataclass
from functools import partial

from hina.aggregator.compose import NO_IMAGE, Result, compose
from hina.ai.base import AiServices, Intent
from hina.ai.scheduler import USER, GpuScheduler

_NEEDS_IMAGE = frozenset(
    {Intent.READ_TEXT, Intent.DESCRIBE_SCENE, Intent.DETECT_OBJECT, Intent.VISUAL_QUESTION}
)
MAX_REPORTED_OBJECTS = 3


@dataclass(frozen=True)
class Reply:
    intent: str
    text: str
    audio: bytes


class Orchestrator:
    """audio -> ASR -> NLU -> route theo intent -> Aggregator -> TTS."""

    def __init__(self, ai: AiServices, scheduler: GpuScheduler) -> None:
        self._ai = ai
        self._run = partial(scheduler.run, USER)

    async def handle(self, audio: bytes, image: bytes | None) -> Reply:
        ai = self._ai
        text = await self._run(partial(ai.asr.transcribe, audio))
        nlu = await self._run(partial(ai.nlu.parse, text))
        result = await self._route(nlu.intent, text, image)
        reply_text = compose(result)
        speech = await self._run(partial(ai.tts.synthesize, reply_text))
        return Reply(result.intent, reply_text, speech)

    async def _route(self, intent: Intent, text: str, image: bytes | None) -> Result:
        ai = self._ai
        if intent in _NEEDS_IMAGE and image is None:
            return Result(NO_IMAGE)
        match intent:
            case Intent.READ_TEXT:
                return Result(intent, await self._run(partial(ai.ocr.read, image)))
            case Intent.DESCRIBE_SCENE | Intent.VISUAL_QUESTION:
                question = text if intent is Intent.VISUAL_QUESTION else None
                return Result(intent, await self._run(partial(ai.vlm.answer, image, question)))
            case Intent.DETECT_OBJECT:
                dets = (await self._run(partial(ai.detector.detect, image)))[:MAX_REPORTED_OBJECTS]
                dists = await asyncio.gather(
                    *(self._run(partial(ai.depth.distance_m, image, d.box)) for d in dets)
                )
                return Result(intent, found=tuple(zip(dets, dists, strict=True)))
            case _:
                return Result(Intent.UNKNOWN)
