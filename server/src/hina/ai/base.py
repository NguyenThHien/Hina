"""Interface mỏng cho 7 khối AI. Orchestrator/Safety chỉ biết các Protocol này."""

from dataclasses import dataclass, field
from enum import StrEnum
from typing import Protocol

from hina.geometry import Box


class Intent(StrEnum):
    READ_TEXT = "READ_TEXT"
    DESCRIBE_SCENE = "DESCRIBE_SCENE"
    DETECT_OBJECT = "DETECT_OBJECT"
    VISUAL_QUESTION = "VISUAL_QUESTION"
    UNKNOWN = "UNKNOWN"


@dataclass(frozen=True)
class Detection:
    label: str
    box: Box
    confidence: float


@dataclass(frozen=True)
class NluResult:
    intent: Intent
    entities: dict[str, str] = field(default_factory=dict)


# ponytail: impl thật có inference blocking phải tự chạy trong executor (asyncio.to_thread),
# nếu không sẽ chặn event loop của scheduler.
class ASR(Protocol):
    async def transcribe(self, audio: bytes) -> str: ...


class NLU(Protocol):
    async def parse(self, text: str) -> NluResult: ...


class OCR(Protocol):
    async def read(self, image: bytes) -> str: ...


class Detector(Protocol):
    async def detect(self, image: bytes) -> list[Detection]: ...


class Depth(Protocol):
    async def distance_m(self, image: bytes, box: Box) -> float | None:
        """None nếu không đủ tin cậy để đưa ra số mét."""
        ...


class VLM(Protocol):
    async def answer(self, image: bytes, question: str | None) -> str: ...


class TTS(Protocol):
    async def synthesize(self, text: str) -> bytes: ...


@dataclass(frozen=True)
class AiServices:
    asr: ASR
    nlu: NLU
    ocr: OCR
    detector: Detector
    depth: Depth
    vlm: VLM
    tts: TTS
