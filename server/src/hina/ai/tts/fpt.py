"""TTS qua FPT.AI v5. API trả link file âm thanh (async): poll tới khi file sẵn sàng.

Endpoint/header theo tài liệu FPT.AI; đối chiếu lại tài liệu hiện hành khi có key.
Không tự timeout ở đây: Orchestrator bọc lời gọi bằng asyncio.timeout(tts_timeout_s).
"""

import asyncio

import httpx

API_URL = "https://api.fpt.ai/hmi/tts/v5"
_PENDING = (403, 404)  # file chưa được tạo xong


class TtsError(RuntimeError):
    pass


class FptTTS:
    def __init__(
        self,
        http: httpx.AsyncClient,
        api_key: str,
        voice: str = "banmai",
        speed: int = 0,
        poll_interval_s: float = 0.5,
    ) -> None:
        self._http = http
        self._headers = {"api-key": api_key, "voice": voice, "speed": str(speed), "format": "mp3"}
        self._poll_interval_s = poll_interval_s

    async def synthesize(self, text: str) -> bytes:
        res = await self._http.post(API_URL, content=text.encode("utf-8"), headers=self._headers)
        if res.status_code != 200:
            raise TtsError(f"fpt http {res.status_code}")
        data = res.json()
        if not isinstance(data, dict) or data.get("error") != 0 or not isinstance(data.get("async"), str):
            message = data.get("message") if isinstance(data, dict) else None
            raise TtsError(f"fpt error: {message}")
        url = data["async"]

        while True:
            audio = await self._http.get(url)
            if audio.status_code == 200 and audio.content:
                return audio.content
            if audio.status_code not in _PENDING:
                raise TtsError(f"fpt audio http {audio.status_code}")
            await asyncio.sleep(self._poll_interval_s)
