import httpx

from hina.ai.http_api import post_model

MAX_TEXT_CHARS = 1000  # API trả 422 nếu dài hơn


class MmsTTS:
    """TTS qua mms-tts-vie-api; trả WAV 16 kHz (mobile nhận diện qua header RIFF)."""

    remote = True

    def __init__(self, http: httpx.AsyncClient, base_url: str, api_key: str) -> None:
        self._http, self._key = http, api_key
        self._url = f"{base_url.rstrip('/')}/tts"

    async def synthesize(self, text: str) -> bytes:
        # Không tự timeout: Orchestrator bọc bằng asyncio.timeout(tts_timeout_s).
        res = await post_model(
            self._http, self._url, self._key, timeout=None, json={"text": text[:MAX_TEXT_CHARS]}
        )
        return res.content
