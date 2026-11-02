from collections.abc import Callable

from hina.ai.asr.stub import StubASR
from hina.ai.base import AiServices
from hina.ai.depth.stub import StubDepth
from hina.ai.detection.stub import StubDetector
from hina.ai.nlu.stub import StubNLU
from hina.ai.ocr.stub import StubOCR
from hina.ai.tts.stub import StubTTS
from hina.ai.vlm.stub import StubVLM
from hina.config import Settings

# Thêm impl thật: IMPLS["asr"]["phowhisper-base"] = PhoWhisperASR, rồi set HINA_ASR=phowhisper-base.
IMPLS: dict[str, dict[str, Callable[[], object]]] = {
    "asr": {"stub": StubASR},
    "nlu": {"stub": StubNLU},
    "ocr": {"stub": StubOCR},
    "detector": {"stub": StubDetector},
    "depth": {"stub": StubDepth},
    "vlm": {"stub": StubVLM},
    "tts": {"stub": StubTTS},
}


def _pick(kind: str, name: str):
    try:
        return IMPLS[kind][name]()
    except KeyError:
        raise ValueError(f"unknown {kind} impl {name!r}; available: {sorted(IMPLS[kind])}") from None


def build_services(s: Settings) -> AiServices:
    return AiServices(**{k: _pick(k, getattr(s, k)) for k in IMPLS})
