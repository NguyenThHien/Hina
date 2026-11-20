from collections.abc import Callable

import httpx
from pydantic import SecretStr

from hina.ai.asr.phowhisper import PhoWhisperASR
from hina.ai.asr.stub import StubASR
from hina.ai.base import AiServices
from hina.ai.depth.none import NoDepth
from hina.ai.depth.stub import StubDepth
from hina.ai.detection.ppocr import PpocrTextDetector
from hina.ai.detection.stub import StubDetector
from hina.ai.detection.yolo import YoloDetector
from hina.ai.nlu.http import HttpNLU
from hina.ai.nlu.stub import StubNLU
from hina.ai.ocr.stub import StubOCR
from hina.ai.ocr.vietocr import VietOCR
from hina.ai.tts.fpt import FptTTS
from hina.ai.tts.mms import MmsTTS
from hina.ai.tts.stub import StubTTS
from hina.ai.vlm.gemini import GeminiVLM
from hina.ai.vlm.smolvlm import SmolVLM
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
    "asr": {
        "stub": _plain(StubASR),
        "phowhisper": lambda s, http: PhoWhisperASR(
            http, s.phowhisper_url, _secret(s.phowhisper_api_key, "HINA_PHOWHISPER_API_KEY"), s.asr_timeout_s
        ),
    },
    "nlu": {
        "stub": _plain(StubNLU),
        "http": lambda s, http: HttpNLU(http, s.nlu_url, s.nlu_timeout_s),
    },
    "ocr": {
        "stub": _plain(StubOCR),
        "vietocr": lambda s, http: VietOCR(
            http, s.vietocr_url, _secret(s.vietocr_api_key, "HINA_VIETOCR_API_KEY"), s.ocr_timeout_s
        ),
    },
    "detector": {
        "stub": _plain(StubDetector),
        "yolo": lambda s, http: YoloDetector(
            http, s.yolo_url, _secret(s.yolo_api_key, "HINA_YOLO_API_KEY"), s.detector_timeout_s, s.yolo_conf
        ),
    },
    "text_detector": {
        "stub": _plain(StubDetector),
        "ppocr": lambda s, http: PpocrTextDetector(
            http, s.ppocr_url, _secret(s.ppocr_api_key, "HINA_PPOCR_API_KEY"), s.ocr_timeout_s
        ),
    },
    "depth": {"stub": _plain(StubDepth), "none": _plain(NoDepth)},
    "vlm": {
        "stub": _plain(StubVLM),
        "gemini": lambda s, http: GeminiVLM(
            http,
            _secret(s.gemini_api_key, "HINA_GEMINI_API_KEY"),
            s.gemini_model,
            _required(s.gemini_base_url, "HINA_GEMINI_BASE_URL"),
        ),
        "smolvlm": lambda s, http: SmolVLM(
            http, s.smolvlm_url, _secret(s.smolvlm_api_key, "HINA_SMOLVLM_API_KEY"), s.smolvlm_max_tokens
        ),
    },
    "tts": {
        "stub": _plain(StubTTS),
        "fpt": lambda s, http: FptTTS(
            http, _secret(s.fpt_api_key, "HINA_FPT_API_KEY"), voice=s.fpt_voice, speed=s.fpt_speed
        ),
        "mms": lambda s, http: MmsTTS(http, s.mms_url, _secret(s.mms_api_key, "HINA_MMS_API_KEY")),
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
