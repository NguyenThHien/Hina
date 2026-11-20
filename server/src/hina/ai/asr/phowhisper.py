import httpx

from hina.ai.http_api import post_model
from hina.preprocess.audio import prepare_audio


class PhoWhisperASR:
    remote = True

    def __init__(self, http: httpx.AsyncClient, base_url: str, api_key: str, timeout_s: float) -> None:
        self._http, self._key, self._timeout = http, api_key, timeout_s
        self._url = f"{base_url.rstrip('/')}/transcribe"

    async def transcribe(self, audio: bytes) -> str:
        wav = prepare_audio(audio)
        res = await post_model(
            self._http, self._url, self._key, timeout=self._timeout,
            files={"file": ("audio.wav", wav, "audio/wav")},
        )
        return str(res.json()["text"]).strip()
