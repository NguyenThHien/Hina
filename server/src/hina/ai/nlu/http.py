import logging

import httpx

from hina.ai.base import Intent, NluResult

log = logging.getLogger(__name__)

MAX_TEXT_CHARS = 500  # API trả 422 nếu dài hơn, nên cắt trước khi gửi


class HttpNLU:
    """NLU qua API ngoài (POST /v1/predict). Mọi lỗi -> UNKNOWN để app hỏi lại.

    Gọi thẳng, KHÔNG qua GpuScheduler: đây là I/O mạng, chờ trong scheduler sẽ chặn Safety.
    """

    def __init__(self, http: httpx.AsyncClient, base_url: str, timeout_s: float = 5) -> None:
        self._http = http
        self._url = f"{base_url.rstrip('/')}/v1/predict"
        self._timeout_s = timeout_s

    async def parse(self, text: str) -> NluResult:
        t = text.strip()[:MAX_TEXT_CHARS]
        if not t:
            return NluResult(Intent.UNKNOWN)
        try:
            resp = await self._http.post(self._url, json={"text": t}, timeout=self._timeout_s)
            resp.raise_for_status()
            intent = Intent(int(resp.json()["label_id"]))
        except Exception:
            log.warning("nlu request failed; asking the user to repeat", exc_info=True)
            return NluResult(Intent.UNKNOWN)
        return NluResult(intent)
