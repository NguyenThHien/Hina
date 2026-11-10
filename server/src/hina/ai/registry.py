from collections.abc import Callable

import httpx
from pydantic import SecretStr

from hina.ai.asr.stub import StubASR
from hina.ai.base import AiServices
from hina.ai.depth.stub import StubDepth
from hina.ai.detection.stub import StubDetector
from hina.ai.nlu.http import HttpNLU
from hina.ai.nlu.stub import StubNLU
from hina.ai.ocr.stub import StubOCR
from hina.ai.tts.fpt import FptTTS
from hina.ai.tts.stub import StubTTS
from hina.ai.vlm.gemini import GeminiVLM
from hina.ai.vlm.stub import StubVLM
from hina.config import Settings

Factory = Callable[[Settings, httpx.AsyncClient], object]


def _plain(cls: type) -> Factory:
    return lambda s, http: cls()


def _secret(value: SecretStr | None, env_name: str) -> str:
    if value is None or not value.get_secret_value():
        raise ValueError(f"{env_name} is required for this AI impl (set it in .env)")
    return value.get_secret_value()


def _required(value: str | None, env_name: str) -> str:
    if not value:
        raise ValueError(f"{env_name} is required for this AI impl (set it in .env)")
    return value


# Thêm impl: IMPLS["asr"]["phowhisper"] = lambda s, http: PhoWhisperASR(...), rồi HINA_ASR=phowhisper.
IMPLS: dict[str, dict[str, Factory]] = {
    "asr": {"stub": _plain(StubASR)},
    "nlu": {
        "stub": _plain(StubNLU),
        "http": lambda s, http: HttpNLU(http, s.nlu_url, s.nlu_timeout_s),
    },
    "ocr": {"stub": _plain(StubOCR)},
    "detector": {"stub": _plain(StubDetector)},
    "depth": {"stub": _plain(StubDepth)},
    "vlm": {
        "stub": _plain(StubVLM),
        "gemini": lambda s, http: GeminiVLM(
            http,
            _secret(s.gemini_api_key, "HINA_GEMINI_API_KEY"),
            s.gemini_model,
            _required(s.gemini_base_url, "HINA_GEMINI_BASE_URL"),
        ),
    },
    "tts": {
        "stub": _plain(StubTTS),
        "fpt": lambda s, http: FptTTS(
            http, _secret(s.fpt_api_key, "HINA_FPT_API_KEY"), voice=s.fpt_voice, speed=s.fpt_speed
        ),
    },
}


def _pick(kind: str, s: Settings, http: httpx.AsyncClient):
    name = getattr(s, kind)
    try:
        factory = IMPLS[kind][name]
    except KeyError:
        raise ValueError(f"unknown {kind} impl {name!r}; available: {sorted(IMPLS[kind])}") from None
    return factory(s, http)


def build_services(s: Settings, http: httpx.AsyncClient) -> AiServices:
    return AiServices(**{kind: _pick(kind, s, http) for kind in IMPLS})
